import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../shared/widgets/nh_bottom_nav.dart';

class CharacterScreen extends ConsumerWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text('PERSONAGEM',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 16,
                              color: AppColors.gold,
                              letterSpacing: 2)),
                      const Spacer(),
                      if ((player?.attributePoints ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.gold.withOpacity(0.5)),
                          ),
                          child: Text(
                            '+${player!.attributePoints} pts disponíveis',
                            style: GoogleFonts.cinzelDecorative(
                                fontSize: 10, color: AppColors.gold),
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    child: Column(
                      children: [
                        // Avatar fullscreen
                        _buildAvatarFull(context),
                        const SizedBox(height: 12),

                        // Classe + Facção
                        _buildClassFaction(player),
                        const SizedBox(height: 12),

                        // Atributos + distribuição
                        _buildAttributes(context, ref, player),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: NhBottomNav(currentIndex: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFull(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    // Layout dos slots — ordem: Capacete, Peitoral, Calças | Botas, Luvas, Ombreiras
    final leftSlots = [
      ('Capacete', Icons.security),
      ('Peitoral', Icons.shield),
      ('Calças', Icons.accessibility),
    ];
    final rightSlots = [
      ('Botas', Icons.hiking),
      ('Luvas', Icons.back_hand_outlined),
      ('Ombreiras', Icons.accessibility_new),
    ];
    final bottomSlots = [
      ('Arma', Icons.gavel),
      ('Relíquia', Icons.auto_awesome),
      ('Acessório', Icons.circle_outlined),
    ];

    return Container(
      height: screenH * 0.52,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        gradient: RadialGradient(colors: [
          AppColors.purple.withOpacity(0.12),
          AppColors.surface,
        ]),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Slots esquerda
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: leftSlots
                      .map((s) => _slot(s.$1, s.$2))
                      .toList(),
                ),

                // Avatar central
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.purple.withOpacity(0.4)),
                            gradient: RadialGradient(colors: [
                              AppColors.purple.withOpacity(0.2),
                              AppColors.shadowVoid,
                            ]),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow
                              Container(
                                width: 100, height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.purple.withOpacity(0.4),
                                      blurRadius: 40,
                                      spreadRadius: 15,
                                    ),
                                  ],
                                ),
                              ),
                              // Silhueta
                              const Icon(Icons.blur_circular,
                                  color: AppColors.purple, size: 90),
                              // Label
                              const Positioned(
                                bottom: 12,
                                child: Text('Avatar 2D',
                                    style: TextStyle(
                                        fontFamily: 'CinzelDecorative',
                                        fontSize: 9,
                                        color: AppColors.textMuted,
                                        letterSpacing: 1)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Slots direita
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: rightSlots
                      .map((s) => _slot(s.$1, s.$2))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Slots inferiores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: bottomSlots
                .map((s) => _slot(s.$1, s.$2, wide: true))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _slot(String label, IconData icon, {bool wide = false}) {
    return Container(
      width: wide ? 90 : 68,
      height: 68,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildClassFaction(player) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _cfItem('CLASSE',
                player?.classType ?? 'Sem Classe',
                'Disponível no Nível 5',
                Icons.shield_outlined, AppColors.purple),
          ),
          Container(width: 1, height: 50, color: AppColors.border),
          Expanded(
            child: _cfItem('FACÇÃO',
                player?.factionType ?? 'Sem Facção',
                'Disponível no Nível 7',
                Icons.flag_outlined, AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget _cfItem(String label, String value, String sub,
      IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 12, color: AppColors.textPrimary)),
          Text(sub,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildAttributes(
      BuildContext context, WidgetRef ref, player) {
    final attrs = [
      ('Força', 'strength', player?.strength ?? 1,
          Icons.fitness_center, AppColors.hp,
          'Poder físico, dano e carga'),
      ('Destreza', 'dexterity', player?.dexterity ?? 1,
          Icons.speed, AppColors.shadowStable,
          'Precisão, crítico e esquiva'),
      ('Inteligência', 'intelligence', player?.intelligence ?? 1,
          Icons.psychology_outlined, AppColors.mp,
          'Dano mágico e resistência'),
      ('Constituição', 'constitution', player?.constitution ?? 1,
          Icons.shield_outlined, AppColors.xp,
          'HP máximo e resistência física'),
      ('Espírito', 'spirit', player?.spirit ?? 1,
          Icons.self_improvement, AppColors.gold,
          'MP, vitalismo e estabilidade'),
      ('Carisma', 'charisma', player?.charisma ?? 1,
          Icons.people_outline, AppColors.purple,
          'NPCs, rotas narrativas e preços'),
    ];

    final hasPoints = (player?.attributePoints ?? 0) > 0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ATRIBUTOS',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 11,
                      color: AppColors.gold,
                      letterSpacing: 2)),
              if (hasPoints)
                Text('${player!.attributePoints} pts',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 16),

          ...attrs.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(a.$4, color: a.$5, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(a.$1,
                              style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                        ),
                        Text('${a.$3}',
                            style: GoogleFonts.cinzelDecorative(
                                fontSize: 14,
                                color: a.$5,
                                fontWeight: FontWeight.bold)),
                        if (hasPoints) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _addPoint(
                                context, ref, player!.id, a.$2),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: a.$5.withOpacity(0.15),
                                border: Border.all(
                                    color: a.$5.withOpacity(0.6)),
                              ),
                              child: Icon(Icons.add,
                                  color: a.$5, size: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (a.$3 / 100).clamp(0.0, 1.0),
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(a.$5),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(a.$6,
                        style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: AppColors.textMuted)),
                  ],
                ),
              )),

          // Reset de atributos de level up
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showResetDialog(context, ref, player),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.textMuted.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh,
                      color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Text('Resetar atributos de nível',
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPoint(BuildContext context, WidgetRef ref,
      int playerId, String attribute) async {
    final dao = PlayerDao(ref.read(appDatabaseProvider));
    final error = await dao.distributePoint(playerId, attribute);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppColors.shadowChaotic,
      ));
      return;
    }
    final updated = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updated;
  }

  void _showResetDialog(
      BuildContext context, WidgetRef ref, player) {
    final level = player?.level ?? 1;
    final cost = 150;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Resetar Atributos',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 15)),
        content: Text(
          'Apenas pontos ganhos por nível serão redistribuídos.\n\nCusto: $cost ouro\n\nAtributos de missões e conquistas não serão afetados.',
          style: GoogleFonts.roboto(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _resetAttributes(context, ref, player, cost);
            },
            child: Text('Resetar ($cost 🪙)',
                style: GoogleFonts.roboto(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAttributes(BuildContext context, WidgetRef ref,
      player, int cost) async {
    if ((player?.gold ?? 0) < cost) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ouro insuficiente.'),
          backgroundColor: AppColors.shadowChaotic,
        ));
      }
      return;
    }

    final dao = PlayerDao(ref.read(appDatabaseProvider));
    final level = player?.level ?? 1;

    // Reseta para 1 + devolve os pontos de level up
    await dao.resetLevelAttributes(player!.id, level, cost);
    final updated = await ref.read(authDsProvider).currentSession();
    ref.read(currentPlayerProvider.notifier).state = updated;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Atributos resetados. Pontos devolvidos.'),
        backgroundColor: AppColors.shadowStable,
      ));
    }
  }
}
