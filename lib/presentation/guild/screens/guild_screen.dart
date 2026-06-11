import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../core/utils/faction_theme.dart';
import '../../../domain/enums/source_type.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/faction_buff_multipliers.dart';
import '../../shared/widgets/npc_dialog_overlay.dart';
import '../../shared/widgets/reward_toast.dart';
import '../../shared/widgets/app_snack.dart';
// Sprint 3.4 Etapa D — religa a AscensionTab (até então órfã) num host
// navegável a partir do header Aventureiro.
import '../widgets/ascension_tab.dart';

/// Sprint 3.4 Etapa A — snapshot mínimo da Guilda usando as fontes de
/// dados consolidadas (`player_faction_membership` factionId='guild' +
/// `player_faction_reputation` factionId='guild' + `players.guildRank`).
///
/// Substitui `GuildStatusTableData` que vinha da `guild_status` (DROPPED).
/// Etapa D vai redesenhar essa tela completamente — esta classe é
/// transitória pra manter o UX atual funcionando com as fontes novas.
class GuildMembershipSnapshot {
  final bool admitted;
  final String guildRank; // 'none', 'e'..'s'
  final int reputation;
  final DateTime? joinedAt;

  /// Missões concluídas (gate de admissão). Lido FRESH do servidor aqui pra
  /// não depender do `currentPlayerProvider` (que pode estar stale).
  final int totalQuestsCompleted;

  const GuildMembershipSnapshot({
    required this.admitted,
    required this.guildRank,
    required this.reputation,
    this.totalQuestsCompleted = 0,
    this.joinedAt,
  });
}

final guildStatusProvider =
    FutureProvider.autoDispose<GuildMembershipSnapshot?>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return null;

  // Época 2 full-online (ADR-0024) — lê DADOS VIVOS via PostgREST em vez
  // das queries Drift cruas (player.id agora é uuid String).
  final client = ref.read(supabaseClientProvider);

  // Membership row pra factionId='guild' (lazy: pode não existir ainda).
  final memRow = await client
      .from('player_faction_membership')
      .select('joined_at')
      .eq('player_id', player.id)
      .eq('faction_id', 'guild')
      .maybeSingle();
  DateTime? joinedAt;
  final raw = memRow?['joined_at'];
  if (raw is int) joinedAt = DateTime.fromMillisecondsSinceEpoch(raw);

  // Reputação pra factionId='guild' (lazy default 50 se não existe).
  final reputation = await ref
      .read(playerFactionReputationRepositoryProvider)
      .getOrDefault(player.id, 'guild');

  // Contador FRESH de missões concluídas (gate da admissão) — direto do
  // servidor, não do currentPlayer (que pode estar stale entre completions).
  final pRow = await client
      .from('players')
      .select('total_quests_completed')
      .eq('id', player.id)
      .maybeSingle();
  final totalQuests = (pRow?['total_quests_completed'] as int?) ?? 0;

  return GuildMembershipSnapshot(
    admitted: player.guildRank != 'none',
    guildRank: player.guildRank,
    reputation: reputation,
    totalQuestsCompleted: totalQuests,
    joinedAt: joinedAt,
  );
});

