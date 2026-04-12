import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/animated_bg.dart';
import '../../../core/widgets/mystic_title.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
      ),
    );
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.67, 1.0, curve: Curves.easeOut),
      ),
    );
    _ctrl.forward().whenComplete(_checkSession);
  }

  Future<void> _checkSession() async {
    if (!mounted) return;
    final ds = ref.read(authDsProvider);
    final player = await ds.currentSession();

    if (!mounted) return;
    if (player != null) {
      ref.read(currentPlayerProvider.notifier).state = player;
      if (player.onboardingDone) {
        context.go('/sanctuary');
      } else {
        context.go('/awakening');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBg(),
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final opacity =
                    (_fadeIn.value * _fadeOut.value).clamp(0.0, 1.0);
                return Opacity(opacity: opacity, child: child);
              },
              child: const MysticTitle(text: 'NoHeroes', fontSize: 36),
            ),
          ),
        ],
      ),
    );
  }
}
