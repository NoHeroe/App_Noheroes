import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/providers.dart';
import '../../core/constants/app_colors.dart';
import '../shared/widgets/app_snack.dart';
import '../shared/widgets/nh_atmosphere.dart';
import '../shared/widgets/nh_back_button.dart';
import 'settings_provider.dart';

/// Configurações do app — áudio, animações de fundo (toggle de performance),
/// conta (sincronizar) e conexão da conta NoHeroes ao site (recompensa).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const NhAtmosphere(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      NhBackButton(
                        onTap: () => context.canPop()
                            ? context.pop()
                            : context.go('/sanctuary'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _card('VISUAL', [
                        _toggle(
                          icon: Icons.auto_awesome,
                          label: 'Animações de fundo',
                          subtitle:
                              'Desligue para aliviar a performance em aparelhos mais fracos.',
                          value: settings.backgroundAnimations,
                          onChanged: notifier.setBackgroundAnimations,
                        ),
                      ]),
                      const SizedBox(height: 14),
                      _card('ÁUDIO', [
                        _toggle(
                          icon: Icons.volume_up_outlined,
                          label: 'Som',
                          value: settings.soundEnabled,
                          onChanged: notifier.setSound,
                        ),
                        const SizedBox(height: 4),
                        _toggle(
                          icon: Icons.music_note_outlined,
                          label: 'Música',
                          value: settings.musicEnabled,
                          onChanged: notifier.setMusic,
                        ),
                      ]),
                      const SizedBox(height: 14),
                      _card('CONTA', [
                        _action(
                          icon: Icons.sync,
                          label: 'Sincronizar conta',
                          subtitle: 'Recarrega seus dados do servidor.',
                          onTap: () => _sync(context, ref),
                        ),
                        const SizedBox(height: 10),
                        _connectCard(context),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    try {
      final updated = await ref.read(authDsProvider).currentSession();
      ref.read(currentPlayerProvider.notifier).state = updated;
      if (context.mounted) {
        AppSnack.success(context, 'Conta sincronizada.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnack.error(context, 'Não foi possível sincronizar.');
      }
    }
  }

  // ── Card de conexão com o site (recompensa) ─────────────────────────
  Widget _connectCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.12),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, size: 16, color: AppColors.goldLt),
              const SizedBox(width: 8),
              Text('Conectar ao site NoHeroes',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 12,
                      color: AppColors.goldLt,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Vincule sua conta ao site e ganhe uma recompensa única:',
            style: GoogleFonts.roboto(fontSize: 11, color: AppColors.txt2),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _RewardChip(icon: Icons.diamond_outlined, label: '15 Gemas'),
              _RewardChip(icon: Icons.monetization_on, label: '100 Ouro'),
              _RewardChip(
                  icon: Icons.inventory_2_outlined, label: '3 Pacotes'),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => AppSnack.warning(
                context, 'Conexão com o site em breve.'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.gold.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
              ),
              child: Text('CONECTAR',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: AppColors.goldLt)),
            ),
          ),
        ],
      ),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────
  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11, color: AppColors.gold, letterSpacing: 2)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _toggle({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.txt2),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.roboto(
                      fontSize: 13, color: AppColors.txt)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.txtMut, height: 1.3)),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.goldLt,
          activeTrackColor: AppColors.gold.withValues(alpha: 0.4),
        ),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.purpleLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.roboto(
                        fontSize: 13, color: AppColors.txt)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: AppColors.txtMut)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.txtMut, size: 18),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RewardChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xB3100C15),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.goldLt),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.txt)),
        ],
      ),
    );
  }
}
