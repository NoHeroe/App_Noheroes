import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../card_economy.dart';

/// FORJA ESTELAR (CEO 2026-06-12): a forja de itens de card game (fundir essência
/// + forjar emblema), acessada por um botão na Coleção. Bigorna única + receitas
/// selecionáveis + multiplicador de quantidade. Backend: card economy (cgResources).
class StellarForgeScreen extends ConsumerStatefulWidget {
  const StellarForgeScreen({super.key});

  @override
  ConsumerState<StellarForgeScreen> createState() => _StellarForgeScreenState();
}

class _StellarForgeScreenState extends ConsumerState<StellarForgeScreen>
    with SingleTickerProviderStateMixin {
  _CardRecipe? _selected;
  int _qty = 1;
  late final AnimationController _spark;
  bool _forging = false;

  static const _rarities = ['comum', 'rara', 'epica', 'lendaria'];
  static const _rarLabel = {
    'comum': 'Comum',
    'rara': 'Rara',
    'epica': 'Épica',
    'lendaria': 'Lendária',
  };

  @override
  void initState() {
    super.initState();
    _spark = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
  }

  @override
  void dispose() {
    _spark.dispose();
    super.dispose();
  }

  int _rarIdx(String r) => _rarities.indexOf(r) + 1;
  String _rarNext(String r) =>
      _rarities[_rarIdx(r).clamp(0, _rarities.length - 1)];
  String _kindLabel(String k) => k == 'relic' ? 'Relíquia' : 'Carta';
  Color _rarColor(String r) => switch (r) {
        'comum' => AppColors.cardComum,
        'rara' => AppColors.cardRara,
        'epica' => AppColors.cardEpica,
        'lendaria' => AppColors.cardLendaria,
        _ => AppColors.cardComum,
      };

  List<_CardRecipe> _recipes() {
    final out = <_CardRecipe>[];
    const poeira = AppColors.conceptMagico;
    const lascaColor = Color(0xFF9FB4D8);
    // FUNDIR ESSÊNCIA: 5 essências r + poeira → 1 essência r+1.
    for (final kind in const ['card', 'relic']) {
      for (final r in const ['comum', 'rara', 'epica']) {
        final soulKey = '${kind == 'relic' ? 'relic_soul_' : 'card_soul_'}$r';
        final nextR = _rarNext(r);
        out.add(_CardRecipe(
          key: 'fuse_${kind}_$r',
          title: 'Essência ${_rarLabel[nextR]} (${_kindLabel(kind)})',
          kind: kind,
          rarity: r,
          opType: 'fuse',
          finalIcon: Icons.auto_awesome,
          finalColor: _rarColor(nextR),
          ingredients: [
            _CardIng(Icons.auto_awesome, _rarColor(r), 5, 'Essência', soulKey),
            _CardIng(Icons.blur_on, poeira, 50 * _rarIdx(r), 'Poeira', 'stardust'),
          ],
        ));
      }
    }
    // FORJAR EMBLEMA: lascas + 2 essências + poeira → emblema.
    for (final kind in const ['card', 'relic']) {
      for (final r in _rarities) {
        final lascaKey = kind == 'relic' ? 'relic_shard' : 'card_shard';
        final soulKey = '${kind == 'relic' ? 'relic_soul_' : 'card_soul_'}$r';
        out.add(_CardRecipe(
          key: 'emblem_${kind}_$r',
          title: 'Emblema ${_rarLabel[r]} (${_kindLabel(kind)})',
          kind: kind,
          rarity: r,
          opType: 'emblem',
          finalIcon: Icons.military_tech,
          finalColor: _rarColor(r),
          ingredients: [
            _CardIng(Icons.layers_outlined, lascaColor, 10 * _rarIdx(r), 'Lasca',
                lascaKey),
            _CardIng(Icons.auto_awesome, _rarColor(r), 2, 'Essência', soulKey),
            _CardIng(Icons.blur_on, poeira, 100 * _rarIdx(r), 'Poeira', 'stardust'),
          ],
        ));
      }
    }
    return out;
  }

  int _max(_CardRecipe r, Map<String, int> res) {
    var max = 99;
    for (final ing in r.ingredients) {
      if (ing.need > 0) max = math.min(max, (res[ing.resKey] ?? 0) ~/ ing.need);
    }
    return max.clamp(0, 99);
  }

  bool _craftable(_CardRecipe r, Map<String, int> res) =>
      r.ingredients.every((ing) => (res[ing.resKey] ?? 0) >= ing.need);

  Future<void> _craftSelected(Map<String, int> res) async {
    final r = _selected;
    final player = ref.read(currentPlayerProvider);
    if (r == null || player == null || _forging || !_craftable(r, res)) return;
    final n = _qty.clamp(1, _max(r, res));
    if (n < 1) return;
    setState(() => _forging = true);
    _spark.forward(from: 0);
    final svc = ref.read(cardEconomyServiceProvider);
    var done = 0;
    for (var i = 0; i < n; i++) {
      final result = r.opType == 'fuse'
          ? await svc.fuseEssence(player.id, r.kind, r.rarity)
          : await svc.forgeEmblem(player.id, r.kind, r.rarity);
      if (!result.ok) break;
      done++;
      if (!mounted) break;
    }
    ref.invalidate(cgResourcesProvider);
    if (!mounted) return;
    setState(() {
      _forging = false;
      _qty = 1;
    });
    _snack(done > 0 ? '${r.title} ×$done!' : 'Recursos insuficientes.', done > 0);
  }

  void _snack(String msg, bool ok) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0E0E1A),
        content: Text(msg,
            style: GoogleFonts.roboto(color: AppColors.textPrimary, fontSize: 13)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(cgResourcesProvider).value ?? const <String, int>{};
    final recipes = _recipes();
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [Color(0xFF1A0020), Color(0xFF0A000A), AppColors.black],
              ),
            ),
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                _anvilStation(res),
                const Divider(height: 16, color: AppColors.borderViolet),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _recipeTile(recipes[i], res),
                  ),
                ),
                _bottomBar(res),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A1B12), Color(0xFF0B0705)],
                ),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.goldLt, size: 15),
            ),
          ),
          const SizedBox(width: 12),
          Text('FORJA ESTELAR',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 16, color: AppColors.goldLt, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _anvilStation(Map<String, int> res) {
    final r = _selected;
    final accent = r?.finalColor ?? AppColors.gold;
    final name = r == null ? 'Escolha uma receita abaixo' : r.title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 128,
            child: AnimatedBuilder(
              animation: _spark,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned.fill(
                      child: CustomPaint(painter: _AnvilPainter())),
                  Align(
                    alignment: const Alignment(0, -0.55),
                    child: Transform.scale(
                      scale: 1.0 + math.sin(_spark.value * math.pi) * 0.12,
                      child: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: accent.withValues(alpha: 0.12),
                          border: Border.all(color: accent.withValues(alpha: 0.6)),
                        ),
                        child: Icon(r?.finalIcon ?? Icons.auto_awesome,
                            size: 26, color: accent),
                      ),
                    ),
                  ),
                  if (_spark.value > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _SparkPainter(_spark.value)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 12,
                  letterSpacing: 1,
                  color: r == null ? AppColors.txtMut : AppColors.textPrimary)),
          if (r != null) ...[
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              children: [for (final ing in r.ingredients) _ingChip(ing, res)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _ingChip(_CardIng ing, Map<String, int> res) {
    final have = res[ing.resKey] ?? 0;
    final ok = have >= ing.need;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ing.icon, size: 18, color: ing.color),
        Text('$have/${ing.need}',
            style: GoogleFonts.robotoMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: ok ? AppColors.txt : AppColors.hp)),
      ],
    );
  }

  Widget _recipeTile(_CardRecipe r, Map<String, int> res) {
    final selected = _selected?.key == r.key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _selected = r;
        _qty = 1;
      }),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? r.finalColor.withValues(alpha: 0.14)
              : const Color(0x33100C15),
          border: Border.all(
              color:
                  selected ? r.finalColor : r.finalColor.withValues(alpha: 0.45),
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: r.finalColor.withValues(alpha: 0.12),
                border: Border.all(color: r.finalColor.withValues(alpha: 0.6)),
              ),
              child: Icon(r.finalIcon, size: 26, color: r.finalColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldLt)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final ing in r.ingredients) _ingChip(ing, res)
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 18, color: AppColors.goldLt),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(Map<String, int> res) {
    final r = _selected;
    final accent = r?.finalColor ?? AppColors.gold;
    final craftable = r != null && _craftable(r, res);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderViolet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (r != null) ...[
            _qtyStepper(_max(r, res), accent),
            const SizedBox(height: 8),
          ],
          GestureDetector(
            onTap: (craftable && !_forging) ? () => _craftSelected(res) : null,
            child: Container(
              width: double.infinity,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (craftable && !_forging)
                    ? accent.withValues(alpha: 0.12)
                    : AppColors.textMuted.withValues(alpha: 0.05),
                border: Border.all(
                    color: (craftable && !_forging)
                        ? accent.withValues(alpha: 0.55)
                        : AppColors.textMuted.withValues(alpha: 0.25),
                    width: 1.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                r == null
                    ? 'SELECIONE UMA RECEITA'
                    : 'FORJAR${_qty > 1 ? ' ×$_qty' : ''}',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: (craftable && !_forging) ? accent : AppColors.textMuted,
                    letterSpacing: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyStepper(int max, Color accent) {
    Widget stepBtn(IconData icon, bool enabled, VoidCallback onTap) {
      return GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0x33100C15),
              border: Border.all(color: AppColors.borderViolet),
            ),
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        stepBtn(Icons.remove, _qty > 1 && !_forging, () => setState(() => _qty--)),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text('×$_qty',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 16, color: AppColors.textPrimary)),
        ),
        const SizedBox(width: 8),
        stepBtn(Icons.add, _qty < max && !_forging,
            () => setState(() => _qty = (_qty + 1).clamp(1, max))),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: (max > 1 && !_forging) ? () => setState(() => _qty = max) : null,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: (max > 1 && !_forging) ? 1 : 0.35,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.7)),
              ),
              child: Text('MÁX ($max)',
                  style: GoogleFonts.roboto(
                      fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardRecipe {
  _CardRecipe({
    required this.key,
    required this.title,
    required this.kind,
    required this.rarity,
    required this.opType,
    required this.finalIcon,
    required this.finalColor,
    required this.ingredients,
  });
  final String key;
  final String title;
  final String kind;
  final String rarity;
  final String opType;
  final IconData finalIcon;
  final Color finalColor;
  final List<_CardIng> ingredients;
}

class _CardIng {
  const _CardIng(this.icon, this.color, this.need, this.name, this.resKey);
  final IconData icon;
  final Color color;
  final int need;
  final String name;
  final String resKey;
}

// ── Bigorna desenhada (copiada do Ferreiro) ─────────────────────────────────
class _AnvilPainter extends CustomPainter {
  const _AnvilPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final faceW = math.min(w * 0.66, 210.0);
    final faceTop = h * 0.46;
    const faceH = 18.0;
    final faceL = cx - faceW / 2, faceR = cx + faceW / 2;
    final waistTop = faceTop + faceH;
    final waistH = h * 0.20;
    final waistTopHalf = faceW * 0.18, waistBotHalf = faceW * 0.12;
    final baseTop = waistTop + waistH;
    final baseH = h * 0.12;
    final baseHalf = faceW * 0.34;
    final bottom = baseTop + baseH;

    final path = Path()
      ..moveTo(faceL, faceTop)
      ..lineTo(faceR, faceTop)
      ..lineTo(faceR + 26, faceTop + faceH * 0.45)
      ..lineTo(faceR, faceTop + faceH)
      ..lineTo(cx + waistTopHalf, waistTop)
      ..lineTo(cx + waistBotHalf, baseTop)
      ..lineTo(cx + baseHalf, baseTop)
      ..lineTo(cx + baseHalf * 0.9, bottom)
      ..lineTo(cx - baseHalf * 0.9, bottom)
      ..lineTo(cx - baseHalf, baseTop)
      ..lineTo(cx - waistBotHalf, baseTop)
      ..lineTo(cx - waistTopHalf, waistTop)
      ..lineTo(faceL, faceTop + faceH)
      ..close();

    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3C3C46), Color(0xFF17171C)],
      ).createShader(Rect.fromLTWH(0, faceTop, w, bottom - faceTop));
    canvas.drawShadow(path, Colors.black, 6, true);
    canvas.drawPath(path, body);

    final hi = Paint()
      ..color = const Color(0xFF6A6A78)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(faceL, faceTop), Offset(faceR, faceTop), hi);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Faíscas da forja (copiada do Ferreiro) ──────────────────────────────────
