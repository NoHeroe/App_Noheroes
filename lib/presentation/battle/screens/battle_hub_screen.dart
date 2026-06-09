import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../card_game/deck_repository.dart';
import '../../shared/widgets/app_snack.dart';

/// Modelo de um submodo (uma "bolinha") dentro de um grupo/estilo de jogo.
class _SubMode {
  final String label; // texto curto da bolinha / título
  final String description; // miniatura exibida ao selecionar
  final void Function(BuildContext context) onPlay;

  const _SubMode({
    required this.label,
    required this.description,
    required this.onPlay,
  });
}

/// Modelo de um grupo/estilo de jogo: botão grande (cor própria) + bolinhas.
class _PlayStyle {
  final String title; // texto do botão grande, ex.: "CARD GAME"
  final String subtitle; // linha curta sob o título
  final IconData icon;
  final Color color; // COR PRÓPRIA do estilo
  final List<_SubMode> subModes;

  const _PlayStyle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.subModes,
  });
}

class BattleHubScreen extends ConsumerStatefulWidget {
  const BattleHubScreen({super.key});

  @override
  ConsumerState<BattleHubScreen> createState() => _BattleHubScreenState();
}

class _BattleHubScreenState extends ConsumerState<BattleHubScreen> {
  /// Submodo selecionado por grupo (índice do estilo -> índice do submodo).
  /// Ausente = nenhum submodo selecionado naquele grupo.
  final Map<int, int> _selected = {};

  // ── Definição dos grupos / submodos ────────────────────────────────────
  late final List<_PlayStyle> _styles = [
    // CARD GAME — roxo (funcional no PvE)
    _PlayStyle(
      title: 'CARD GAME',
      subtitle: 'Duelo de cartas — ACDA',
      icon: Icons.style_outlined,
      color: AppColors.purple,
      subModes: [
        _SubMode(
          label: 'PvE',
          description: 'Solo contra a IA de Caelum. Dificuldade ajustável.',
          onPlay: (c) => _onCardPvePlay(),
        ),
        _SubMode(
          label: 'PvP',
          description:
              'Duelo ranqueado contra outros invocadores. Sobe de elo.',
          onPlay: (c) => AppSnack.info(
              c, 'PvP em breve — precisa do servidor online.'),
        ),
        _SubMode(
          label: 'Amistoso',
          description: 'Partida casual com um amigo, sem ranking.',
          onPlay: (c) => AppSnack.info(c, 'Modo amistoso em breve.'),
        ),
      ],
    ),

    // ARENA 3D — PvE — verde ascendente
    _PlayStyle(
      title: 'ARENA 3D — PvE',
      subtitle: 'Solo & grupo contra Caelum',
      icon: Icons.castle_outlined,
      color: AppColors.shadowAscending,
      subModes: [
        _SubMode(
          label: 'Dungeons',
          description: 'Masmorras procedurais 1–5 jogadores. Cada run é única.',
          onPlay: (c) => AppSnack.info(c, 'Dungeons em desenvolvimento.'),
        ),
        _SubMode(
          label: 'Raids',
          description: 'Bosses épicos de Caelum. Recompensas lendárias.',
          onPlay: (c) => AppSnack.info(c, 'Raids em desenvolvimento.'),
        ),
        _SubMode(
          label: 'Towers',
          description: 'Torre dimensional infinita. Quanto mais alto, mais forte.',
          onPlay: (c) => AppSnack.info(c, 'Towers em desenvolvimento.'),
        ),
        _SubMode(
          label: 'Shadow Boss',
          description: 'Enfrente a manifestação da sua própria sombra.',
          onPlay: (c) => AppSnack.info(c, 'Shadow Boss em desenvolvimento.'),
        ),
      ],
    ),

    // ARENA 3D — PvP — dourado
    _PlayStyle(
      title: 'ARENA 3D — PvP',
      subtitle: 'Confronto direto entre jogadores',
      icon: Icons.sports_martial_arts,
      color: AppColors.gold,
      subModes: [
        _SubMode(
          label: '1v1',
          description: 'Duelo direto. Build, habilidade e estratégia.',
          onPlay: (c) => AppSnack.info(c, 'Arena 1v1 em desenvolvimento.'),
        ),
        _SubMode(
          label: '2v2',
          description: 'Dupla coordenada contra a dupla adversária.',
          onPlay: (c) => AppSnack.info(c, 'Arena 2v2 em desenvolvimento.'),
        ),
        _SubMode(
          label: '5v5',
          description: 'Batalha em time. Composição, sinergia e execução.',
          onPlay: (c) => AppSnack.info(c, 'Arena 5v5 em desenvolvimento.'),
        ),
      ],
    ),

    // FENDAS — azul-vazio
    _PlayStyle(
      title: 'FENDAS',
      subtitle: 'Eventos dimensionais temporários',
      icon: Icons.blur_on,
      color: AppColors.mp,
      subModes: [
        _SubMode(
          label: 'Fenda do Vazio',
          description: 'Abre espontaneamente. Risco real, loot exclusivo.',
          onPlay: (c) => AppSnack.info(c, 'Fenda do Vazio em desenvolvimento.'),
        ),
        _SubMode(
          label: 'Fenda de Chrysalis',
          description: 'Fenda biológica. Mutantes N1–N6, seiva pura.',
          onPlay: (c) =>
              AppSnack.info(c, 'Fenda de Chrysalis em desenvolvimento.'),
        ),
      ],
    ),
  ];

