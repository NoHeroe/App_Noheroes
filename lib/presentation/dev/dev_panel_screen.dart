import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/providers.dart';
import '../../core/config/faction_alliances.dart';
import '../../core/constants/app_colors.dart';
import '../../core/events/app_event.dart';
import '../../core/events/faction_events.dart';
import '../../core/events/reward_events.dart';
import '../../core/utils/guild_rank.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/player_dao.dart';
import '../../domain/enums/mission_tab_origin.dart';
import '../../domain/models/achievement_definition.dart';
import '../../presentation/quests/providers/quests_screen_notifier.dart';
import '../shared/widgets/app_snack.dart';

/// Sprint 3.3 hotfix dev panel — versão enxuta focada em validar
/// conquistas + level up + daily missions. Substitui versão antiga
/// de 1227 LOC com ~22 botões espalhados por 12 seções.
///
/// **Fix P0** aplicado nas 3 ações que afetam daily missions:
/// `_forceDailyReset`, `_skipToTomorrow`, `_resetTodayDailyMissions`
/// agora invalidam `questsScreenNotifierProvider(playerId)`. Sem
/// isso, o provider AutoDispose ficava vivo entre navegação dev→
/// quests e a UI mostrava state stale (CEO interpretava como "não
/// funcionou").
class DevPanelScreen extends ConsumerStatefulWidget {
  const DevPanelScreen({super.key});
  @override
  ConsumerState<DevPanelScreen> createState() => _DevPanelScreenState();
}

class _DevPanelScreenState extends ConsumerState<DevPanelScreen> {
  final _levelCtrl = TextEditingController();
  final _goldCtrl = TextEditingController();
  final _xpCtrl = TextEditingController();
  final _gemsCtrl = TextEditingController();
  bool _saving = false;

  // Reputação compacta — dropdown picker + delta field.
  String _selectedFaction = kKnownFactions.first;
  final _repDeltaCtrl = TextEditingController(text: '10');

  // Sprint 3.1 Bloco 14 — Events inspector. Ring buffer de 20 entries.
  static const int _kEventBufferMax = 20;
  final List<_EventLogEntry> _eventBuffer = [];
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bus = ref.read(appEventBusProvider);
      _eventSub = bus.on<AppEvent>().listen((e) {
        if (!mounted) return;
        setState(() {
          _eventBuffer.insert(
              0,
              _EventLogEntry(
                at: DateTime.now(),
                type: e.runtimeType.toString(),
                repr: e.toString(),
              ));
          if (_eventBuffer.length > _kEventBufferMax) {
            _eventBuffer.removeLast();
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _levelCtrl.dispose();
    _goldCtrl.dispose();
    _xpCtrl.dispose();
    _gemsCtrl.dispose();
    _repDeltaCtrl.dispose();
    super.dispose();
  }

  /// Invalida providers que cacheiam state derivado do player ou de
  /// daily missions. Chamado após mutations dev pra garantir que
  /// telas vistas em sequência (dev → quests → achievements) reflitam
  /// o DB atualizado. Dev panel — preferimos super-invalidar a perder
  /// alguma tela.
  void _invalidateAll(int playerId) {
    ref.invalidate(questsScreenNotifierProvider(playerId));
    ref.invalidate(playerStreamProvider);
  }

  // ─── AJUSTAR VALORES ───────────────────────────────────────────────

  Future<void> _apply() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);
    final dao = PlayerDao(db);

    final newLevel = int.tryParse(_levelCtrl.text) ?? player.level;
    final newGold = int.tryParse(_goldCtrl.text) ?? player.gold;
    final newXp = int.tryParse(_xpCtrl.text) ?? player.xp;
    final newGems = int.tryParse(_gemsCtrl.text) ?? player.gems;

    await (db.update(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .write(PlayersTableCompanion(
      level: Value(newLevel),
      gold: Value(newGold),
      xp: Value(newXp),
      gems: Value(newGems),
    ));

    final updated = await dao.findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    _invalidateAll(player.id);
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Aplicado: Lv$newLevel | ${newGold}g | ${newXp}xp | $newGems💎'),
        backgroundColor: AppColors.shadowAscending,
      ),
    );
  }

  // ─── NAVEGAÇÃO ────────────────────────────────────────────────────

  Future<void> _resetClass() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .write(const PlayersTableCompanion(
      classType: Value(null),
      factionType: Value(null),
    ));
    final updated = await PlayerDao(db).findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    _invalidateAll(player.id);
    AppSnack.success(context, 'Classe e facção resetadas');
  }

  // ─── PROGRESSO (Sprint 3.4 Etapa A hotfix P2) ─────────────────────
  //
  // Atalhos pra exercitar o caminho REAL do `PlayerDao.addXp` +
  // `LevelUp` listener global (`PlayerStateSyncService` em
  // `app/app_listeners.dart`). Validação manual do CEO no flow de
  // level up ficava bloqueada sem um meio rápido de injetar XP.
  //
  // ⚠️ TODOS via `addXp` — NÃO setamos `level` direto. Subir level via
  // `PlayersTableCompanion(level: Value(N))` bypassaria o caminho que
  // está sendo testado.

  Future<void> _addXpRaw(int amount) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    final dao = PlayerDao(db);
    final levelUp = await dao.addXp(player.id, amount);
    if (levelUp != null) {
      // Publica no bus pra exercitar `PlayerStateSyncService` E os
      // outros listeners (achievementsService.attachMetaLikeListeners
      // escuta LevelUp pra trigger de meta achievements).
      ref.read(appEventBusProvider).publish(levelUp);
    }
    // Mesmo sem level up, atualizamos `currentPlayerProvider` aqui pra
    // refresh imediato de XP bar quando NÃO cruzou threshold (sem
    // LevelUp emit, sync service não dispara).
    final fresh = await dao.findById(player.id);
    if (!mounted) return;
    if (fresh != null) {
      ref.read(currentPlayerProvider.notifier).state = fresh;
    }
    _invalidateAll(player.id);
    AppSnack.success(
        context,
        levelUp != null
            ? '+$amount XP → Lv${levelUp.previousLevel} → Lv${levelUp.newLevel}.'
            : '+$amount XP aplicado (sem level up).');
  }

