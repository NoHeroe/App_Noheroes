import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';

class SanctuaryDrawer extends ConsumerWidget {
  const SanctuaryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    final items = [
      _Item('Inventário',    Icons.inventory_2_outlined,  '/inventory'),
      _Item('Mercado',       Icons.store_outlined,         '/shop'),
      _Item('Conquistas',    Icons.emoji_events_outlined,  '/achievements'),
      _Item('Histórico',     Icons.history,                '/history'),
      _Item('Amigos',        Icons.group_outlined,         null),
      _Item('Meus Produtos', Icons.book_outlined,          null),
      _Item('Configurações', Icons.settings_outlined,      null),
    ];

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.purple),
                      color: AppColors.shadowVoid,
                    ),
                    child: const Icon(Icons.blur_circular,
                        color: AppColors.purple, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(player?.shadowName ?? 'Sombra',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Nível ${player?.level ?? 1} · Sem Classe',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: AppColors.textMuted)),
                  Text(player?.email ?? '',
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: items.map((item) => ListTile(
                  leading: Icon(item.icon,
                      color: AppColors.textSecondary, size: 20),
                  title: Text(item.label,
                      style: GoogleFonts.roboto(
                          fontSize: 14, color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textMuted, size: 18),
                  onTap: item.route != null
                      ? () {
                          Navigator.pop(context);
                          context.go(item.route!);
                        }
                      : null,
                )).toList(),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout,
                    color: AppColors.hp, size: 20),
                title: Text('Sair',
                    style: GoogleFonts.roboto(
                        fontSize: 14, color: AppColors.hp)),
                onTap: () => _logout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Sair de Caelum?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 16)),
        content: Text('Sua sombra permanecerá aguardando.',
            style: GoogleFonts.roboto(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ficar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authDsProvider).logout();
              ref.read(currentPlayerProvider.notifier).state = null;
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.go('/login');
              }
            },
            child: Text('Sair',
                style: GoogleFonts.roboto(color: AppColors.hp)),
          ),
        ],
      ),
    );
  }
}

class _Item {
  final String label;
  final IconData icon;
  final String? route;
  _Item(this.label, this.icon, this.route);
}
