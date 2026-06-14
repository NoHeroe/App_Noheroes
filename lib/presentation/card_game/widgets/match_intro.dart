import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Sequência cinematográfica de ENTRADA na partida (1×, estilo Clash Royale):
///  1. NUVENS desvanecem revelando o campo;
///  2. DIÁLOGO do oponente (IA + dificuldade) — pop in, segura ~2s, pop out;
///  3. MOEDA (cara/coroa) com o resultado visível;
///  4. 1º BANNER de turno ("Seu Turno" / "Turno do Oponente").
/// Trava o input (AbsorbPointer) e chama [onComplete] no fim.
class MatchIntroOverlay extends StatefulWidget {
  const MatchIntroOverlay({
    super.key,
    required this.playerStarts,
    required this.onComplete,
  });

  final bool playerStarts;
  final VoidCallback onComplete;

  @override
  State<MatchIntroOverlay> createState() => _MatchIntroOverlayState();
}

class _MatchIntroOverlayState extends State<MatchIntroOverlay> {
  // -1 pré-roll (véu escuro, pré-carrega) · 0 nuvens · 1 moeda · 2 banner.
  int _stage = -1;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));
  void _go(int s) {
    if (mounted) setState(() => _stage = s);
  }

  Future<void> _run() async {
    // CEO 2026-06-13: respiro de pré-carga antes de tudo começar (véu escuro no
    // 1º frame, dá tempo do flutter_animate/assets ficarem prontos antes da
    // animação pesada das nuvens) — evita afobamento na abertura.
    await _wait(800);
    _go(0); // nuvens
    await _wait(1950); // nuvens de tempestade densas abrem e revelam o campo
    await _wait(1500); // respiro de 1,5s entre o fim da fumaça e a moeda (CEO 2026-06-14)
    _go(1);
    await _wait(2400); // moeda gira + resultado
    _go(2); // banner: chama onComplete via TurnBanner.onDone
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pré-roll: véu TOTALMENTE opaco (mesma cor do véu das nuvens) já no
            // 1º frame, enquanto pré-carrega — transição perfeita pras nuvens.
            if (_stage == -1)
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFF0A0912)),
              ),
            // Véu escuro leve atrás da moeda/banner (não nas nuvens).
            if (_stage >= 1)
              const ColoredBox(color: Color(0x99060008))
                  .animate()
                  .fadeIn(duration: 250.ms),
            if (_stage == 0) _clouds(),
            if (_stage == 1)
              Center(child: _CoinFlip(playerStarts: widget.playerStarts)),
            if (_stage == 2)
              TurnBanner(
                playerTurn: widget.playerStarts,
                onDone: widget.onComplete,
              ),
          ],
        ),
      ),
    );
  }

  // --- 1. Nuvens de TEMPESTADE densas que se abrem revelando o campo ------
  // CEO 2026-06-13: pesadas, escuras, grandes; centro abre de dentro pra
  // cima/fora, laterais deslizam — nada de "porta de shopping". Véu escuro +
  // 2 relâmpagos pra dar tom de tempestade.
  static const List<String> _kClouds = [
    'assets/vfx/particles/smoke_04.png',
    'assets/vfx/particles/smoke_03.png',
    'assets/vfx/particles/smoke_06.png',
    'assets/vfx/particles/smoke_09.png',
  ];

  Widget _clouds() {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final items = <Widget>[];

        // Véu de tempestade TOTALMENTE opaco no início (esconde o campo já no 1º
        // frame — corrige o flash do tabuleiro antes das nuvens) e clareia
        // conforme elas abrem.
        items.add(const Positioned.fill(
          child: ColoredBox(color: Color(0xFF0A0912)),
        ).animate().fadeOut(delay: 750.ms, duration: 1000.ms));

        // Relâmpagos breves (flashes frios).
        items.add(const Positioned.fill(child: ColoredBox(color: Color(0x44C2CEEC)))
            .animate()
            .fadeIn(duration: 50.ms)
            .fadeOut(delay: 70.ms, duration: 150.ms));
        items.add(const Positioned.fill(child: ColoredBox(color: Color(0x33B6C2E4)))
            .animate()
            .fadeIn(delay: 520.ms, duration: 45.ms)
            .fadeOut(delay: 575.ms, duration: 150.ms));

        // Duas camadas densas de nuvens (fundo escuro + frente mais clara).
        for (var layer = 0; layer < 2; layer++) {
          final cols = layer == 0 ? 5 : 4;
          final rows = layer == 0 ? 6 : 5;
          for (var r = 0; r < rows; r++) {
            for (var col = 0; col < cols; col++) {
              final idx = r * cols + col + layer * 31;
              // Offset alternado por linha pra romper a grade (orgânico).
              final ox = (r.isEven ? 0.5 : 0.05);
              final cx = (col + ox) / cols * w;
              final cy = (r + 0.5) / rows * h;
              final size = w * (layer == 0 ? 0.9 : 0.66);
              final relX = cx / w - 0.5; // -0.5 (esq) .. 0.5 (dir)
              final central = relX.abs() < 0.2;
              // Centro: abre de dentro pra CIMA/fora (sobe muito + cresce).
              // Laterais: deslizam pro seu lado (+ leve subida).
              final endX = central ? relX * w * 0.5 : (relX < 0 ? -1 : 1) * w * 0.6;
              final endY = -h * (central ? 0.42 : 0.12);
              final scaleEnd = central ? 2.1 : 1.7;
              final tint = layer == 0
                  ? (idx.isEven
                      ? const Color(0xFF24262F)
                      : const Color(0xFF34384A))
                  : const Color(0xFF4C5168);
              final stagger = ((idx % 6) * 45).ms;
              items.add(Positioned(
                left: cx - size / 2,
                top: cy - size / 2,
                width: size,
                height: size,
                child: Transform.rotate(
                  angle: (idx * 1.7) % (2 * math.pi) - math.pi,
                  child: Image.asset(
                    _kClouds[idx % _kClouds.length],
                    color: tint,
                    colorBlendMode: BlendMode.modulate,
                    fit: BoxFit.contain,
                  ),
                )
                    .animate()
                    .moveX(begin: 0, end: endX, delay: stagger, duration: 1550.ms, curve: Curves.easeIn)
                    .moveY(begin: 0, end: endY, delay: stagger, duration: 1550.ms, curve: Curves.easeIn)
                    .scaleXY(begin: 1.05, end: scaleEnd, delay: stagger, duration: 1550.ms, curve: Curves.easeOut)
                    .fadeOut(delay: stagger + 650.ms, duration: 900.ms),
              ));
            }
          }
        }
        return Stack(children: items);
      },
    );
  }

}

