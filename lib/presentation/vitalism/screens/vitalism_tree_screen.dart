import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/vitalism_tree_layout.dart';
import '../../../data/datasources/local/vitalism_unique_service.dart';
import '../../shared/widgets/app_snack.dart';

// Árvore fictícia de Vitalismo Único — 5 nós em diamante.
// Para afinidades ATIVAS: tap desbloqueia (placeholder mecânico — sem custo).
// Para afinidades DORMENTES (ADR 0005): estado congelado, sem interação.
// Gameplay real virá quando a engine externa entrar.

class VitalismTreeScreen extends ConsumerStatefulWidget {
  final String vitalismId;
  const VitalismTreeScreen({super.key, required this.vitalismId});

  @override
  ConsumerState<VitalismTreeScreen> createState() =>
      _VitalismTreeScreenState();
}

class _VitalismTreeScreenState extends ConsumerState<VitalismTreeScreen> {
  bool _loading = true;
  int _playerLevel = 1;
  int? _playerId;
  OwnedAffinity? _catalogEntry;
  bool _isActive = false;
  Map<String, bool> _unlockedById = const {};

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
    _playerLevel = player.level;

    final svc = ref.read(vitalismUniqueServiceProvider);
    final active = await svc.ownedAffinitiesOf(player.id);
    final dormant = await svc.dormantAffinitiesOf(player.id);

    OwnedAffinity? match;
    var isActive = false;
    for (final a in active) {
      if (a.id == widget.vitalismId) {
        match = a;
        isActive = true;
        break;
      }
    }
    if (match == null) {
      for (final a in dormant) {
        if (a.id == widget.vitalismId) {
          match = a;
          break;
        }
      }
    }

    if (match == null) {
      if (mounted) context.go('/vitalism');
      return;
    }

    await _refreshNodes(svc);
    if (!mounted) return;

