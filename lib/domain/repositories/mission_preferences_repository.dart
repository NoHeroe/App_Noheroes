import '../models/mission_preferences.dart';

/// Sprint 3.1 Bloco 4 — Repository das preferências do quiz de
/// calibração (`player_mission_preferences`). Relação 1:1 com players.
abstract class MissionPreferencesRepository {
  /// Preferências do jogador ou `null` se ainda não calibrou.
  Future<MissionPreferences?> findByPlayerId(int playerId);

  /// Grava ou atualiza. Usado na primeira calibração (ADR 0015) e em
  /// cada refazer do quiz — neste caso incrementa `updates_count`.
  ///
  /// Contratos do chamador:
  ///   - `prefs.createdAt` só é respeitado na primeira gravação; updates
  ///     subsequentes preservam o createdAt persistido (DB é fonte da
  ///     verdade aqui).
  ///   - `prefs.updatesCount` deve ser incrementado pelo chamador antes
  ///     de chamar upsert (ex: `prefs.copyWith(updatesCount: old + 1)`).
  Future<void> upsert(MissionPreferences prefs);

  /// Atalho pro gating de refazer (Bloco 9): retorna `updates_count`
  /// atual do jogador, ou 0 se nunca calibrou.
  Future<int> updatesCountOf(int playerId);
}
