import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../card_economy.dart';

/// Aba "Mercado" da tela de Pacotes — loja semanal do card game (Bloco 6).
/// Estoque fixo em ouro (limite semanal; além do limite custa gemas) + 1 slot
/// rotativo épico+ por gemas. Server-authoritative (cg_shop_state / cg_shop_buy).
class WeeklyShopSection extends ConsumerStatefulWidget {
  const WeeklyShopSection({super.key});

  @override
  ConsumerState<WeeklyShopSection> createState() => _WeeklyShopSectionState();
}

class _WeeklyShopSectionState extends ConsumerState<WeeklyShopSection> {
  Map<String, dynamic>? _state;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final st = await ref.read(cardEconomyServiceProvider).shopState(player.id);
      if (!mounted) return;
      setState(() {
        _state = st['ok'] == true ? st : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.roboto(color: AppColors.txt)),
        backgroundColor: ok ? const Color(0xFF14331E) : const Color(0xFF1A1326),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _buy(String itemKey) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final p = ref.read(currentPlayerProvider)!;
      final r = await ref.read(cardEconomyServiceProvider).shopBuy(p.id, itemKey);
      if (r.ok) {
        _snack('Comprado!', ok: true);
        ref.invalidate(cgResourcesProvider);
        final updated = await ref.read(authDsProvider).currentSession();
        if (mounted && updated != null) {
          ref.read(currentPlayerProvider.notifier).state = updated;
        }
        await _load();
      } else {
        _snack(switch (r.reason) {
          'insufficient_gold' => 'Ouro insuficiente',
          'insufficient_gems' => 'Gemas insuficientes',
          _ => 'Não foi possível comprar.',
        });
      }
    } catch (_) {
      _snack('Erro de rede. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.purpleLt, strokeWidth: 2.4),
      );
    }
    final st = _state;
    if (st == null) {
      return Center(
        child: Text('Mercado indisponível.',
            style: GoogleFonts.roboto(color: AppColors.txtMut)),
      );
    }
    final items = (st['items'] as List?) ?? const [];
    final rot = st['rotative'] as Map?;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('LOJA SEMANAL',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 14, color: AppColors.goldLt, letterSpacing: 1.5)),
        const SizedBox(height: 2),
        Text('Renova toda semana. Acima do limite, custa gemas.',
            style: GoogleFonts.roboto(fontSize: 10.5, color: AppColors.txtMut)),
        const SizedBox(height: 12),
        if (rot != null) _rotativeCard(rot),
        const SizedBox(height: 10),
        for (final raw in items) _itemCard((raw as Map).cast<String, dynamic>()),
      ],
    );
  }

  Widget _itemCard(Map<String, dynamic> it) {
    final bought = (it['bought'] as num? ?? 0).toInt();
    final limit = (it['weekly_limit'] as num? ?? 0).toInt();
    final useGems = bought >= limit;
    final priceGold = (it['price_gold'] as num).toInt();
    final priceGems = (it['price_gems'] as num).toInt();
    final amount = (it['amount'] as num).toInt();
    return _shopRow(
      name: it['display_name'] as String? ?? '',
      sub: 'x$amount · $bought/$limit esta semana',
      priceLabel: useGems ? '$priceGems' : '$priceGold',
      gems: useGems,
      icon: _iconFor(it['item_key'] as String? ?? ''),
      onTap: () => _buy(it['item_key'] as String),
    );
  }

  Widget _rotativeCard(Map rot) {
    return _shopRow(
      name: '${rot['name']}',
      sub: 'x${rot['amount']} · oferta rotativa da semana',
      priceLabel: '${rot['gems']}',
      gems: true,
      highlight: true,
      icon: Icons.star,
      onTap: () => _buy('rotative'),
    );
  }

  /// Ícone que simboliza o item da loja (CEO 2026-06-12: ícone à esquerda).
  IconData _iconFor(String key) {
    if (key.contains('shard') || key.contains('lasca')) {
      return Icons.layers_outlined;
    }
    if (key.contains('soul') ||
        key.contains('essence') ||
        key.contains('essenc') ||
        key.contains('emblem')) {
      return Icons.auto_awesome;
    }
    if (key.contains('stardust') || key.contains('dust') || key.contains('poeira')) {
      return Icons.blur_on;
    }
    if (key.contains('pack') || key.contains('pacote')) {
      return Icons.inventory_2_outlined;
    }
    if (key.contains('gem')) return Icons.diamond;
    if (key.contains('gold') || key.contains('coin')) return Icons.monetization_on;
    return Icons.category_outlined;
  }

  Widget _shopRow({
    required String name,
    required String sub,
    required String priceLabel,
    required bool gems,
    required IconData icon,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final cur = gems ? AppColors.conceptCelestial : AppColors.gold;
    final accent = highlight ? AppColors.gold : AppColors.purpleLt;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1A1326), Color(0xFF0B0810)],
        ),
        border: Border.all(
            color: highlight
                ? AppColors.gold.withValues(alpha: 0.6)
                : AppColors.borderViolet),
      ),
      child: Row(
        children: [
          // Ícone do item à ESQUERDA.
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.txt)),
                const SizedBox(height: 2),
                Text(sub,
                    style: GoogleFonts.roboto(
                        fontSize: 10.5, color: AppColors.txtMut)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Opacity(
            opacity: _busy ? 0.5 : 1,
            child: GestureDetector(
              onTap: _busy ? null : onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: cur.withValues(alpha: 0.14),
                  border: Border.all(color: cur.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(gems ? Icons.diamond : Icons.monetization_on,
                        size: 14, color: cur),
                    const SizedBox(width: 5),
                    Text(priceLabel,
                        style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cur)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
