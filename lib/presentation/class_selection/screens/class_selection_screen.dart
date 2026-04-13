import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/class_bonus_service.dart';

class ClassSelectionScreen extends ConsumerStatefulWidget {
  const ClassSelectionScreen({super.key});
  @override
  ConsumerState<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends ConsumerState<ClassSelectionScreen> {
  List<Map<String, dynamic>> _classes = [];
  int _selected = -1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final raw = await rootBundle.loadString('assets/data/classes.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    setState(() => _classes = (data['classes'] as List).cast<Map<String, dynamic>>());
  }

  Color _color(Map c) => Color(int.parse(c['color'] as String));

  Future<void> _confirm() async {
    if (_selected < 0) return;
    final cls = _classes[_selected];
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Confirmar classe?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cls['name'] as String,
                style: GoogleFonts.cinzelDecorative(
                    color: _color(cls), fontSize: 18)),
            const SizedBox(height: 8),
            Text('Esta escolha é permanente.\nMudar de classe tem custo elevado.',
                style: GoogleFonts.roboto(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirmar',
                style: GoogleFonts.roboto(color: _color(cls))),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    final db = ref.read(appDatabaseProvider);
    await ClassBonusService(db).applyClassBonus(player.id, cls['id'] as String);

    // Atualiza provider
    final updated = await db.managers.playersTable
        .filter((f) => f.id(player.id))
        .getSingleOrNull();
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      context.go('/sanctuary');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _classes.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : Stack(
              children: [
                _buildBg(),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildList()),
                      _buildConfirmBtn(),
                    ],
                  ),
                ),
                if (_loading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                        child: CircularProgressIndicator(color: AppColors.gold)),
                  ),
              ],
            ),
    );
  }

  Widget _buildBg() => Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xFF1A0A2E), Color(0xFF0A0010), AppColors.black],
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          children: [
            Text('RITUAL DA CLASSE',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 16, color: AppColors.gold, letterSpacing: 3)),
            const SizedBox(height: 8),
            Text(
              'Você atingiu o nível 5 em Caelum.\nEsta escolha define sua jornada.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _classes.length,
        itemBuilder: (_, i) => _ClassCard(
          data: _classes[i],
          isSelected: _selected == i,
          onTap: () => setState(() => _selected = i),
        ),
      );

  Widget _buildConfirmBtn() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selected >= 0 ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selected >= 0
                  ? _color(_classes[_selected])
                  : AppColors.border,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _selected >= 0
                  ? 'ESCOLHER ${(_classes[_selected]['name'] as String).toUpperCase()}'
                  : 'SELECIONE UMA CLASSE',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  letterSpacing: 1),
            ),
          ),
        ),
      );
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSelected;
  final VoidCallback onTap;
  const _ClassCard({required this.data, required this.isSelected, required this.onTap});

  Color get color => Color(int.parse(data['color'] as String));

  @override
  Widget build(BuildContext context) {
    final isSpecial = data['isSpecial'] == true;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Icon(_iconFor(data['id'] as String),
                  color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data['name'] as String,
                          style: GoogleFonts.cinzelDecorative(
                              fontSize: 14, color: AppColors.textPrimary)),
                      if (isSpecial) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.4)),
                          ),
                          child: Text('ESPECIAL',
                              style: GoogleFonts.roboto(
                                  fontSize: 8,
                                  color: AppColors.gold,
                                  letterSpacing: 1)),
                        ),
                      ],
                      if (data['hasVitalism'] == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.purple.withValues(alpha: 0.4)),
                          ),
                          child: Text('VITALISMO',
                              style: GoogleFonts.roboto(
                                  fontSize: 8,
                                  color: AppColors.purple,
                                  letterSpacing: 1)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(data['subtitle'] as String,
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: color)),
                  const SizedBox(height: 6),
                  Text(data['description'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text('⚠ ${data['weakness']}',
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String id) => switch (id) {
    'warrior'      => Icons.shield,
    'colossus'     => Icons.fitness_center,
    'monk'         => Icons.self_improvement,
    'rogue'        => Icons.visibility_off,
    'hunter'       => Icons.gps_fixed,
    'druid'        => Icons.eco,
    'mage'         => Icons.auto_fix_high,
    'shadowWeaver' => Icons.blur_circular,
    _              => Icons.person,
  };
}
