import 'package:drift/drift.dart';

import '../../../domain/enums/mission_category.dart';
import '../../../domain/models/daily_mission.dart';
import '../../../domain/models/daily_mission_status.dart';
import '../app_database.dart';
import '../tables/daily_missions_table.dart';

part 'daily_missions_dao.g.dart';

/// Sprint 3.2 Etapa 1.2 — DAO da tabela [DailyMissionsTable].
///
/// Camada de persistência das missões diárias. Conversão entre
/// [DailyMissionsTableData] (Drift) e [DailyMission] (domain) mora aqui
/// pra serviços trabalharem só com o domain.
@DriftAccessor(tables: [DailyMissionsTable])
class DailyMissionsDao extends DatabaseAccessor<AppDatabase>
    with _$DailyMissionsDaoMixin {
  DailyMissionsDao(super.db);

  Future<List<DailyMission>> findByPlayerAndDate(
      int playerId, String dateStr) async {
    final rows = await (select(dailyMissionsTable)
          ..where((t) =>
              t.playerId.equals(playerId) & t.data.equals(dateStr)))
        .get();
    return rows.map(_fromRow).toList();
  }

  Future<DailyMission?> findById(int id) async {
    final row = await (select(dailyMissionsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Insere as 3 missões geradas numa transação. Retorna a lista com IDs
  /// preenchidos (mesma ordem da entrada).
  Future<List<DailyMission>> insertAll(List<DailyMission> missions) async {
    return transaction(() async {
      final out = <DailyMission>[];
      for (final m in missions) {
        final id = await into(dailyMissionsTable).insert(_toCompanion(m));
        out.add(_withId(m, id));
      }
      return out;
    });
  }

  /// Atualiza progresso (subTarefas), status, completedAt, rewardClaimed.
  /// Não toca em campos imutáveis (modalidade, titulos, etc.).
  Future<void> updateMission(DailyMission mission) async {
    await (update(dailyMissionsTable)
          ..where((t) => t.id.equals(mission.id)))
        .write(DailyMissionsTableCompanion(
      subTarefasJson: Value(mission.encodeSubTarefas()),
      status: Value(mission.status.storage),
      completedAt: Value(mission.completedAt?.millisecondsSinceEpoch),
      rewardClaimed: Value(mission.rewardClaimed),
    ));
  }

  /// Lista missões `pending`/`partial` com `data < dateStr`. Usado pelo
  /// [DailyMissionRolloverService] no boot do dia novo.
  Future<List<DailyMission>> findPendingBefore(
      int playerId, String dateStr) async {
    final rows = await (select(dailyMissionsTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.data.isSmallerThanValue(dateStr) &
              t.status.isIn([
                DailyMissionStatus.pending.storage,
                DailyMissionStatus.partial.storage,
              ])))
        .get();
    return rows.map(_fromRow).toList();
  }

  /// Lista todas as missões de um dia anterior específico (todos os
  /// status). Usado pra decidir streak no rollover.
  Future<List<DailyMission>> findByPlayerAndDateAll(
      int playerId, String dateStr) =>
      findByPlayerAndDate(playerId, dateStr);

  /// Apaga missões de um dia inteiro pra um player. Usado por dev tools
  /// (Resetar missões de hoje) e internamente por `generateForToday(force: true)`.
  Future<void> deleteByPlayerAndDate(int playerId, String dateStr) async {
    await (delete(dailyMissionsTable)
          ..where((t) =>
              t.playerId.equals(playerId) & t.data.equals(dateStr)))
        .go();
  }

  /// Move uma missão pra outra data. Usado pelo dev tool "Pular pra amanhã"
  /// pra deslocar pendentes de hoje pra ontem antes do rollover.
  Future<void> updateMissionDate(int missionId, String dateStr) async {
    await (update(dailyMissionsTable)..where((t) => t.id.equals(missionId)))
        .write(DailyMissionsTableCompanion(data: Value(dateStr)));
  }

  // ─── conversões ────────────────────────────────────────────────────

  DailyMission _fromRow(DailyMissionsTableData row) => DailyMission(
        id: row.id,
        playerId: row.playerId,
        data: row.data,
        modalidade: MissionCategoryCodec.fromStorage(row.modalidade),
        subCategoria: row.subCategoria,
        tituloKey: row.tituloKey,
        tituloResolvido: row.tituloResolvido,
        quoteResolvida: row.quoteResolvida,
        subTarefas: DailyMission.decodeSubTarefas(row.subTarefasJson),
        status: DailyMissionStatusCodec.fromStorage(row.status),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        completedAt: row.completedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.completedAt!),
        rewardClaimed: row.rewardClaimed,
      );

  DailyMissionsTableCompanion _toCompanion(DailyMission m) =>
      DailyMissionsTableCompanion(
        playerId: Value(m.playerId),
        data: Value(m.data),
        modalidade: Value(m.modalidade.storage),
        subCategoria: m.subCategoria == null
            ? const Value.absent()
            : Value(m.subCategoria),
        tituloKey: Value(m.tituloKey),
        tituloResolvido: Value(m.tituloResolvido),
        quoteResolvida: Value(m.quoteResolvida),
        subTarefasJson: Value(m.encodeSubTarefas()),
        status: Value(m.status.storage),
        createdAt: Value(m.createdAt.millisecondsSinceEpoch),
        completedAt: m.completedAt == null
            ? const Value.absent()
            : Value(m.completedAt!.millisecondsSinceEpoch),
        rewardClaimed: Value(m.rewardClaimed),
      );

  DailyMission _withId(DailyMission m, int id) => DailyMission(
        id: id,
        playerId: m.playerId,
        data: m.data,
        modalidade: m.modalidade,
        subCategoria: m.subCategoria,
        tituloKey: m.tituloKey,
        tituloResolvido: m.tituloResolvido,
        quoteResolvida: m.quoteResolvida,
        subTarefas: m.subTarefas,
        status: m.status,
        createdAt: m.createdAt,
        completedAt: m.completedAt,
        rewardClaimed: m.rewardClaimed,
      );
}
