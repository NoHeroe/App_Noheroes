import 'dart:async';

import 'package:drift/drift.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/daily_mission_events.dart';
import '../../../core/events/reward_events.dart';
import '../../../domain/models/reward_resolved.dart';
import '../../database/app_database.dart';

/// Sprint 3.4 Etapa B (Sub-Etapa B.1) — single writer de
/// `players.total_gold_earned_via_quests`.
///
/// ## Foundation
///
/// Sub-type `admission_gold_earned_via_quests_window` do
/// `FactionAdmissionValidator` precisa medir delta de ouro recebido
/// via quest dentro de uma janela móvel (ex.: "50+ gold em 48h pra
/// admissão Renegado"). Como `players.gold` flutua por outras fontes
/// (compras, NPCs, etc), precisamos um contador *all-time* dedicado.
///
/// ## Cobertura de paths
///
/// 1. **Class / faction / individual / admission missions** — usam
///    `RewardGrantService.grant` que emite `RewardGranted`. Listener
///    aqui escuta `RewardGranted` com `fromAchievementCascade=false`
///    e soma `resolved.gold`.
///
/// 2. **Daily missions** — flow próprio em
///    `DailyMissionProgressService` que atualiza `players.gold` via
///    SQL direto sem disparar `RewardGranted`. Solução cirúrgica:
///    `DailyMissionCompleted` ganhou campo `goldEarned` (default 0
///    pra backwards-compat). Listener aqui escuta esse evento
///    também e soma `evt.goldEarned`.
///
/// 3. **Achievements** — `RewardGrantService.grantAchievement` emite
///    `RewardGranted(fromAchievementCascade=true)`. **Filtramos fora**
///    — gold de conquista não é "via quest".
///
/// ## Convenções
///
/// - Idempotência: events são de "terminal" (commit já aconteceu);
///   não há risco de re-entrega causando duplicação. Listener apenas
///   incrementa.
/// - Single writer: este é o único lugar que escreve em
///   `total_gold_earned_via_quests`. Outros locais leem (ex.:
///   `FactionAdmissionValidator`).
/// - Provider eager em `app/providers.dart` registra subscriptions
///   no boot (espelha pattern de `DailyMissionStatsService`).
class QuestRewardStatsService {
  final AppDatabase _db;
  final AppEventBus _bus;
  final List<StreamSubscription> _subs = [];

  QuestRewardStatsService({
    required AppDatabase db,
    required AppEventBus bus,
  })  : _db = db,
        _bus = bus;

  /// Registra listeners. Caller (provider) é responsável pelo
  /// `dispose` via [stop].
  Future<void> start() async {
    _subs.add(_bus.on<RewardGranted>().listen(_onRewardGranted));
    _subs.add(
        _bus.on<DailyMissionCompleted>().listen(_onDailyMissionCompleted));
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  Future<void> _onRewardGranted(RewardGranted evt) async {
    if (evt.fromAchievementCascade) return; // achievement reward não conta
    try {
      final resolved = RewardResolved.fromJsonString(evt.rewardResolvedJson);
      if (resolved.gold <= 0) return;
      await _increment(evt.playerId, resolved.gold);
    } catch (e) {
      // ignore: avoid_print
      print('[quest-reward-stats] decode falhou em RewardGranted '
          '(player=${evt.playerId}): $e');
    }
  }

  Future<void> _onDailyMissionCompleted(DailyMissionCompleted evt) async {
    if (evt.goldEarned <= 0) return;
    await _increment(evt.playerId, evt.goldEarned);
  }

  Future<void> _increment(int playerId, int amount) async {
    await _db.customUpdate(
      'UPDATE players SET total_gold_earned_via_quests = '
      'total_gold_earned_via_quests + ? WHERE id = ?',
      variables: [
        Variable.withInt(amount),
        Variable.withInt(playerId),
      ],
      updates: {_db.playersTable},
    );
  }
}
