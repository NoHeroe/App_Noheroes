import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/faction_theme.dart';
import '../../../data/datasources/local/class_bonus_service.dart';
import '../../shared/widgets/app_snack.dart';

/// Sprint 3.4 Etapa E — ficha da facção ATUAL do player (`/faction/<id>`).
///
/// NÃO é catálogo: mostra só a facção que o player é membro (id da rota ==
/// `players.faction_type`). Conteúdo: lore (factions.json) + buffs
/// detalhados (catálogo via FactionBuffService) + reputação (0-100) +
/// loja (placeholder até Etapa H) + sair (LeaveFactionService).
///
/// Acessada pelo "Ver detalhes" do card de facção no `/guild` (Etapa D).

/// Lore da facção lida de `assets/data/factions.json` (subtitle/philosophy/
/// description/leader). Family por id.
final _factionLoreProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, factionId) async {
  final raw = await rootBundle.loadString('assets/data/factions.json');
  final data = json.decode(raw) as Map<String, dynamic>;
  final all = (data['factions'] as List).cast<Map<String, dynamic>>();
  for (final f in all) {
    if (f['id'] == factionId) return f;
  }
  return null;
});

/// Buffs do catálogo da facção (todos: applied + pending), independente do
/// player. Reusa `FactionBuffService.previewLabelsForFaction` (Etapa C).
final _factionBuffPreviewProvider = FutureProvider.autoDispose
    .family<({List<String> applied, List<String> pending}), String>(
        (ref, factionId) async {
  return ref.read(factionBuffServiceProvider).previewLabelsForFaction(factionId);
});

/// Reputação atual do player na facção (0-100, default 50).
final _factionReputationProvider =
    FutureProvider.autoDispose.family<int, String>((ref, factionId) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return 50;
  return ref.read(factionReputationServiceProvider).current(player.id, factionId);
});

