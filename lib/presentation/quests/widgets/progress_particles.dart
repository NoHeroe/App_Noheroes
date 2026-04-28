import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Sprint 3.2 Etapa 1.3.C — partículas leves emitidas da extremidade
/// preenchida da barra de progresso.
///
/// 2 modos:
/// - **Contínuo**: 3-4 partículas/segundo flutuando da posição X = `value
///   * width` (ponta da barra preenchida). Só ocorre quando `value > 0.05`.
/// - **Burst**: ~12-15 partículas extras quando [burstSignal] muda
///   (jogador clicou +1/+10 e a barra está animando).
///
/// Hibernação (hotfix-3): quando todas as partículas morrem E não há demanda
/// de spawn (value muito baixo + sem burst recente), o `AnimationController`
/// faz `stop()` pra não consumir CPU. Reinicia automaticamente quando
/// burstSignal muda ou value sobe acima de 0.05.
///
/// Pool reutilizável de 30 slots, sem alocação por partícula.
class ProgressParticles extends StatefulWidget {
  /// Posição X (0..1) da ponta da barra preenchida — origem do spawn.
  final double value;

  /// Cor base das partículas (alpha 0.7 aplicado).
  final Color color;

  /// Disparar burst — incrementar pra emitir ~12-15 partículas extras.
  final ValueListenable<int>? burstSignal;

  /// Habilita as partículas. Default true. Quando false, controller fica
  /// stopped permanentemente — uso pra desabilitar via flag em testes ou
  /// devices low-end.
  final bool enabled;

  const ProgressParticles({
    super.key,
    required this.value,
    required this.color,
    this.burstSignal,
    this.enabled = true,
  });

  @override
  State<ProgressParticles> createState() => _ProgressParticlesState();
}

class _ProgressParticlesState extends State<ProgressParticles>
    with SingleTickerProviderStateMixin {
  static const int _poolSize = 30;
  static const double _spawnIntervalMs = 280; // ~3.5 partículas/seg
  static const int _burstCount = 13;
  static const double _lifetimeSec = 1.2;
  static const double _minValueForSpawn = 0.05;

  late final AnimationController _ctl;
  final math.Random _rand = math.Random();
  final List<_Particle> _pool = [];

  Duration _lastTick = Duration.zero;
  double _spawnAccumMs = 0.0;
  int _lastBurstSignal = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _poolSize; i++) {
      _pool.add(_Particle.dead());
    }
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick);
    widget.burstSignal?.addListener(_onBurstSignal);
    _lastBurstSignal = widget.burstSignal?.value ?? 0;
    if (widget.enabled && widget.value > _minValueForSpawn) {
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant ProgressParticles old) {
    super.didUpdateWidget(old);
    if (old.burstSignal != widget.burstSignal) {
      old.burstSignal?.removeListener(_onBurstSignal);
      widget.burstSignal?.addListener(_onBurstSignal);
      _lastBurstSignal = widget.burstSignal?.value ?? 0;
    }
    // Liga/desliga conforme demanda muda.
    if (!widget.enabled) {
      _stop();
    } else if (widget.value > _minValueForSpawn && !_running) {
      _start();
    }
  }

  void _onBurstSignal() {
    final v = widget.burstSignal?.value ?? 0;
    if (v == _lastBurstSignal) return;
    _lastBurstSignal = v;
    if (!widget.enabled) return;
    _spawnBurst();
    _start();
  }

  void _start() {
    if (_running || !widget.enabled) return;
    _running = true;
    _lastTick = Duration.zero;
    _ctl.repeat();
  }

  void _stop() {
    if (!_running) return;
    _running = false;
    _ctl.stop();
  }

  bool _anyAlive() {
    for (final p in _pool) {
      if (p.alive) return true;
    }
    return false;
  }

  @override
  void dispose() {
    widget.burstSignal?.removeListener(_onBurstSignal);
    _ctl.dispose();
    super.dispose();
  }

  void _onTick() {
    final now = _ctl.lastElapsedDuration ?? Duration.zero;
    final dtMs = (now.inMicroseconds - _lastTick.inMicroseconds) / 1000.0;
    _lastTick = now;
    final dtSec = (dtMs / 1000.0).clamp(0.0, 0.05); // cap 50ms (anti-stutter)

    bool changed = false;

    // Atualiza partículas vivas.
    for (final p in _pool) {
      if (!p.alive) continue;
      p.life -= dtSec;
      if (p.life <= 0) {
        p.alive = false;
        changed = true;
        continue;
      }
      p.pos = Offset(p.pos.dx + p.vx * dtSec, p.pos.dy + p.vy * dtSec);
      p.alpha = (p.life / _lifetimeSec).clamp(0.0, 1.0) * 0.7;
      changed = true;
    }

    // Spawn contínuo só se value > threshold.
    if (widget.enabled && widget.value > _minValueForSpawn) {
      _spawnAccumMs += dtMs;
      if (_spawnAccumMs >= _spawnIntervalMs) {
        _spawnAccumMs = 0.0;
        _spawnOne();
        changed = true;
      }
    }

    if (changed) {
      setState(() {});
    }

    // Hibernação: todas mortas + sem demanda → stop.
    if (!_anyAlive() && widget.value <= _minValueForSpawn) {
      _stop();
    }
  }

  void _spawnOne() {
    final slot = _pool.firstWhere((p) => !p.alive, orElse: () => _pool.first);
    slot.alive = true;
    slot.life = _lifetimeSec;
    slot.alpha = 0.7;
    slot.radius = 1.5 + _rand.nextDouble() * 1.5;
    slot.relX = widget.value.clamp(0.0, 1.0);
    slot.pos = Offset.zero;
    slot.vx = (_rand.nextDouble() - 0.5) * 30; // ±15 px/s
    slot.vy = -(20 + _rand.nextDouble() * 30); // sobe 20-50 px/s
    slot.resolved = false;
  }

  void _spawnBurst() {
    for (int i = 0; i < _burstCount; i++) {
      _spawnOne();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _ParticlesPainter(
          particles: _pool,
          color: widget.color,
          relX: widget.value.clamp(0.0, 1.0),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Particle {
  Offset pos;
  double radius;
  double vx;
  double vy;
  double alpha;
  double life;
  double relX;
  bool resolved;
  bool alive;

  _Particle.dead()
      : pos = Offset.zero,
        radius = 0,
        vx = 0,
        vy = 0,
        alpha = 0,
        life = 0,
        relX = 0,
        resolved = false,
        alive = false;
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double relX;

  _ParticlesPainter({
    required this.particles,
    required this.color,
    required this.relX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      if (!p.alive) continue;
      if (!p.resolved) {
        p.pos = Offset(p.relX * size.width, size.height / 2);
        p.resolved = true;
      }
      paint.color = color.withValues(alpha: p.alpha);
      canvas.drawCircle(p.pos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => true;
}
