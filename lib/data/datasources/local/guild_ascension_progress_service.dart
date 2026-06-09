import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/events/app_event.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/daily_mission_events.dart';
import '../../../core/events/diary_events.dart';
import '../../../core/events/mission_events.dart';
import '../../../core/events/reward_events.dart';
import 'guild_ascension_service.dart';

/// A.2 — ignição event-driven do motor de ascensão da Guilda (Época 2,
/// full-online — ADR-0024).
///
/// Escuta eventos terminais de gameplay e re-avalia o progresso dos steps do
/// ciclo de ascensão do player contra DADOS VIVOS (via `GuildAscensionService`,
/// agora PostgREST). NÃO ascende (o `ascend()` é manual no botão da
/// `AscensionTab`). Sem reward/grant aqui.
///
/// ## Eventos consumidos
/// `DailyMissionCompleted`/`DailyMissionFailed`, `MissionCompleted`,
/// `DiaryEntryCreated`, `RewardGranted`, `AchievementUnlocked`.
///
/// ## Serialização
/// Fila serial `_tail` — garante avanço sequencial dos steps entre eventos
/// concorrentes. O read-modify-write atômico de UMA row é feito no servidor
/// (update por id); a fila evita corrida entre steps do MESMO ciclo.
///
/// ## NOTA de migração (uuid vs int nos eventos)
/// Os eventos do EventBus ainda carregam `int playerId` (camada de eventos
/// não-migrada). O caminho EVENT-DRIVEN (`_onEvent`) não consegue recuperar o
/// uuid do jogador a partir desse int → fica desabilitado até a migração dos
/// eventos pra String. O caminho ON-DEMAND (`evaluatePlayer(String)`, chamado
/// pela `AscensionTab` com `player.id` uuid) funciona normalmente. Ver
/// 'unresolved' do resumo de migração.
class GuildAscensionProgressService {
  final SupabaseClient _client;
  final AppEventBus _bus;
  final GuildAscensionService _ascension;

  final List<StreamSubscription> _subs = [];
  Future<void> _tail = Future<void>.value();

  GuildAscensionProgressService({
    required SupabaseClient client,
    required AppEventBus bus,
    required GuildAscensionService ascension,
  })  : _client = client,
        _bus = bus,
        _ascension = ascension;

  void start() {
    _subs.add(_bus.on<DailyMissionCompleted>().listen(_onEvent));
    _subs.add(_bus.on<DailyMissionFailed>().listen(_onEvent));
    _subs.add(_bus.on<MissionCompleted>().listen(_onEvent));
    _subs.add(_bus.on<DiaryEntryCreated>().listen(_onEvent));
    _subs.add(_bus.on<RewardGranted>().listen(_onEvent));
    _subs.add(_bus.on<AchievementUnlocked>().listen(_onEvent));
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  void _onEvent(AppEvent evt) {
    // MIGRAÇÃO: evt.playerId é `int` (eventos legacy). Sem mapeamento int→uuid
    // confiável, o caminho event-driven fica inerte até os eventos migrarem
    // pra String playerId. A re-avaliação on-demand (evaluatePlayer) cobre a
    // UI da AscensionTab nesse meio-tempo. Ver 'unresolved'.
    if (evt.playerId == null) return;
    // Intencionalmente sem enfileirar: não há uuid pra passar ao
    // GuildAscensionService (que agora exige String playerId).
  }

  /// Enfileira [task] no encadeamento serial. Erros logados sem quebrar
  /// a fila (próximo task ainda roda).
  Future<void> _enqueue(Future<void> Function() task) {
    final next = _tail.then((_) => task());
    _tail = next.catchError((Object e, StackTrace st) {
      // ignore: avoid_print
      print('[ascension-progress] task falhou: $e\n$st');
    });
    return next;
  }

  /// Re-avaliação on-demand (ex: `AscensionTab.build`). Mesma fila serial.
  /// `playerId` é o uuid do jogador (String).
  Future<void> evaluatePlayer(String playerId) =>
      _enqueue(() => _evaluatePlayer(playerId));

  /// Future que resolve quando a fila atual esvazia (testes).
  Future<void> settle() => _tail;

  Future<void> _evaluatePlayer(String playerId) async {
    final row = await _client
        .from('players')
        .select('guild_rank')
        .eq('id', playerId)
        .maybeSingle();
    if (row == null) return;
    final rank = (row['guild_rank'] as String?) ?? 'none';
    // Sem rank (não é membro) ou já no topo → nada a avançar.
    if (rank.isEmpty ||
        rank.toLowerCase() == 'none' ||
        rank.toUpperCase() == 'S') {
      return;
    }

    // B.3 — só avança trials com JANELA ATIVA não vencida. A materialização
    // dos trials é responsabilidade do `pay()` (RPC). Fora de `active` →
    // no-op (evita auto-completar por contador lifetime antes de pagar).
    final st = await _client
        .from('guild_ascension_state')
        .select('status, window_deadline_ms')
        .eq('player_id', playerId)
        .eq('rank_from', rank.toUpperCase())
        .maybeSingle();
    if (st == null) return;
    if ((st['status'] as String?) != 'active') return;
    final deadline = (st['window_deadline_ms'] as num?)?.toInt();
    if (deadline == null ||
        DateTime.now().millisecondsSinceEpoch >= deadline) {
      return;
    }

    // Avança quantos trials estiverem satisfeitos pelos contadores dentro
    // da janela. Cap = nº de trials + 1 → evita loop infinito.
    final missions = await _ascension.getMissions(playerId, rank);
    var guard = missions.length + 1;
    while (guard-- > 0) {
      final completed = await _ascension.checkCurrentMission(playerId, rank);
      if (!completed) break;
    }
  }
}