/// Banner de TURNO (pop in / segura / pop out): "SEU TURNO" (dourado, com linhas
/// de tensão passando em direções opostas em cima e embaixo) ou "TURNO DO
/// OPONENTE" (vermelho). Usado na intro e a cada virada de turno. Chama [onDone]
/// ao terminar — quem renderiza trava o input enquanto está visível.
class TurnBanner extends StatefulWidget {
  const TurnBanner({super.key, required this.playerTurn, this.onDone});

  final bool playerTurn;
  final VoidCallback? onDone;

  @override
  State<TurnBanner> createState() => _TurnBannerState();
}

class _TurnBannerState extends State<TurnBanner> {
  @override
  void initState() {
    super.initState();
    // CEO 2026-06-13: duração do banner do oponente IGUAL ao "Seu Turno".
    Future<void>.delayed(const Duration(milliseconds: 1750), () {
      if (mounted) widget.onDone?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Versão anterior SEM as barras (CEO 2026-06-13): faixa escura + texto
    // (dourado no seu turno / vermelho no oponente), pop in/out. Só a FONTE
    // mudou — Metamorphous (fantasia), pra comparar com a Cinzel Decorative.
    final color = widget.playerTurn ? AppColors.gold : AppColors.conceptCorrompido;
    final text = widget.playerTurn ? 'SEU TURNO' : 'TURNO DO OPONENTE';
    const holdMs = 1100;

    final band = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            AppColors.black.withValues(alpha: 0.82),
            AppColors.black.withValues(alpha: 0.82),
            Colors.transparent,
          ],
          stops: const [0, 0.18, 0.82, 1],
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.metamorphous(
          fontSize: widget.playerTurn ? 30 : 24,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 2,
          shadows: const [Shadow(color: AppColors.black, blurRadius: 12)],
        ),
      ),
    );

    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.05),
        child: band
            .animate()
            .scaleXY(
                begin: 0.7, end: 1, duration: 300.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 180.ms)
            .then(delay: holdMs.ms)
            .scaleXY(begin: 1, end: 0.85, duration: 300.ms, curve: Curves.easeIn)
            .fadeOut(duration: 300.ms),
      ),
    );
  }
}

