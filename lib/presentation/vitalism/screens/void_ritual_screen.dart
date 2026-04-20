import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/vitalism_unique_service.dart';
import '../../../domain/enums/affinity_tier.dart';

// Ritual do Vazio de Caelum — despertar do Vitalismo da Vida.
// Tela imersiva. O jogador ATRAVESSA ela, não é um popup.
// Ver [[vitalismos_unicos#O Vazio de Caelum]] e Sprint 1.2 Bloco 4.
//
// TODO asset: lottie do Vazio pra substituir o _VoidBackdrop procedural.
// TODO asset: som ritualístico em _sacrifice() (pubspec não tem audioplayers).
class VoidRitualScreen extends ConsumerStatefulWidget {
  const VoidRitualScreen({super.key});

  @override
  ConsumerState<VoidRitualScreen> createState() => _VoidRitualScreenState();
}

enum _Phase {
  loading,
  blocked,
  invoking,
  selecting,
  confirming,
  sacrificing,
  ascending,
}

class _VoidRitualScreenState extends ConsumerState<VoidRitualScreen> {
  _Phase _phase = _Phase.loading;
  List<OwnedAffinity> _rares = const [];
  final Set<String> _selected = {};
  int _pointsGained = 0;
  int? _playerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      if (mounted) context.go('/login');
      return;
    }
    _playerId = player.id;

    final svc = ref.read(vitalismUniqueServiceProvider);
    final owned = await svc.ownedAffinitiesOf(player.id);
    final rares = owned.where((e) => e.tier == AffinityTier.rare).toList();

    if (!mounted) return;

    if (rares.length < 3) {
      setState(() {
        _rares = rares;
        _phase = _Phase.blocked;
      });
      return;
    }

    setState(() {
      _rares = rares;
      _phase = _Phase.invoking;
    });
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    setState(() => _phase = _Phase.selecting);
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < 3) {
        _selected.add(id);
      }
    });
  }

  Future<void> _askConfirm() async {
    if (_selected.length != 3) return;
    setState(() => _phase = _Phase.confirming);
  }

  void _abortConfirmation() {
    setState(() => _phase = _Phase.selecting);
  }

  Future<void> _sacrifice() async {
    setState(() => _phase = _Phase.sacrificing);
    final svc = ref.read(vitalismUniqueServiceProvider);
    final pid = _playerId!;
    final points = await svc.performLifeRitual(pid, _selected.toList());
    // Pausa dramática — mesmo que o banco responda em ms.
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    setState(() {
      _pointsGained = points ?? 0;
      _phase = _Phase.ascending;
    });
  }

  Future<void> _finish() async {
    // Regra 4 + 9: invalida stream antes de navegar; ctx.go é último passo.
    unawaited(ref.refresh(playerStreamProvider.future));
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    context.go('/vitalism');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _VoidBackdrop(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 650),
              child: KeyedSubtree(
                key: ValueKey(_phase),
                child: _buildPhase(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.loading:
        return const _LoadingView();
      case _Phase.blocked:
        return _BlockedView(
          raresOwned: _rares.length,
          onLeave: () => context.go('/sanctuary'),
        );
      case _Phase.invoking:
        return const _InvokingView();
      case _Phase.selecting:
        return _SelectingView(
          rares: _rares,
          selected: _selected,
          onToggle: _toggleSelect,
          onConfirm: _askConfirm,
        );
      case _Phase.confirming:
        return _ConfirmingView(
          selected: _rares.where((r) => _selected.contains(r.id)).toList(),
          onAbort: _abortConfirmation,
          onCommit: _sacrifice,
        );
      case _Phase.sacrificing:
        return _SacrificingView(
          selected: _rares.where((r) => _selected.contains(r.id)).toList(),
        );
      case _Phase.ascending:
        return _AscendingView(
          points: _pointsGained,
          onContinue: _finish,
        );
    }
  }
}

// ── Fundo ritualístico ──────────────────────────────────────────────────────

class _VoidBackdrop extends StatelessWidget {
  const _VoidBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.4,
          colors: [
            Color(0xFF1A0A2E),
            Color(0xFF0A0010),
            AppColors.black,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: List.generate(24, (i) => _Particle(seed: i)),
      ),
    );
  }
}

class _Particle extends StatelessWidget {
  final int seed;
  const _Particle({required this.seed});

  @override
  Widget build(BuildContext context) {
    final rng = Random(seed);
    final top  = rng.nextDouble();
    final left = rng.nextDouble();
    final size = 2.0 + rng.nextDouble() * 3.5;
    final delay = Duration(milliseconds: rng.nextInt(3200));
    final dur   = Duration(milliseconds: 2400 + rng.nextInt(2400));

    return Positioned(
      top: MediaQuery.of(context).size.height * top,
      left: MediaQuery.of(context).size.width * left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.purple.withValues(alpha: 0.75),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.6),
              blurRadius: 6,
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: dur, delay: delay)
          .then()
          .fadeOut(duration: dur),
    );
  }
}

// ── Fases ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.purple,
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final int raresOwned;
  final VoidCallback onLeave;
  const _BlockedView({required this.raresOwned, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, color: AppColors.textMuted, size: 42)
              .animate()
              .fadeIn(duration: 800.ms),
          const SizedBox(height: 24),
          Text(
            'O Vazio não responde ao teu chamado.',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.textPrimary,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 900.ms),
          const SizedBox(height: 18),
          Text(
            'É preciso trazer três Raros — teus ou tomados.\n\n'
            'Atualmente em ti: $raresOwned.',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms, duration: 900.ms),
          const SizedBox(height: 40),
          _MutedButton(label: 'Retornar', onTap: onLeave)
              .animate()
              .fadeIn(delay: 1200.ms, duration: 800.ms),
        ],
      ),
    );
  }
}

