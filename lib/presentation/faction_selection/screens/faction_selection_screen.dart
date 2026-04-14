import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/class_bonus_service.dart';
import '../../../data/datasources/local/quest_admission_service.dart';

class FactionSelectionScreen extends ConsumerStatefulWidget {
  const FactionSelectionScreen({super.key});
  @override
  ConsumerState<FactionSelectionScreen> createState() => _FactionSelectionScreenState();
}

class _FactionSelectionScreenState extends ConsumerState<FactionSelectionScreen> {
  List<Map<String, dynamic>> _factions = [];
  int _selected = -1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFactions();
  }

  Future<void> _loadFactions() async {
    final raw = await rootBundle.loadString('assets/data/factions.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    setState(() => _factions = (data['factions'] as List).cast<Map<String, dynamic>>());
  }

  Color _color(Map c) => Color(int.parse(c['color'] as String));

  Future<void> _confirm() async {
    if (_selected < 0) return;
    final faction = _factions[_selected];
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
        title: Text('Jurar lealdade?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(faction['name'] as String,
                style: GoogleFonts.cinzelDecorative(
                    color: _color(faction), fontSize: 16)),
            const SizedBox(height: 4),
            Text('"${faction['philosophy']}"',
                style: GoogleFonts.roboto(
                    color: _color(faction),
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Text('Você receberá 3 missões de admissão.\nComplete-as para entrar na facção.\nFalhar resultará em penalidade de reputação.',
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
            child: Text('Iniciar admissão',
                style: GoogleFonts.roboto(color: _color(faction))),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    final db = ref.read(appDatabaseProvider);
    await QuestAdmissionService(db).startFactionAdmission(
      player.id,
      faction['id'] as String,
    );

    final updated = await db.managers.playersTable
        .filter((f) => f.id(player.id))
        .getSingleOrNull();
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      ref.invalidate(habitsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('3 missões de admissão criadas! Complete-as para entrar na facção.'),
            backgroundColor: AppColors.mp,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/sanctuary');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _factions.isEmpty
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
            colors: [Color(0xFF0A1A0A), Color(0xFF0A0010), AppColors.black],
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          children: [
            Text('ESCOLHA DAS FACÇÕES',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 15, color: AppColors.gold, letterSpacing: 3)),
            const SizedBox(height: 8),
            Text(
              'Você atingiu o nível 7.\nCaelum exige que você escolha um lado.',
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
        itemCount: _factions.length,
        itemBuilder: (_, i) => _FactionCard(
          data: _factions[i],
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
                  ? _color(_factions[_selected])
                  : AppColors.border,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _selected >= 0
                  ? 'JURAR LEALDADE À ${(_factions[_selected]['name'] as String).toUpperCase()}'
                  : 'SELECIONE UMA FACÇÃO',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  letterSpacing: 1),
            ),
          ),
        ),
      );
}

class _FactionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isSelected;
  final VoidCallback onTap;
  const _FactionCard({required this.data, required this.isSelected, required this.onTap});

  @override
  State<_FactionCard> createState() => _FactionCardState();
}

class _FactionCardState extends State<_FactionCard> {
  bool _expanded = false;

  Color get color => Color(int.parse(widget.data['color'] as String));
  Map<String, dynamic> get data => widget.data;

  @override
  Widget build(BuildContext context) {
    final isSecret = data['isSecret'] == true;
    final isRecommended = data['recommended'] == true;
    final buffs = (data['buffs'] as List).cast<String>();

    return GestureDetector(
      onTap: () {
        widget.onTap();
        setState(() => _expanded = !_expanded);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: data['id'] == 'error'
                ? AppColors.purple.withValues(alpha: widget.isSelected ? 0.8 : 0.4)
                : (widget.isSelected ? color : AppColors.border),
            width: widget.isSelected ? 1.5 : 1,
          ),
          boxShadow: data['id'] == 'error' ? [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(data['name'] as String,
                              style: GoogleFonts.cinzelDecorative(
                                  fontSize: 13, color: AppColors.textPrimary)),
                          const SizedBox(width: 8),
                          if (isRecommended)
                            _badge('RECOMENDADA', AppColors.gold),
                          if (isSecret)
                            _badge('SECRETA', AppColors.hp),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('"${data['philosophy']}"',
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: color,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(data['difficulty'] as String,
                        style: GoogleFonts.roboto(
                            fontSize: 10, color: AppColors.textMuted)),
                    if (widget.isSelected)
                      Icon(Icons.check_circle, color: color, size: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(data['description'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4)),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['description'] as String,
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text('Líder: ${data['leader']}',
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: AppColors.textMuted)),
                  Text('Dificuldade: ${data['difficulty']}',
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: color)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: buffs
                  .take(3)
                  .map((b) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(b,
                            style: GoogleFonts.roboto(
                                fontSize: 10, color: color)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.roboto(
                fontSize: 8, color: color, letterSpacing: 1)),
      );
}
