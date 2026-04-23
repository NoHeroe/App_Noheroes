import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../../core/utils/guild_rank.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/models/reward_declared.dart';
import '../../../domain/repositories/mission_repository.dart';

/// Sprint 3.1 Bloco 7b — reescrita do ClassQuestService legado.
///
/// Antes (sprint 2.x): criava rows em `class_quests` table com
/// check_type+check_params embutidos. Hoje cria rows em
/// `player_mission_progress` (schema 24) com modality=internal,
/// tabOrigin=class. Progresso real flui pelo MissionProgressService +
/// strategies do Bloco 6 quando o check_type legacy mapeia pra um
/// AppEvent conhecido.
///
/// **Débito reconhecido**: nem todo `check_type` legacy tem evento
/// correspondente na lista do Bloco 2 (ex: `talk_npc`,
/// `complete_category_today`). Essas missões criam row com
/// `metaJson.legacy_check_type` preenchido mas `internal_event` ausente —
/// InternalModalityStrategy não avança. Dev Panel (Bloco 15) e UI de
/// missões (Bloco 10) podem oferecer conclusão manual até que o Bloco
/// 14 entregue strategies específicas de categoria.
class ClassQuestService {
  final MissionRepository _repo;
  final Random _random;

  ClassQuestService(this._repo, {Random? random})
      : _random = random ?? Random();

  /// Sorteia 3 diárias de classe do pool JSON e persiste em
  /// `player_mission_progress` como rows internal. Idempotente por dia:
  /// se já existe rows de classe tab hoje, retorna as existentes sem
  /// recriar.
  Future<List<MissionProgress>> assignDailyQuests(
    int playerId,
    String classId, {
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    // Idempotência por dia — tab=class + started_at >= hoje 00:00.
    final existing = await _repo.findByTab(playerId, MissionTabOrigin.classTab);
    final todayStart = DateTime(today.year, today.month, today.day);
    final already = existing
        .where((m) => m.startedAt.isAfter(
            todayStart.subtract(const Duration(milliseconds: 1))))
        .toList();
    if (already.length >= 3) return already.take(3).toList();

    final pool = await _loadPool(classId);
    if (pool.isEmpty) return const [];

    pool.shuffle(_random);
    final chosen = pool.take(3).toList();
    final created = <MissionProgress>[];
    for (final q in chosen) {
      final id = await _repo.insert(_fromJson(q, playerId, today));
      final loaded = await _repo.findById(id);
      if (loaded != null) created.add(loaded);
    }
    return created;
  }

  Future<List<Map<String, dynamic>>> _loadPool(String classId) async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/class_quests_daily.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final poolMap = json['class_quests'] as Map<String, dynamic>?;
      final pool = (poolMap?[classId] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
      return List<Map<String, dynamic>>.from(pool);
    } catch (_) {
      return const [];
    }
  }

  MissionProgress _fromJson(
    Map<String, dynamic> q,
    int playerId,
    DateTime now,
  ) {
    final checkType = q['check_type'] as String?;
    final checkParams = (q['check_params'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final event = _checkTypeToEvent(checkType);
    final target = (checkParams['count'] as int?) ??
        (checkParams['amount'] as int?) ??
        1;

    return MissionProgress(
      id: 0,
      playerId: playerId,
      missionKey: (q['key'] as String?) ?? 'CLASS_UNKNOWN',
      modality: MissionModality.internal,
      tabOrigin: MissionTabOrigin.classTab,
      rank: GuildRank.e,
      targetValue: target,
      currentValue: 0,
      reward: RewardDeclared(
        xp: (q['xp'] as int?) ?? 0,
        gold: (q['gold'] as int?) ?? 0,
      ),
      startedAt: now,
      rewardClaimed: false,
      metaJson: jsonEncode({
        if (event != null) 'internal_event': event,
        if (checkType != null) 'legacy_check_type': checkType,
        if (checkParams.isNotEmpty) 'legacy_check_params': checkParams,
      }),
    );
  }

  /// Mapeia `check_type` legado pra nome de AppEvent do Bloco 2.
  /// Retorna `null` quando não há mapping direto — nesse caso a missão
  /// não avança via EventBus e depende de conclusão manual/Bloco 14.
  String? _checkTypeToEvent(String? checkType) {
    return switch (checkType) {
      'spend_gold' => 'GoldSpent',
      'craft_item' => 'ItemCrafted',
      'enchant_item' => 'ItemEnchanted',
      'level_up' => 'LevelUp',
      _ => null,
    };
  }
}
