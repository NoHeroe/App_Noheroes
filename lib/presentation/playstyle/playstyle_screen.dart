import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' hide Column;
import '../../app/providers.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/tables/players_table.dart';
import '../../data/database/daos/player_dao.dart';
import '../shared/widgets/milestone_popup.dart';

const _styles = [
  {
    'id': 'solo',
    'label': 'Solo',
    'icon': Icons.person,
    'description': 'Você caminha sozinho. Missões individuais rendem +15% XP. Sem bônus de party.',
    'color': 0xFF8B3DFF,
  },
  {
    'id': 'duo',
    'label': 'Duo',
    'icon': Icons.people,
    'description': 'Um parceiro de jornada. Missões em dupla rendem bônus de 20% XP e ouro para ambos.',
    'color': 0xFF3070B3,
  },
  {
    'id': 'team',
    'label': 'Team',
    'icon': Icons.groups,
    'description': 'Força coletiva. Parties de 3-5 rendem bônus progressivo. Missões exclusivas desbloqueadas.',
    'color': 0xFF4FA06B,
  },
];

class PlaystyleScreen extends ConsumerWidget {
  const PlaystyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final current = player?.playStyle ?? 'none';

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                children: [
                  Text('ESTILO DE JOGO',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 18, color: AppColors.gold, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text('Nível 15 — Escolha como você joga em Caelum.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _styles.map((s) {
                  final id = s['id'] as String;
                  final color = Color(s['color'] as int);
                  final selected = current == id;
                  return GestureDetector(
                    onTap: () => _select(context, ref, id, color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? color.withValues(alpha: 0.6)
                              : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.12),
                              border: Border.all(color: color.withValues(alpha: 0.4)),
                            ),
                            child: Icon(s['icon'] as IconData,
                                color: color, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(s['label'] as String,
                                      style: GoogleFonts.cinzelDecorative(
                                          fontSize: 14, color: color)),
                                  if (selected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: color.withValues(alpha: 0.4)),
                                      ),
                                      child: Text('Ativo',
                                          style: GoogleFonts.roboto(
                                              fontSize: 9, color: color)),
                                    ),
                                  ],
                                ]),
                                const SizedBox(height: 4),
                                Text(s['description'] as String,
                                    style: GoogleFonts.roboto(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (current != 'none')
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: TextButton(
                  onPressed: () => context.go('/sanctuary'),
                  child: Text('Continuar',
                      style: GoogleFonts.roboto(
                          fontSize: 13, color: AppColors.textMuted)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, WidgetRef ref,
      String styleId, Color color) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .write(PlayersTableCompanion(playStyle: Value(styleId)));
    final updated = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updated;

    if (context.mounted) {
      final label = styleId == 'solo'
          ? 'Solo'
          : styleId == 'duo'
              ? 'Duo'
              : 'Team';
      MilestonePopup.show(
        context,
        title: 'Estilo $label',
        subtitle: 'Caminho definido',
        message: styleId == 'solo'
            ? 'Você escolheu caminhar sozinho. Missões individuais rendem mais. A solidão tem seu preço — e sua recompensa.'
            : styleId == 'duo'
                ? 'Dois caminhos, uma jornada. Encontre seu parceiro e os bônus de dupla serão automáticos.'
                : 'Você joga em equipe. Parties formadas rendem mais para todos. Caelum reconhece força coletiva.',
        icon: styleId == 'solo'
            ? Icons.person
            : styleId == 'duo'
                ? Icons.people
                : Icons.groups,
        color: color,
        onDismiss: () => context.go('/sanctuary'),
      );
    }
  }
}