class _SparkPainter extends CustomPainter {
  final double t;
  const _SparkPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final cx = size.width / 2;
    final oy = size.height * 0.225;
    final origin = Offset(cx, oy);

    final flashA = math.sin(t * math.pi).clamp(0.0, 1.0);
    final flash = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFE0A3).withValues(alpha: 0.55 * flashA),
        const Color(0x00FFB347),
      ]).createShader(Rect.fromCircle(center: origin, radius: 34));
    canvas.drawCircle(origin, 34, flash);

    const n = 18;
    final alpha = (1 - t).clamp(0.0, 1.0);
    for (var i = 0; i < n; i++) {
      final ang = (i / n) * 2 * math.pi - math.pi / 2;
      final speed = 0.6 + ((i * 53) % 10) / 10 * 0.7;
      final dist = t * 72 * speed;
      final px = cx + math.cos(ang) * dist;
      final py = oy + math.sin(ang) * dist - t * 12 * speed;
      final dir = Offset(math.cos(ang), math.sin(ang));
      final p = Paint()
        ..color = (i.isEven ? const Color(0xFFFFB347) : const Color(0xFFFF8A3D))
            .withValues(alpha: alpha)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
      canvas.drawLine(
          Offset(px, py), Offset(px + dir.dx * 5, py + dir.dy * 5), p);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.t != t;
}
