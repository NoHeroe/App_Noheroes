import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/requirements_helper.dart';

class CreateHabitSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const CreateHabitSheet({super.key, required this.onCreated});

  @override
  ConsumerState<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<CreateHabitSheet> {
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  String  _category = 'physical';
  bool    _loading  = false;
  String? _error;

  Map<String, dynamic> _templates = {};
  List<RequirementItem> _requirements = [];
  String? _autoDescription;
  bool _isRepeatable = false;

  final _categories = [
    ('physical',  'Físico',       Icons.fitness_center,     AppColors.hp),
    ('mental',    'Mental',       Icons.psychology_outlined, AppColors.mp),
    ('spiritual', 'Espiritual',   Icons.self_improvement,    AppColors.shadowStable),
    ('order',     'Ordem',        Icons.checklist,           AppColors.gold),
    ('vitalism',  'Vitalismo',    Icons.bolt,                AppColors.purple),
    ('recovery',  'Recuperação',  Icons.bedtime_outlined,    const Color(0xFF00897B)),
  ];

  Color get _catColor => _categories
      .firstWhere((c) => c.$1 == _category, orElse: () => _categories.first)
      .$4;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final raw = await rootBundle.loadString('assets/data/quest_templates.json');
      setState(() => _templates = json.decode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _currentTemplates {
    final cats = _templates['categories'] as Map<String, dynamic>?;
    if (cats == null) return [];
    final cat = cats[_category] as Map<String, dynamic>?;
    if (cat == null) return [];
    return (cat['templates'] as List).cast<Map<String, dynamic>>();
  }

  void _addTemplate(Map<String, dynamic> t) {
    setState(() {
      _requirements.add(RequirementItem(
        label:  t['label'] as String,
        target: t['defaultTarget'] as int,
        unit:   t['unit'] as String,
      ));
      _refreshAutoDescription();
    });
  }

  void _refreshAutoDescription() {
    final cats = _templates['categories'] as Map<String, dynamic>?;
    if (cats == null) return;
    final cat = cats[_category] as Map<String, dynamic>?;
    if (cat == null) return;
    final descs = (cat['descriptions'] as List).cast<String>();
    _autoDescription = descs[Random().nextInt(descs.length)];
  }

  void _changeCategory(String cat) {
    setState(() {
      _category = cat;
      _requirements.clear();
      _autoDescription = null;
    });
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Dê um nome à missão.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    final reqJson = _requirements.isEmpty
        ? null
        : RequirementsHelper.serialize(_requirements);

    final error = await ref.read(habitDsProvider).createPersonalHabit(
      playerId:        player.id,
      title:           _titleCtrl.text.trim(),
      description:     _descCtrl.text.trim(),
      category:        _category,
      rank:            'e',
      isFreeUser:      true,
      requirements:    reqJson,
      autoDescription: _autoDescription,
      isRepeatable:    _isRepeatable,
    );

    setState(() => _loading = false);
    if (error != null) { setState(() => _error = error); return; }
    widget.onCreated();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Título da sheet
            Text('Nova Missão',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Você se comprometerá com esta missão.',
                style: GoogleFonts.roboto(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 20),

            // Nome
            _inputField(_titleCtrl, 'Nome da missão', Icons.title),
            const SizedBox(height: 10),
            _inputField(_descCtrl, 'Descrição pessoal (opcional)',
                Icons.notes, maxLines: 2),
            const SizedBox(height: 16),

            // Categoria — scroll horizontal
            Text('Categoria',
                style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final sel = _category == cat.$1;
                  return GestureDetector(
                    onTap: () => _changeCategory(cat.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 80,
                      decoration: BoxDecoration(
                        color: sel
                            ? cat.$4.withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: Border.all(
                            color: sel ? cat.$4 : AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat.$3,
                              color: sel ? cat.$4 : AppColors.textMuted,
                              size: 20),
                          const SizedBox(height: 4),
                          Text(cat.$2,
                              style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: sel ? cat.$4 : AppColors.textMuted),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Templates de requisitos
            if (_currentTemplates.isNotEmpty) ...[
              Row(
                children: [
                  Text('REQUISITOS SUGERIDOS',
                      style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: AppColors.textMuted,
                          letterSpacing: 2)),
                  const Spacer(),
                  Text('toque para adicionar',
                      style: GoogleFonts.roboto(
                          fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _currentTemplates.map((t) {
                  final alreadyAdded = _requirements
                      .any((r) => r.label == t['label']);
                  return GestureDetector(
                    onTap: alreadyAdded ? null : () => _addTemplate(t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: alreadyAdded
                            ? _catColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: Border.all(
                            color: alreadyAdded
                                ? _catColor
                                : AppColors.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (alreadyAdded)
                            Icon(Icons.check,
                                color: _catColor, size: 12),
                          if (alreadyAdded) const SizedBox(width: 4),
                          Text(
                              '${t['label']} (${t['defaultTarget']} ${_unitLabel(t['unit'] as String)})',
                              style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: alreadyAdded
                                      ? _catColor
                                      : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Requisitos adicionados
            if (_requirements.isNotEmpty) ...[
              Text('ADICIONADOS',
                  style: GoogleFonts.roboto(
                      fontSize: 9,
                      color: AppColors.gold,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              ..._requirements.asMap().entries.map((e) {
                final req = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _catColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _catColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_categoryIcon, color: _catColor, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            '${req.label} — ${req.target} ${req.unitLabel}',
                            style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: AppColors.textPrimary)),
                      ),
                      GestureDetector(
                        onTap: () => setState(
                            () => _requirements.removeAt(e.key)),
                        child: const Icon(Icons.close,
                            color: AppColors.textMuted, size: 16),
                      ),
                    ],
                  ),
                );
              }),

              // Descrição automática preview
              if (_autoDescription != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _catColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _catColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: _catColor.withValues(alpha: 0.6),
                          size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('"$_autoDescription"',
                            style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic)),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _refreshAutoDescription()),
                        child: Icon(Icons.refresh,
                            color: _catColor.withValues(alpha: 0.6),
                            size: 14),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],

            // Toggle repetir diariamente
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Repetir diariamente',
                            style: GoogleFonts.roboto(
                                fontSize: 13, color: AppColors.textPrimary)),
                        Text(
                            _isRepeatable
                                ? 'Reaparece todo dia, acumula streak.'
                                : 'Some apos concluir (missao unica).',
                            style: GoogleFonts.roboto(
                                fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isRepeatable,
                    onChanged: (v) => setState(() => _isRepeatable = v),
                    activeColor: AppColors.gold,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (_error != null) ...[
              Text(_error!,
                  style: GoogleFonts.roboto(
                      color: AppColors.hp, fontSize: 12)),
              const SizedBox(height: 8),
            ],

            // Botão criar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _catColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Assumir Compromisso',
                        style: GoogleFonts.cinzelDecorative(
                            color: Colors.white, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.roboto(color: AppColors.textPrimary),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: _catColor, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _catColor, width: 1.5)),
      ),
    );
  }

  String _unitLabel(String unit) => switch (unit) {
    'reps'    => 'x',
    'km'      => 'km',
    'min'     => 'min',
    'pages'   => 'pág',
    'words'   => 'pal',
    'glasses' => 'copos',
    'hours'   => 'h',
    'cycles'  => 'ciclos',
    _         => unit,
  };

  IconData get _categoryIcon => switch (_category) {
    'physical'  => Icons.fitness_center,
    'mental'    => Icons.psychology_outlined,
    'spiritual' => Icons.self_improvement,
    'order'     => Icons.checklist,
    'vitalism'  => Icons.bolt,
    'recovery'  => Icons.bedtime_outlined,
    _           => Icons.star_outline,
  };
}
