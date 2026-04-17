import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/datasources/local/habit_local_ds.dart';
import '../../../data/database/tables/habits_table.dart';
import '../../shared/widgets/nh_bottom_nav.dart';
import '../../../data/datasources/local/achievement_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/create_habit_sheet.dart';
import '../widgets/completion_dialog.dart';
import '../../shared/widgets/reward_toast.dart';
import '../widgets/class_quest_card.dart';
import '../widgets/faction_quest_card.dart';
import '../../../data/datasources/local/faction_quest_service.dart';
import '../../../data/datasources/local/quest_admission_service.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/npc_dialog_overlay.dart';
import '../../shared/widgets/milestone_popup.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, ref),
                Expanded(
                  child: habitsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.purple)),
                    error: (e, _) => Center(
                        child: Text('Erro: $e',
                            style: const TextStyle(
                                color: AppColors.textMuted))),
                    data: (habits) =>
                        _buildList(context, ref, habits),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: NhBottomNav(currentIndex: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final player = ref.watch(currentPlayerProvider);
    final total = habitsAsync.value?.length ?? 0;
    final done  = habitsAsync.value?.where((h) => h.isDone).length ?? 0;
    final streak = player?.streakDays ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MISSÕES',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      color: AppColors.gold,
                      letterSpacing: 2)),
              Row(
                children: [
                  if (streak > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text('$streak dias',
                              style: GoogleFonts.roboto(
                                  fontSize: 11, color: AppColors.gold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text('$done/$total',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.purple),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref,
      List<HabitWithStatus> habits) {
    // Separa por tipo de missão
    // Rituais Diários: system habits sem prefixo '[' no título
    final dailyRituals = habits
        .where((h) => h.habit.isSystemHabit && !h.habit.title.startsWith('['))
        .toList();

    // Missões de Classe: títulos que começam com '[Guerreiro]', '[Mago]' etc.
    final classQuests = habits
        .where((h) =>
            h.habit.title.startsWith('[') &&
            !h.habit.title.toLowerCase().contains('admiss'))
        .toList();

    // Admissão de Facção: títulos que contêm '[Admissão'
    final admissionQuests = habits
        .where((h) =>
            h.habit.title.toLowerCase().contains('[admiss'))
        .toList();

    // Missões Individuais: não são system habits e não têm prefixo '['
    final personalQuests = habits
        .where((h) =>
            !h.habit.isSystemHabit && !h.habit.title.startsWith('['))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // ── RITUAIS DIÁRIOS ──
        if (dailyRituals.isNotEmpty) ...[
          _sectionHeader('RITUAIS DIÁRIOS', Icons.wb_sunny_outlined),
          const SizedBox(height: 10),
          ...dailyRituals.map((h) => HabitCard(
                habitWithStatus: h,
                onTap: () => _showCompletion(context, ref, h),
              )),
          const SizedBox(height: 20),
        ],

        // ── MISSÕES DE CLASSE (auto-conclusão) ──
        Builder(builder: (ctx) {
          final classQuestsAsync = ref.watch(todayClassQuestsProvider);
          return classQuestsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cqs) {
              if (cqs.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('MISSÕES DE CLASSE',
                      Icons.auto_fix_high_outlined, color: AppColors.purple),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Concluídas automaticamente ao agir.',
                        style: GoogleFonts.roboto(
                            fontSize: 10, color: AppColors.textMuted)),
                  ),
                  ...cqs.map((q) => ClassQuestCard(quest: q)),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        }),

        // ── MISSÃO DE FACÇÃO SEMANAL ──
        Builder(builder: (ctx) {
          final fqAsync = ref.watch(activeFactionQuestProvider);
          return fqAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (fq) {
              if (fq == null) return const SizedBox.shrink();
              final player = ref.read(currentPlayerProvider);
              final faction = player?.factionType ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('MISSÃO DA FACÇÃO',
                      Icons.shield_outlined, color: AppColors.gold),
                  const SizedBox(height: 10),
                  FactionQuestCard(quest: fq, factionId: faction),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        }),

        // ── MISSÕES DE CLASSE (hábitos via título [Classe]) ──
        if (classQuests.isNotEmpty) ...[
          _sectionHeader(
            'MISSÕES DE CLASSE',
            Icons.auto_fix_high_outlined,
            color: AppColors.purple,
          ),
          const SizedBox(height: 10),
          ...classQuests.map((h) => HabitCard(
                habitWithStatus: h,
                onTap: () => _showCompletion(context, ref, h),
              )),
          const SizedBox(height: 20),
        ],

        // ── ADMISSÃO DE FACÇÃO ──
        if (admissionQuests.isNotEmpty) ...[
          _sectionHeader(
            'ADMISSÃO DE FACÇÃO',
            Icons.shield_outlined,
            color: const Color(0xFF8B2020),
          ),
          const SizedBox(height: 10),
          ...admissionQuests.map((h) => HabitCard(
                habitWithStatus: h,
                onTap: () => _showCompletion(context, ref, h),
              )),
          const SizedBox(height: 20),
        ],

        // ── MISSÕES INDIVIDUAIS ──
        _sectionHeader('MISSÕES INDIVIDUAIS', Icons.person_outline),
        const SizedBox(height: 10),
        if (personalQuests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhuma missão individual ainda.',
              style: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.textMuted),
            ),
          )
        else
          ...personalQuests.map((h) => HabitCard(
                habitWithStatus: h,
                onTap: () => _showCompletion(context, ref, h),
                onLongPress: () => _showDelete(context, ref, h.habit),
              )),

        // Botão criar missão individual
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _showCreate(context, ref),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.4)),
              color: AppColors.purple.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppColors.purple, size: 18),
                const SizedBox(width: 8),
                Text('Nova Missão Individual',
                    style: GoogleFonts.roboto(
                        color: AppColors.purple, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, {Color? color}) {
    final c = color ?? AppColors.gold;
    return Row(
      children: [
        Icon(icon, color: c, size: 14),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.cinzelDecorative(
                fontSize: 11, color: c, letterSpacing: 2)),
      ],
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateHabitSheet(
        onCreated: () => ref.invalidate(habitsProvider),
      ),
    );
  }

  void _showCompletion(
      BuildContext context, WidgetRef ref, HabitWithStatus h) {
    if (h.isDone && !h.habit.isRepeatable) return;
    showDialog(
      context: context,
      builder: (_) => CompletionDialog(
        habitWithStatus: h,
        onComplete: (status) async {
          final prevLevel = ref.read(currentPlayerProvider)?.level ?? 1;
          final player = ref.read(currentPlayerProvider);
          if (player == null) return;
          final result = await ref.read(habitDsProvider).completeHabit(
                habitId:  h.habit.id,
                playerId: player.id,
                rank:     h.habit.rank,
                status:   status,
              );
          final updated = await ref.read(authDsProvider).currentSession();
          ref.read(currentPlayerProvider.notifier).state = updated;
          ref.invalidate(habitsProvider);

          // Auto-confirma faccao se as 3 missoes de admissao ja foram concluidas
          try {
          if (updated != null) {
            final rawFaction = updated.factionType ?? '';
            if (rawFaction.startsWith('pending:')) {
              final factionId = rawFaction.replaceFirst('pending:', '');
              final db = ref.read(appDatabaseProvider);
              final admSvc = QuestAdmissionService(db);
              final passed = await admSvc.checkFactionAdmission(updated.id, factionId);
              if (passed) {
                await admSvc.confirmFaction(updated.id, factionId);
                final confirmed = await ref.read(authDsProvider).currentSession();
                ref.read(currentPlayerProvider.notifier).state = confirmed;
                ref.invalidate(habitsProvider);
                ref.invalidate(activeFactionQuestProvider);
                if (context.mounted) {
                  await MilestonePopup.show(
                    context,
                    title: 'Admissao Aprovada',
                    subtitle: 'Bem-vindo a faccao',
                    message: 'Voce provou seu valor. A faccao o reconhece como membro.\n\nA partir de agora missoes semanais da faccao estarao disponiveis — e sua reputacao pode crescer.',
                    icon: Icons.shield_outlined,
                    color: AppColors.gold,
                  );
                }
                if (context.mounted) {
                  await NpcDialogOverlay.show(
                    context,
                    npcName: 'O Vazio',
                    npcTitle: 'Presenca silenciosa',
                    message: 'Va ate a aba de Faccoes na Guilda e fale com o lider. Ele tera palavras para voce.',
                  );
                }
              }
            }
          }

          } catch (_) { /* admissao silenciosa */ }

          // Auto-check class/faction quests — pula quando a missao completada for [Admissao]
          final isAdmissionHabit = h.habit.title.startsWith('[Admissão]');
          try {
          if (!isAdmissionHabit && updated != null && (updated.classType?.isNotEmpty ?? false)) {
            final ctx = {
              'streak': updated.streakDays,
              'niet_free_days': updated.streakDays,
            };
            final completedCQ = await ref.read(classQuestServiceProvider)
                .checkAndComplete(updated.id, ctx);
            ref.invalidate(todayClassQuestsProvider);
            if (completedCQ.isNotEmpty && context.mounted) {
              for (final cq in completedCQ) {
                RewardToast.show(context,
                    source: cq.title,
                    xp: cq.xpReward,
                    gold: cq.goldReward);
              }
            }
            // Auto-check faction quest
            final faction = updated.factionType ?? '';
            if (faction.isNotEmpty && faction != 'none' && !faction.startsWith('pending:')) {
              final fctx = {'streak': updated.streakDays, 'niet_free_days': updated.streakDays};
              final fDone = await ref.read(factionQuestServiceProvider)
                  .checkAndComplete(updated.id, faction, fctx);
              ref.invalidate(activeFactionQuestProvider);
              if (fDone && context.mounted) {
                final fq = await ref.read(factionQuestServiceProvider)
                    .getActiveQuest(updated.id, faction);
                if (fq != null) {
                  final loot = FactionQuestService.calcLoot(updated.guildRank, fq.factionItemChance);
                  RewardToast.show(context,
                      source: fq.title,
                      xp: fq.xpReward,
                      gold: fq.goldReward,
                      achievementTitle: loot['has_faction_item'] == true
                          ? 'Item da facção dropado!'
                          : null);
                }
              }
            }
          }
          } catch (_) { /* class/faction quest silencioso */ }

          if (updated != null && updated.level > prevLevel && context.mounted) {
            final msgs = _levelUnlockMessages(updated.level);
            MilestonePopup.show(
              context,
              title: 'Nivel ' + updated.level.toString(),
              subtitle: 'Subiu de nivel',
              message: msgs.isNotEmpty
                  ? 'Voce alcancou o Nivel ' + updated.level.toString() + '!\n\n' + msgs.join('\n')
                  : 'Voce alcancou o Nivel ' + updated.level.toString() + '! Caelum reconhece seu crescimento.',
              icon: Icons.arrow_circle_up,
              color: AppColors.xp,
            );
          }
          if (updated != null) {
            try {
            final db = ref.read(appDatabaseProvider);
            final newAchievements = await AchievementService(db).checkAndUnlock(updated);
            if (context.mounted) {
              final achievement = newAchievements.isNotEmpty ? newAchievements.first : null;
              RewardToast.show(
                context,
                source: h.habit.title,
                xp: result.xpGained,
                gold: result.goldGained,
                achievementTitle: achievement,
              );
            }
            } catch (_) { /* achievement silencioso */ }
          }
        },
      ),
    );
  }

  void _showDelete(
      BuildContext context, WidgetRef ref, HabitsTableData habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Abandonar missão?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 15)),
        content: Text(
          'Você se comprometeu com "${habit.title}".\nAbandonar tem um custo — sua sombra registrará isso.',
          style: GoogleFonts.roboto(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Manter',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(habitDsProvider)
                  .deletePersonalHabit(habit.id);
              ref.invalidate(habitsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Abandonar',
                style: GoogleFonts.roboto(color: AppColors.hp)),
          ),
        ],
      ),
    );
  }
}

List<String> _levelUnlockMessages(int level) {
  final u = <String>[];
  if (level == 2)  u.add('Biblioteca desbloqueada');
  if (level == 5)  u.add('Selecao de Classe disponivel');
  if (level == 6)  u.add('Guilda de Aventureiros desbloqueada');
  if (level == 7)  u.add('Faccoes disponiveis');
  if (level == 10) u.add('Regioes medias desbloqueadas');
  if (level == 25) u.add('Vitalismo avancado desbloqueado');
  if (level == 50) u.add('Subclasses disponiveis');
  return u;
}
