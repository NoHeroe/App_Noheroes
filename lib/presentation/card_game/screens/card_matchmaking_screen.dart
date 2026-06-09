import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

/// Tela de "procurar partida" do Modo Cartas (ACDA).
///
/// Funcional/estrutural — recebe o `mode` por query param. Para `pve` simula
/// um breve preparo e navega pra prévia da partida. Outros modos exibem um
/// estado "em breve".
class CardMatchmakingScreen extends StatefulWidget {
  const CardMatchmakingScreen({super.key, required this.mode});

  final String mode;

  @override
  State<CardMatchmakingScreen> createState() => _CardMatchmakingScreenState();
}

class _CardMatchmakingScreenState extends State<CardMatchmakingScreen> {
  Timer? _timer;

  bool get _isPve => widget.mode == 'pve';

  @override
  void initState() {
    super.initState();
    if (_isPve) {
      _timer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        context.go('/card-game/match?mode=pve');
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [Color(0xFF101830), Color(0xFF0A000A), AppColors.black],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _Header(onBack: () => context.go('/battle')),
                Expanded(
                  child: Center(
                    child: _isPve ? _pveBody() : _soonBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pveBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.conceptCelestial),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Preparando partida contra a IA…',
          style: GoogleFonts.cinzelDecorative(
              fontSize: 14, color: AppColors.textPrimary, letterSpacing: 1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Embaralhando criaturas e relíquias de Caelum.',
          style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _soonBody() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 20),
          Text(
            'Em breve',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 16, color: AppColors.gold, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Este modo precisa do servidor online dedicado, ainda em construção.',
            style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.go('/battle'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROCURANDO PARTIDA',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: AppColors.conceptCelestial,
                        letterSpacing: 2)),
                Text('Modo Cartas — ACDA',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
