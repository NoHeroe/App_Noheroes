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
    final shadowName = player?.shadowName ?? 'Sombra';
    final level = player?.level ?? 1;
    final email = player?.email ?? '';

    final items = [
      _DrawerItem('Perfil', Icons.person_outline, () {}),
      _DrawerItem('Histórico de Missões', Icons.history, () {}),
      _DrawerItem('Conquistas', Icons.emoji_events_outlined, () {}),
      _DrawerItem('Lista de Amigos', Icons.group_outlined, () {}),
      _DrawerItem('Meus Produtos', Icons.book_outlined, () {}),
      _DrawerItem('Configurações', Icons.settings_outlined, () {}),
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
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.purple),
                      color: AppColors.shadowVoid,
                    ),
                    child: const Icon(Icons.blur_circular,
                        color: AppColors.purple, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(shadowName,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 18, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Nível $level · Sombra Sem Classe',
                      style: GoogleFonts.roboto(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(email,
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children:
                    items.map((item) => _DrawerTile(item: item)).toList(),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: _DrawerTile(
                item: _DrawerItem('Sair', Icons.logout,
                    () => _showLogoutDialog(context, ref)),
                isLogout: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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
        content: Text('Sua sombra permanecerá aguardando seu retorno.',
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

class _DrawerItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _DrawerItem(this.label, this.icon, this.onTap);
}

class _DrawerTile extends StatelessWidget {
  final _DrawerItem item;
  final bool isLogout;
  const _DrawerTile({required this.item, this.isLogout = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: item.onTap,
      leading: Icon(item.icon,
          color: isLogout ? AppColors.hp : AppColors.textSecondary, size: 20),
      title: Text(item.label,
          style: GoogleFonts.roboto(
              fontSize: 14,
              color: isLogout ? AppColors.hp : AppColors.textPrimary)),
      trailing: isLogout
          ? null
          : const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
    );
  }
}
