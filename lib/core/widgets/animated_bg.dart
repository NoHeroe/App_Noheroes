import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBg extends StatefulWidget {
  const AnimatedBg({super.key});

  @override
  State<AnimatedBg> createState() => _AnimatedBgState();
}

class _AnimatedBgState extends State<AnimatedBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 100; i++) {
      _particles.add(_Particle.random(_random, startAnywhere: true));
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(() {
        for (var p in _particles) {
          p.update();
        }
        setState(() {});
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(_particles),
      child: Container(),
    );
  }
}

class _Particle {
  Offset pos;
  double radius;
  double speedY;
  double driftX;
  double alpha;
  final math.Random rand;

  _Particle(this.pos, this.radius, this.speedY, this.driftX, this.alpha, this.rand);

  factory _Particle.random(math.Random rand, {bool startAnywhere = false}) {
    const double w = 400;
    const double h = 800;
    return _Particle(
      Offset(rand.nextDouble() * w,
          startAnywhere ? rand.nextDouble() * h : h + rand.nextDouble() * 100),
      1 + rand.nextDouble() * 2.5,
      0.2 + rand.nextDouble() * 0.5,
      (rand.nextDouble() - 0.5) * 0.5,
      0.4 + rand.nextDouble() * 0.3,
      rand,
    );
  }

  void update() {
    pos = Offset(pos.dx + driftX, pos.dy - speedY);
    if (pos.dy < -10 || pos.dx < -50 || pos.dx > 450) {
      pos = Offset(rand.nextDouble() * 400, 800 + rand.nextDouble() * 100);
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = const Color(0xFF8B3DFF).withOpacity(p.alpha);
      canvas.drawCircle(p.pos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
