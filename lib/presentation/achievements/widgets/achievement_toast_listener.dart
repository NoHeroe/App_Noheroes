import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/events/reward_events.dart';
import '../../../domain/models/achievement_definition.dart';
import '../../../domain/services/achievements_service.dart';
import 'achievement_unlocked_toast.dart';

/// Sprint 3.3 Etapa Final-B — wrapper que escuta `AchievementUnlocked`
/// no app event bus e exibe `AchievementUnlockedToast` em sequência via
/// `OverlayEntry`. Mount global em `MaterialApp.builder` garante toast
/// em qualquer rota.
///
/// Fila interna (`Queue<_PendingToast>`) processa um toast por vez —
/// cenário de cascata metaLike pode disparar 2-3 unlocks em sequência
/// rápida; sem fila viraria pilha visual confusa. Próximo toast aparece
/// quando o anterior dismiss (auto-timer 4s OU tap manual).
///
/// Disabled achievements (shell) NÃO geram toast.
class AchievementToastListener extends ConsumerStatefulWidget {
  final Widget child;
  const AchievementToastListener({super.key, required this.child});

  @override
  ConsumerState<AchievementToastListener> createState() =>
      _AchievementToastListenerState();
}

class _AchievementToastListenerState
    extends ConsumerState<AchievementToastListener> {
  StreamSubscription<AchievementUnlocked>? _sub;
  final Queue<AchievementDefinition> _queue = Queue();
  OverlayEntry? _active;
  Timer? _autoDismissTimer;

  static const _autoDismiss = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bus = ref.read(appEventBusProvider);
      _sub = bus.on<AchievementUnlocked>().listen(_onUnlocked);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _autoDismissTimer?.cancel();
    _active?.remove();
    _active = null;
    super.dispose();
  }

  Future<void> _onUnlocked(AchievementUnlocked evt) async {
    if (!mounted) return;
    final svc = ref.read(achievementsServiceProvider);
    await svc.ensureLoaded();
    final def = svc.catalog[evt.achievementKey];
    if (def == null) return;
    if (def.disabled) return; // shells não viram toast.
    _queue.add(def);
    if (_active == null) {
      _showNext();
    }
  }

  void _showNext() {
    if (_queue.isEmpty) {
      _active = null;
      return;
    }
    final def = _queue.removeFirst();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Sem overlay disponível (boot inicial ou teardown) — descarta o
      // resto da fila pra evitar fugas.
      _queue.clear();
      _active = null;
      return;
    }

    late OverlayEntry entry;
    void dismiss() {
      _autoDismissTimer?.cancel();
      _autoDismissTimer = null;
      if (entry.mounted) entry.remove();
      _active = null;
      // Próximo da fila com pequeno gap pra animação respirar.
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _showNext();
      });
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final mediaPadding = MediaQuery.of(ctx).padding;
        return Positioned(
          top: mediaPadding.top + 8,
          left: 16,
          right: 16,
          child: Center(
            child: AchievementUnlockedToast(
              def: def,
              onDismiss: dismiss,
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    _active = entry;
    _autoDismissTimer = Timer(_autoDismiss, dismiss);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
