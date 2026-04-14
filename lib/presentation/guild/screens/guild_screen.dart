import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/daos/guild_dao.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables/items_table.dart';
import '../../../data/database/tables/inventory_table.dart';
import 'package:drift/drift.dart' hide Column;
import '../../shared/widgets/npc_dialog_overlay.dart';
import '../../shared/widgets/reward_toast.dart';

// Provider do status da guilda
final guildStatusProvider = FutureProvider.autoDispose<GuildStatusTableData?>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return null;
  final db = ref.read(appDatabaseProvider);
  final dao = GuildDao(db);
  await dao.ensureExists(player.id);
  return dao.getStatus(player.id);
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
      dynamic player, GuildStatusTableData? status) {
    final admitted = status != null && status.guildRank != 'none';
    final rankLabel = _rankLabel(status?.guildRank ?? 'none');
    final reputation = status?.guildReputation ?? 0;

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
                _buildShopPlaceholder(),
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
            onPressed: () => Navigator.of(context).pop(),
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
      bool admitted, GuildStatusTableData? status, dynamic player) {
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
      dynamic player, GuildStatusTableData? status) {
    final spent = status?.totalGoldSpent ?? 0;
    final needed = 50;
    final progress = (spent / needed).clamp(0.0, 1.0);
    final canAdmit = spent >= needed;

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
            'Para carregar o Colar da Guilda, você precisa demonstrar comprometimento com Caelum.',
            style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 16),

          // Requisito: gastar 50 ouro
          Row(
            children: [
              Icon(
                canAdmit ? Icons.check_circle : Icons.radio_button_unchecked,
                color: canAdmit ? AppColors.shadowAscending : AppColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text('Gaste 50 de ouro na loja',
                  style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: canAdmit
                          ? AppColors.shadowAscending
                          : AppColors.textSecondary)),
              const Spacer(),
              Text('$spent/50',
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

  Widget _buildRankCard(GuildStatusTableData status) {
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
                'Colar Nível ${status.collarLevel} · ${status.guildReputation} reputação',
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

  Widget _buildShopPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_outlined,
              color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Loja da Guilda',
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

  Future<void> _confirmAdmission(
      BuildContext context, WidgetRef ref, dynamic player) async {
    final db = ref.read(appDatabaseProvider);
    final dao = GuildDao(db);
    await dao.completeAdmission(player.id);

    // Entrega Colar da Guilda no inventário
    // (item com nome fixo, não vendável — inserido direto)
    try {
      final itemId = await db.into(db.itemsTable).insert(
        ItemsTableCompanion(
          name: const Value('Colar da Guilda'),
          description: const Value(
              'O símbolo universal do aventureiro. Não pode ser vendido. Evolui com seu Rank.'),
          type: const Value('accessory'),
          rarity: const Value('unique'),
          slot: const Value('accessory'),
          goldValue: const Value(0),
          iconName: const Value('collar'),
        ),
      );
      await db.into(db.inventoryTable).insert(
        InventoryTableCompanion(
          playerId: Value(player.id),
          itemId: Value(itemId),
          quantity: const Value(1),
        ),
      );
    } catch (_) {}

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
