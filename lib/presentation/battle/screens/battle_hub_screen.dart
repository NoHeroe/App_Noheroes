import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../card_game/deck_repository.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/nh_back_button.dart';

/// Modelo de um submodo (uma "bolinha") dentro de um grupo/estilo de jogo.
class _SubMode {
  final String label; // texto curto da bolinha / título
  final String description; // miniatura exibida ao selecionar
  final void Function(BuildContext context) onPlay;

  /// Submodo bloqueado (cadeado; não selecionável). Ex.: PvP/Amistoso.
  final bool locked;

  const _SubMode({
    required this.label,
    required this.description,
    required this.onPlay,
    this.locked = false,
  });
}

/// Modelo de um grupo/estilo de jogo: botão grande (cor própria) + bolinhas.
class _PlayStyle {
  final String title; // texto do botão grande, ex.: "CARD GAME"
  final String subtitle; // linha curta sob o título
  final IconData icon;
  final Color color; // COR PRÓPRIA do estilo
  final List<_SubMode> subModes;

  /// Nível mínimo pra desbloquear o grupo (0 = sempre). Card Game = 2.
  final int requiredLevel;

  /// Grupo inteiro em desenvolvimento (cadeado permanente, independe de nível).
  final bool inDev;

  const _PlayStyle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.subModes,
    this.requiredLevel = 0,
    this.inDev = false,
  });
}

class BattleHubScreen extends ConsumerStatefulWidget {
  const BattleHubScreen({super.key});

  @override
  ConsumerState<BattleHubScreen> createState() => _BattleHubScreenState();
}