class FactionScreen extends ConsumerWidget {
  final String factionId;
  const FactionScreen({super.key, required this.factionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final currentFaction = player?.factionType ?? 'none';

    // Sprint 3.4 Etapa F — ficha dedicada do Lobo Solitário.
    final isLoneWolf = FactionTheme.isLoneWolf(factionId) &&
        FactionTheme.isLoneWolf(currentFaction);
    final isMember =
        FactionTheme.hasRealFaction(factionId) && currentFaction == factionId;

    final color = FactionTheme.colorOf(factionId);
    final name = FactionTheme.nameOf(factionId);

    final headerTitle = isLoneWolf ? name : (isMember ? name : 'FACÇÃO');
    final headerColor = (isLoneWolf || isMember) ? color : AppColors.gold;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, headerTitle, headerColor),
            Expanded(
              child: isLoneWolf
                  ? _buildLoneWolfView(context, ref, color)
                  : isMember
                      ? _buildMemberView(context, ref, color, name)
                      : _buildNonMemberView(context, currentFaction),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppColors.textMuted, size: 18),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/guild'),
          ),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 14, color: color, letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── E2 — estado COM facção ─────────────────────────────────────────
  Widget _buildMemberView(
      BuildContext context, WidgetRef ref, Color color, String name) {
    final loreAsync = ref.watch(_factionLoreProvider(factionId));
    final buffAsync = ref.watch(_factionBuffPreviewProvider(factionId));
    final repAsync = ref.watch(_factionReputationProvider(factionId));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildBanner(color, name, loreAsync.value),
        const SizedBox(height: 16),
        _buildLoreSection(loreAsync, color),
        const SizedBox(height: 16),
        _buildBuffsSection(buffAsync, color),
        const SizedBox(height: 16),
        _buildReputationSection(repAsync, color),
        const SizedBox(height: 16),
        _buildShopButton(context, color),
        const SizedBox(height: 12),
        _buildLeaveButton(context, ref, name),
      ],
    );
  }

  Widget _buildBanner(Color color, String name, Map<String, dynamic>? lore) {
    final subtitle = lore?['subtitle'] as String?;
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
              color: color.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(Icons.shield, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 17, color: color, letterSpacing: 1)),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5)),
                ],
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text('MEMBRO',
                      style: GoogleFonts.roboto(
                          fontSize: 9, color: color, letterSpacing: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoreSection(
      AsyncValue<Map<String, dynamic>?> loreAsync, Color color) {
    return _section(
      title: 'LORE',
      color: color,
      child: loreAsync.when(
        loading: () => const _SectionLoading(),
        error: (_, __) => Text('Lore indisponível.',
            style: GoogleFonts.roboto(
                fontSize: 11, color: AppColors.textMuted)),
        data: (lore) {
          if (lore == null) {
            return Text('Lore indisponível.',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: AppColors.textMuted));
          }
          final philosophy = lore['philosophy'] as String?;
          final description = lore['description'] as String?;
          final leader = lore['leader'] as String?;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (philosophy != null && philosophy.isNotEmpty) ...[
                Text('"$philosophy"',
                    style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: color,
                        fontStyle: FontStyle.italic,
                        height: 1.5)),
                const SizedBox(height: 10),
              ],
              if (description != null && description.isNotEmpty)
                Text(description,
                    style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.6)),
              if (leader != null && leader.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.account_balance,
                        color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Liderança: $leader',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildBuffsSection(
      AsyncValue<({List<String> applied, List<String> pending})> buffAsync,
      Color color) {
    return _section(
      title: 'BUFFS DA FACÇÃO',
      color: color,
      child: buffAsync.when(
        loading: () => const _SectionLoading(),
        error: (_, __) => Text('Buffs indisponíveis.',
            style: GoogleFonts.roboto(
                fontSize: 11, color: AppColors.textMuted)),
        data: (buffs) {
          if (buffs.applied.isEmpty && buffs.pending.isEmpty) {
            return Text('Esta facção ainda não tem buffs catalogados.',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: AppColors.textMuted));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (buffs.applied.isNotEmpty) ...[
                Text('ATIVOS',
                    style: GoogleFonts.roboto(
                        fontSize: 9,
                        color: AppColors.shadowAscending,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: buffs.applied
                      .map((b) => _buffChip(b, color, active: true))
                      .toList(growable: false),
                ),
              ],
              if (buffs.pending.isNotEmpty) ...[
                if (buffs.applied.isNotEmpty) const SizedBox(height: 14),
                Text('EM BREVE',
                    style: GoogleFonts.roboto(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: buffs.pending
                      .map((b) => _buffChip(b, color, active: false))
                      .toList(growable: false),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buffChip(String label, Color color, {required bool active}) {
    final c = active ? AppColors.shadowAscending : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(active ? label : '$label · em breve',
          style: GoogleFonts.roboto(fontSize: 10, color: c)),
    );
  }

  Widget _buildReputationSection(AsyncValue<int> repAsync, Color color) {
    return _section(
      title: 'REPUTAÇÃO',
      color: color,
      child: repAsync.when(
        loading: () => const _SectionLoading(),
        error: (_, __) => Text('Reputação indisponível.',
            style: GoogleFonts.roboto(
                fontSize: 11, color: AppColors.textMuted)),
        data: (rep) {
          final pct = (rep / 100).clamp(0.0, 1.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reputação atual',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text('$rep / 100',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 14, color: color)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Sprint 3.4 Etapa H — botão religado: abre a loja da facção
  // (/shop/faction_shop_<id>), comprável em Insígnias. Convenção de key
  // espelha shops.json (faction_shop_<factionId>).
  Widget _buildShopButton(BuildContext context, Color color) {
    return GestureDetector(
      onTap: () => context.push('/shop/faction_shop_$factionId'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          color: color.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, color: color, size: 16),
            const SizedBox(width: 8),
            Text('Loja da facção',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 12, color: color, letterSpacing: 1)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveButton(BuildContext context, WidgetRef ref, String name) {
    return GestureDetector(
      onTap: () => _onLeave(context, ref, name),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hp.withValues(alpha: 0.4)),
          color: AppColors.hp.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: AppColors.hp, size: 16),
            const SizedBox(width: 8),
            Text('Sair da facção',
                style: GoogleFonts.roboto(fontSize: 12, color: AppColors.hp)),
          ],
        ),
      ),
    );
  }

  // Reusa o padrão da Etapa D (`_onSwitchFaction`): dialog → LeaveFactionService
  // (já pronto, Sub-Etapa B.2) → /faction-selection. Não cria lógica de saída.
  Future<void> _onLeave(
      BuildContext context, WidgetRef ref, String name) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

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

    try {
      await ref.read(leaveFactionServiceProvider).leaveFaction(
            playerId: player.id,
            factionId: factionId,
          );
    } catch (e) {
      if (context.mounted) {
        AppSnack.warning(context, 'Não foi possível sair: $e');
      }
      return;
    }

    final updated = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updated;
    ref.invalidate(factionBuffSnapshotProvider);

    if (context.mounted) context.go('/faction-selection');
  }

  // ── F (Etapa F) — ficha dedicada do Lobo Solitário ─────────────────
  // Sem reputação, sem loja. Lore + 3 bônus + abandonar caminho.
  Widget _buildLoneWolfView(BuildContext context, WidgetRef ref, Color color) {
    final buffAsync =
        ref.watch(_factionBuffPreviewProvider(FactionTheme.loneWolf));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Banner void.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.18), AppColors.surface],
            ),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 18,
                  spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(Icons.dark_mode_outlined, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lobo Solitário',
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 17, color: color, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('Sem lealdades. Só o caminho.',
                        style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text('CAMINHO',
                          style: GoogleFonts.roboto(
                              fontSize: 9, color: color, letterSpacing: 1.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // LORE (texto próprio — não há entry em factions.json).
        _section(
          title: 'O CAMINHO',
          color: color,
          child: Text(
            'Você escolheu trilhar sozinho.\n\n'
            'Solidão escolhida não é solidão — é nitidez. O Vazio respeita '
            'quem não pede companhia pra atravessar. Sem facção, sem buffs '
            'de atributo do coletivo — mas cada passo rende mais por ser seu.',
            style: GoogleFonts.roboto(
                fontSize: 12, color: AppColors.textSecondary, height: 1.6),
          ),
        ),
        const SizedBox(height: 16),
        // BUFFS (reusa a seção; lê o entry lone_wolf do catálogo).
        _buildBuffsSection(buffAsync, color),
        const SizedBox(height: 16),
        // Abandonar — volta pra 'none' e abre a seleção (sem penalidade:
        // Lobo não é facção, então não passa pelo LeaveFactionService).
        GestureDetector(
          onTap: () => _onAbandonLoneWolf(context, ref),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hp.withValues(alpha: 0.4)),
              color: AppColors.hp.withValues(alpha: 0.06),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: AppColors.hp, size: 16),
                const SizedBox(width: 8),
                Text('Abandonar caminho do Lobo',
                    style:
                        GoogleFonts.roboto(fontSize: 12, color: AppColors.hp)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onAbandonLoneWolf(BuildContext context, WidgetRef ref) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Abandonar o caminho do Lobo?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 15)),
        content: Text(
          'Você volta a ficar sem caminho definido e pode escolher uma '
          'facção. O bônus de Lobo Solitário (+5% XP/ouro/gemas) é perdido '
          'enquanto não for Lobo de novo.',
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
            child: Text('Abandonar',
                style: GoogleFonts.roboto(color: AppColors.hp)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ClassBonusService(ref.read(supabaseClientProvider))
        .applyFactionChoice(player.id, 'none');
    final updated = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updated;
    ref.invalidate(factionBuffSnapshotProvider);

    if (context.mounted) context.go('/faction-selection');
  }

  // ── E3 — estado SEM facção (fallback defensivo) ────────────────────
  Widget _buildNonMemberView(BuildContext context, String currentFaction) {
    // Player é membro de OUTRA facção (navegação inconsistente) → aponta
    // pra ficha da facção real dele. Caso normal aqui é faction_type='none'.
    final inOther = FactionTheme.isReal(currentFaction);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(inOther ? Icons.swap_horiz : Icons.flag_outlined,
                  color: AppColors.textMuted, size: 40),
              const SizedBox(height: 14),
              Text(inOther ? 'NÃO É MEMBRO' : 'SEM FACÇÃO',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      letterSpacing: 2)),
              const SizedBox(height: 10),
              Text(
                inOther
                    ? 'Você não é membro desta facção. Veja a ficha da sua facção atual.'
                    : 'Você ainda não jurou lealdade a nenhuma facção. Escolher um lado desbloqueia buffs permanentes e conteúdo exclusivo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => inOther
                      ? context.go('/faction/$currentFaction')
                      : context.go('/faction-selection'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side:
                          BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                  ),
                  child: Text(
                      inOther ? 'Ir para minha facção' : 'Escolher facção',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 12, color: AppColors.gold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Card de seção padrão (título + conteúdo) — estética consistente com /guild.
  Widget _section({
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11, color: color, letterSpacing: 2)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 18,
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.gold),
        ),
      ),
    );
  }
}
