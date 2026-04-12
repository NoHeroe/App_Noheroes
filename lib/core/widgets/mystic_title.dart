import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MysticTitle extends StatefulWidget {
  final String text;
  final double fontSize;

  const MysticTitle({
    super.key,
    required this.text,
    this.fontSize = 28,
  });

  @override
  State<MysticTitle> createState() => _MysticTitleState();
}

class _MysticTitleState extends State<MysticTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Simula background-position 0%->100%->0% com background-size:200%
        // t: 0->0.5 vai de esquerda pra direita, 0.5->1 volta
        final pos = t <= 0.5 ? t * 2 : (1.0 - t) * 2;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFF7C3AED), // roxo
                Color(0xFFC29546), // dourado
                Color(0xFF7C3AED), // roxo
              ],
              stops: [
                (pos - 0.5).clamp(0.0, 1.0),
                pos.clamp(0.0, 1.0),
                (pos + 0.5).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: GoogleFonts.cinzelDecorative(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
        );
      },
    );
  }
}
