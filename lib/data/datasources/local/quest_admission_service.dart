import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/faction_events.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/models/reward_declared.dart';
import '../../../domain/repositories/mission_repository.dart';
import '../../../domain/services/faction_admission_sub_task_types.dart';
import '../../../domain/services/faction_admission_validator.dart';
import '../../database/app_database.dart';
import '../../database/daos/player_dao.dart';
import 'class_quest_service.dart';

/// Sprint 3.4 Sub-Etapa B.2 — service refatorado pra usar catálogo v2
/// + sub-tasks automáticas em metaJson + sequenciamento + escala de
/// dificuldade por reputação.
///
/// ## Responsabilidades
///
/// 1. `startClassQuests(playerId, classId)` — confirma classe + 3
///    diárias + emite `ClassSelected`. (Inalterado vs Sprint 3.1.)
///
/// 2. `startFactionAdmission(playerId, factionId)` — cria N missões
///    de admissão eliminatória (N depende da facção, vem do catálogo
///    `assets/data/faction_admission_quests_v2.json`). Cada missão
///    persiste sub-tasks em metaJson (com [FactionAdmissionSubTask]
///    serializadas via JSON roundtrip da Sub-Etapa B.1). Apenas a
///    primeira missão começa `is_unlocked=true`; demais aguardam
///    promoção pelo `FactionAdmissionProgressService` quando a
///    anterior completar.
///
/// ## Modelo dual da Guilda
///
/// `factionId == 'guild'` é tratado com **early-return** vazio.
/// Guilda usa flow especial em `guild_screen.dart`
/// (Aventureiro nível 1 = `players.guild_rank in ['e'..'s']`).
/// Facção Guilda nível 2 (`players.faction_type == 'guild'`) é
/// concedida via entrada DIRETA em `FactionSelectionScreen._confirm`,
/// sem admissão eliminatória.
///
/// ## Escala de dificuldade por reputação
///
/// Reputação atual do player na facção tentada:
///
/// | Faixa | Janela | Threshold |
/// |---|---|---|
/// | reputação > 70 | 72h | -15% (ceil) |
/// | reputação 40..70 | 48h (padrão) | padrão |
/// | reputação < 40 | 36h | +20% (ceil) |
///
/// Threshold scaling NÃO se aplica a sub-types não-monótonos
/// (`zero_failed_window`, `zero_category_window`,
/// `no_partial_day_window` — exigência "zero" não escala) nem a
/// `exact_daily_count_window` (target narrativo fixo). MIN 1 sempre.
class QuestAdmissionService {
  final AppDatabase _db;
  final MissionRepository _missionRepo;
  final ClassQuestService _classQuests;
  final AppEventBus _eventBus;

  QuestAdmissionService(
    this._db,
    this._missionRepo,
    this._classQuests,
    this._eventBus,
  );

  /// Janela base de 48h em ms.
  static const int _baseWindowMs = 48 * 60 * 60 * 1000;

  /// Sub-types que **não sofrem** scaling de threshold (zero/exact).
  static const Set<String> _noScaleSubTypes = {
    FactionAdmissionSubTaskTypes.zeroFailedWindow,
    FactionAdmissionSubTaskTypes.zeroCategoryWindow,
    FactionAdmissionSubTaskTypes.noPartialDayWindow,
    FactionAdmissionSubTaskTypes.exactDailyCountWindow,
  };

  /// Chamado na escolha de classe (nível 5). Confirma `classType`,
  /// dispara assignment de 3 diárias, e emite `ClassSelected`.
  Future<void> startClassQuests(int playerId, String classId) async {
    await _db.customUpdate(
      'UPDATE players SET class_type = ? WHERE id = ?',
      variables: [
        Variable.withString(classId),
        Variable.withInt(playerId),
      ],
      updates: {_db.playersTable},
    );
    await _classQuests.assignDailyQuests(playerId, classId);
    _eventBus.publish(ClassSelected(playerId: playerId, classId: classId));
  }