class _BattleHubScreenState extends ConsumerState<BattleHubScreen>
    with SingleTickerProviderStateMixin {
  /// Submodo selecionado por grupo (índice do estilo -> índice do submodo).
  /// Ausente = nenhum submodo selecionado naquele grupo.
  final Map<int, int> _selected = {};

  /// Pulso contínuo p/ o brilho + partículas do botão quando um modo é escolhido.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── Definição dos grupos / submodos ────────────────────────────────────
  late final List<_PlayStyle> _styles = [
    // CARD GAME — roxo (PvE funcional; desbloqueia no nível 2).
    _PlayStyle(
      title: 'CARD GAME',
      subtitle: 'Duelo de cartas — ACDA',
      icon: Icons.style_outlined,
      color: AppColors.purple,
      requiredLevel: 2,
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
          locked: true,
          onPlay: (c) => AppSnack.info(
              c, 'PvP em breve — precisa do servidor online.'),
        ),
        _SubMode(
          label: 'Amistoso',
          description: 'Partida casual com um amigo, sem ranking.',
          locked: true,
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
      inDev: true,
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
      inDev: true,
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
      inDev: true,
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
    final sub = _styles[styleIndex].subModes[subIndex];
    if (sub.locked) {
      // Submodo bloqueado (PvP/Amistoso): não seleciona, só avisa.
      sub.onPlay(context);
      return;
    }
    setState(() {
      if (_selected[styleIndex] == subIndex) {
        _selected.remove(styleIndex); // toggle off
      } else {
        _selected[styleIndex] = subIndex;
      }
    });
  }

  void _onLockedGroupTap(_PlayStyle style) {
    AppSnack.info(
      context,
      style.inDev
          ? '${style.title} em desenvolvimento.'
          : '${style.title} desbloqueia no nível ${style.requiredLevel}.',
    );
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
                context.push('/card-game/deck-builder');
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
    final level = ref.watch(currentPlayerProvider)?.level ?? 1;
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
                // Header sem título: só o botão de voltar.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      // Botão voltar PADRÃO (CEO 2026-06-12).
                      NhBackButton(onTap: () => context.go('/sanctuary')),
                    ],
                  ),
                ),

                // Grupos: botão grande + bolinhas + miniatura
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: _styles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 22),
                    itemBuilder: (context, i) => _buildStyleGroup(i, level),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Um grupo: botão HEXAGONAL (estilo COMBATE, maior) + bolinhas ───────
  Widget _buildStyleGroup(int styleIndex, int level) {
    final style = _styles[styleIndex];
    final groupLocked = style.inDev || level < style.requiredLevel;
    final selIndex = _selected[styleIndex];
    final hasSelection = !groupLocked && selIndex != null;
    // CEO 2026-06-12: paleta DOURADA (igual ao botão COMBATE de referência).
    const color = AppColors.gold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hexGroupButton(styleIndex, style, groupLocked, hasSelection, selIndex,
            color),

        // Bolinhas + miniatura só pra grupos desbloqueados.
        if (!groupLocked) ...[
          const SizedBox(height: 12),
          // Fileira de bolinhas CENTRALIZADA.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 22,
            runSpacing: 10,
            children: List.generate(style.subModes.length, (subIndex) {
              return _buildDot(
                label: style.subModes[subIndex].label,
                color: color,
                selected: selIndex == subIndex,
                locked: style.subModes[subIndex].locked,
                onTap: () => _onDotTap(styleIndex, subIndex),
              );
            }),
          ),
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
                  const Icon(Icons.info_outline, size: 13, color: color),
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
      ],
    );
  }

  // ── Uma bolinha (dot) de submodo ───────────────────────────────────────
  Widget _buildDot({
    required String label,
    required Color color,
    required bool selected,
    required bool locked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: locked
                    ? AppColors.textMuted.withValues(alpha: 0.18)
                    : (selected
                        ? color
                        : AppColors.textMuted.withValues(alpha: 0.35)),
                border: Border.all(
                  color: selected && !locked
                      ? color
                      : AppColors.textMuted.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: selected && !locked
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: locked
                  ? const Icon(Icons.lock,
                      size: 10, color: AppColors.textMuted)
                  : null,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: selected && !locked ? color : AppColors.textMuted,
                letterSpacing: 0.3,
                fontWeight:
                    selected && !locked ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Botão hexagonal (estilo COMBATE, maior, paleta do grupo) ───────────
  /// Quando um modo é escolhido (hasSelection), o hexágono ganha brilho
  /// PULSANTE + PARTÍCULAS (CEO 2026-06-12). Sem ícone de "tap".
  Widget _hexGroupButton(int styleIndex, _PlayStyle style, bool groupLocked,
      bool hasSelection, int? selIndex, Color color) {
    final shellColor = groupLocked ? AppColors.textMuted : color;
    final content =
        _hexContent(style, groupLocked, hasSelection, selIndex, color);
    void onTap() =>
        groupLocked ? _onLockedGroupTap(style) : _onPlay(styleIndex);

    if (!hasSelection) {
      return GestureDetector(
        onTap: onTap,
        child: _hexShell(color: shellColor, glow: 0, child: content),
      );
    }
    // Selecionado: pulso + partículas.
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final pulse = 0.5 + 0.5 * math.sin(_pulse.value * 2 * math.pi);
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _hexShell(
                  color: shellColor, glow: 0.5 + 0.5 * pulse, child: content),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                      painter: _HexParticlePainter(_pulse.value, color)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hexShell(
      {required Color color, required double glow, required Widget child}) {
    final top = Color.lerp(
        const Color(0xFF2A2139), color, 0.16 + 0.16 * glow)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14 + 0.36 * glow),
            blurRadius: 18 + 22 * glow,
            spreadRadius: 0.5 + 1.5 * glow,
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipPath(
            clipper: _HexClipper(),
            child: Container(
              width: double.infinity, // hex preenche a largura toda (fill cheio)
              padding:
                  const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [top, const Color(0xFF0D0A13)],
                ),
              ),
              child: child,
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _HexBorderPainter(
                  color.withValues(alpha: 0.55 + 0.35 * glow), 1.5 + glow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hexContent(_PlayStyle style, bool groupLocked, bool hasSelection,
      int? selIndex, Color color) {
    final icon = groupLocked
        ? Icons.lock
        : (hasSelection ? Icons.play_arrow_rounded : style.icon);
    final titleText = hasSelection
        ? 'JOGAR — ${style.subModes[selIndex!].label}'
        : style.title;
    final subText = groupLocked
        ? (style.inDev
            ? 'Em desenvolvimento'
            : 'Desbloqueia no nível ${style.requiredLevel}')
        : (hasSelection ? style.title : style.subtitle);
    return Opacity(
      opacity: groupLocked ? 0.6 : 1,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: groupLocked
                  ? AppColors.textMuted.withValues(alpha: 0.12)
                  : color.withValues(alpha: hasSelection ? 0.22 : 0.12),
              border: Border.all(
                  color: groupLocked
                      ? AppColors.textMuted.withValues(alpha: 0.4)
                      : color.withValues(alpha: hasSelection ? 0.75 : 0.4)),
            ),
            child: Icon(icon,
                color: groupLocked ? AppColors.textMuted : color,
                size: hasSelection ? 30 : 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    letterSpacing: 1,
                    color: groupLocked
                        ? AppColors.textMuted
                        : (hasSelection ? color : AppColors.textPrimary),
                    shadows: hasSelection
                        ? [
                            Shadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 12)
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }
}

// ── Hexágono (apontado nas laterais) — recorte + contorno + partículas ──────
Path _hexPath(Size size) {
  final w = size.width, h = size.height;
  const inset = 0.04;
  return Path()
    ..moveTo(w * inset, 0)
    ..lineTo(w * (1 - inset), 0)
    ..lineTo(w, h / 2)
    ..lineTo(w * (1 - inset), h)
    ..lineTo(w * inset, h)
    ..lineTo(0, h / 2)
    ..close();
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _hexPath(size);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexBorderPainter extends CustomPainter {
  final Color color;
  final double width;
  _HexBorderPainter(this.color, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.miter
      ..color = color;
    canvas.drawPath(_hexPath(size), paint);
  }

  @override
  bool shouldRepaint(covariant _HexBorderPainter old) =>
      old.color != color || old.width != width;
}

/// Embers (faíscas) douradas estilo "aceitar do LoL": sobem com balanço
/// horizontal, velocidades/tamanhos variados, surgem embaixo e somem em cima,
/// cintilando. Movimento orgânico (não uma cachoeira rígida).
class _HexParticlePainter extends CustomPainter {
  final double t; // 0..1 loop
  final Color color;
  _HexParticlePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 24;
    for (var i = 0; i < n; i++) {
      final seed = ((i * 73) % 100) / 100.0;
      final seed2 = ((i * 137) % 100) / 100.0;
      final speed = 0.6 + seed * 0.9; // cada ember tem ritmo próprio
      final phase = ((t * speed) + seed) % 1.0;
      // posição base espalhada + balanço senoidal (sway) ao subir.
      final baseX = size.width * (0.04 + seed2 * 0.92);
      final sway =
          math.sin((phase * 1.6 + seed) * math.pi * 2) * (6 + 10 * seed);
      final x = baseX + sway;
      final y = size.height * (1 - phase) - 2;
      // fade-in embaixo, fade-out em cima.
      final fade = (phase < 0.18 ? phase / 0.18 : (1 - phase) / 0.82)
          .clamp(0.0, 1.0);
      final twinkle = 0.45 + 0.55 * (0.5 + 0.5 * math.sin((t * 3 + seed2) * math.pi * 2));
      final a = (fade * 0.9 * twinkle).clamp(0.0, 1.0);
      final r = 1.0 + 1.9 * seed;
      final p = Paint()
        ..color = color.withValues(alpha: a)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.8 + seed);
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _HexParticlePainter old) => old.t != t;
}