class _InvokingView extends StatelessWidget {
  const _InvokingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'O VAZIO DE CAELUM',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                color: AppColors.purpleLight,
                letterSpacing: 6,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 1400.ms)
                .then()
                .shimmer(duration: 1200.ms, color: AppColors.purpleGlow),
            const SizedBox(height: 28),
            Text(
              'Tu o invocaste.\nEle te escuta.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.7,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 900.ms, duration: 1200.ms),
          ],
        ),
      ),
    );
  }
}

class _SelectingView extends StatelessWidget {
  final List<OwnedAffinity> rares;
  final Set<String> selected;
  final void Function(String) onToggle;
  final VoidCallback onConfirm;

  const _SelectingView({
    required this.rares,
    required this.selected,
    required this.onToggle,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final ready = selected.length == 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        children: [
          Text(
            'ESCOLHE OS TRÊS',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.purpleLight,
              letterSpacing: 5,
            ),
          ).animate().fadeIn(duration: 900.ms),
          const SizedBox(height: 8),
          Text(
            'que hão de se desfazer em ti.',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 900.ms),
          const SizedBox(height: 16),
          _Counter(value: selected.length, max: 3),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: rares.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final r = rares[i];
                final isSelected = selected.contains(r.id);
                return _RareCard(
                  affinity: r,
                  selected: isSelected,
                  dimmed: !isSelected && selected.length >= 3,
                  onTap: () => onToggle(r.id),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: 'Invocar o ritual',
            enabled: ready,
            destructive: true,
            onTap: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _ConfirmingView extends StatelessWidget {
  final List<OwnedAffinity> selected;
  final VoidCallback onAbort;
  final VoidCallback onCommit;

  const _ConfirmingView({
    required this.selected,
    required this.onAbort,
    required this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ISTO É IRREVERSÍVEL',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              color: AppColors.hp,
              letterSpacing: 5,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 18),
          Text(
            'Ao confirmar, estes três se desfarão em ti.\n'
            'Toda afinidade que hoje possuis será canalizada.\n'
            'No fim, apenas a Vida restará.',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
          const SizedBox(height: 24),
          for (final r in selected) ...[
            _DoomedCard(affinity: r),
            const SizedBox(height: 8),
          ],
          const Spacer(),
          _PrimaryButton(
            label: 'Sacrificar',
            enabled: true,
            destructive: true,
            onTap: onCommit,
          ),
          const SizedBox(height: 10),
          _MutedButton(label: 'Desistir', onTap: onAbort),
        ],
      ),
    );
  }
}

class _SacrificingView extends StatelessWidget {
  final List<OwnedAffinity> selected;
  const _SacrificingView({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'O VAZIO RECEBE',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.purpleLight,
              letterSpacing: 5,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 1400.ms)
              .then()
              .fadeOut(duration: 1400.ms),
          const SizedBox(height: 32),
          for (final r in selected) ...[
            _DoomedCard(affinity: r)
                .animate()
                .fadeOut(delay: 800.ms, duration: 1800.ms)
                .blur(
                  begin: const Offset(0, 0),
                  end: const Offset(8, 8),
                  delay: 800.ms,
                  duration: 1800.ms,
                ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AscendingView extends StatelessWidget {
  final int points;
  final VoidCallback onContinue;
  const _AscendingView({required this.points, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'O VITALISMO DA VIDA',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.shadowAscending,
              letterSpacing: 5,
            ),
          ).animate().fadeIn(duration: 1600.ms),
          const SizedBox(height: 10),
          Text(
            'desperta em ti.',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 18,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ).animate().fadeIn(delay: 800.ms, duration: 1400.ms),
          const SizedBox(height: 40),
          Text(
            '$points',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 54,
              color: AppColors.gold,
              letterSpacing: 4,
            ),
          )
              .animate()
              .fadeIn(delay: 1800.ms, duration: 900.ms)
              .scale(delay: 1800.ms, duration: 900.ms,
                  begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          const SizedBox(height: 8),
          Text(
            'pontos canalizados',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ).animate().fadeIn(delay: 2100.ms, duration: 900.ms),
          const Spacer(),
          _PrimaryButton(
            label: 'Continuar',
            enabled: true,
            destructive: false,
            onTap: onContinue,
          ).animate().fadeIn(delay: 2600.ms, duration: 900.ms),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _Counter extends StatelessWidget {
  final int value;
  final int max;
  const _Counter({required this.value, required this.max});
  @override
  Widget build(BuildContext context) {
    return Text(
      '$value  de  $max',
      style: GoogleFonts.cinzelDecorative(
        fontSize: 16,
        color: value == max ? AppColors.hp : AppColors.textSecondary,
        letterSpacing: 4,
      ),
    );
  }
}

class _RareCard extends StatelessWidget {
  final OwnedAffinity affinity;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _RareCard({
    required this.affinity,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.hp.withValues(alpha: 0.7)
        : AppColors.border;
    final bg = selected
        ? AppColors.hp.withValues(alpha: 0.08)
        : AppColors.surface;
    final opacity = dimmed ? 0.4 : 1.0;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: dimmed ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.hp : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      affinity.name,
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      affinity.themeDescription,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoomedCard extends StatelessWidget {
  final OwnedAffinity affinity;
  const _DoomedCard({required this.affinity});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.hp.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.hp.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.whatshot, color: AppColors.hp.withValues(alpha: 0.75),
              size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              affinity.name,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 12,
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool destructive;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.destructive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = destructive ? AppColors.hp : AppColors.purple;
    final color = enabled ? base : AppColors.textMuted;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.cinzelDecorative(
            fontSize: 13,
            color: color,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

class _MutedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MutedButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: GoogleFonts.roboto(
          color: AppColors.textMuted,
          fontSize: 13,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
