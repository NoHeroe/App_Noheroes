import 'dart:async';

import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/providers.dart';
import '../../core/config/faction_alliances.dart';
import '../../core/constants/app_colors.dart';
import '../../core/events/app_event.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/player_dao.dart';
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
              height: 40,
              child: ElevatedButton(
                onPressed: _saving ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('APLICAR',
                        style: GoogleFonts.cinzelDecorative(
                            color: Colors.white, fontSize: 12)),
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
                      horizontal: 8, vertical: 8),
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
                      horizontal: 8, vertical: 8),
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
                    horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('APLY',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: Colors.white)),
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
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(label,
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textMuted)),
            ),
            Expanded(
              child: Text(value,
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.textPrimary)),
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
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        style: GoogleFonts.roboto(
            fontSize: 13, color: AppColors.textPrimary),
      );

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      SizedBox(
        width: double.infinity,
        height: 36,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 11, color: Colors.white)),
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
