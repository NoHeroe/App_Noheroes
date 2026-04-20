import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/asset_loader.dart';
import '../../../data/datasources/local/vitalism_unique_service.dart';
import '../../shared/widgets/npc_dialog_overlay.dart';
import '../widgets/crystal_obsidian_widget.dart';

// Cerimônia do Cristal de Obsidiana — despertar inicial do Vitalismo Único.
// Tela única, acessada uma vez por vitalista ao chegar no nível 25 sem afinidade.
// Ver [[vitalismos_unicos#O Cristal de Obsidiana do Dragão]].
class CrystalCeremonyScreen extends ConsumerStatefulWidget {
  const CrystalCeremonyScreen({super.key});

  @override
  ConsumerState<CrystalCeremonyScreen> createState() =>
      _CrystalCeremonyScreenState();
}

enum _Phase {
  loading,     // busca NPC da facção + valida pré-requisitos
  presenting,  // cristal exibido + prompt "toca o Cristal"
  awakening,   // chamando awakeFromCrystal + pausa dramática
  revealed,    // mostra o Vitalismo despertado ou "nenhum se manifestou"
}

class _CrystalCeremonyScreenState
    extends ConsumerState<CrystalCeremonyScreen> {
  _Phase _phase = _Phase.loading;
  int? _playerId;
  OwnedAffinity? _awakened;
  bool _emptyPool = false;

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

    // Guard interno: cerimônia é única. Se já tem afinidade, volta.
    final existing = await svc.ownedAffinitiesOf(player.id);
    if (existing.isNotEmpty) {
      if (mounted) context.go('/sanctuary');
      return;
    }

    // NPC da facção introduz a cerimônia (Regra 10 — NpcDialogOverlay padrão).
    final npc = await AssetLoader.getNpcIdentity(player.factionType);
    if (!mounted) return;

    await NpcDialogOverlay.show(
      context,
      npcName:  npc['name']  ?? '???',
      npcTitle: npc['title'] ?? '',
      message:  'O Cristal te aguarda. Toca-o.',
    );
    if (!mounted) return;

    setState(() => _phase = _Phase.presenting);
  }

  Future<void> _touchCrystal() async {
    if (_phase != _Phase.presenting) return;
    setState(() => _phase = _Phase.awakening);

    final svc = ref.read(vitalismUniqueServiceProvider);
    await svc.awakeFromCrystal(_playerId!);

    // Pausa dramática
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final owned = await svc.ownedAffinitiesOf(_playerId!);
    setState(() {
      if (owned.isEmpty) {
        _emptyPool = true;
      } else {
        _awakened = owned.first;
      }
      _phase = _Phase.revealed;
    });
  }

  Future<void> _finish() async {
    // Regra 4 + 9: invalida stream, delay, ctx.go último passo.
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
          _buildBackdrop(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
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

  Widget _buildBackdrop() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.3,
          colors: [
            Color(0xFF1A0A2E),
            Color(0xFF0A0010),
            AppColors.black,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.purple,
          ),
        );
      case _Phase.presenting:
        return _PresentingView(onTouch: _touchCrystal);
      case _Phase.awakening:
        return const _AwakeningView();
      case _Phase.revealed:
        return _RevealedView(
          awakened: _awakened,
          emptyPool: _emptyPool,
          onContinue: _finish,
        );
    }
  }
}

class _PresentingView extends StatelessWidget {
  final VoidCallback onTouch;
  const _PresentingView({required this.onTouch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'CERIMÔNIA DO DESPERTAR',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.purpleLight,
              letterSpacing: 5,
            ),
          ).animate().fadeIn(duration: 900.ms),
          const Spacer(),
          GestureDetector(
            onTap: onTouch,
            child: const CrystalObsidianWidget(height: 240),
          )
              .animate()
              .fadeIn(duration: 1400.ms)
              .slideY(begin: 0.12, end: 0, duration: 1400.ms, curve: Curves.easeOut),
          const Spacer(),
          Text(
            'Toca o Cristal.',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.textPrimary,
              letterSpacing: 3,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 1100.ms)
              .then()
              .fadeOut(duration: 1100.ms),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _AwakeningView extends StatelessWidget {
  const _AwakeningView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'O CRISTAL RESPONDE',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              color: AppColors.purpleLight,
              letterSpacing: 5,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 1000.ms)
              .then()
              .fadeOut(duration: 1000.ms),
          const Spacer(),
          const CrystalObsidianWidget(height: 240, pulsing: false)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 1100.ms, color: AppColors.purpleLight)
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.07, 1.07),
                duration: 1100.ms,
                curve: Curves.easeInOut,
              ),
          const Spacer(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _RevealedView extends StatelessWidget {
  final OwnedAffinity? awakened;
  final bool emptyPool;
  final VoidCallback onContinue;

  const _RevealedView({
    required this.awakened,
    required this.emptyPool,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (awakened != null) ..._awakened(context) else ..._empty(context),
          const Spacer(),
          _ContinueButton(onTap: onContinue)
              .animate()
              .fadeIn(delay: 2400.ms, duration: 900.ms),
        ],
      ),
    );
  }

  List<Widget> _awakened(BuildContext context) {
    final a = awakened!;
    return [
      Text(
        'TUA AFINIDADE DESPERTA',
        style: GoogleFonts.cinzelDecorative(
          fontSize: 12,
          color: AppColors.purpleLight,
          letterSpacing: 5,
        ),
      ).animate().fadeIn(duration: 1200.ms),
      const SizedBox(height: 28),
      Text(
        a.name,
        style: GoogleFonts.cinzelDecorative(
          fontSize: 24,
          color: AppColors.gold,
          letterSpacing: 2,
        ),
        textAlign: TextAlign.center,
      )
          .animate()
          .fadeIn(delay: 700.ms, duration: 1100.ms)
          .scale(
              delay: 700.ms, duration: 1100.ms,
              begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),
      const SizedBox(height: 16),
      Text(
        a.carrierName,
        style: GoogleFonts.cinzelDecorative(
          fontSize: 12,
          color: AppColors.textSecondary,
          letterSpacing: 3,
        ),
      ).animate().fadeIn(delay: 1400.ms, duration: 900.ms),
      const SizedBox(height: 30),
      Text(
        a.themeDescription,
        style: GoogleFonts.roboto(
          fontSize: 13,
          color: AppColors.textPrimary,
          fontStyle: FontStyle.italic,
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 1900.ms, duration: 900.ms),
    ];
  }

  List<Widget> _empty(BuildContext context) {
    return [
      const Icon(
        Icons.hourglass_empty,
        size: 52,
        color: AppColors.textMuted,
      ).animate().fadeIn(duration: 1100.ms),
      const SizedBox(height: 28),
      Text(
        'NENHUM SE MANIFESTOU',
        style: GoogleFonts.cinzelDecorative(
          fontSize: 14,
          color: AppColors.textMuted,
          letterSpacing: 5,
        ),
      ).animate().fadeIn(delay: 700.ms, duration: 1100.ms),
      const SizedBox(height: 22),
      Text(
        'És vitalista, mas nenhum Vitalismo Único respondeu ao Cristal.\n\n'
        'Os canais estão ocupados por outros neste mundo.\n'
        'Terás de tomar o teu — em PvP.',
        style: GoogleFonts.roboto(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ).animate().fadeIn(delay: 1400.ms, duration: 1100.ms),
    ];
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ContinueButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.1),
          border:
              Border.all(color: AppColors.purple.withValues(alpha: 0.6), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'CONTINUAR',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 13,
            color: AppColors.purpleLight,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
