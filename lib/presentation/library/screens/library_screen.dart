import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/diary_service.dart';
import '../../../data/database/app_database.dart';
import 'dart:math' as math;

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  int _section = -1; // -1 = hub, 0 = diário, 1 = obras, 2 = coleção
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _navigate(int section) {
    _fadeCtrl.reverse().then((_) {
      setState(() => _section = section);
      _fadeCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: FadeTransition(
        opacity: _fade,
        child: _section == -1
            ? _buildHub(context)
            : _buildSection(),
      ),
    );
  }

  // ─── HUB ───────────────────────────────────────────────────────────────────
  Widget _buildHub(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/sanctuary'),
                  child: const Icon(Icons.arrow_back_ios,
                      color: AppColors.textSecondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('BIBLIOTECA',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 16,
                        color: const Color(0xFFC2A05A),
                        letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Hub visual
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Descrição do hub
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2A05A).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFC2A05A).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'O conhecimento de Caelum vive aqui. Registros, obras e memórias dos que vieram antes.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.5,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Cards de seção
                  Expanded(
                    child: Column(
                      children: [
                        // Diário — full width
                        Expanded(
                          flex: 2,
                          child: _HubCard(
                            title: 'DIÁRIO',
                            subtitle: 'Seus registros em Caelum',
                            icon: Icons.auto_stories_outlined,
                            color: const Color(0xFF8B3DFF),
                            onTap: () => _navigate(0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Obras + Coleção — row
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Expanded(
                                child: _HubCard(
                                  title: 'OBRAS',
                                  subtitle: 'Leituras do universo',
                                  icon: Icons.menu_book_outlined,
                                  color: const Color(0xFF3070B3),
                                  onTap: () => _navigate(1),
                                  badge: 'EM BREVE',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HubCard(
                                  title: 'COLEÇÃO',
                                  subtitle: 'Lore & Progresso',
                                  icon: Icons.explore_outlined,
                                  color: const Color(0xFFC2A05A),
                                  onTap: () => _navigate(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEÇÃO ─────────────────────────────────────────────────────────────────
  Widget _buildSection() {
    return switch (_section) {
      0 => _DiarySection(onBack: () => _navigate(-1)),
      1 => _WorksSection(onBack: () => _navigate(-1)),
      2 => _CollectionSection(onBack: () => _navigate(-1)),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─── HUB CARD ──────────────────────────────────────────────────────────────
class _HubCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              AppColors.surface,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decoração de fundo
            Positioned(
              right: -10, bottom: -10,
              child: Icon(icon,
                  color: color.withValues(alpha: 0.06), size: 80),
            ),
            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: GoogleFonts.roboto(
                              fontSize: 10,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            // Badge
            if (badge != null)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Text(badge!,
                      style: GoogleFonts.roboto(
                          fontSize: 8,
                          color: AppColors.gold,
                          letterSpacing: 1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── DIÁRIO ────────────────────────────────────────────────────────────────
class _DiarySection extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const _DiarySection({required this.onBack});

  @override
  ConsumerState<_DiarySection> createState() => _DiarySectionState();
}

class _DiarySectionState extends ConsumerState<_DiarySection> {
  List<DiaryEntriesTableData> _entries = [];
  DiaryEntriesTableData? _selected;
  final _ctrl = TextEditingController();
  bool _writing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    final service = DiaryService(db);
    final entries = await service.getHistory(player.id);
    setState(() => _entries = entries);
  }

  Future<void> _save() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null || _ctrl.text.trim().isEmpty) return;
    final db = ref.read(appDatabaseProvider);
    final service = DiaryService(db);
    await service.saveEntry(player.id, _ctrl.text.trim());
    _ctrl.clear();
    setState(() => _writing = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return _buildEntryDetail();
    }
    return SafeArea(
      child: Column(
        children: [
          _SectionHeader(
            title: 'DIÁRIO',
            color: const Color(0xFF8B3DFF),
            onBack: widget.onBack,
            action: GestureDetector(
              onTap: () => setState(() => _writing = !_writing),
              child: Icon(
                _writing ? Icons.close : Icons.edit_outlined,
                color: const Color(0xFF8B3DFF), size: 20,
              ),
            ),
          ),
          if (_writing) _buildWriteBox(),
          Expanded(
            child: _entries.isEmpty && !_writing
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_stories_outlined,
                            color: AppColors.textMuted, size: 40),
                        const SizedBox(height: 12),
                        Text('Nenhum registro ainda.',
                            style: GoogleFonts.roboto(
                                color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _writing = true),
                          child: Text('Escrever primeiro registro',
                              style: GoogleFonts.roboto(
                                  color: const Color(0xFF8B3DFF),
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      final words = e.content.split(' ').length;
                      final date = DateTime.parse(e.entryDate.toIso8601String());
                      return GestureDetector(
                        onTap: () => setState(() => _selected = e),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF8B3DFF)
                                      .withValues(alpha: 0.1),
                                  border: Border.all(
                                      color: const Color(0xFF8B3DFF)
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Center(
                                  child: Text('${date.day}',
                                      style: GoogleFonts.cinzelDecorative(
                                          fontSize: 14,
                                          color: const Color(0xFF8B3DFF))),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: GoogleFonts.cinzelDecorative(
                                          fontSize: 11,
                                          color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      e.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$words p.',
                                  style: GoogleFonts.roboto(
                                      fontSize: 9,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF8B3DFF).withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _ctrl,
            maxLines: 4,
            style: GoogleFonts.roboto(
                fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'O que aconteceu hoje em Caelum...',
              hintStyle: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.textMuted),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B3DFF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF8B3DFF).withValues(alpha: 0.4)),
              ),
              child: Text('Registrar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                      fontSize: 13, color: const Color(0xFF8B3DFF))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryDetail() {
    final e = _selected!;
    final date = DateTime.parse(e.entryDate.toIso8601String());
    return SafeArea(
      child: Column(
        children: [
          _SectionHeader(
            title: '${date.day}/${date.month}/${date.year}',
            color: const Color(0xFF8B3DFF),
            onBack: () => setState(() => _selected = null),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Text(e.content,
                  style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.8)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OBRAS ─────────────────────────────────────────────────────────────────
class _WorksSection extends StatelessWidget {
  final VoidCallback onBack;
  const _WorksSection({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _SectionHeader(
            title: 'OBRAS',
            color: const Color(0xFF3070B3),
            onBack: onBack,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3070B3).withValues(alpha: 0.1),
                        border: Border.all(
                            color: const Color(0xFF3070B3).withValues(alpha: 0.4)),
                      ),
      
                      child: const Icon(Icons.menu_book_outlined,
                          color: Color(0xFF3070B3), size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text('Obras de Caelum',
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Text(
                      'As obras do universo NoHeroes estarão disponíveis aqui em breve.\n\nHistórias, lore expandido e registros do Vazio serão acessados diretamente pelo app.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Text('EM BREVE',
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 11,
                              color: AppColors.gold,
                              letterSpacing: 2)),
                    ),
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

// ─── COLEÇÃO ───────────────────────────────────────────────────────────────
class _CollectionSection extends ConsumerWidget {
  final VoidCallback onBack;
  const _CollectionSection({required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    final categories = [
      _CollectionCat(
        title: 'Regiões',
        icon: Icons.explore_outlined,
        color: const Color(0xFFC2A05A),
        total: 6,
        unlocked: _regionsUnlocked(player?.level ?? 1),
        lore: 'Campos de Aureum, Ruínas, Floresta Branca e mais.',
      ),
      _CollectionCat(
        title: 'Personagens',
        icon: Icons.people_outline,
        color: const Color(0xFF8B3DFF),
        total: 20,
        unlocked: _npcsUnlocked(player),
        lore: 'NPCs encontrados em Caelum.',
      ),
      _CollectionCat(
        title: 'Facções',
        icon: Icons.shield_outlined,
        color: AppColors.gold,
        total: 8,
        unlocked: _factionsUnlocked(player),
        lore: 'Facções descobertas ou ingressadas.',
      ),
      _CollectionCat(
        title: 'Lore',
        icon: Icons.auto_stories_outlined,
        color: const Color(0xFF4FA06B),
        total: 50,
        unlocked: 0,
        lore: 'Fragmentos do universo de Caelum. Desbloqueados via missões e regiões.',
      ),
    ];

    return SafeArea(
      child: Column(
        children: [
          _SectionHeader(
            title: 'COLEÇÃO',
            color: const Color(0xFFC2A05A),
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: categories
                  .map((cat) => _CollectionCard(cat: cat))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  int _regionsUnlocked(int level) {
    if (level >= 30) return 6;
    if (level >= 20) return 5;
    if (level >= 12) return 4;
    if (level >= 8) return 3;
    if (level >= 3) return 2;
    return 1;
  }

  int _npcsUnlocked(player) {
    if (player == null) return 0;
    int count = 1; // Figura Desconhecida sempre
    if ((player.level ?? 1) >= 6) count += 1; // Noryan
    if (player.classType?.isNotEmpty ?? false) count += 1;
    if ((player.factionType ?? '').isNotEmpty && player.factionType != 'none') count += 2;
    return count.clamp(0, 20);
  }

  int _factionsUnlocked(player) {
    if (player == null) return 0;
    if ((player.level ?? 1) >= 7) return 3;
    if ((player.level ?? 1) >= 6) return 1;
    return 0;
  }
}

class _CollectionCat {
  final String title;
  final IconData icon;
  final Color color;
  final int total;
  final int unlocked;
  final String lore;

  const _CollectionCat({
    required this.title,
    required this.icon,
    required this.color,
    required this.total,
    required this.unlocked,
    required this.lore,
  });
}

class _CollectionCard extends StatelessWidget {
  final _CollectionCat cat;
  const _CollectionCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final pct = cat.total > 0 ? cat.unlocked / cat.total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cat.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Roda de progresso
          SizedBox(
            width: 64, height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(64, 64),
                  painter: _CircleProgressPainter(
                    progress: pct,
                    color: cat.color,
                    bg: AppColors.border,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${cat.unlocked}',
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 14, color: cat.color)),
                    Text('/${cat.total}',
                        style: GoogleFonts.roboto(
                            fontSize: 8, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(cat.icon, color: cat.color, size: 16),
                  const SizedBox(width: 6),
                  Text(cat.title,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 13, color: AppColors.textPrimary)),
                ]),
                const SizedBox(height: 4),
                Text(cat.lore,
                    style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(cat.color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(pct * 100).toInt()}% descoberto',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;

  _CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.bg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final bgPaint = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ─── SECTION HEADER ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onBack;
  final Widget? action;

  const _SectionHeader({
    required this.title,
    required this.color,
    required this.onBack,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back_ios,
                color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 15, color: color, letterSpacing: 2)),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}