  void _onDotTap(int styleIndex, int subIndex) {
    setState(() {
      if (_selected[styleIndex] == subIndex) {
        _selected.remove(styleIndex); // toggle off
      } else {
        _selected[styleIndex] = subIndex;
      }
    });
  }

  /// Gating do Card Game PvE: exige um deck ativo VÁLIDO (9+9) antes de ir
  /// pro matchmaking. Sem deck válido → popup oferecendo montar agora.
  Future<void> _onCardPvePlay() async {
    PlayerDeck? deck;
    try {
      // Lê o deck ativo (resolve o FutureProvider). Sem login → null.
      deck = await ref.read(activeDeckProvider.future);
    } catch (_) {
      // Erro de rede/posse — trata como "sem deck" (oferece montar).
      deck = null;
    }
    if (!mounted) return;

    if (deck != null && deck.isValid) {
      context.go('/card-game/matchmaking?mode=pve');
      return;
    }
    _showNoDeckDialog();
  }

  void _showNoDeckDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceVeil2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderViolet),
          ),
          title: Row(
            children: [
              const Icon(Icons.style_outlined,
                  color: AppColors.purpleLight, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Sem deck',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 15,
                        color: AppColors.purpleLight,
                        letterSpacing: 1)),
              ),
            ],
          ),
          content: Text(
            'Você ainda não tem um deck válido (9 criaturas + 9 relíquias). '
            'Montar agora?',
            style: GoogleFonts.roboto(
                fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted),
              child: const Text('Agora não'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context.go('/card-game/deck-builder');
              },
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.purpleLight),
              child: const Text('Montar deck'),
            ),
          ],
        );
      },
    );
  }

  void _onPlay(int styleIndex) {
    final selIndex = _selected[styleIndex];
    final style = _styles[styleIndex];
    if (selIndex == null) {
      AppSnack.warning(context, 'Escolha um submodo de ${style.title} primeiro.');
      return;
    }
    style.subModes[selIndex].onPlay(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Atmosfera
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [Color(0xFF1A0020), Color(0xFF0A000A), AppColors.black],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/sanctuary'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.surface,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: AppColors.textSecondary, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CAMPO DE BATALHA',
                                style: GoogleFonts.cinzelDecorative(
                                    fontSize: 14,
                                    color: AppColors.hp,
                                    letterSpacing: 2)),
                            Text('Escolha o estilo e o submodo',
                                style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Aviso em breve
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.construction,
                          color: AppColors.gold, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            'Apenas Card Game (PvE) jogável. Os demais em desenvolvimento.',
                            style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: AppColors.gold,
                                fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),

                // Grupos: botão grande + bolinhas + miniatura
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: _styles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 22),
                    itemBuilder: (context, i) => _buildStyleGroup(i),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Um grupo: botão grande + fileira de bolinhas + miniatura ───────────
  Widget _buildStyleGroup(int styleIndex) {
    final style = _styles[styleIndex];
    final selIndex = _selected[styleIndex];
    final hasSelection = selIndex != null;
    final color = style.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botão grande (cor própria). Ativo quando há submodo selecionado.
        GestureDetector(
          onTap: () => _onPlay(styleIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasSelection
                    ? color.withValues(alpha: 0.9)
                    : AppColors.border,
                width: hasSelection ? 1.6 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasSelection
                    ? [
                        color.withValues(alpha: 0.28),
                        color.withValues(alpha: 0.06),
                      ]
                    : [AppColors.surface, AppColors.surface],
              ),
              boxShadow: hasSelection
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: hasSelection ? 0.22 : 0.10),
                    border: Border.all(
                        color: color.withValues(
                            alpha: hasSelection ? 0.7 : 0.3)),
                  ),
                  child: Icon(
                    hasSelection ? Icons.play_arrow_rounded : style.icon,
                    color: color,
                    size: hasSelection ? 30 : 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSelection
                            ? 'JOGAR — ${style.subModes[selIndex].label}'
                            : style.title,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 15,
                          color: hasSelection ? color : AppColors.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasSelection ? style.title : style.subtitle,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: hasSelection
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasSelection
                      ? Icons.chevron_right_rounded
                      : Icons.touch_app_outlined,
                  color: hasSelection ? color : AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Fileira de bolinhas (uma por submodo)
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: List.generate(style.subModes.length, (subIndex) {
            final selected = selIndex == subIndex;
            return _buildDot(
              label: style.subModes[subIndex].label,
              color: color,
              selected: selected,
              onTap: () => _onDotTap(styleIndex, subIndex),
            );
          }),
        ),

        // Miniatura do submodo selecionado
        if (hasSelection) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 13, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    style.subModes[selIndex].description,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Uma bolinha (dot) de submodo ───────────────────────────────────────
  Widget _buildDot({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? color
                  : AppColors.textMuted.withValues(alpha: 0.35),
              border: Border.all(
                color: selected
                    ? color
                    : AppColors.textMuted.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: selected ? color : AppColors.textMuted,
              letterSpacing: 0.3,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
