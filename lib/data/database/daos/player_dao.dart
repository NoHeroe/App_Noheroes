import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/events/player_events.dart';
import '../../../domain/entities/player.dart';

/// Wrapper fino full-online (Época 2 — ADR-0024) que substitui o antigo
/// `PlayerDao` (Drift). Mantém a MESMA API de métodos pra que callers
/// compilem sem mudança, mas delega TUDO ao Supabase: leituras viram
/// PostgREST (`from('players')...`) e operações atômicas (read-modify-write,
/// multi-write) viram RPCs Postgres (`rpc(...)`).
///
/// Diferenças de assinatura vs. versão Drift:
///   - `id` que refere o JOGADOR agora é `String` (uuid = auth.users.id),
///     não mais `int`.
///   - `findById`/`findByEmail` retornam [Player] (`fromMap`) em vez de
///     `PlayersTableData`.
///   - `createPlayer` saiu — criação de jogador é responsabilidade do
///     fluxo de auth/onboarding (signup do Supabase), não deste wrapper.
class PlayerDao {
  final SupabaseClient _client;
  PlayerDao(this._client);

  Future<Player?> findByEmail(String email) async {
    final row = await _client
        .from('players')
        .select()
        .eq('email', email)
        .maybeSingle();
    return row == null ? null : Player.fromMap(row);
  }

  Future<Player?> findById(String id) async {
    final row =
        await _client.from('players').select().eq('id', id).maybeSingle();
    return row == null ? null : Player.fromMap(row);
  }

  /// Atômico — RPC `touch_last_login` (streak + caelum_day + last_login_at).
  Future<void> touchLastLogin(String id) async {
    await _client.rpc('touch_last_login', params: {'p_player': id});
  }

  Future<void> completeOnboarding(
      String id, String shadowName, String narrativeMode) async {
    await _client.from('players').update({
      'onboarding_done': true,
      'shadow_name': shadowName,
      'narrative_mode': narrativeMode,
    }).eq('id', id);
  }

  /// Credita XP via RPC `add_xp` (level loop + scaling + max_hp/mp + peak).
  /// A RPC retorna `{previous_level, new_level}` (ou null se player ausente).
  /// Reconstrói o `LevelUp?` que o caller publica no [AppEventBus] (a borda
  /// data segue desacoplada de events — ADR 0016).
  Future<LevelUp?> addXp(String id, int xpAmount) async {
    final res = await _client.rpc('add_xp', params: {
      'p_player': id,
      'p_amount': xpAmount,
    });
    if (res == null) return null;
    final map = res as Map<String, dynamic>;
    final prev = (map['previous_level'] as num).toInt();
    final next = (map['new_level'] as num).toInt();
    if (next > prev) {
      return LevelUp(playerId: id, newLevel: next, previousLevel: prev);
    }
    return null;
  }

  /// Setter direto pra `xp_to_next` (backfill defensivo de players legacy).
  Future<void> setXpToNext(String id, int value) async {
    await _client.from('players').update({'xp_to_next': value}).eq('id', id);
  }

  /// Marca timestamp (ms epoch) do último daily reset.
  Future<void> markDailyReset(String id, DateTime at) async {
    await _client
        .from('players')
        .update({'last_daily_reset': at.millisecondsSinceEpoch})
        .eq('id', id);
  }

  /// Análogo pro weekly.
  Future<void> markWeeklyReset(String id, DateTime at) async {
    await _client
        .from('players')
        .update({'last_weekly_reset': at.millisecondsSinceEpoch})
        .eq('id', id);
  }

  /// Persiste peso/altura (ranges validados pelo BodyMetricsService antes).
  Future<void> updateBodyMetrics(String id,
      {int? weightKg, int? heightCm}) async {
    final patch = <String, dynamic>{};
    if (weightKg != null) patch['weight_kg'] = weightKg;
    if (heightCm != null) patch['height_cm'] = heightCm;
    if (patch.isEmpty) return;
    await _client.from('players').update(patch).eq('id', id);
  }

  /// Marca timestamp (ms epoch) do último rollover de missões diárias.
  Future<void> markDailyMissionRollover(String id, DateTime at) async {
    await _client
        .from('players')
        .update({'last_daily_mission_rollover': at.millisecondsSinceEpoch})
        .eq('id', id);
  }

  /// Incremento atômico do streak de missões diárias — RPC.
  Future<void> incrementDailyMissionsStreak(String id) async {
    await _client
        .rpc('increment_daily_missions_streak', params: {'p_player': id});
  }

  /// Reset atômico do streak de missões diárias — RPC.
  Future<void> resetDailyMissionsStreak(String id) async {
    await _client
        .rpc('reset_daily_missions_streak', params: {'p_player': id});
  }

  Future<void> setAutoConfirmEnabled(String id, bool value) async {
    await _client
        .from('players')
        .update({'auto_confirm_enabled': value})
        .eq('id', id);
  }

  /// Persiste CSV de paths visitados. O read-modify-write atômico vive na
  /// RPC `record_screen_visit` (usada via PlayerScreensVisitedService); este
  /// setter só sobrescreve o valor recebido.
  Future<void> setScreensVisitedKeys(String id, String csv) async {
    await _client
        .from('players')
        .update({'screens_visited_keys': csv})
        .eq('id', id);
  }

  /// Crédito de gold atômico (gold + lifetime) — RPC `add_gold`.
  Future<void> addGold(String id, int amount) async {
    await _client.rpc('add_gold', params: {
      'p_player': id,
      'p_amount': amount,
    });
  }

  /// Atualiza corrupção/estado da sombra atomicamente — RPC `update_shadow`.
  Future<void> updateShadow(String id, int shadowImpact) async {
    await _client.rpc('update_shadow', params: {
      'p_player': id,
      'p_shadow_impact': shadowImpact,
    });
  }

  /// Distribui 1 ponto de atributo via RPC `distribute_point`. Retorna `null`
  /// em sucesso ou a string de erro em falha (legacy callers).
  Future<String?> distributePoint(String id, String attribute) async {
    final result = await distributePointWithEvent(id, attribute);
    return result.error;
  }

  /// Variante que reconstrói o `AttributePointSpent` pra caller publicar.
  /// A RPC `distribute_point` faz o spend + incrementa
  /// `total_attribute_points_spent` atomicamente e retorna `{error, new_value}`.
  Future<DistributePointResult> distributePointWithEvent(
      String id, String attribute) async {
    final res = await _client.rpc('distribute_point', params: {
      'p_player': id,
      'p_attribute': attribute,
    });
    final map = (res as Map<String, dynamic>?) ?? const {};
    final error = map['error'] as String?;
    if (error != null) {
      return DistributePointResult.error(error);
    }
    final newValue = (map['new_value'] as num?)?.toInt() ?? 0;
    return DistributePointResult.ok(AttributePointSpent(
      playerId: id,
      attributeKey: attribute,
      newValue: newValue,
    ));
  }

  /// Reset de atributos de nível atômico — RPC `reset_level_attributes`.
  Future<void> resetLevelAttributes(
      String id, int level, int goldCost) async {
    await _client.rpc('reset_level_attributes', params: {
      'p_player': id,
      'p_level': level,
      'p_gold_cost': goldCost,
    });
  }
}

/// Resultado imutável de [PlayerDao.distributePointWithEvent]. Em sucesso,
/// [event] é non-null e [error] é null. Em falha, vice-versa.
class DistributePointResult {
  final AttributePointSpent? event;
  final String? error;

  const DistributePointResult.ok(AttributePointSpent this.event)
      : error = null;
  const DistributePointResult.error(String this.error) : event = null;

  bool get isOk => event != null;
}