/// Moeda (cara/coroa) que gira e assenta no resultado. `playerStarts` → "CARA"
/// (você começa); senão "COROA" (IA começa).
class _CoinFlip extends StatefulWidget {
  const _CoinFlip({required this.playerStarts});
  final bool playerStarts;

  @override
  State<_CoinFlip> createState() => _CoinFlipState();
}

class _CoinFlipState extends State<_CoinFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = widget.playerStarts ? 'CARA' : 'COROA';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Moeda girando em 3D (flip no eixo X com perspectiva) — assenta plana.
        AnimatedBuilder(
          animation: _c,
          builder: (ctx, _) {
            final t = Curves.easeOutCubic.transform(_c.value);
            final spin = t * math.pi * 6; // 3 voltas completas
            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0016) // perspectiva
              ..rotateX(spin);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: _coinFace(),
            );
          },
        ),
        const SizedBox(height: 20),
        // Resultado: CARA / COROA com brilho.
        Text(
          face,
          style: GoogleFonts.cinzelDecorative(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.goldLt,
            letterSpacing: 3,
            shadows: [
              Shadow(color: AppColors.gold.withValues(alpha: 0.6), blurRadius: 16),
              const Shadow(color: AppColors.black, blurRadius: 8),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 1400.ms, duration: 250.ms)
            .scaleXY(begin: 0.7, end: 1, delay: 1400.ms, duration: 280.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 4),
        Text(
          widget.playerStarts ? 'VOCÊ COMEÇA' : 'IA COMEÇA',
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 2,
            shadows: const [Shadow(color: AppColors.black, blurRadius: 8)],
          ),
        ).animate().fadeIn(delay: 1550.ms, duration: 250.ms),
      ],
    );
  }

  /// Disco da moeda: metálico (radial dourado com profundidade), aro grosso,
  /// anel interno, sigilo (espadas cruzadas) gravado e um gloss no topo.
  Widget _coinFace() {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 1.15,
          colors: [
            Color(0xFFFBF0C8),
            Color(0xFFE3C56E),
            Color(0xFFB48E3A),
            Color(0xFF7A5A22),
          ],
          stops: [0, 0.4, 0.75, 1],
        ),
        border: Border.all(color: const Color(0xFF5E461A), width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0xAA000000), blurRadius: 18, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x55E4CB8A), blurRadius: 22, spreadRadius: -2),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anel interno gravado.
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x55503A12), width: 2),
            ),
          ),
          // Sigilo (espadas cruzadas) gravado, em dourado escuro.
          SvgPicture.asset(
            'assets/icons/rpg/crossed-swords.svg',
            width: 54,
            height: 54,
            colorFilter:
                const ColorFilter.mode(Color(0xFF6A4E18), BlendMode.srcIn),
          ),
          // Gloss (brilho) na parte de cima.
          Positioned(
            top: 12,
            child: Container(
              width: 62,
              height: 20,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(40)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
