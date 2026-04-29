import 'package:drift/drift.dart';

import '../../../domain/models/player_daily_subtask_volume.dart';
import '../app_database.dart';
import '../tables/player_daily_subtask_volume_table.dart';

part 'player_daily_subtask_volume_dao.g.dart';

/// Sprint 3.3 Etapa 2.1a — DAO da tabela
/// [PlayerDailySubtaskVolumeTable]. Tracking **terminal**: o
/// `DailyMissionStatsService` soma `progressoAtual` de cada sub-task
/// no fechamento da missão.
@DriftAccessor(tables: [PlayerDailySubtaskVolumeTable])
class PlayerDailySubtaskVolumeDao extends DatabaseAccessor<AppDatabase>
    with _$PlayerDailySubtaskVolumeDaoMixin {
  PlayerDailySubtaskVolumeDao(super.db);

  /// Volume all-time de uma sub-tarefa específica. Retorna `0` se a row
  /// nunca foi criada.
  Future<int> getVolume(int playerId, String subTaskKey) async {
    final row = await (select(playerDailySubtaskVolumeTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.subTaskKey.equals(subTaskKey)))
        .getSingleOrNull();
    return row?.totalUnits ?? 0;
  }

  /// Soma all-time de TODAS as sub-tarefas do jogador.
  Future<int> getTotalVolume(int playerId) async {
    final sumExpr =
        playerDailySubtaskVolumeTable.totalUnits.sum();
    final query = selectOnly(playerDailySubtaskVolumeTable)
      ..addColumns([sumExpr])
      ..where(
          playerDailySubtaskVolumeTable.playerId.equals(playerId));
    final row = await query.getSingleOrNull();
    return row?.read(sumExpr) ?? 0;
  }

  /// Lista todos os volumes do jogador. Útil pra `getTotalVolume`
  /// alternativo + introspecção em testes.
  Future<List<PlayerDailySubtaskVolume>> listByPlayer(
      int playerId) async {
    final rows = await (select(playerDailySubtaskVolumeTable)
          ..where((t) => t.playerId.equals(playerId)))
        .get();
    return rows.map(PlayerDailySubtaskVolume.fromRow).toList();
  }

  /// UPSERT: insere row se inexistente, incrementa se existe. Atomic
  /// via `INSERT ... ON CONFLICT (player_id, sub_task_key) DO UPDATE`.
  /// [delta] pode ser 0 (no-op idempotente).
  Future<void> incrementVolume(
      int playerId, String subTaskKey, int delta) async {
    if (delta == 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(playerDailySubtaskVolumeTable).insert(
      PlayerDailySubtaskVolumeTableCompanion(
        playerId: Value(playerId),
        subTaskKey: Value(subTaskKey),
        totalUnits: Value(delta),
        updatedAt: Value(now),
      ),
      onConflict: DoUpdate(
        (old) => PlayerDailySubtaskVolumeTableCompanion.custom(
          totalUnits: old.totalUnits + Constant(delta),
          updatedAt: Constant(now),
        ),
        target: [
          playerDailySubtaskVolumeTable.playerId,
          playerDailySubtaskVolumeTable.subTaskKey,
        ],
      ),
    );
  }
}
