import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../card_economy.dart';

/// Seção "EMBLEMAS" do Ferreiro (hybrid — ADR economia v1): forja de Emblema de
/// Evolução e fusão de Essências, via RPCs do card game sobre `player_cg_resources`.
///
/// Redesenho (CEO 2026-06-11): só esta aba muda. Sem título no topo; materiais
/// como PILLS no topo-direito (padrão do Santuário). Cada receita é um "card de
/// produto": título dentro do card, ÍCONE GRANDE do produto final à esquerda, a
/// receita (ícones de insumo + quantidade + nome em miniatura) ao lado, e um
/// botão pequeno de forjar no canto inferior-direito.
class CardForgeSection extends ConsumerStatefulWidget {
  const CardForgeSection({super.key});

  @override
  ConsumerState<CardForgeSection> createState() => _CardForgeSectionState();
}

class _CardForgeSectionState extends ConsumerState<CardForgeSection> {
  bool _busy = false;

  static const _rarities = ['comum', 'rara', 'epica', 'lendaria'];
  static const _rarLabel = {
    'comum': 'Comum',
    'rara': 'Rara',
    'epica': 'Épica',
    'lendaria': 'Lendária',
  };
  int _idx(String r) => _rarities.indexOf(r) + 1;
  String _next(String r) => _rarities[(_idx(r)).clamp(0, _rarities.length - 1)];