  Future<void> _addXp200() => _addXpRaw(200);

  Future<void> _addXp1000() => _addXpRaw(1000);

  /// Sobe exatamente 1 nível via `addXp` real (caminho do listener).
  /// Calcula `(player.xpToNext - player.xp + 1)` pra cruzar o threshold
  /// por 1 ponto. Se já estava em xp ≥ xpToNext (estado inválido), o
  /// `+1` ainda funciona (o while em `addXp` consome de novo).
  Future<void> _levelUpOnce() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    final fresh = await PlayerDao(db).findById(player.id);
    if (fresh == null) return;
    final needed = (fresh.xpToNext - fresh.xp + 1).clamp(1, 1 << 30);
    await _addXpRaw(needed);
  }

  /// Sprint 3.4 hotfix P2 — força unlock da `SECRET_LOBO_SOLITARIO`
  /// pra teste do filtro de visibilidade da ERROR em
  /// `FactionSelectionScreen`. Conquista é shell (`disabled=true` no
  /// catálogo), normalmente nem o cache `_eventAchievements` carrega
  /// — mas o repository de unlock direto persiste row em
  /// `player_achievements_completed` por PK composta sem ligar pro
  /// flag `disabled`. Bypass intencional pra dev panel.
  Future<void> _forceUnlockLoboSolitario() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(playerAchievementsRepositoryProvider);
    const key = 'SECRET_LOBO_SOLITARIO';
    final already = await repo.isCompleted(player.id, key);
    if (already) {
      if (!mounted) return;
      AppSnack.info(context, 'SECRET_LOBO_SOLITARIO já desbloqueada.');
      return;
    }
    await repo.markCompleted(player.id, key, at: DateTime.now());
    // Publica AchievementUnlocked pra disparar popup gourmet (se
    // listener tá montado) e cascata metaLike — todo o pipeline real.
    ref.read(appEventBusProvider).publish(
        AchievementUnlocked(playerId: player.id, achievementKey: key));
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(
        context,
        'SECRET_LOBO_SOLITARIO desbloqueada. ERROR agora visível em '
        '/faction-selection.');
  }

  // ─── FACÇÕES (Sprint 3.4 Etapa A) ─────────────────────────────────

  /// Trigger manual do flow de admissão. Útil pra debug em devices que
  /// já tinham `faction_type='X'` antes do bug-fix da Sprint 3.4 (ou
  /// que selecionaram facção antes do `QuestAdmissionService` ser
  /// religado em `FactionSelectionScreen`). Lê `players.faction_type`,
  /// strip do prefixo `pending:` se houver, dispara
  /// `startFactionAdmission`, mostra resultado.
  Future<void> _triggerAdmission() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final raw = player.factionType ?? '';
    if (raw.isEmpty || raw == 'none') {
      if (!mounted) return;
      AppSnack.error(context,
          'Nenhuma facção selecionada (faction_type vazio/none).');
      return;
    }
    final factionId = raw.startsWith('pending:')
        ? raw.substring('pending:'.length)
        : raw;
    final svc = ref.read(questAdmissionServiceProvider);
    final created = await svc.startFactionAdmission(player.id, factionId);
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(
        context,
        created.isEmpty
            ? 'Pool vazio pra "$factionId" (verifique JSON).'
            : '${created.length} missões de admissão criadas pra "$factionId".');
  }

  /// Sprint 3.4 Etapa A hotfix — atalho pra testes: libera Guilda
  /// instantaneamente sem precisar passar pelo gate de N missões.
  /// Marca rank canônico='e' em `players.guild_rank` + insere row em
  /// `player_faction_membership` (factionId='guild', joinedAt=now) +
  /// fecha quaisquer quests pending de admissão da Guilda.
  /// Idempotente: se já é membro, AppSnack info e retorna.
  Future<void> _unlockGuildInstantly() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);

    if (player.guildRank != 'none' && player.guildRank.isNotEmpty) {
      if (!mounted) return;
      AppSnack.info(context,
          'Já é membro da Guilda (rank=${player.guildRank}).');
      return;
    }

    // 1. Rank canônico via service (ADR-0009).
    final rankService = ref.read(playerRankServiceProvider);
    await rankService.setRank(player.id, GuildRank.e);

    // 2. Membership row pra factionId='guild'. Idempotente via
    //    INSERT OR IGNORE; se já existia (ex: pending), promovemos
    //    `joined_at` se ainda for null.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT OR IGNORE INTO player_faction_membership '
      '(player_id, faction_id, joined_at, left_at, locked_until, '
      ' debuff_until, admission_attempts) '
      'VALUES (?, ?, ?, NULL, NULL, NULL, 0)',
      [player.id, 'guild', nowMs],
    );
    await db.customStatement(
      'UPDATE player_faction_membership SET joined_at = ? '
      "WHERE player_id = ? AND faction_id = 'guild' "
      'AND joined_at IS NULL',
      [nowMs, player.id],
    );

    // 3. Fecha quests admissão pendentes da Guilda (markCompleted),
    //    pra remover ruído visual de cards "ADMISSION_GUILD_*" parados.
    final missionRepo = ref.read(missionRepositoryProvider);
    final admissions = await missionRepo
        .findByTab(player.id, MissionTabOrigin.admission);
    var closed = 0;
    for (final m in admissions) {
      if (m.completedAt != null || m.failedAt != null) continue;
      // Filtra por factionId no metaJson (ou pela própria missionKey).
      final isGuild = m.metaJson.contains('"faction_id":"guild"') ||
          m.missionKey.startsWith('ADMISSION_GUILD');
      if (!isGuild) continue;
      await missionRepo.markCompleted(m.id,
          at: DateTime.now(), rewardClaimed: true);
      closed++;
    }

    final updated = await PlayerDao(db).findById(player.id);
    if (!mounted) return;
    if (updated != null) {
      ref.read(currentPlayerProvider.notifier).state = updated;
    }
    _invalidateAll(player.id);
    AppSnack.success(context,
        'Guilda liberada (rank=E + membership + $closed quests fechadas).');
  }

  // ─── Sub-Etapa B.2 — atalhos pra testar admissão eliminatória ─

  /// Completa todas as sub-tasks da admissão pendente do player atual.
  /// Marca `completed=true` em cada sub-task de cada missão ativa
  /// (tabOrigin=admission, faction matches `players.faction_type`
  /// stripped de `pending:`). O listener regular (`FactionAdmission
  /// ProgressService`) detecta no próximo evento e cascateia
  /// `FactionAdmissionQuestCompleted` + promoção de próxima missão +
  /// eventualmente `FactionAdmissionApproved`. Pra forçar essa cadeia
  /// IMEDIATAMENTE, emitimos um `RewardGranted` no-op (qualquer evento
  /// terminal serve — o listener escuta vários).
  Future<void> _forceCompleteAdmission() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final raw = player.factionType ?? '';
    if (raw.isEmpty || raw == 'none') {
      if (!mounted) return;
      AppSnack.error(context, 'Nenhuma admissão ativa.');
      return;
    }
    final factionId = raw.startsWith('pending:')
        ? raw.substring('pending:'.length)
        : raw;

    final db = ref.read(appDatabaseProvider);
    final missionRepo = ref.read(missionRepositoryProvider);
    final all = await missionRepo.findByTab(
        player.id, MissionTabOrigin.admission);
    var modified = 0;
    for (final m in all) {
      if (m.completedAt != null || m.failedAt != null) continue;
      Map<String, dynamic> meta;
      try {
        meta = jsonDecode(m.metaJson) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      if (meta['faction_id'] != factionId) continue;
      final subs = (meta['sub_tasks'] as List?) ?? const [];
      final updated = subs
          .map((s) {
            final mp = (s as Map).cast<String, dynamic>();
            mp['completed'] = true;
            return mp;
          })
          .toList();
      meta['sub_tasks'] = updated;
      meta['is_unlocked'] = true; // garante que progress detecta
      await db.customUpdate(
        'UPDATE player_mission_progress SET meta_json = ? WHERE id = ?',
        variables: [
          Variable.withString(jsonEncode(meta)),
          Variable.withInt(m.id),
        ],
        updates: {db.playerMissionProgressTable},
      );
      modified++;
    }
    // Trigger no-op pra o listener processar.
    ref.read(appEventBusProvider).publish(RewardGranted(
        playerId: player.id,
        rewardResolvedJson:
            '{"xp":0,"gold":0,"gems":0,"seivas":0,"items":[],'
            '"achievements_to_check":[],"recipes_to_unlock":[]}'));
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(
        context,
        '$modified missões de admissão preenchidas. Aguarde cascata.');
  }

  /// Dispara `FactionAdmissionRejected` manualmente
  /// (reason="dev_panel_force_reject"). Listener handler reseta
  /// admissão (failed + rep -10 + lock 48h + faction_type='none').
  Future<void> _forceRejectAdmission() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final raw = player.factionType ?? '';
    if (raw.isEmpty || raw == 'none') {
      if (!mounted) return;
      AppSnack.error(context, 'Nenhuma admissão ativa.');
      return;
    }
    final factionId = raw.startsWith('pending:')
        ? raw.substring('pending:'.length)
        : raw;

    ref.read(appEventBusProvider).publish(FactionAdmissionRejected(
          playerId: player.id,
          factionId: factionId,
          attemptCount: 1,
          reason: 'dev_panel_force_reject',
          missionId: 'DEV',
        ));
    if (!mounted) return;
    AppSnack.success(
        context,
        'FactionAdmissionRejected emitido pra "$factionId". '
        '_handleRejection vai resetar.');
    // Pequeno delay + invalidate pra UI pegar mudanças.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) _invalidateAll(player.id);
  }

  /// Subtrai 24h do `window_start_ms` de todas as sub-tasks de
  /// missões ativas da admissão atual. Permite testar `window_expired`
  /// sem aguardar 48h reais.
  Future<void> _advanceAdmissionTime() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final raw = player.factionType ?? '';
    if (raw.isEmpty || raw == 'none') {
      if (!mounted) return;
      AppSnack.error(context, 'Nenhuma admissão ativa.');
      return;
    }
    final factionId = raw.startsWith('pending:')
        ? raw.substring('pending:'.length)
        : raw;

    final db = ref.read(appDatabaseProvider);
    final missionRepo = ref.read(missionRepositoryProvider);
    final all = await missionRepo.findByTab(
        player.id, MissionTabOrigin.admission);
    const shift = 24 * 60 * 60 * 1000;
    var modified = 0;
    for (final m in all) {
      if (m.completedAt != null || m.failedAt != null) continue;
      Map<String, dynamic> meta;
      try {
        meta = jsonDecode(m.metaJson) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      if (meta['faction_id'] != factionId) continue;
      final ws = (meta['window_start_ms'] as int?) ?? 0;
      if (ws > 0) {
        meta['window_start_ms'] = ws - shift;
        final subs = (meta['sub_tasks'] as List?) ?? const [];
        final updated = subs.map((s) {
          final mp = (s as Map).cast<String, dynamic>();
          if ((mp['window_start_ms'] as int?) != null) {
            mp['window_start_ms'] = (mp['window_start_ms'] as int) - shift;
          }
          return mp;
        }).toList();
        meta['sub_tasks'] = updated;
        await db.customUpdate(
          'UPDATE player_mission_progress SET meta_json = ? WHERE id = ?',
          variables: [
            Variable.withString(jsonEncode(meta)),
            Variable.withInt(m.id),
          ],
          updates: {db.playerMissionProgressTable},
        );
        modified++;
      }
    }
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(
        context, '$modified missões avançadas em 24h.');
  }

  /// Lista rows de `player_faction_membership` + `player_faction_reputation`
  /// pra debug. Mostra timestamps em ISO local pra leitura.
  Future<void> _listMembership() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    final memRows = await db.customSelect(
      'SELECT faction_id, joined_at, left_at, locked_until, debuff_until, '
      ' admission_attempts FROM player_faction_membership '
      'WHERE player_id = ? ORDER BY faction_id',
      variables: [Variable.withInt(player.id)],
    ).get();
    final repRows = await db.customSelect(
      'SELECT faction_id, reputation FROM player_faction_reputation '
      'WHERE player_id = ? ORDER BY faction_id',
      variables: [Variable.withInt(player.id)],
    ).get();
    if (!mounted) return;
    String fmtMs(int? ms) =>
        ms == null ? '-' : DateTime.fromMillisecondsSinceEpoch(ms)
            .toIso8601String()
            .substring(0, 16);
    final lines = <String>[
      'faction_type atual: ${player.factionType ?? "(null)"}',
      '',
      'MEMBERSHIPS (${memRows.length}):',
      ...memRows.map((r) =>
          '  ${r.read<String>('faction_id')} '
          'joined=${fmtMs(r.data['joined_at'] as int?)} '
          'left=${fmtMs(r.data['left_at'] as int?)} '
          'lock=${fmtMs(r.data['locked_until'] as int?)} '
          'debuff=${fmtMs(r.data['debuff_until'] as int?)} '
          'attempts=${r.read<int>('admission_attempts')}'),
      '',
      'REPUTATIONS (${repRows.length}):',
      ...repRows.map((r) =>
          '  ${r.read<String>('faction_id')} = ${r.read<int>('reputation')}'),
    ];
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Facção: dados do jogador',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.purpleLight, fontSize: 14)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(lines.join('\n'),
                style: GoogleFonts.robotoMono(
                    fontSize: 10, color: AppColors.textPrimary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ─── MISSÕES DIÁRIAS ──────────────────────────────────────────────

  Future<void> _forceDailyReset() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.customUpdate(
      'UPDATE players SET last_daily_reset = NULL WHERE id = ?',
      variables: [Variable.withInt(player.id)],
      updates: {db.playersTable},
    );
    final result =
        await ref.read(dailyResetServiceProvider).checkAndApply(player.id);
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(
        context,
        'Daily reset: ${result.processed} processadas / '
        '${result.reassignedDaily} novas daily / ${result.reassignedClass} novas classe');
  }

  Future<void> _forceCompleteFirst() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(missionRepositoryProvider);
    final active = await repo.findActive(player.id);
    if (active.isEmpty) {
      if (!mounted) return;
      AppSnack.error(context, 'Sem missões ativas');
      return;
    }
    final first = active.first;
    await repo.markCompleted(first.id,
        at: DateTime.now(), rewardClaimed: true);
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(context, 'Completada: ${first.missionKey}');
  }

  Future<void> _forceFailFirst() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(missionRepositoryProvider);
    final active = await repo.findActive(player.id);
    if (active.isEmpty) {
      if (!mounted) return;
      AppSnack.error(context, 'Sem missões ativas');
      return;
    }
    final first = active.first;
    await repo.markFailed(first.id, at: DateTime.now());
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(context, 'Falhou: ${first.missionKey}');
  }

  Future<void> _skipToTomorrow() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Pular pra amanhã?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.shadowObsessive, fontSize: 14)),
        content: Text(
          'Vai simular passagem de dia. Missões pendentes de hoje viram '
          'parcial/falha conforme progresso. Use uma vez por dia — se '
          'já tem missões em ontem, use "Resetar" em vez disso.',
          style: GoogleFonts.roboto(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.shadowObsessive),
            child: const Text('Pular dia'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final todayStr = _isoDate(today);
    final yesterdayStr = _isoDate(yesterday);

    final dao = ref.read(dailyMissionsDaoProvider);

    final yesterdayExisting =
        await dao.findByPlayerAndDate(player.id, yesterdayStr);
    if (yesterdayExisting.isNotEmpty) {
      if (!mounted) return;
      AppSnack.error(context,
          'Já tem missões em ontem ($yesterdayStr). Use "Resetar" em vez disso.');
      return;
    }

    final todays = await dao.findByPlayerAndDate(player.id, todayStr);
    for (final m in todays) {
      await dao.updateMissionDate(m.id, yesterdayStr);
    }

    final db = ref.read(appDatabaseProvider);
    final yesterday2359 =
        DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59);
    await db.customUpdate(
      'UPDATE players SET last_daily_mission_rollover = ? WHERE id = ?',
      variables: [
        Variable.withInt(yesterday2359.millisecondsSinceEpoch),
        Variable.withInt(player.id),
      ],
      updates: {db.playersTable},
    );

    await ref
        .read(dailyMissionRolloverServiceProvider)
        .processRollover(player.id);
    final generated = await ref
        .read(dailyMissionGeneratorServiceProvider)
        .generateForToday(player.id);

    final updated = await PlayerDao(db).findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    _invalidateAll(player.id);
    AppSnack.success(
        context,
        'Pulou pra amanhã. ${todays.length} pendentes fechadas, '
        '${generated.length} novas geradas.');
  }

  Future<void> _resetTodayDailyMissions() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Resetar missões diárias de hoje?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.hp, fontSize: 14)),
        content: Text(
          'Vai apagar as 3 missões de hoje sem reward + gerar 3 novas. '
          'Confirma?',
          style: GoogleFonts.roboto(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.hp),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final generated = await ref
        .read(dailyMissionGeneratorServiceProvider)
        .generateForToday(player.id, force: true);
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(
        context, 'Resetou. ${generated.length} novas missões geradas.');
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ─── CONQUISTAS ───────────────────────────────────────────────────

  Future<void> _resetAllAchievements() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Resetar TODAS as conquistas?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.hp, fontSize: 14)),
        content: Text(
          'Apaga player_achievements_completed do jogador. Conquistas '
          'que ainda preenchem critério vão re-disparar quando o próximo '
          'trigger rodar (event, daily stats, level up). Comportamento '
          'esperado pra validar pipeline.',
          style: GoogleFonts.roboto(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.hp),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final db = ref.read(appDatabaseProvider);
    final deleted = await db.customUpdate(
      'DELETE FROM player_achievements_completed WHERE player_id = ?',
      variables: [Variable.withInt(player.id)],
      updates: {db.playerAchievementsCompletedTable},
    );
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(context, '$deleted conquistas resetadas.');
  }

  Future<void> _listAchievements() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(playerAchievementsRepositoryProvider);
    final keys = await repo.listCompletedKeys(player.id);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Conquistas (${keys.length})',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.gold, fontSize: 14)),
        content: SizedBox(
          width: double.maxFinite,
          child: keys.isEmpty
              ? Text('Nenhuma conquista desbloqueada.',
                  style:
                      GoogleFonts.roboto(color: AppColors.textSecondary))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final k in keys)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(k,
                              style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  color: AppColors.textPrimary)),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ─── DISPARO MANUAL DE TOAST (Sprint 3.3 Etapa Final-B hotfix) ────
  //
  // Bypass total do trigger: marca completed direto + publica
  // AchievementUnlocked. Usado pra validar pipeline do popup gourmet
  // sem ter que satisfazer condições reais. Conquista vai pra estado
  // pendente de coleta (rewardClaimed=false).

  Future<AchievementDefinition?> _pickEligibleAchievement({
    required bool secret,
  }) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return null;
    final svc = ref.read(achievementsServiceProvider);
    await svc.ensureLoaded();
    final repo = ref.read(playerAchievementsRepositoryProvider);
    final completed =
        (await repo.listCompletedKeys(player.id)).toSet();

    final eligible = svc.catalog.values
        .where((d) => !d.disabled)
        .where((d) => d.isSecret == secret)
        .where((d) => !completed.contains(d.key))
        .toList();
    if (eligible.isEmpty) return null;
    eligible.shuffle(math.Random());
    return eligible.first;
  }

  Future<void> _triggerAchievement({required bool secret}) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final pick = await _pickEligibleAchievement(secret: secret);
    if (pick == null) {
      if (!mounted) return;
      AppSnack.info(
          context,
          secret
              ? 'Sem secretas elegíveis (todas já desbloqueadas?)'
              : 'Sem conquistas elegíveis (todas já desbloqueadas?)');
      return;
    }

    final repo = ref.read(playerAchievementsRepositoryProvider);
    final bus = ref.read(appEventBusProvider);
    await repo.markCompleted(player.id, pick.key, at: DateTime.now());
    bus.publish(
        AchievementUnlocked(playerId: player.id, achievementKey: pick.key));

    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(
        context, '${secret ? "Disparada secreta" : "Disparada"}: ${pick.key}');
  }

  // ─── COLETA MANUAL (Sprint 3.3 Etapa Final-A) ─────────────────────

  Future<void> _claimAllPending() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(playerAchievementsRepositoryProvider);
    final svc = ref.read(achievementsServiceProvider);

    final pending = await repo.listPendingClaims(player.id);
    if (pending.isEmpty) {
      if (!mounted) return;
      AppSnack.info(context, 'Nenhuma conquista pendente de coleta.');
      return;
    }

    var claimed = 0;
    var failed = 0;
    for (final key in pending) {
      final ok = await svc.claimReward(player.id, key);
      if (ok) {
        claimed++;
      } else {
        failed++;
      }
    }

    final updated = await PlayerDao(ref.read(appDatabaseProvider))
        .findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    _invalidateAll(player.id);
    AppSnack.success(
      context,
      'Coletadas: $claimed${failed > 0 ? ' (falhas: $failed)' : ''}.',
    );
  }

  Future<void> _listPendingClaims() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(playerAchievementsRepositoryProvider);
    final pending = await repo.listPendingClaims(player.id);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Pendentes de coleta (${pending.length})',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.purpleLight, fontSize: 14)),
        content: SizedBox(
          width: double.maxFinite,
          child: pending.isEmpty
              ? Text('Nenhuma conquista pendente.',
                  style: GoogleFonts.roboto(
                      color: AppColors.textSecondary))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final k in pending)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 2),
                          child: Text(k,
                              style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  color: AppColors.textPrimary)),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // ─── REPUTAÇÃO COMPACTA ───────────────────────────────────────────

  Future<void> _applyRepDelta() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final delta = int.tryParse(_repDeltaCtrl.text);
    if (delta == null) {
      if (!mounted) return;
      AppSnack.error(context, 'Delta inválido');
      return;
    }
    await ref.read(factionReputationServiceProvider).adjustReputation(
        playerId: player.id, factionId: _selectedFaction, delta: delta);
    if (!mounted) return;
    _invalidateAll(player.id);
    AppSnack.success(context, '$_selectedFaction $delta aplicado');
    setState(() {}); // rebuild current rep label
  }

  // ─── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.go('/sanctuary'),
        ),
        title: Text('DEV PANEL',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.hp, fontSize: 14, letterSpacing: 2)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.hp.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.hp.withValues(alpha: 0.4)),
            ),
            child: Text('APENAS DEV',
                style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: AppColors.hp,
                    letterSpacing: 1)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATUS
            _section('STATUS'),
            _infoRow('Lv',
                '${player?.level ?? 0} · ${player?.xp ?? 0}xp · ${player?.gold ?? 0}g · ${player?.gems ?? 0}💎'),
            _infoRow('Classe',
                '${player?.classType ?? '-'} · ${player?.factionType ?? '-'}'),
            _infoRow('Sombra',
                '${player?.shadowState ?? '-'} · Dia ${player?.caelumDay ?? 1} em Caelum'),
            const SizedBox(height: 16),

            // 2. AJUSTAR VALORES
            _section('AJUSTAR VALORES'),
            _field(_levelCtrl, 'Novo nível', '${player?.level ?? 1}'),
            const SizedBox(height: 6),
            _field(_goldCtrl, 'Novo ouro', '${player?.gold ?? 0}'),
            const SizedBox(height: 6),
            _field(_xpCtrl, 'Novo XP', '${player?.xp ?? 0}'),
            const SizedBox(height: 6),
            _field(_gemsCtrl, 'Novas gemas', '${player?.gems ?? 0}'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  // Hotfix visual — mesmo pattern do _actionBtn.
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    // Cinzel renderizava estranho em algumas devices ("APlICAR")
                    // — troca pra Roboto bold com letter-spacing pra manter o
                    // look de botão de ação principal.
                    : Text('APLICAR',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        )),
              ),
            ),
            const SizedBox(height: 16),

            // 3. NAVEGAÇÃO
            _section('NAVEGAÇÃO'),
            _actionBtn(
                'Resetar classe e facção', AppColors.hp, _resetClass),
            const SizedBox(height: 6),
            _actionBtn('Ir para seleção de classe', AppColors.gold,
                () => context.go('/class-selection')),
            const SizedBox(height: 6),
            _actionBtn('Ir para seleção de facção',
                AppColors.shadowStable,
                () => context.go('/faction-selection')),
            const SizedBox(height: 16),

            // 3.4. PROGRESSO (Sprint 3.4 Etapa A hotfix P2)
            _section('PROGRESSO'),
            _actionBtn('Adicionar 200 XP', AppColors.purple, _addXp200),
            const SizedBox(height: 6),
            _actionBtn('Adicionar 1000 XP', AppColors.purple, _addXp1000),
            const SizedBox(height: 6),
            _actionBtn('Subir 1 nível (via addXp real)',
                AppColors.shadowAscending, _levelUpOnce),
            const SizedBox(height: 6),
            _actionBtn('Forçar unlock SECRET_LOBO_SOLITARIO',
                AppColors.gold, _forceUnlockLoboSolitario),
            const SizedBox(height: 16),

            // 3.5. FACÇÕES (Sprint 3.4 Etapa A — debug do flow de admissão)
            _section('FACÇÕES'),
            _actionBtn('Trigger admission (facção atual)',
                AppColors.shadowStable, _triggerAdmission),
            const SizedBox(height: 6),
            _actionBtn('Listar membership atual',
                AppColors.purpleLight, _listMembership),
            const SizedBox(height: 6),
            // Sprint 3.4 Etapa A hotfix — atalho pra testes da Guilda.
            _actionBtn('Liberar guilda (instantâneo)',
                AppColors.gold, _unlockGuildInstantly),
            const SizedBox(height: 6),
            // Sprint 3.4 Sub-Etapa B.2 — atalhos pra testar admissão
            // eliminatória sem aguardar 48h reais.
            _actionBtn('Forçar conclusão de admissão atual',
                AppColors.shadowAscending, _forceCompleteAdmission),
            const SizedBox(height: 6),
            _actionBtn('Forçar reprovação de admissão atual',
                AppColors.hp, _forceRejectAdmission),
            const SizedBox(height: 6),
            _actionBtn('Avançar tempo +24h (admissão atual)',
                AppColors.shadowObsessive, _advanceAdmissionTime),
            const SizedBox(height: 16),

            // 4. MISSÕES DIÁRIAS
            _section('MISSÕES DIÁRIAS'),
            _actionBtn('Resetar missões diárias de hoje', AppColors.hp,
                _resetTodayDailyMissions),
            const SizedBox(height: 6),
            _actionBtn('Pular pra amanhã (simular dia)',
                AppColors.shadowObsessive, _skipToTomorrow),
            const SizedBox(height: 6),
            _actionBtn('Reset daily now (bypass 24h)', AppColors.purple,
                _forceDailyReset),
            const SizedBox(height: 6),
            _actionBtn('Forçar complete 1ª missão ativa',
                AppColors.shadowAscending, _forceCompleteFirst),
            const SizedBox(height: 6),
            _actionBtn(
                'Forçar fail 1ª missão ativa', AppColors.hp, _forceFailFirst),
            const SizedBox(height: 16),

            // 5. CONQUISTAS
            _section('CONQUISTAS'),
            _actionBtn('Resetar TODAS as conquistas', AppColors.hp,
                _resetAllAchievements),
            const SizedBox(height: 6),
            _actionBtn('Listar conquistas atuais', AppColors.gold,
                _listAchievements),
            const SizedBox(height: 6),
            // Sprint 3.3 Etapa Final-B hotfix — disparo manual pra validar
            // popup gourmet sem precisar satisfazer trigger real.
            _actionBtn('Disparar conquista aleatória', AppColors.purple,
                () => _triggerAchievement(secret: false)),
            const SizedBox(height: 6),
            _actionBtn('Disparar conquista SECRETA aleatória',
                AppColors.shadowObsessive,
                () => _triggerAchievement(secret: true)),
            const SizedBox(height: 6),
            // Sprint 3.3 Etapa Final-A — coleta manual: helpers do dev
            // panel pra validar pipeline sem precisar da UI da Sub B.
            _actionBtn('Coletar TODAS pendentes',
                AppColors.shadowAscending, _claimAllPending),
            const SizedBox(height: 6),
            _actionBtn('Listar pendentes de coleta',
                AppColors.purpleLight, _listPendingClaims),
            const SizedBox(height: 16),

            // 6. REPUTAÇÃO FACÇÕES (compacto)
            _section('REPUTAÇÃO FACÇÕES'),
            _buildReputationCompactRow(player?.id),
            const SizedBox(height: 16),

            // 7. EVENTS INSPECTOR
            _section('EVENTS (últimos $_kEventBufferMax)'),
            _buildEventsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReputationCompactRow(int? playerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedFaction,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                style: GoogleFonts.roboto(
                    fontSize: 12, color: AppColors.textPrimary),
                dropdownColor: AppColors.surface,
                items: [
                  for (final f in kKnownFactions)
                    DropdownMenuItem(value: f, child: Text(f)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedFaction = v);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _repDeltaCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '±delta',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                style: GoogleFonts.roboto(
                    fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _applyRepDelta,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                minimumSize: const Size(64, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('APLICAR',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (playerId != null)
          FutureBuilder<int>(
            future: ref
                .read(factionReputationServiceProvider)
                .current(playerId, _selectedFaction),
            builder: (ctx, snap) {
              final rep = snap.data ?? 50;
              return Text('rep atual ($_selectedFaction): $rep',
                  style: GoogleFonts.robotoMono(
                      fontSize: 11, color: AppColors.textMuted));
            },
          ),
      ],
    );
  }

  Widget _buildEventsList() {
    if (_eventBuffer.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('(sem eventos capturados ainda)',
            style: GoogleFonts.roboto(
                fontSize: 11, color: AppColors.textMuted)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in _eventBuffer)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              '${entry.at.toIso8601String().substring(11, 19)}  '
              '${entry.type}  ${entry.repr}',
              style: GoogleFonts.robotoMono(
                  fontSize: 10, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  // ─── helpers visuais ──────────────────────────────────────────────

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: GoogleFonts.cinzelDecorative(
                fontSize: 12,
                color: AppColors.purpleLight,
                letterSpacing: 1.5)),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 54,
              child: Text(label,
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textMuted)),
            ),
            Expanded(
              // Sprint 3.3 hotfix visual — softWrap + maxLines pra textos
              // longos como "Sombra: stable · Dia 12 em Caelum" não
              // sumirem em telas pequenas.
              child: Text(value,
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.textPrimary),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _field(
          TextEditingController ctrl, String label, String hint) =>
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        style: GoogleFonts.roboto(
            fontSize: 13, color: AppColors.textPrimary),
      );

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            // Hotfix visual — sem height fixo. Padding vertical + minimumSize
            // garantem altura adequada pro texto não cortar (Roboto fontSize
            // 12 + line-height 1.2 ≈ 17px, soma com padding 12+12 = 41px).
            // Antes: SizedBox(height: 36) cortava ascenders/descenders.
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              )),
        ),
      );
}

/// Sprint 3.1 Bloco 14 — entry do events inspector ring buffer.
class _EventLogEntry {
  final DateTime at;
  final String type;
  final String repr;
  const _EventLogEntry({
    required this.at,
    required this.type,
    required this.repr,
  });
}
