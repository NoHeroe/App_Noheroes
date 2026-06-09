import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/faction_alliances.dart';
import '../../core/events/app_event_bus.dart';
import '../../core/events/faction_events.dart';
import 'faction_buff_service.dart';

/// Sprint 3.1 Bloco 13b — CRUD + propagação via alianças.
///
/// Época 2 (ADR-0024) — full-online Supabase. A leitura/escrita da
/// reputação 0-100 por `(playerId, factionId)` (default 50 neutro) é
/// atômica via RPC `faction_reputation_delta` (read-modify-write +
/// clamp + upsert no servidor). O service orquestra a propagação via
/// `kFactionAlliances` client-side (cada single-delta é atômico na sua
/// própria RPC — paridade com o Dart original, onde cada `_adjustSingle`
/// era independente) e mantém a emissão de `FactionReputationChanged`
/// no cliente.
///
/// `adjustReputation(playerId, factionId, delta)`:
///
///   1. Aplica delta na facção alvo (RPC retorna before/after).
///   2. Emite `FactionReputationChanged` pra facção alvo.
///   3. Itera `kFactionAlliances[factionId]` — pra cada (aliada/rival,
///      multiplier): aplica `delta × multiplier` na aliada + emit evento.
///
/// Matrix vazia (neutra) → passo 3 é noop. Multiplier pode ser negativo
/// (rival) — a RPC aceita delta negativo e faz clamp 0 na base.
class FactionReputationService {
  final SupabaseClient _client;
  final AppEventBus _bus;

  /// Sprint 3.4 Etapa C — xpMult universal: buff de facção aplica em
  /// reputação ganha (delta > 0) com mesma porcentagem do XP. Opcional
  /// pra retrocompat de testes.
  final FactionBuffService? _factionBuff;

  FactionReputationService({
    required SupabaseClient client,
    required AppEventBus bus,
    FactionBuffService? factionBuff,
  })  : _client = client,
        _bus = bus,
        _factionBuff = factionBuff;

  /// Reputação atual (cria lazy default 50 se não existe).
  ///
  /// Lê direto a row; `faction_reputation_delta` cria/atualiza, mas a
  /// leitura pura usa um delta 0 implícito? Não — pra não escrever, lemos
  /// a row e devolvemos 50 se ausente (paridade com `getOrDefault`).
  Future<int> current(String playerId, String factionId) async {
    final row = await _client
        .from('player_faction_reputation')
        .select('reputation')
        .eq('player_id', playerId)
        .eq('faction_id', factionId)
        .maybeSingle();
    if (row == null) return 50;
    return (row['reputation'] as num?)?.toInt() ?? 50;
  }

  /// Todas as reputações do jogador.
  Future<Map<String, int>> all(String playerId) async {
    final rows = await _client
        .from('player_faction_reputation')
        .select('faction_id, reputation')
        .eq('player_id', playerId);
    final out = <String, int>{};
    for (final r in (rows as List)) {
      final m = (r as Map).cast<String, dynamic>();
      final fid = m['faction_id'] as String?;
      if (fid == null) continue;
      out[fid] = (m['reputation'] as num?)?.toInt() ?? 50;
    }
    return out;
  }

  /// Aplica [delta] em [factionId] + propaga via matrix.
  ///
  /// Delta positivo = subiu reputação. Matrix aliada aplica sinal
  /// preservado; matrix rival aplica sinal invertido via multiplier
  /// negativo.
  ///
  /// Emite `FactionReputationChanged` pra cada facção afetada.
  ///
  /// Sprint 3.4 Etapa C — xpMult universal aplica em delta GANHO
  /// (positivo). Penalidades (delta < 0) e propagações negativas via
  /// matrix passam cru. Regra OPÇÃO A: Guilda member ganhando rep
  /// **da Guilda** não recebe buff (buff só aplica em outras facções).
  Future<void> adjustReputation({
    required String playerId,
    required String factionId,
    required int delta,
  }) async {
    if (delta == 0) return;

    final adjustedMain = await _applyBuff(playerId, factionId, delta);

    // 1. Aplica delta principal.
    await _adjustSingle(
      playerId: playerId,
      factionId: factionId,
      delta: adjustedMain,
    );

    // 2. Propaga via matrix de alianças (neutra = noop).
    //    Propagação usa o delta ORIGINAL como base (não o buffed) —
    //    semântica: matrix amplifica o gesto original, não o ganho
    //    pessoal já buffado. Após propagação, aplica buff individual
    //    em cada aliada propagada (mesma regra OPÇÃO A).
    final allies = kFactionAlliances[factionId] ?? const <String, double>{};
    for (final entry in allies.entries) {
      final ally = entry.key;
      final mult = entry.value;
      final propagated = (delta * mult).round();
      if (propagated == 0) continue;
      final adjustedProp = await _applyBuff(playerId, ally, propagated);
      await _adjustSingle(
        playerId: playerId,
        factionId: ally,
        delta: adjustedProp,
      );
    }
  }

  /// xpMult em delta positivo, com OPÇÃO A pra Guilda. Sem buff injetado
  /// → retorna delta cru (path legacy/teste).
  Future<int> _applyBuff(
      String playerId, String targetFactionId, int delta) async {
    if (delta <= 0) return delta;
    final buff = _factionBuff;
    if (buff == null) return delta;

    final mults = await buff.getActiveMultipliers(playerId);
    if (mults.xpMult == 1.0) return delta;

    if (targetFactionId == 'guild') {
      final row = await _client
          .from('players')
          .select('faction_type')
          .eq('id', playerId)
          .maybeSingle();
      if (row != null && row['faction_type'] == 'guild') {
        return delta; // Guilda member ganhando rep da Guilda — sem buff
      }
    }
    return (delta * mults.xpMult).round();
  }

  /// Aplica um único delta atômico via RPC `faction_reputation_delta`
  /// (read-modify-write + clamp 0..100 + upsert no servidor). A RPC
  /// retorna `{before, after}`; emitimos `FactionReputationChanged`
  /// só quando houve mudança real (clamp pode engolir o delta).
  Future<void> _adjustSingle({
    required String playerId,
    required String factionId,
    required int delta,
  }) async {
    final res = await _client.rpc('faction_reputation_delta', params: {
      'p_player': playerId,
      'p_faction': factionId,
      'p_delta': delta,
    });
    final map = (res as Map).cast<String, dynamic>();
    final before = (map['before'] as num?)?.toInt() ?? 50;
    final after = (map['after'] as num?)?.toInt() ?? before;
    if (after != before) {
      _bus.publish(FactionReputationChanged(
        playerId: playerId,
        factionId: factionId,
        newValue: after,
        previousValue: before,
      ));
    }
  }
}