  /// Cria as missões de admissão eliminatória pra [factionId] em
  /// `player_mission_progress` (tabOrigin=admission). Idempotente: se
  /// já existem missões ativas pra esse par (player, faction), retorna
  /// elas em vez de duplicar.
  ///
  /// **Early-return pra Guilda**: retorna `[]` sem efeito colateral —
  /// Guilda usa flow especial fora deste service. Defesa em
  /// profundidade caso algum caller passe `factionId == 'guild'` por
  /// engano.
  Future<List<MissionProgress>> startFactionAdmission(
    int playerId,
    String factionId,
  ) async {
    if (factionId == 'guild') {
      // ignore: avoid_print
      print('[admission] factionId="guild" ignorado — Guilda usa '
          'flow especial em guild_screen.dart (Aventureiro nível 1) + '
          'entrada direta em FactionSelectionScreen (nível 2).');
      return const [];
    }

    // Idempotência: se já existem missões ativas pra esse par.
    final existing =
        await _missionRepo.findByTab(playerId, MissionTabOrigin.admission);
    final active = existing
        .where((m) =>
            m.completedAt == null &&
            m.failedAt == null &&
            _metaFactionOf(m.metaJson) == factionId)
        .toList();
    if (active.isNotEmpty) return active;

    final pool = await _loadAdmissionPoolV2(factionId);
    if (pool.isEmpty) {
      // ignore: avoid_print
      print('[admission] pool vazio pra "$factionId" — verifique '
          'faction_admission_quests_v2.json.');
      return const [];
    }

    // Captura snapshot do estado pra scaling + persistência.
    final reputation = await _readReputation(playerId, factionId);
    final scale = _calculateScale(reputation);
    final player = await PlayerDao(_db).findById(playerId);
    final snapshotRank = player?.guildRank ?? 'none';

    // Increment admissionAttempts em player_faction_membership.
    final attemptCount = await _incrementAttemptCount(playerId, factionId);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final created = <MissionProgress>[];

    for (var i = 0; i < pool.length; i++) {
      final q = pool[i];
      final isFirst = i == 0;
      // Sub-tasks da missão. Janela começa AGORA pra missão 1; pras
      // outras a janela é placeholder (0) — `FactionAdmissionProgress
      // Service` reseta windowStartMs ao desbloquear N+1.
      final windowStartMs = isFirst ? nowMs : 0;
      final subTasks = _buildSubTasks(
        catalogSubs: (q['sub_tasks'] as List).cast<Map<String, dynamic>>(),
        windowStartMs: windowStartMs,
        snapshotRank: snapshotRank,
        thresholdMult: scale.thresholdMult,
      );

      final missionId = q['id'] as String;
      final missionRank = _parseRank(q['rank'] as String?);

      final id = await _missionRepo.insert(MissionProgress(
        id: 0,
        playerId: playerId,
        missionKey: missionId,
        modality: MissionModality.internal,
        tabOrigin: MissionTabOrigin.admission,
        rank: missionRank,
        targetValue: subTasks.length, // pra mostrar N/M no header
        currentValue: 0,
        reward: const RewardDeclared(),
        startedAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
        rewardClaimed: false,
        metaJson: jsonEncode({
          'faction_id': factionId,
          'mission_id': missionId,
          'title': q['title'],
          'description': q['description'],
          'is_unlocked': isFirst,
          'window_start_ms': windowStartMs,
          'window_duration_ms': scale.windowMs,
          'snapshot_rank': snapshotRank,
          'sub_tasks':
              subTasks.map((s) => s.toJson()).toList(growable: false),
        }),
      ));
      final loaded = await _missionRepo.findById(id);
      if (loaded != null) created.add(loaded);
    }

    if (created.isNotEmpty) {
      _eventBus.publish(FactionAdmissionStarted(
        playerId: playerId,
        factionId: factionId,
        totalQuests: created.length,
        attemptCount: attemptCount,
      ));
    }
    return created;
  }

  // ─── helpers ─────────────────────────────────────────────────────

  /// Lê reputação atual do player na facção (default 50 se não existe).
  Future<int> _readReputation(int playerId, String factionId) async {
    final rows = await _db.customSelect(
      'SELECT reputation FROM player_faction_reputation '
      'WHERE player_id = ? AND faction_id = ? LIMIT 1',
      variables: [
        Variable.withInt(playerId),
        Variable.withString(factionId),
      ],
    ).get();
    return rows.isNotEmpty ? rows.first.read<int>('reputation') : 50;
  }

