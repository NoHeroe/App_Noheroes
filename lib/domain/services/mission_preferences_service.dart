import 'package:drift/drift.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/events/player_events.dart';
import '../../data/database/app_database.dart';
import '../exceptions/reward_exceptions.dart';
import '../models/mission_preferences.dart';
import '../repositories/mission_preferences_repository.dart';

/// Sprint 3.1 Bloco 9 — custo pra refazer a calibração. Instâncias são
/// imutáveis (`const`), calculadas pelo tier do `updatesCount` via
/// `MissionPreferencesService.costForRecalibration`.
class RecalibrationCost {
  final int gems;
  final int seivas;

  const RecalibrationCost({this.gems = 0, this.seivas = 0});
  const RecalibrationCost.free() : this();

  bool get isFree => gems == 0 && seivas == 0;

  @override
  String toString() => 'RecalibrationCost(gems=$gems, seivas=$seivas)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecalibrationCost &&
          gems == other.gems &&
          seivas == other.seivas);

  @override
  int get hashCode => Object.hash(gems, seivas);
}

/// Sprint 3.1 Bloco 9 — serviço de leitura/escrita das preferências do
/// quiz de calibração (ADR 0015 + DESIGN_DOC §7).
///
/// Entrega infra pra:
///   - Calibração **inicial** (Bloco 9) — quiz dispara via phase13 do
///     TutorialManager após `ClassSelected`.
///   - Calibração **refazer** (UI no Bloco 10) — gate hard lvl >= 10 +
///     custos por tier no `updatesCount`.
///
/// Emite `MissionPreferencesChanged` no final de `save` pra invalidar
/// providers consumidores (ex: assignment de diárias no Bloco 14).
///
/// Contrato de ciclo de vida:
///   - Ctor sync, sem I/O.
///   - Métodos são idempotentes na leitura; `save` e `chargeRecalibration`
///     fazem UPDATE com `updates: {playersTable}` pra invalidar
///     `playerStreamProvider`.
///
/// Seivas (débito Bloco 15.5): schema 24 **não persiste** seivas. O
/// `chargeRecalibration` loga TODO em vez de gravar quando
/// `cost.seivas > 0`. Espelha o padrão do `RewardGrantService`.
class MissionPreferencesService {
  final MissionPreferencesRepository _repo;
  final AppEventBus _bus;
  final AppDatabase _db;

  MissionPreferencesService({
    required MissionPreferencesRepository repo,
    required AppEventBus bus,
    required AppDatabase db,
  })  : _repo = repo,
        _bus = bus,
        _db = db;

  /// Preferências atuais do jogador ou `null` se ainda não calibrou.
  Future<MissionPreferences?> findCurrent(int playerId) =>
      _repo.findByPlayerId(playerId);

  /// `true` se o jogador já tem uma row em `player_mission_preferences`.
  /// Consumido pelo hook phase13 do TutorialManager (pula se `true`) e
  /// pelo gate de refazer (bloqueia se `false`).
  Future<bool> hasValidPreferences(int playerId) async {
    final prefs = await _repo.findByPlayerId(playerId);
    return prefs != null;
  }

  /// Atalho pro gate de refazer — `0` se nunca calibrou, senão o
  /// `updates_count` persistido.
  Future<int> currentUpdatesCount(int playerId) =>
      _repo.updatesCountOf(playerId);

  /// Persiste [draft]. Se já existia row, incrementa `updates_count` e
  /// preserva `createdAt` original (repo passa o valor atualizado, mas
  /// aqui calculamos o incremento). Emite `MissionPreferencesChanged`
  /// pós-upsert (caller pode assinar pra reassign de missões — Bloco 14).
  ///
  /// Contrato: `draft.createdAt` é usado só na primeira gravação; updates
  /// subsequentes preservam o persistido via merge in-memory.
  Future<void> save(MissionPreferences draft) async {
    final existing = await _repo.findByPlayerId(draft.playerId);
    final now = DateTime.now();
    final MissionPreferences toPersist;
    if (existing == null) {
      toPersist = draft.copyWith(updatedAt: now, updatesCount: 0);
    } else {
      toPersist = MissionPreferences(
        playerId: draft.playerId,
        primaryFocus: draft.primaryFocus,
        intensity: draft.intensity,
        missionStyle: draft.missionStyle,
        physicalSubfocus: draft.physicalSubfocus,
        mentalSubfocus: draft.mentalSubfocus,
        spiritualSubfocus: draft.spiritualSubfocus,
        timeDailyMinutes: draft.timeDailyMinutes,
        createdAt: existing.createdAt,
        updatedAt: now,
        updatesCount: existing.updatesCount + 1,
      );
    }
    await _repo.upsert(toPersist);
    _bus.publish(MissionPreferencesChanged(playerId: draft.playerId));
  }

