import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/guild_rank.dart';

class SanctuaryDrawer extends ConsumerWidget {
  const SanctuaryDrawer({super.key});

  // Rótulo legível da classe
  String _classLabel(String? classType) => switch (classType) {
        'warrior'      => 'Guerreiro',
        'colossus'     => 'Colosso',
        'monk'         => 'Monge',
        'rogue'        => 'Ladino',
        'hunter'       => 'Caçador',
        'druid'        => 'Druida',
        'mage'         => 'Mago',
        'shadowWeaver' => 'Tecelão de Sombras',
        _              => 'Sem Classe',
      };

  // Rótulo legível da facção
  String _factionLabel(String? factionType) {
    if (factionType == null || factionType.isEmpty) return 'Sem Facção';
    if (factionType.startsWith('pending:')) return 'Admissão Pendente';
    return switch (factionType) {
      'moon_clan'   => 'Clã da Lua',
      'sun_clan'    => 'Clã do Sol',
      'black_legion'=> 'Legião Negra',
      'new_order'   => 'Nova Ordem',
      'trinity'     => 'Trindade',
      'renegades'   => 'Renegados',
      'guild'       => 'Guilda',
      _             => factionType,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    final rawRank = player?.guildRank ?? 'none';
    final hasRank = rawRank != 'none';
    final guildRank = hasRank ? GuildRankSystem.fromString(rawRank) : null;
    final rankLabel = hasRank ? GuildRankSystem.label(guildRank!).toUpperCase() : 'SEM RANK';

    final items = [
      _Item('Inventário',    Icons.inventory_2_outlined,  '/inventory'),
      _Item('Mercado',       Icons.store_outlined,         '/shop'),
      _Item('Conquistas',    Icons.emoji_events_outlined,  '/achievements'),
      _Item('Reputação',     Icons.people_outline,          '/reputation'),
      // Sprint 3.1 Bloco 14.6c — Histórico virou rota dedicada.
      _Item('Histórico',     Icons.history,                '/history'),
      // Sprint 3.2 Etapa 1.0 — Perfil (dados físicos + IMC + recomendações).
      _Item('Perfil',        Icons.person_outline,         '/perfil'),
      _Item('Amigos',        Icons.group_outlined,         null),
      _Item('Meus Produtos', Icons.book_outlined,          null),
      _Item('Configurações', Icons.settings_outlined,      null),
    ];

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header do jogador
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + Badge de Rank
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.purple),
                          color: AppColors.shadowVoid,
                        ),
                        child: const Icon(Icons.blur_circular,
                            color: AppColors.purple, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge do Rank
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasRank
                                  ? AppColors.gold.withValues(alpha: 0.15)
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: hasRank
                                      ? AppColors.gold.withValues(alpha: 0.5)
                                      : AppColors.border),
                            ),
                            child: Text(
                              rankLabel,
                              style: GoogleFonts.cinzelDecorative(
                                  fontSize: 9,
                                  color: hasRank ? AppColors.gold : AppColors.textMuted,
                                  letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nível ${player?.level ?? 1}',
                            style: GoogleFonts.roboto(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Nome da sombra
                  Text(
                    player?.shadowName ?? 'Sombra',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 17, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  // Classe · Facção
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.auto_fix_high_outlined,
                        label: _classLabel(player?.classType),
                        color: AppColors.purple,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.shield_outlined,
                        label: _factionLabel(player?.factionType),
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player?.email ?? '',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            // Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ...items.map((item) => ListTile(
                        leading: Icon(item.icon,
                            color: AppColors.textSecondary, size: 20),
                        title: Text(item.label,
                            style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: AppColors.textPrimary)),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.textMuted, size: 18),
                        onTap: item.route != null
                            ? () {
                                Navigator.pop(context);
                                context.go(item.route!);
                              }
                            : null,
                      )),
                  // Sprint 3.1 Bloco 10a.2 — item "Refazer Calibração"
                  // condicional. Oculto se canRecalibrate=false (lvl<10
                  // OU nunca calibrou). Ver MissionPreferencesService.
                  if (player != null)
                    _RecalibrateTile(
                        playerId: player.id, playerLevel: player.level),
                ],
              ),
            ),

            // Botão sair
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ListTile(
                leading:
                    const Icon(Icons.logout, color: AppColors.hp, size: 20),
                title: Text('Sair',
                    style: GoogleFonts.roboto(
                        fontSize: 14, color: AppColors.hp)),
                onTap: () => _logout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Sair de Caelum?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 16)),
        content: Text('Sua sombra permanecerá aguardando.',
            style: GoogleFonts.roboto(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ficar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authDsProvider).logout();
              ref.read(currentPlayerProvider.notifier).state = null;
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.go('/login');
              }
            },
            child: Text('Sair',
                style: GoogleFonts.roboto(color: AppColors.hp)),
          ),
        ],
      ),
    );
  }
}

class _Item {
  final String label;
  final IconData icon;
  final String? route;
  _Item(this.label, this.icon, this.route);
}

/// Sprint 3.1 Bloco 10a.2 — item "Refazer Calibração" no SanctuaryDrawer.
///
/// Consome `canRecalibrateProvider` (FutureProvider.family) declarado no
/// Bloco 10a.1. Gate hard (DESIGN_DOC §7):
///
///   - `playerLevel >= 10` E já tem prefs → renderiza item
///   - Qualquer outra combinação (lvl < 10, nunca calibrou, erro, loading)
///     → `SizedBox.shrink` (item **oculto**, não desabilitado)
///
/// Navega pra `/mission_calibration?recalibrate=true`. A tela (Bloco 10b)
/// lê o query param pra aplicar o fluxo de refazer (cobra via
/// `chargeRecalibration` baseado em `updatesCount`).
class _RecalibrateTile extends ConsumerWidget {
  final int playerId;
  final int playerLevel;
  const _RecalibrateTile({required this.playerId, required this.playerLevel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGate = ref.watch(canRecalibrateProvider(
      (playerId: playerId, playerLevel: playerLevel),
    ));
    return asyncGate.when(
      data: (canRecalibrate) {
        if (!canRecalibrate) return const SizedBox.shrink();
        return ListTile(
          key: const ValueKey('drawer-recalibrate'),
          leading: const Icon(Icons.psychology_outlined,
              color: AppColors.textSecondary, size: 20),
          title: Text(
            'Refazer Calibração',
            style: GoogleFonts.roboto(
                fontSize: 14, color: AppColors.textPrimary),
          ),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
          onTap: () {
            Navigator.pop(context);
            context.go('/mission_calibration?recalibrate=true');
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
                fontSize: 10,
                color: color.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}
