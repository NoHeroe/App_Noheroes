import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/daily_mission_status.dart';
import '../../shared/widgets/player_stats_counter.dart';
import 'daily_pilar_visuals.dart';

/// Sprint 3.2 Etapa 1.3.C — popup overlay de conclusão de missão.
///
/// 3 modos visuais:
/// - **completed** (verde): "MISSÃO COMPLETA" + reward + 12 XP particles
///   verdes + 6 gold dourados voando em arco bezier pro [PlayerStatsCounter].
/// - **partial** (amarelo): "PARCIAL" + reward proporcional + ~50% das
///   partículas, todas amarelas.
/// - **failed** (vermelho): "FALHA" + ripple radial expandindo, sem
///   partículas e sem reward.
///
/// Padrão espelha [RewardToast]: classe estática `show(...)` insere
/// `OverlayEntry`. Self-dismiss após o ciclo completo (~2.5s).
class MissionCompletionPopup {
  static void show(
    BuildContext context, {
    required DailyMissionStatus status,
    required int rewardXp,
    required int rewardGold,
    required GlobalKey originKey,
    GlobalKey<PlayerStatsCounterState>? targetKey,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final mediaSize = MediaQuery.of(context).size;
    final mediaPadding = MediaQuery.of(context).padding;

    final originPos = _resolveCenter(originKey) ??
        Offset(mediaSize.width / 2, mediaSize.height / 2);
    final targetPos = _resolveCenter(targetKey) ??
        Offset(mediaSize.width - 70, mediaPadding.top + 40);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _PopupOverlay(
        status: status,
        rewardXp: rewardXp,
        rewardGold: rewardGold,
        originPos: originPos,
        targetPos: targetPos,
        onTargetReached: () => targetKey?.currentState?.pulse(),
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  static Offset? _resolveCenter(GlobalKey? key) {
    final ctx = key?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return Offset(
      topLeft.dx + box.size.width / 2,
      topLeft.dy + box.size.height / 2,
    );
  }
}

class _PopupOverlay extends StatefulWidget {
  final DailyMissionStatus status;
  final int rewardXp;
  final int rewardGold;
  final Offset originPos;
  final Offset targetPos;
  final VoidCallback onTargetReached;
  final VoidCallback onDismiss;

  const _PopupOverlay({
    required this.status,
    required this.rewardXp,
    required this.rewardGold,
    required this.originPos,
    required this.targetPos,
    required this.onTargetReached,
    required this.onDismiss,
  });

  @override
  State<_PopupOverlay> createState() => _PopupOverlayState();
}

class _PopupOverlayState extends State<_PopupOverlay>
    with SingleTickerProviderStateMixin {
  // Timeline (ms):
  static const int _fadeInMs = 200;
  static const int _holdMs = 600;
  static const int _staggerMs = 30;
  static const int _travelMs = 800;
  static const int _fadeOutMs = 300;
  // Total = fadeIn + hold + (stagger × particles) + travel + fadeOut.

  late final AnimationController _ctl;
  late final List<_FlyingParticle> _particles;
  bool _targetPulseFired = false;
  late final int _totalMs;

  @override
  void initState() {
    super.initState();
    _particles = _buildParticles();
    final lastSpawnMs = _fadeInMs + _holdMs +
        (_staggerMs * (_particles.isEmpty ? 0 : _particles.length - 1));
    _totalMs = lastSpawnMs + _travelMs + _fadeOutMs;
    _ctl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs),
    )..addListener(_onTick);
    _ctl.forward().whenComplete(widget.onDismiss);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _onTick() {
    setState(() {});
    if (!_targetPulseFired) {
      // Dispara pulse no counter quando a primeira partícula chega
      // (~last spawn não — primeira é mais natural).
      final firstArrival =
          (_fadeInMs + _holdMs + _travelMs) / _totalMs;
      if (_ctl.value >= firstArrival) {
        _targetPulseFired = true;
        widget.onTargetReached();
      }
    }
  }

  List<_FlyingParticle> _buildParticles() {
    int xpCount, goldCount;
    Color xpColor, goldColor;
    switch (widget.status) {
      case DailyMissionStatus.completed:
        xpCount = 12;
        goldCount = 6;
        xpColor = const Color(0xFF4ADE80);
        goldColor = const Color(0xFFFBBF24);
        break;
      case DailyMissionStatus.partial:
        xpCount = 6;
        goldCount = 3;
        xpColor = const Color(0xFFC9A14A);
        goldColor = const Color(0xFFC9A14A);
        break;
      case DailyMissionStatus.failed:
      case DailyMissionStatus.pending:
        return const [];
    }
    final rand = math.Random();
    final list = <_FlyingParticle>[];
    for (int i = 0; i < xpCount; i++) {
      list.add(_FlyingParticle(
        spawnIndex: list.length,
        color: xpColor,
        radius: 2.0 + rand.nextDouble() * 1.0,
        controlOffsetY:
            -(60 + rand.nextDouble() * 40), // arco ~60-100px acima
        wobble: (rand.nextDouble() - 0.5) * 30,
      ));
    }
    for (int i = 0; i < goldCount; i++) {
      list.add(_FlyingParticle(
        spawnIndex: list.length,
        color: goldColor,
        radius: 2.5 + rand.nextDouble() * 1.0,
        controlOffsetY: -(60 + rand.nextDouble() * 40),
        wobble: (rand.nextDouble() - 0.5) * 30,
      ));
    }
    list.shuffle(rand);
    return list;
  }

  double get _phaseFadeIn {
    final tMs = _ctl.value * _totalMs;
    return (tMs / _fadeInMs).clamp(0.0, 1.0);
  }

  double get _phaseFadeOut {
    final tMs = _ctl.value * _totalMs;
    final fadeOutStart = _totalMs - _fadeOutMs;
    if (tMs < fadeOutStart) return 1.0;
    return (1.0 - (tMs - fadeOutStart) / _fadeOutMs).clamp(0.0, 1.0);
  }

  double get _ripplePhase {
    if (widget.status != DailyMissionStatus.failed) return 0.0;
    final tMs = _ctl.value * _totalMs;
    if (tMs < _fadeInMs) return 0.0;
    final start = _fadeInMs.toDouble();
    const dur = 600.0;
    return ((tMs - start) / dur).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    return IgnorePointer(
      child: SizedBox(
        width: mediaSize.width,
        height: mediaSize.height,
        child: Stack(
          children: [
            // Ripple (failed only).
            if (widget.status == DailyMissionStatus.failed && _ripplePhase > 0)
              Positioned(
                left: widget.originPos.dx - 100,
                top: widget.originPos.dy - 100,
                child: IgnorePointer(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _RipplePainter(
                        phase: _ripplePhase,
                        color: DailyPilarVisuals.failedColor,
                      ),
                    ),
                  ),
                ),
              ),
            // Popup central.
            Positioned(
              left: widget.originPos.dx - 100,
              top: widget.originPos.dy - 30,
              width: 200,
              child: Opacity(
                opacity: _phaseFadeIn * _phaseFadeOut,
                child: _PopupCard(
                  status: widget.status,
                  rewardXp: widget.rewardXp,
                  rewardGold: widget.rewardGold,
                ),
              ),
            ),
            // Partículas voadoras.
            if (_particles.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlesPainter(
                    particles: _particles,
                    origin: widget.originPos,
                    target: widget.targetPos,
                    elapsedMs: _ctl.value * _totalMs,
                    staggerMs: _staggerMs.toDouble(),
                    burstStartMs: (_fadeInMs + _holdMs).toDouble(),
                    travelMs: _travelMs.toDouble(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PopupCard extends StatelessWidget {
  final DailyMissionStatus status;
  final int rewardXp;
  final int rewardGold;

  const _PopupCard({
    required this.status,
    required this.rewardXp,
    required this.rewardGold,
  });

  @override
  Widget build(BuildContext context) {
    late String title;
    late Color color;
    String? rewardLine;
    switch (status) {
      case DailyMissionStatus.completed:
        title = 'MISSÃO COMPLETA';
        color = AppColors.shadowAscending;
        rewardLine = '+$rewardXp XP  +$rewardGold gold';
        break;
      case DailyMissionStatus.partial:
        title = 'PARCIAL';
        color = DailyPilarVisuals.partialColor;
        rewardLine = '+$rewardXp XP  +$rewardGold gold (proporcional)';
        break;
      case DailyMissionStatus.failed:
        title = 'FALHA';
        color = DailyPilarVisuals.failedColor;
        rewardLine = null;
        break;
      case DailyMissionStatus.pending:
        title = '';
        color = AppColors.textMuted;
        rewardLine = null;
    }
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                color: color,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (rewardLine != null) ...[
              const SizedBox(height: 6),
              Text(
                rewardLine,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlyingParticle {
  final int spawnIndex;
  final Color color;
  final double radius;
  final double controlOffsetY; // arco mais alto que origem/destino
  final double wobble; // jitter horizontal no path

  const _FlyingParticle({
    required this.spawnIndex,
    required this.color,
    required this.radius,
    required this.controlOffsetY,
    required this.wobble,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_FlyingParticle> particles;
  final Offset origin;
  final Offset target;
  final double elapsedMs;
  final double staggerMs;
  final double burstStartMs;
  final double travelMs;

  _ParticlesPainter({
    required this.particles,
    required this.origin,
    required this.target,
    required this.elapsedMs,
    required this.staggerMs,
    required this.burstStartMs,
    required this.travelMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final spawnMs = burstStartMs + p.spawnIndex * staggerMs;
      final dt = elapsedMs - spawnMs;
      if (dt < 0) continue;
      final t = (dt / travelMs).clamp(0.0, 1.0);
      // Ease-out cubic.
      final eased = 1 - math.pow(1 - t, 3).toDouble();
      final pos = _bezier(origin, target, p.controlOffsetY, p.wobble, eased);
      // Fade out near end.
      final alpha = t < 0.85 ? 1.0 : (1.0 - (t - 0.85) / 0.15).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(pos, p.radius, paint);
    }
  }

  Offset _bezier(
      Offset a, Offset b, double controlOffsetY, double wobble, double t) {
    final mid = Offset(
      (a.dx + b.dx) / 2 + wobble,
      math.min(a.dy, b.dy) + controlOffsetY,
    );
    final u = 1 - t;
    final x = u * u * a.dx + 2 * u * t * mid.dx + t * t * b.dx;
    final y = u * u * a.dy + 2 * u * t * mid.dy + t * t * b.dy;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => true;
}

class _RipplePainter extends CustomPainter {
  final double phase; // 0..1
  final Color color;

  _RipplePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (phase <= 0 || phase >= 1) return;
    final radius = 100 * phase;
    final alpha = (1 - phase).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - phase * 0.5);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.phase != phase;
}
