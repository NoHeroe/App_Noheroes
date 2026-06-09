import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/events/app_event_bus.dart';
import '../../../core/events/faction_events.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../domain/enums/mission_modality.dart';
import '../../../domain/enums/mission_tab_origin.dart';
import '../../../domain/enums/rank_codec.dart';
import '../../../domain/models/mission_progress.dart';
import '../../../domain/models/reward_declared.dart';
import '../../../domain/repositories/mission_repository.dart';
import '../../../domain/services/faction_admission_sub_task_types.dart';
import '../../../domain/services/faction_admission_validator.dart';
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
  final SupabaseClient _client;
  final MissionRepository _missionRepo;
  final ClassQuestService _classQuests;
  final AppEventBus _eventBus;

  QuestAdmissionService(
    this._client,
    this._missionRepo,
    this._classQuests,
    this._eventBus,
  );

  /// Sprint 3.4 Sub-Etapa B.2 hotfix #2 — janela base por tier
  /// narrativo da facção. Cada tier reflete dificuldade esperada:
  ///
  /// - **MÉDIO** (lua/sol/renegados): 48h. Throughput ~6 dailies.
  /// - **ALTO** (nova ordem/legião negra/trindade): 72h. Throughput ~9.
  /// - **EXTREMO** (error): 96h. Throughput ~12.
  ///
  /// A janela é o tempo absoluto pra player completar UMA missão da
  /// admissão; sequenciamento garante que cada missão da sequência
  /// recebe sua janela própria a partir do unlock. Reputação modifica
  /// (rep > 70: +24h; rep < 40: -12h) pra criar gradiente de
  /// dificuldade dinâmica.
  static const Map<_AdmissionTier, int> _tierBaseWindowMs = {
    _AdmissionTier.medium: 48 * 60 * 60 * 1000,
    _AdmissionTier.high: 72 * 60 * 60 * 1000,
    _AdmissionTier.extreme: 96 * 60 * 60 * 1000,
  };

  /// Mapa de facção pra tier narrativo. Guilda NÃO entra (modelo dual
  /// — usa entrada direta sem admissão eliminatória).
  static const Map<String, _AdmissionTier> _factionTier = {
    'moon_clan': _AdmissionTier.medium,
    'sun_clan': _AdmissionTier.medium,
    'renegades': _AdmissionTier.medium,
    'new_order': _AdmissionTier.high,
    'black_legion': _AdmissionTier.high,
    'trinity': _AdmissionTier.high,
    'error': _AdmissionTier.extreme,
  };

  /// Sub-types que **não sofrem** scaling de threshold (zero/exact).
  static const Set<String> _noScaleSubTypes = {
    FactionAdmissionSubTaskTypes.zeroFailedWindow,
    FactionAdmissionSubTaskTypes.zeroCategoryWindow,
    FactionAdmissionSubTaskTypes.noPartialDayWindow,
    FactionAdmissionSubTaskTypes.exactDailyCountWindow,
  };

  /// Chamado na escolha de classe (nível 5). Confirma `classType`,
  /// dispara assignment de 3 diárias, e emite `ClassSelected`.
  Future<void> startClassQuests(String playerId, String classId) async {
    // Update single-table (sem atomicidade multi-tabela) — persiste direto.
    await _client
        .from('players')
        .update({'class_type': classId}).eq('id', playerId);
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
    String playerId,
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
    final scale = _calculateScale(factionId, reputation);
    final snapshotRank = await _readGuildRank(playerId);

    // Increment admissionAttempts (atômico) via RPC.
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

      // Insert simples (single-row; sem atomicidade multi-tabela — não há
      // RPC dedicada pra admission). Persiste direto e relê a row pra
      // materializar o MissionProgress de retorno.
      final row = <String, dynamic>{
        'player_id': playerId,
        'mission_key': missionId,
        'modality': MissionModality.internal.storage,
        'tab_origin': MissionTabOrigin.admission.storage,
        'rank': RankCodec.storage(missionRank),
        'target_value': subTasks.length, // pra mostrar N/M no header
        'current_value': 0,
        'reward_json': const RewardDeclared().toJsonString(),
        'started_at': nowMs,
        'reward_claimed': false,
        'meta_json': jsonEncode({
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
      };
      final inserted = await _client
          .from('player_mission_progress')
          .insert(row)
          .select()
          .single();
      created.add(MissionProgress.fromJson(inserted));
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
  Future<int> _readReputation(String playerId, String factionId) async {
    final row = await _client
        .from('player_faction_reputation')
        .select('reputation')
        .eq('player_id', playerId)
        .eq('faction_id', factionId)
        .maybeSingle();
    return (row?['reputation'] as num?)?.toInt() ?? 50;
  }

  /// Lê o `guild_rank` atual do player (default 'none' se row ausente).
  Future<String> _readGuildRank(String playerId) async {
    final row = await _client
        .from('players')
        .select('guild_rank')
        .eq('id', playerId)
        .maybeSingle();
    return (row?['guild_rank'] as String?) ?? 'none';
  }

  /// Incrementa `player_faction_membership.admission_attempts` (cria row
  /// se não existe) de forma atômica. Retorna novo valor. Delegado à RPC
  /// increment_admission_attempts — NÃO reimplementamos o upsert+increment
  /// no cliente.
  Future<int> _incrementAttemptCount(
      String playerId, String factionId) async {
    final result = await _client.rpc('increment_admission_attempts', params: {
      'p_player': playerId,
      'p_faction': factionId,
    });
    return (result as num?)?.toInt() ?? 1;
  }

  /// Sprint 3.4 Sub-Etapa B.2 hotfix #2 — janela escalada por tier
  /// narrativo da facção + reputação. Threshold sempre escala pela
  /// reputação (independente do tier).
  ///
  /// Tabela final de janelas (ms):
  ///
  /// | Tier | rep < 40 (-12h) | rep 40..70 (base) | rep > 70 (+24h) |
  /// |---|---|---|---|
  /// | MÉDIO  | 36h | 48h  | 72h  |
  /// | ALTO   | 60h | 72h  | 96h  |
  /// | EXTREMO| 84h | 96h  | 120h |
  ///
  /// `factionId` desconhecido (não está em `_factionTier`) cai em
  /// MÉDIO como default seguro. Defesa em profundidade — não deveria
  /// acontecer no flow normal porque caller já valida factionId.
  ({int windowMs, double thresholdMult}) _calculateScale(
      String factionId, int reputation) {
    final tier = _factionTier[factionId] ?? _AdmissionTier.medium;
    final baseMs = _tierBaseWindowMs[tier]!;
    int windowMs;
    double thresholdMult;
    if (reputation > 70) {
      windowMs = baseMs + 24 * 60 * 60 * 1000; // +24h
      thresholdMult = 0.85;
    } else if (reputation < 40) {
      windowMs = baseMs - 12 * 60 * 60 * 1000; // -12h
      thresholdMult = 1.20;
    } else {
      windowMs = baseMs;
      thresholdMult = 1.0;
    }
    return (windowMs: windowMs, thresholdMult: thresholdMult);
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
          // Sprint 3.4 Sub-Etapa B.2 hotfix — label do catálogo
          // persiste em metaJson via toJson; UI lê pra renderizar
          // texto legível em vez do sub_type cru.
          label: s['label'] as String?,
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

/// Sprint 3.4 Sub-Etapa B.2 hotfix #2 — tier narrativo da admissão.
/// Define janela base + dificuldade esperada. Mapping concreto de
/// facção pra tier vive em [QuestAdmissionService._factionTier].
enum _AdmissionTier { medium, high, extreme }
