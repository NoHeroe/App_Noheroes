import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../../domain/models/shop_spec.dart';

// Tela /shops — lista as lojas que o jogador pode acessar.
class ShopsListScreen extends ConsumerStatefulWidget {
  const ShopsListScreen({super.key});
  @override
  ConsumerState<ShopsListScreen> createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends ConsumerState<ShopsListScreen> {
  Future<List<ShopSpec>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      setState(() => _future = Future.value(const []));
      return;
    }
    final snapshot = PlayerSnapshot(
      level:      player.level,
      rank:       ItemEquipPolicy.parseRank(player.guildRank),
      classKey:   player.classType,
      factionKey: player.factionType,
    );
    setState(() => _future = ref
        .read(shopsServiceProvider)
        .listShopsAvailableTo(snapshot));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<ShopSpec>>(
                future: _future,
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.gold),
                    );
                  }
                  final shops = snap.data ?? const <ShopSpec>[];
                  if (shops.isEmpty) return _EmptyView();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    itemCount: shops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ShopCard(
                      shop: shops[i],
                      onTap: () => context.go('/shop/${shops[i].key}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textSecondary, size: 20),
            onPressed: () => context.go('/sanctuary'),
          ),
          Expanded(
            child: Center(
              child: Text(
                'MERCADO',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 15,
                  color: AppColors.gold,
                  letterSpacing: 5,
                ),
              ),
            ),
          ),
          Consumer(
            builder: (_, ref, __) {
              final p = ref.watch(currentPlayerProvider);
              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text('🪙 ${p?.gold ?? 0}',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.gold)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final ShopSpec shop;
  final VoidCallback onTap;
  const _ShopCard({required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = shop.type == 'guild'
        ? AppColors.gold
        : AppColors.purpleLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.1),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Icon(
                shop.type == 'guild'
                    ? Icons.shield_outlined
                    : Icons.store_outlined,
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(shop.description,
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text('${shop.items.length} itens',
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: accent.withValues(alpha: 0.85))),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: accent.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined,
                color: AppColors.textMuted.withValues(alpha: 0.4), size: 44),
            const SizedBox(height: 18),
            Text('Nenhuma loja acessível.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(
              'A Loja da Guilda exige rank. Entra na Guilda pra destravar.',
              style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
