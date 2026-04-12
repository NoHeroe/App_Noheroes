import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';

class CreateHabitSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const CreateHabitSheet({super.key, required this.onCreated});

  @override
  ConsumerState<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<CreateHabitSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'physical';
  bool _isRepeatable = false;
  bool _loading = false;
  String? _error;

  final _categories = [
    ('physical',  'Físico',    Icons.fitness_center,      AppColors.hp),
    ('mental',    'Mental',    Icons.psychology_outlined,  AppColors.mp),
    ('spiritual', 'Espiritual',Icons.self_improvement,     AppColors.shadowStable),
    ('order',     'Ordem',     Icons.checklist,            AppColors.gold),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Dê um nome à missão.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    // Rank é definido pelo rank do jogador (por ora todos começam em E)
    final playerRank = 'e';

    final error = await ref.read(habitDsProvider).createPersonalHabit(
      playerId: player.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      rank: playerRank,
      // isRepeatable removido
      isFreeUser: true,
    );

    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    widget.onCreated();
    if (mounted) Navigator.pop(context);
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
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Nova Missão Individual',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              'Você se comprometerá com esta missão.\nA intensidade é definida pelo seu Rank atual.',
              style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Título
            TextField(
              controller: _titleCtrl,
              style: GoogleFonts.roboto(color: AppColors.textPrimary),
              decoration: _inputDec('Nome da missão', Icons.title),
            ),
            const SizedBox(height: 12),

            // Descrição
            TextField(
              controller: _descCtrl,
              style: GoogleFonts.roboto(color: AppColors.textPrimary),
              maxLines: 2,
              decoration: _inputDec('Descrição (opcional)', Icons.notes),
            ),
            const SizedBox(height: 16),

            // Categoria
            Text('Categoria',
                style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: _categories.map((c) {
                final selected = _category == c.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _category = c.$1),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? c.$4.withOpacity(0.15) : Colors.transparent,
                        border: Border.all(
                            color: selected ? c.$4 : AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(c.$3,
                              color: selected ? c.$4 : AppColors.textMuted,
                              size: 18),
                          const SizedBox(height: 4),
                          Text(c.$2,
                              style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  color: selected ? c.$4 : AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Repetível
            Row(
              children: [
                Switch(
                  value: _isRepeatable,
                  onChanged: (v) => setState(() => _isRepeatable = v),
                  activeColor: AppColors.purple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Missão repetível',
                          style: GoogleFonts.roboto(
                              fontSize: 13, color: AppColors.textPrimary)),
                      Text('Pode ser completada múltiplas vezes por dia',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: GoogleFonts.roboto(color: AppColors.hp, fontSize: 12)),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
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

  InputDecoration _inputDec(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.roboto(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.purple, size: 18),
      filled: true,
      fillColor: AppColors.surfaceAlt,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.5)),
    );
  }
}