class GuildScreen extends ConsumerWidget {
  const GuildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final guildAsync = ref.watch(guildStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: guildAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, _) => Center(
              child: Text('Erro: $e',
                  style: const TextStyle(color: AppColors.textMuted))),
          data: (status) => _buildContent(context, ref, player, status),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      dynamic player, GuildMembershipSnapshot? status) {
    final admitted = status != null && status.guildRank != 'none';
    final rankLabel = _rankLabel(status?.guildRank ?? 'none');
    final reputation = status?.reputation ?? 0;
    final factionType = (player?.factionType as String?) ?? 'none';

    return Column(
      children: [
        _buildHeader(context, rankLabel, reputation, admitted),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // D1 — DESTAQUE PRINCIPAL: facção atual do player.
              _buildFactionCard(context, ref, factionType),
              const SizedBox(height: 12),

              // D4 — Trocar facção (sai da atual via LeaveFactionService
              // se member, ou vai direto pra seleção se sem facção).
              _buildSwitchFactionButton(context, ref, player, factionType),
              const SizedBox(height: 16),

              // Card Noryan Gray (narrativa)
              _buildNoryanCard(context, ref, admitted, status, player),
              const SizedBox(height: 16),

              // D2 — Header Aventureiro nível 1 (rank + ascensão) OU
              // fluxo de admissão (rank == none).
              if (!admitted) ...[
                _buildAdmissionCard(context, ref, player, status),
              ] else ...[
                _buildRankCard(context, status),
                const SizedBox(height: 16),
                // D3 — Missões de Guilda (placeholder elegante).
                _buildMissionsPlaceholder(),
                const SizedBox(height: 16),
                _buildGuildShopCard(context),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── D1 ────────────────────────────────────────────────────────────
  // Tema (nome/cor) por facção vive em FactionTheme (Etapa E extraiu os
  // maps que eram inline aqui, pra reuso na FactionScreen).

  Widget _buildFactionCard(
      BuildContext context, WidgetRef ref, String factionType) {
    // Sprint 3.4 Etapa F — Lobo Solitário tem card próprio (não é facção
    // real, mas mostra os bônus e linka pra ficha dedicada).
    if (FactionTheme.isLoneWolf(factionType)) {
      return _buildLoneWolfCard(context, ref);
    }

    final isPending = factionType.startsWith('pending:');
    // Usa o helper central do sweep (exclui lone_wolf/none/pending).
    final hasFaction = FactionTheme.hasRealFaction(factionType);

    if (!hasFaction) {
      return _buildNoFactionCard(context, isPending, factionType);
    }

    final name = FactionTheme.nameOf(factionType);
    final color = FactionTheme.colorOf(factionType);
    final buffAsync = ref.watch(factionBuffSnapshotProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.14), AppColors.surface],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Brasão temático
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(Icons.shield, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SUA FACÇÃO',
                        style: GoogleFonts.roboto(
                            fontSize: 9,
                            color: AppColors.textMuted,
                            letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text(name,
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 16, color: color, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Buffs ativos (reusa FactionBuffService via provider global —
          // consistente com /personagem).
          buffAsync.when(
            loading: () => const SizedBox(
                height: 18,
                child: Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.gold)))),
            error: (_, __) => const SizedBox.shrink(),
            data: (snap) => _buildFactionBuffs(snap, color),
          ),
          const SizedBox(height: 16),
          // Sprint 3.4 Etapa E — "Ver detalhes" religado: abre a ficha da
          // facção atual (/faction/<faction_type>).
          GestureDetector(
            onTap: () => context.go('/faction/$factionType'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.4)),
                color: color.withValues(alpha: 0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ver detalhes',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 11, color: color, letterSpacing: 1)),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: color, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sprint 3.4 Etapa F — card especial do Lobo Solitário (sentinel
  // faction_type='lone_wolf'). Tema void/cinza, anti-facção. Mostra os
  // bônus (+5% XP/gold/gems via FactionBuffService) e linka pra ficha.
  Widget _buildLoneWolfCard(BuildContext context, WidgetRef ref) {
    final color = FactionTheme.colorOf(FactionTheme.loneWolf);
    final buffAsync = ref.watch(factionBuffSnapshotProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.16), AppColors.surface],
        ),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(Icons.dark_mode_outlined, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SEU CAMINHO',
                        style: GoogleFonts.roboto(
                            fontSize: 9,
                            color: AppColors.textMuted,
                            letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text('Lobo Solitário',
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 16, color: color, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text('Sem lealdades. Só o caminho.',
                        style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buffAsync.when(
            loading: () => const SizedBox(
                height: 18,
                child: Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.gold)))),
            error: (_, __) => const SizedBox.shrink(),
            data: (snap) => _buildFactionBuffs(snap, color),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go('/faction/${FactionTheme.loneWolf}'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.4)),
                color: color.withValues(alpha: 0.1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ver detalhes',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 11, color: color, letterSpacing: 1)),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: color, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactionBuffs(FactionBuffSnapshot snap, Color color) {
    if (snap.applied.isEmpty) {
      return Text(
        snap.multipliers.hasDebuff
            ? 'Buffs suspensos pelo debuff de saída.'
            : 'Sem buffs ativos no momento.',
        style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textMuted),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: snap.applied
          .map((e) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(e.label,
                    style: GoogleFonts.roboto(fontSize: 10, color: color)),
              ))
          .toList(growable: false),
    );
  }

  Widget _buildNoFactionCard(
      BuildContext context, bool isPending, String factionType) {
    if (isPending) {
      final pendingId = factionType.substring('pending:'.length);
      final pendingName = FactionTheme.nameOf(pendingId);
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mp.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.hourglass_top, color: AppColors.mp, size: 20),
              const SizedBox(width: 10),
              Text('ADMISSÃO EM CURSO',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 12, color: AppColors.mp, letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 10),
            Text(
              'Você está em processo de admissão na facção $pendingName. '
              'Complete as missões de admissão para jurar lealdade.',
              style: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.go('/quests'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.mp.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.mp.withValues(alpha: 0.4)),
                  ),
                ),
                child: Text('Ver missões de admissão',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 12, color: AppColors.mp)),
              ),
            ),
          ],
        ),
      );
    }

    // Sem facção.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.flag_outlined,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Text('SEM FACÇÃO',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 10),
          Text(
            'Você ainda não jurou lealdade a nenhuma facção. Escolher um '
            'lado desbloqueia buffs permanentes e conteúdo exclusivo.',
            style: GoogleFonts.roboto(
                fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.go('/faction-selection'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
              ),
              child: Text('Escolher facção',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 12, color: AppColors.gold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── D4 ────────────────────────────────────────────────────────────
  Widget _buildSwitchFactionButton(BuildContext context, WidgetRef ref,
      dynamic player, String factionType) {
    // Sprint 3.4 Etapa F — 🔴 CRÍTICO: lone_wolf NÃO é membro real. Usa o
    // helper central pra NÃO chamar leaveFaction('lone_wolf') (que lançaria).
    // Lobo cai em isMember=false → botão só navega pra /faction-selection.
    final isMember = FactionTheme.hasRealFaction(factionType);

    return GestureDetector(
      onTap: () => _onSwitchFaction(context, ref, player, factionType, isMember),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          color: AppColors.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz,
                color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(isMember ? 'Trocar de facção' : 'Escolher facção',
                style: GoogleFonts.roboto(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _onSwitchFaction(BuildContext context, WidgetRef ref,
      dynamic player, String factionType, bool isMember) async {
    // Sem facção (ou pending) → vai direto pra seleção, sem penalidade.
    if (!isMember) {
      context.go('/faction-selection');
      return;
    }

    final name = FactionTheme.nameOf(factionType);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Sair de $name?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 15)),
        content: Text(
          'Sair custa caro:\n'
          '• -20 de reputação na facção\n'
          '• Debuff de -30% XP / -30% ouro por 48h\n'
          '• Bloqueio de 7 dias para entrar em outra facção\n\n'
          'Seu Rank de Aventureiro é preservado.',
          style: GoogleFonts.roboto(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ficar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sair da facção',
                style: GoogleFonts.roboto(color: AppColors.hp)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Conecta ao LeaveFactionService já pronto (Sub-Etapa B.2): aplica
    // debuff 48h + lock 7d + -20 rep numa transação. Não duplicamos a
    // lógica de saída aqui.
    try {
      await ref.read(leaveFactionServiceProvider).leaveFaction(
            playerId: player.id,
            factionId: factionType,
          );
    } catch (e) {
      if (context.mounted) {
        AppSnack.warning(context, 'Não foi possível sair: $e');
      }
      return;
    }

    // Refresca player + snapshot da guilda.
    final updated = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updated;
    ref.invalidate(guildStatusProvider);
    ref.invalidate(factionBuffSnapshotProvider);

    if (context.mounted) context.go('/faction-selection');
  }

  void _openAscension(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _AscensionHostScreen()),
    );
  }

  Widget _buildHeader(BuildContext context, String rankLabel,
      int reputation, bool admitted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textMuted, size: 18),
            onPressed: () => context.go('/sanctuary'),
          ),
          const SizedBox(width: 4),
          // Emblema
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.1),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GUILDA DE AVENTUREIROS',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 12,
                        color: AppColors.gold,
                        letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text(
                  admitted ? '$rankLabel · $reputation rep.' : 'Sem Rank',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoryanCard(BuildContext context, WidgetRef ref,
      bool admitted, GuildMembershipSnapshot? status, dynamic player) {
    final msg = admitted
        ? '"Bem-vindo de volta, aventureiro. A Guilda registrou sua presença."'
        : '"Você chegou até aqui. Isso já diz algo. Mas carregar o Colar exige mais do que presença."';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.1),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.person,
                color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Noryan Gray',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 12, color: AppColors.gold)),
                Text('Mestre da Guilda',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Text(msg,
                    style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdmissionCard(BuildContext context, WidgetRef ref,
      dynamic player, GuildMembershipSnapshot? status) {
    // Sprint 2.2 Bloco 6 — gate mudou de "50 ouro gasto" pra "N quests
    // concluídas". Contador vive em players.totalQuestsCompleted
    // (migration 20→21, incrementado nos 3 services de quest).
    // Jogadores v0.28.0 começam em 0 após upgrade — intencional.
    //
    // Sprint 3.4 Etapa A hotfix — gate reduzido de 25 → 15 pra
    // facilitar testes e onboarding. Decisão de balanceamento do CEO.
    //
    // Lê o contador FRESH do snapshot (servidor) — não do currentPlayer, que
    // pode estar stale. O contador volta a incrementar via QuestRewardStatsService.
    final completed =
        status?.totalQuestsCompleted ?? (player?.totalQuestsCompleted as int?) ?? 0;
    const needed = 15;
    final progress = (completed / needed).clamp(0.0, 1.0);
    final canAdmit = completed >= needed;
    final missing = (needed - completed).clamp(0, needed);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined,
                  color: AppColors.gold, size: 16),
              const SizedBox(width: 8),
              Text('TESTE DE ENTRADA',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 11,
                      color: AppColors.gold,
                      letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Para carregar o Colar da Guilda, você precisa completar $needed missões e demonstrar comprometimento com Caelum.',
            style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 16),

          // Requisito: concluir N missões
          Row(
            children: [
              Icon(
                canAdmit ? Icons.check_circle : Icons.radio_button_unchecked,
                color: canAdmit ? AppColors.shadowAscending : AppColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                  canAdmit
                      ? 'Missões completas'
                      : 'Complete $needed missões',
                  style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: canAdmit
                          ? AppColors.shadowAscending
                          : AppColors.textSecondary)),
              const Spacer(),
              Text('$completed/$needed',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor:
                  AlwaysStoppedAnimation(canAdmit
                      ? AppColors.shadowAscending
                      : AppColors.gold),
              minHeight: 4,
            ),
          ),
          if (!canAdmit) ...[
            const SizedBox(height: 8),
            Text(
              missing == 1
                  ? 'Falta 1 missão.'
                  : 'Faltam $missing missões.',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: canAdmit
                  ? () => _confirmAdmission(context, ref, player)
                  : null,
              style: TextButton.styleFrom(
                backgroundColor: canAdmit
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : AppColors.border,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: canAdmit
                          ? AppColors.gold.withValues(alpha: 0.5)
                          : Colors.transparent),
                ),
              ),
              child: Text(
                canAdmit ? 'Confirmar Admissão' : 'Requisito não atendido',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: canAdmit
                        ? AppColors.gold
                        : AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── D2 ────────────────────────────────────────────────────────────
  // Header Aventureiro nível 1: rank atual + progressão E→S + CTA pros
  // Testes de Ascensão (religa a AscensionTab, antes órfã).
  static const _rankOrder = ['e', 'd', 'c', 'b', 'a', 's'];

  Widget _buildRankCard(BuildContext context, GuildMembershipSnapshot status) {
    final rankLower = status.guildRank.toLowerCase();
    final rank = rankLower.toUpperCase();
    final idx = _rankOrder.indexOf(rankLower);
    final isMax = idx == _rankOrder.length - 1;
    final nextRank = (idx >= 0 && !isMax)
        ? _rankOrder[idx + 1].toUpperCase()
        : null;
    // Progressão visual E→S (idx 0..5).
    final progress = idx >= 0 ? (idx / (_rankOrder.length - 1)) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(rank,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 18, color: AppColors.gold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aventureiro Rank $rank',
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 13, color: AppColors.gold)),
                    const SizedBox(height: 4),
                    Text('${status.reputation} reputação',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progressão E → S
          Row(
            children: [
              Text('E',
                  style: GoogleFonts.roboto(
                      fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.border,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.gold),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('S',
                  style: GoogleFonts.roboto(
                      fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 14),
          // CTA Testes de Ascensão (ou estado de topo).
          if (isMax)
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 8),
                Text('Rank máximo atingido — Lenda de Caelum.',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _openAscension(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_circle_up,
                        color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Text(
                        nextRank != null
                            ? 'Testes de Ascensão — Rank $nextRank'
                            : 'Testes de Ascensão',
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 11,
                            color: AppColors.gold,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── D3 ────────────────────────────────────────────────────────────
  // Missões de Guilda — estado vazio elegante. NÃO implementa lógica
  // (sprint futura, dívida D18).
  Widget _buildMissionsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.map_outlined,
                color: AppColors.textMuted, size: 22),
          ),
          const SizedBox(height: 12),
          Text('Missões de Guilda',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('Missões de Guilda chegam em breve.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // Sprint 2.2 Bloco 7 — substitui placeholder "Em breve" por atalho funcional.
  // Visível só quando admitted=true (verificado no call-site via admitted flag).
  Widget _buildGuildShopCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shop/guild_shop'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.1),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.storefront,
                  color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LOJA DA GUILDA',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 12,
                          color: AppColors.gold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text('Mercadoria exclusiva pros aventureiros oficiais.',
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.gold, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAdmission(
      BuildContext context, WidgetRef ref, dynamic player) async {
    final client = ref.read(supabaseClientProvider);
    final invService = ref.read(playerInventoryServiceProvider);
    final eqService = ref.read(playerEquipmentServiceProvider);
    final rankService = ref.read(playerRankServiceProvider);

    // Idempotência defensiva — ninguém recebe Colar duas vezes.
    final current = await invService.listOf(player.id);
    final alreadyHasCollar =
        current.any((e) => e.spec.key == 'COLLAR_GUILD');
    if (alreadyHasCollar) {
      if (context.mounted) {
        NpcDialogOverlay.show(
          context,
          npcName: 'Noryan Gray',
          npcTitle: 'Mestre da Guilda',
          message: 'Você já é membro. O Colar continua em você.',
        );
      }
      return;
    }

    // Época 2 full-online (ADR-0024) — registra membership na tabela nova
    // (factionId='guild') via PostgREST em vez do INSERT/UPDATE Drift crus.
    // PK composta (player_id, faction_id) → upsert idempotente. O guard
    // `alreadyHasCollar` acima já barra membros existentes, então setar
    // joined_at aqui equivale a promover o registro pendente.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await client.from('player_faction_membership').upsert(
      {
        'player_id': player.id,
        'faction_id': 'guild',
        'joined_at': nowMs,
      },
      onConflict: 'player_id,faction_id',
    );

    // Rank canônico em players.guildRank (normalizado 'E') via service novo.
    await rankService.setRank(player.id, GuildRank.e);

    // Entrega o Colar via sistema novo (ADR 0008 + 0009).
    final inventoryId = await invService.addItem(
      playerId:     player.id,
      itemKey:      'COLLAR_GUILD',
      quantity:     1,
      acquiredVia:  SourceType.questReward,
      evolutionStage: 'stage_E',
    );
    if (inventoryId > 0) {
      final snapshot = PlayerSnapshot(
        level:      player.level,
        rank:       GuildRank.e,
        classKey:   player.classType,
        factionKey: player.factionType,
      );
      await eqService.equip(
        playerId:    player.id,
        inventoryId: inventoryId,
        player:      snapshot,
      );
    }

    // Atualiza providers.
    final updatedPlayer = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updatedPlayer;
    ref.invalidate(guildStatusProvider);

    if (context.mounted) {
      RewardToast.show(
        context,
        source: 'Admissão na Guilda de Aventureiros',
        xp: 200,
        gold: 0,
        gems: 1,
        achievementTitle: 'Colar da Guilda recebido',
      );
      await Future.delayed(const Duration(milliseconds: 400));
      if (context.mounted) {
        NpcDialogOverlay.show(
          context,
          npcName: 'Noryan Gray',
          npcTitle: 'Mestre da Guilda',
          message:
              'Você agora carrega o Colar da Guilda. Não é enfeite — é responsabilidade. Seu Rank é E. Missões da Guilda e Testes de Ascensão definirão até onde você chega.',
        );
      }
    }
  }

  String _rankLabel(String rank) => switch (rank) {
        'e' => 'Rank E',
        'd' => 'Rank D',
        'c' => 'Rank C',
        'b' => 'Rank B',
        'a' => 'Rank A',
        's' => 'Rank S',
        _ => 'Sem Rank',
      };
}

/// Sprint 3.4 Etapa D — host navegável da `AscensionTab` (até então órfã).
/// Acessado via "Testes de Ascensão" no header Aventureiro de /guild.
/// `AscensionTab` é um ListView; embutir num ListView do hub causaria
/// conflito de scroll, então abre como tela própria via Navigator.push.
class _AscensionHostScreen extends StatelessWidget {
  const _AscensionHostScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.gold),
        title: Text('TESTES DE ASCENSÃO',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 13, color: AppColors.gold, letterSpacing: 2)),
      ),
      body: const SafeArea(child: AscensionTab()),
    );
  }
}
