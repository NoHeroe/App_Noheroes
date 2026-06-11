import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../card_economy.dart';

/// Seção "EMBLEMAS" do Ferreiro (hybrid — ADR economia v1): forja de Emblema de
/// Evolução e fusão de Essências, executadas via RPCs do card game sobre
/// `player_cg_resources`. Renderizada DENTRO da tela do Ferreiro (sem tela nova).
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _resourcePanel(n),
        const SizedBox(height: 14),
        _header('FORJAR EMBLEMA',
            '10×nível Lascas + 2 Essências + 100×nível Poeira → 1 Emblema'),
        const SizedBox(height: 8),
        for (final kind in const ['card', 'relic']) ...[
          _kindLabel(kind),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _rarities)
                _forgeTile(kind, r, n),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        _header('FUNDIR ESSÊNCIA',
            '5 Essências de uma raridade + 50×nível Poeira → 1 da seguinte'),
        const SizedBox(height: 8),
        for (final kind in const ['card', 'relic']) ...[
          _kindLabel(kind),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in const ['comum', 'rara', 'epica'])
                _fuseTile(kind, r, n),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// Painel "SEUS RECURSOS" — visibilidade dos materiais do card game.
  Widget _resourcePanel(int Function(String) n) {
    Widget chip(IconData ic, String label, int v) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: const Color(0x33100C15),
            border: Border.all(color: AppColors.borderViolet),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic, size: 13, color: AppColors.purpleLt),
            const SizedBox(width: 5),
            Text('$label ',
                style: GoogleFonts.roboto(fontSize: 10.5, color: AppColors.txtMut)),
            Text('$v',
                style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldLt)),
          ]),
        );
    const rLetters = {'comum': 'C', 'rara': 'R', 'epica': 'É', 'lendaria': 'L'};
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0x22100C15),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEUS RECURSOS',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 12, color: AppColors.goldLt, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Wrap(spacing: 7, runSpacing: 7, children: [
            chip(Icons.blur_on, 'Poeira', n('stardust')),
            chip(Icons.layers_outlined, 'Lasca C', n('card_shard')),
            chip(Icons.layers_outlined, 'Lasca R', n('relic_shard')),
            for (final r in _rarities)
              chip(Icons.auto_awesome, 'Ess.C·${rLetters[r]}', n('card_soul_$r')),
            for (final r in _rarities)
              chip(Icons.auto_awesome, 'Ess.R·${rLetters[r]}', n('relic_soul_$r')),
            for (final r in _rarities)
              chip(Icons.military_tech_outlined, 'Embl.C·${rLetters[r]}',
                  n('card_scroll_$r')),
            for (final r in _rarities)
              chip(Icons.military_tech_outlined, 'Embl.R·${rLetters[r]}',
                  n('relic_runes_$r')),
          ]),
        ],
      ),
    );
  }

  Widget _header(String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 14, color: AppColors.goldLt, letterSpacing: 1.5)),
          const SizedBox(height: 2),
          Text(sub,
              style: GoogleFonts.roboto(fontSize: 10.5, color: AppColors.txtMut)),
        ],
      );

  Widget _kindLabel(String kind) => Text(
        kind == 'relic' ? 'Relíquia' : 'Carta',
        style: GoogleFonts.roboto(
            fontSize: 11, letterSpacing: 1, color: AppColors.txt2),
      );

  Widget _forgeTile(String kind, String rarity, int Function(String) n) {
    final idx = _idx(rarity);
    final lascaKey = kind == 'relic' ? 'relic_shard' : 'card_shard';
    final soulKey = '${kind == 'relic' ? 'relic_soul_' : 'card_soul_'}$rarity';
    final needLasca = 10 * idx;
    const needSoul = 2;
    final needPoeira = 100 * idx;
    final can = n(lascaKey) >= needLasca &&
        n(soulKey) >= needSoul &&
        n('stardust') >= needPoeira &&
        !_busy;
    return _tile(
      title: _rarLabel[rarity]!,
      cost: '$needLasca L · $needSoul E · $needPoeira P',
      can: can,
      onTap: () => _run(
          () => ref
              .read(cardEconomyServiceProvider)
              .forgeEmblem(ref.read(currentPlayerProvider)!.id, kind, rarity),
          'Emblema forjado!'),
    );
  }

  Widget _fuseTile(String kind, String rarity, int Function(String) n) {
    final idx = _idx(rarity);
    final soulKey = '${kind == 'relic' ? 'relic_soul_' : 'card_soul_'}$rarity';
    final needPoeira = 50 * idx;
    final can =
        n(soulKey) >= 5 && n('stardust') >= needPoeira && !_busy;
    return _tile(
      title: '${_rarLabel[rarity]!} →',
      cost: '5 E · $needPoeira P',
      can: can,
      onTap: () => _run(
          () => ref
              .read(cardEconomyServiceProvider)
              .fuseEssence(ref.read(currentPlayerProvider)!.id, kind, rarity),
          'Essência fundida!'),
    );
  }

  Widget _tile({
    required String title,
    required String cost,
    required bool can,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: can ? 1 : 0.45,
      child: GestureDetector(
        onTap: can ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0x33100C15),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_outlined,
                      size: 15, color: AppColors.goldLt),
                  const SizedBox(width: 6),
                  Text(title,
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.txt)),
                ],
              ),
              const SizedBox(height: 4),
              Text(cost,
                  style: GoogleFonts.robotoMono(
                      fontSize: 10, color: AppColors.txt2)),
            ],
          ),
        ),
      ),
    );
  }
}