    setState(() {
      _catalogEntry = match;
      _isActive = isActive;
      _loading = false;
    });
  }

  Future<void> _refreshNodes(VitalismUniqueService svc) async {
    if (_playerId == null) return;
    final rows = await svc.treeNodesOf(_playerId!, widget.vitalismId);
    _unlockedById = {
      for (final r in rows) r.nodeId: r.unlocked,
    };
  }

  bool _isUnlocked(TreeNodeSpec spec) =>
      _unlockedById[spec.nodeIdFor(widget.vitalismId)] ?? false;

  Future<void> _tapNode(TreeNodeSpec spec) async {
    if (!_isActive) return; // árvore dormente é read-only

    if (_isUnlocked(spec)) {
      AppSnack.info(context, '${spec.placeholderName} já está desperto.');
      return;
    }
    if (_playerLevel < spec.requiredLevel) {
      AppSnack.warning(
        context,
        'Requisito: nível ${spec.requiredLevel}.',
      );
      return;
    }

    final svc = ref.read(vitalismUniqueServiceProvider);
    final ok = await svc.unlockTreeNode(
      playerId:   _playerId!,
      vitalismId: widget.vitalismId,
      nodeId:     spec.nodeIdFor(widget.vitalismId),
    );
    if (!mounted) return;
    if (!ok) return;

    await _refreshNodes(svc);
    if (!mounted) return;
    setState(() {});
    AppSnack.success(context, '${spec.placeholderName} desperta em ti.');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.purple,
          ),
        ),
      );
    }
    final entry = _catalogEntry!;
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _TreeBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _TreeHeader(
                  title: entry.name,
                  onBack: () => context.go('/vitalism'),
                ),
                if (!_isActive) const _DormantBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Text(
                    entry.themeDescription,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      child: _DiamondTree(
                        isActive: _isActive,
                        playerLevel: _playerLevel,
                        isUnlocked: _isUnlocked,
                        onTap: _tapNode,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header / banner / backdrop ──────────────────────────────────────────────

class _TreeBackdrop extends StatelessWidget {
  const _TreeBackdrop();
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.3,
          colors: [
            Color(0xFF15122A),
            Color(0xFF07060E),
            AppColors.black,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
    );
  }
}

class _TreeHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TreeHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textSecondary, size: 20),
            onPressed: onBack,
          ),
          Expanded(
            child: Center(
              child: Text(
                title.toUpperCase(),
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 13,
                  color: AppColors.purpleLight,
                  letterSpacing: 4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _DormantBanner extends StatelessWidget {
  const _DormantBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.ac_unit, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'DORMENTE — tua árvore guardada',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 10,
                color: AppColors.textSecondary,
                letterSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Árvore em diamante ──────────────────────────────────────────────────────

class _DiamondTree extends StatelessWidget {
  final bool isActive;
  final int playerLevel;
  final bool Function(TreeNodeSpec) isUnlocked;
  final Future<void> Function(TreeNodeSpec) onTap;

  const _DiamondTree({
    required this.isActive,
    required this.playerLevel,
    required this.isUnlocked,
    required this.onTap,
  });

  // Coordenadas relativas (0..1). Stack layout.
  static const _width = 320.0;
  static const _height = 460.0;

  Offset _posFor(TreeNodeSpec spec) {
    final xByCol = <int, double>{0: 0.20, 1: 0.50, 2: 0.80};
    final yByRow = <int, double>{0: 0.10, 1: 0.36, 2: 0.62, 3: 0.88};
    return Offset(xByCol[spec.col]! * _width, yByRow[spec.row]! * _height);
  }

  @override
  Widget build(BuildContext context) {
    const specs = VitalismTreeLayout.diamond;
    final positions = {for (final s in specs) s.index: _posFor(s)};

    return Center(
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Linhas conectoras atrás dos nós
            Positioned.fill(
              child: CustomPaint(
                painter: _EdgesPainter(
                  positions: positions,
                  unlockedByIndex: {
                    for (final s in specs) s.index: isUnlocked(s),
                  },
                  active: isActive,
                ),
              ),
            ),
            for (final spec in specs)
              Positioned(
                left: positions[spec.index]!.dx - _nodeRadius,
                top: positions[spec.index]!.dy - _nodeRadius,
                child: _TreeNodeView(
                  spec: spec,
                  unlocked: isUnlocked(spec),
                  available: isActive &&
                      !isUnlocked(spec) &&
                      playerLevel >= spec.requiredLevel,
                  isActive: isActive,
                  onTap: () => onTap(spec),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const double _nodeRadius = 30;

class _TreeNodeView extends StatelessWidget {
  final TreeNodeSpec spec;
  final bool unlocked;
  final bool available;
  final bool isActive;
  final VoidCallback onTap;

  const _TreeNodeView({
    required this.spec,
    required this.unlocked,
    required this.available,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = !isActive
        ? AppColors.textMuted
        : unlocked
            ? AppColors.gold
            : available
                ? AppColors.purpleLight
                : AppColors.textMuted;
    final fill = color.withValues(alpha: unlocked ? 0.25 : 0.08);

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _nodeRadius * 2,
            height: _nodeRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: color, width: unlocked ? 2 : 1.2),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              unlocked
                  ? Icons.auto_awesome
                  : (available
                      ? Icons.radio_button_unchecked
                      : Icons.lock_outline),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nv. ${spec.requiredLevel}',
            style: GoogleFonts.roboto(
              fontSize: 9,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final Map<int, bool> unlockedByIndex;
  final bool active;

  _EdgesPainter({
    required this.positions,
    required this.unlockedByIndex,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final (a, b) in VitalismTreeLayout.edges) {
      final pa = positions[a]!;
      final pb = positions[b]!;
      final bothUnlocked =
          (unlockedByIndex[a] ?? false) && (unlockedByIndex[b] ?? false);
      final paint = Paint()
        ..color = !active
            ? AppColors.border
            : bothUnlocked
                ? AppColors.gold.withValues(alpha: 0.7)
                : AppColors.purple.withValues(alpha: 0.35)
        ..strokeWidth = bothUnlocked ? 2 : 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pa, pb, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter old) =>
      old.active != active || old.unlockedByIndex != unlockedByIndex;
}
