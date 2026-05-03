import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../domain/enums/source_type.dart';
import '../../../domain/models/player_snapshot.dart';
import 'package:drift/drift.dart' hide Column;
import '../../shared/widgets/npc_dialog_overlay.dart';
import '../../shared/widgets/reward_toast.dart';

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

  const GuildMembershipSnapshot({
    required this.admitted,
    required this.guildRank,
    required this.reputation,
    this.joinedAt,
  });
}

final guildStatusProvider =
    FutureProvider.autoDispose<GuildMembershipSnapshot?>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return null;
  final db = ref.read(appDatabaseProvider);

  // Membership row pra factionId='guild' (lazy: pode não existir ainda).
  final memRows = await db.customSelect(
    "SELECT joined_at FROM player_faction_membership "
    "WHERE player_id = ? AND faction_id = 'guild' "
    "LIMIT 1",
    variables: [Variable.withInt(player.id)],
  ).get();
  DateTime? joinedAt;
  if (memRows.isNotEmpty) {
    final raw = memRows.first.data['joined_at'];
    if (raw is int) joinedAt = DateTime.fromMillisecondsSinceEpoch(raw);
  }

  // Reputação pra factionId='guild' (lazy default 50 se não existe).
  final repRows = await db.customSelect(
    "SELECT reputation FROM player_faction_reputation "
    "WHERE player_id = ? AND faction_id = 'guild' "
    "LIMIT 1",
    variables: [Variable.withInt(player.id)],
  ).get();
  final reputation = repRows.isNotEmpty
      ? repRows.first.read<int>('reputation')
      : 50;

  return GuildMembershipSnapshot(
    admitted: player.guildRank != 'none',
    guildRank: player.guildRank,
    reputation: reputation,
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

    return Column(
      children: [
        _buildHeader(context, rankLabel, reputation, admitted),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Card Noryan Gray
              _buildNoryanCard(context, ref, admitted, status, player),
              const SizedBox(height: 16),

              if (!admitted) ...[
                _buildAdmissionCard(context, ref, player, status),
              ] else ...[
                _buildRankCard(status!),
                const SizedBox(height: 16),
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
    // Sprint 2.2 Bloco 6 — gate mudou de "50 ouro gasto" pra "25 quests
    // concluídas". Contador vive em players.totalQuestsCompleted (migration
    // 20→21, incrementado nos 3 services de quest). Jogadores v0.28.0
    // começam em 0 após upgrade — intencional, não retroage.
    final completed = (player?.totalQuestsCompleted as int?) ?? 0;
    const needed = 25;
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
            'Para carregar o Colar da Guilda, você precisa completar 25 missões e demonstrar comprometimento com Caelum.',
            style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 16),

          // Requisito: concluir 25 missões
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
                      : 'Complete ${needed} missões',
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

  Widget _buildRankCard(GuildMembershipSnapshot status) {
    final rank = status.guildRank.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.15),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(rank,
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 18, color: AppColors.gold)),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rank ${rank} da Guilda',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 13, color: AppColors.gold)),
              const SizedBox(height: 4),
              Text(
                'Rank ${rank} · ${status.reputation} reputação',
                style: GoogleFonts.roboto(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined,
              color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Missões da Guilda',
                  style: GoogleFonts.roboto(
                      fontSize: 13, color: AppColors.textPrimary)),
              Text('Em breve — Sprint 3',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // Sprint 2.2 Bloco 7 — substitui placeholder "Em breve" por atalho funcional.
  // Visível só quando admitted=true (verificado no call-site via admitted flag).
  Widget _buildGuildShopCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/shop/guild_shop'),
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
    final db = ref.read(appDatabaseProvider);
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

    // Sprint 3.4 Etapa A — registra membership na tabela nova
    // (factionId='guild'). Substitui o `dao.completeAdmission` legacy
    // que escrevia em `guild_status` (DROPPED). `INSERT OR IGNORE`
    // mantém idempotência caso a row já exista.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      'INSERT OR IGNORE INTO player_faction_membership '
      '(player_id, faction_id, joined_at, left_at, locked_until, '
      ' debuff_until, admission_attempts) '
      'VALUES (?, ?, ?, NULL, NULL, NULL, 0)',
      [player.id, 'guild', nowMs],
    );
    // Caso já exista mas com joined_at NULL (pendente), promove agora.
    await db.customStatement(
      'UPDATE player_faction_membership SET joined_at = ? '
      "WHERE player_id = ? AND faction_id = 'guild' "
      'AND joined_at IS NULL',
      [nowMs, player.id],
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