  /// Incrementa `player_faction_membership.admissionAttempts` (cria
  /// row se não existe). Retorna novo valor.
  Future<int> _incrementAttemptCount(
      int playerId, String factionId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // INSERT OR IGNORE (cria row pendente se não existe).
    await _db.customStatement(
      'INSERT OR IGNORE INTO player_faction_membership '
      '(player_id, faction_id, joined_at, left_at, locked_until, '
      ' debuff_until, admission_attempts) '
      'VALUES (?, ?, NULL, NULL, NULL, NULL, 0)',
      [playerId, factionId],
    );
    // Increment.
    await _db.customStatement(
      'UPDATE player_faction_membership '
      'SET admission_attempts = admission_attempts + 1 '
      'WHERE player_id = ? AND faction_id = ?',
      [playerId, factionId],
    );
    final rows = await _db.customSelect(
      'SELECT admission_attempts FROM player_faction_membership '
      'WHERE player_id = ? AND faction_id = ? LIMIT 1',
      variables: [
        Variable.withInt(playerId),
        Variable.withString(factionId),
      ],
    ).get();
    // Variável `nowMs` mantida pra futura colocação de timestamp da
    // tentativa; atual schema não tem coluna last_attempt_at.
    // ignore: unused_local_variable
    final _ = nowMs;
    return rows.isNotEmpty ? rows.first.read<int>('admission_attempts') : 1;
  }

  /// Calcula janela + multiplier de threshold em função da reputação.
  ({int windowMs, double thresholdMult}) _calculateScale(int reputation) {
    if (reputation > 70) {
      return (windowMs: 72 * 60 * 60 * 1000, thresholdMult: 0.85);
    }
    if (reputation < 40) {
      return (windowMs: 36 * 60 * 60 * 1000, thresholdMult: 1.20);
    }
    return (windowMs: _baseWindowMs, thresholdMult: 1.0);
  }

  /// Aplica scaling no target — respeitando regras (zero/exact não
  /// escalam, MIN 1).
  int _scaleTarget(int rawTarget, String subType, double mult) {
    if (mult == 1.0) return rawTarget;
    if (_noScaleSubTypes.contains(subType)) return rawTarget;
    if (rawTarget <= 0) return rawTarget; // 0 = "zero" requirement
    final scaled = rawTarget * mult;
    final rounded = mult > 1.0 ? scaled.ceil() : scaled.floor();
    return math.max(1, rounded);
  }

  List<FactionAdmissionSubTask> _buildSubTasks({
    required List<Map<String, dynamic>> catalogSubs,
    required int windowStartMs,
    required String snapshotRank,
    required double thresholdMult,
  }) {
    return [
      for (final s in catalogSubs)
        FactionAdmissionSubTask(
          subType: s['sub_type'] as String,
          target: _scaleTarget(
              (s['target'] as int?) ?? 0, s['sub_type'] as String,
              thresholdMult),
          windowStartMs: windowStartMs,
          snapshotRank: snapshotRank,
          params: (s['params'] as Map?)?.cast<String, dynamic>(),
        ),
    ];
  }

  GuildRank _parseRank(String? raw) {
    if (raw == null) return GuildRank.e;
    final lower = raw.toLowerCase();
    return GuildRank.values.firstWhere(
      (r) => r.name == lower,
      orElse: () => GuildRank.e,
    );
  }

  String? _metaFactionOf(String metaJson) {
    if (metaJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(metaJson);
      if (decoded is! Map) return null;
      return decoded['faction_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAdmissionPoolV2(
      String factionId) async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/faction_admission_quests_v2.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final pool =
          (json[factionId] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
      return List<Map<String, dynamic>>.from(pool);
    } catch (e) {
      // ignore: avoid_print
      print('[admission] _loadAdmissionPoolV2 falhou pra '
          '"$factionId": $e');
      return const [];
    }
  }
}