  Color _rarColor(String r) {
    switch (r) {
      case 'comum':
        return AppColors.cardComum;
      case 'rara':
        return AppColors.cardRara;
      case 'epica':
        return AppColors.cardEpica;
      case 'lendaria':
        return AppColors.cardLendaria;
    }
    return AppColors.cardComum;
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

  Future<void> _run(Future<CgResult> Function() op, String okMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await op();
      if (r.ok) {
        _snack(okMsg, ok: true);
        ref.invalidate(cgResourcesProvider);
      } else {
        _snack('Recursos insuficientes.');
      }
    } catch (_) {
      _snack('Erro de rede. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resAsync = ref.watch(cgResourcesProvider);
    final res = resAsync.value ?? const <String, int>{};
    int n(String k) => res[k] ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
      children: [
        // Materiais como PILLS no topo-direito (padrão Santuário; sem título).
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              _pill(Icons.blur_on, AppColors.conceptMagico, 'Poeira', n('stardust')),
              _pill(Icons.layers_outlined, const Color(0xFF9FB4D8), 'Lasca carta',
                  n('card_shard')),
              _pill(Icons.layers_outlined, AppColors.purpleLt, 'Lasca relíquia',
                  n('relic_shard')),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // FUNDIR ESSÊNCIA — combina 5 de uma raridade na seguinte (carta/relíquia).
        for (final kind in const ['card', 'relic'])
          for (final r in const ['comum', 'rara', 'epica'])
            _fuseCard(kind, r, n),

        // FORJAR EMBLEMA — sobe o nível da carta (carta/relíquia, por raridade).
        for (final kind in const ['card', 'relic'])
          for (final r in _rarities) _emblemCard(kind, r, n),
      ],
    );
  }

  // ── Pill de material (topo-direito) ─────────────────────────────────────
  Widget _pill(IconData icon, Color color, String label, int value) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xE6141019), Color(0xE60A080E)],
        ),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text('$value',
              style: GoogleFonts.roboto(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.txt)),
        ],
      ),
    );
  }

  String _kindLabel(String kind) => kind == 'relic' ? 'Relíquia' : 'Carta';

  // ── Receita: FUNDIR (5 essências r + poeira → 1 essência seguinte) ──────
  Widget _fuseCard(String kind, String rarity, int Function(String) n) {
    final soulKey = '${kind == 'relic' ? 'relic_soul_' : 'card_soul_'}$rarity';
    final needPoeira = 50 * _idx(rarity);
    final nextR = _next(rarity);
    final can = n(soulKey) >= 5 && n('stardust') >= needPoeira && !_busy;
    return _productCard(
      title: 'Essência ${_rarLabel[nextR]} (${_kindLabel(kind)})',
      finalIcon: Icons.auto_awesome,
      finalColor: _rarColor(nextR),
      inputs: [
        _Ingredient(Icons.auto_awesome, _rarColor(rarity), 5, 'Essência',
            n(soulKey) >= 5),
        _Ingredient(Icons.blur_on, AppColors.conceptMagico, needPoeira, 'Poeira',
            n('stardust') >= needPoeira),
      ],
      action: 'Fundir',
      can: can,
      onTap: () => _run(
          () => ref
              .read(cardEconomyServiceProvider)
              .fuseEssence(ref.read(currentPlayerProvider)!.id, kind, rarity),
          'Essência fundida!'),
    );
  }

  // ── Receita: FORJAR EMBLEMA (lascas + 2 essências + poeira → emblema) ────
  Widget _emblemCard(String kind, String rarity, int Function(String) n) {
    final lascaKey = kind == 'relic' ? 'relic_shard' : 'card_shard';
    final soulKey = '${kind == 'relic' ? 'relic_soul_' : 'card_soul_'}$rarity';
    final needLasca = 10 * _idx(rarity);
    const needSoul = 2;
    final needPoeira = 100 * _idx(rarity);
    final can = n(lascaKey) >= needLasca &&
        n(soulKey) >= needSoul &&
        n('stardust') >= needPoeira &&
        !_busy;
    return _productCard(
      title: 'Emblema ${_rarLabel[rarity]} (${_kindLabel(kind)})',
      finalIcon: Icons.military_tech,
      finalColor: _rarColor(rarity),
      inputs: [
        _Ingredient(Icons.layers_outlined, const Color(0xFF9FB4D8), needLasca,
            'Lasca', n(lascaKey) >= needLasca),
        _Ingredient(Icons.auto_awesome, _rarColor(rarity), needSoul, 'Essência',
            n(soulKey) >= needSoul),
        _Ingredient(Icons.blur_on, AppColors.conceptMagico, needPoeira, 'Poeira',
            n('stardust') >= needPoeira),
      ],
      action: 'Forjar',
      can: can,
      onTap: () => _run(
          () => ref
              .read(cardEconomyServiceProvider)
              .forgeEmblem(ref.read(currentPlayerProvider)!.id, kind, rarity),
          'Emblema forjado!'),
    );
  }

  // ── Card de produto genérico ────────────────────────────────────────────
  Widget _productCard({
    required String title,
    required IconData finalIcon,
    required Color finalColor,
    required List<_Ingredient> inputs,
    required String action,
    required bool can,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x33100C15),
        border: Border.all(color: finalColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título DENTRO do card, destacado no topo.
          Text(title,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLt)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone GRANDE do produto final, à esquerda.
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: finalColor.withValues(alpha: 0.12),
                  border: Border.all(color: finalColor.withValues(alpha: 0.6)),
                ),
                child: Icon(finalIcon, size: 30, color: finalColor),
              ),
              const SizedBox(width: 12),
              // A RECEITA: ícones dos insumos + quantidade + nome em miniatura.
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [for (final ing in inputs) _ingredient(ing)],
                ),
              ),
            ],
          ),
          // Botão pequeno no canto inferior-direito.
          Align(
            alignment: Alignment.centerRight,
            child: Opacity(
              opacity: can ? 1 : 0.4,
              child: GestureDetector(
                onTap: can ? onTap : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF2A2140),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hardware, size: 13, color: AppColors.goldLt),
                      const SizedBox(width: 5),
                      Text(action,
                          style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldLt)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Um insumo da receita: ícone + quantidade (vermelha se faltar) + nome mini.
  Widget _ingredient(_Ingredient ing) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ing.icon, size: 22, color: ing.color),
        const SizedBox(height: 1),
        Text('${ing.qty}',
            style: GoogleFonts.robotoMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ing.enough ? AppColors.txt : AppColors.hp)),
        Text(ing.name,
            style: GoogleFonts.roboto(fontSize: 8.5, color: AppColors.txtMut)),
      ],
    );
  }
}

/// Insumo de uma receita (ícone + quantidade necessária + nome + suficiência).
class _Ingredient {
  final IconData icon;
  final Color color;
  final int qty;
  final String name;
  final bool enough;
  const _Ingredient(this.icon, this.color, this.qty, this.name, this.enough);
}