  /// Tier de custo pra refazer baseado em quantos refazeres já rolaram.
  /// O `currentUpdatesCount` é lido do DB ANTES do refazer — depois de
  /// `save`, ele já cresceu e o próximo tier aplica.
  ///
  /// Tiers (DESIGN_DOC §7):
  ///   - `0` → free (1ª refazer, grandfathered a partir de lvl 10)
  ///   - `1` → 100 gems + 1 seiva (2ª refazer)
  ///   - `2+` → 300 gems + 3 seivas (3ª+ refazer; não escala além)
  RecalibrationCost costForRecalibration(int currentUpdatesCount) {
    if (currentUpdatesCount <= 0) return const RecalibrationCost.free();
    if (currentUpdatesCount == 1) {
      return const RecalibrationCost(gems: 100, seivas: 1);
    }
    return const RecalibrationCost(gems: 300, seivas: 3);
  }

  /// Gate **hard** pra UI de refazer (DESIGN_DOC §7):
  ///
  ///   - `playerLevel >= 10` — abaixo disso o botão fica **oculto** (não
  ///     desabilitado). UI do Bloco 10 respeita.
  ///   - `hasValidPreferences == true` — só refaz quem já fez a inicial.
  ///
  /// A contagem do `updatesCount` é independente do gate; este método só
  /// decide se o botão aparece.
  Future<bool> canRecalibrate({
    required int playerId,
    required int playerLevel,
  }) async {
    if (playerLevel < 10) return false;
    return hasValidPreferences(playerId);
  }

  /// Debita o custo de refazer. Lança [InsufficientGemsException] se
  /// `players.gems < cost.gems`. Seivas: TODO Bloco 15.5 (schema 24 não
  /// persiste seivas) — log com o valor pendente.
  ///
  /// Emite `GemsSpent(source: GemSink.recalibration)` pós-commit pra
  /// integrar com strategies internal (ex: quest "gaste 100 gemas").
  ///
  /// Atomicidade: o check de saldo + debit ficam na mesma transação pra
  /// evitar race (outro debit concorrente poderia gastar o saldo entre
  /// check e update).
  Future<void> chargeRecalibration(
    int playerId,
    RecalibrationCost cost,
  ) async {
    if (cost.isFree) return;

    if (cost.gems > 0) {
      await _db.transaction(() async {
        final row = await (_db.select(_db.playersTable)
              ..where((t) => t.id.equals(playerId)))
            .getSingleOrNull();
        if (row == null) {
          throw InsufficientGemsException(
            playerId: playerId,
            required: cost.gems,
            available: 0,
          );
        }
        if (row.gems < cost.gems) {
          throw InsufficientGemsException(
            playerId: playerId,
            required: cost.gems,
            available: row.gems,
          );
        }
        await _db.customUpdate(
          'UPDATE players SET gems = gems - ? WHERE id = ?',
          variables: [
            Variable.withInt(cost.gems),
            Variable.withInt(playerId),
          ],
          updates: {_db.playersTable},
        );
      });
      _bus.publish(GemsSpent(
        playerId: playerId,
        amount: cost.gems,
        source: GemSink.recalibration,
      ));
    }

    if (cost.seivas > 0) {
      // ignore: avoid_print
      print('[mission-preferences] TODO(sprint-2.4/bloco-15.5): persistir '
          'débito de ${cost.seivas} seivas pra player $playerId — schema '
          '24 não tem coluna.');
    }
  }
}
