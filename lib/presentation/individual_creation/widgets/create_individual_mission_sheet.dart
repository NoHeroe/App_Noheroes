import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../core/utils/requirements_helper.dart';
import '../../../domain/enums/intensity.dart';
import '../../../domain/enums/mission_category.dart';
import '../../../domain/services/individual_creation_service.dart';
import '../../../domain/services/mission_balancer_service.dart';
import '../../shared/widgets/npc_dialog_overlay.dart';

/// Sprint 3.1 Bloco 14.6b — bottom sheet de criação de missão individual
/// (port v0.28.2 `create_habit_sheet.dart` adaptado ao schema 25).
///
/// ## Fluxo visual (scrollável único, sem PageController)
///
/// 1. Handle drag 36×4
/// 2. Título "NOVA MISSÃO" CinzelDecorative + subtítulo narrativo
/// 3. TextField nome + TextField descrição pessoal (opcional, multiline)
/// 4. Categoria: scroll horizontal 72px de cards animados — 4
///    categorias (fisico/mental/espiritual/vitalismo). Cor + ícone por
///    categoria alimentam a paleta do resto da sheet.
/// 5. Intensidade: 3 pills horizontais compactas (leve/médio/pesado)
/// 6. Frequência: 4 pills compactas (uma vez/diária/semanal/mensal)
/// 7. Templates sugeridos: Wrap de chips lidos de
///    `assets/data/quest_templates.json`. Tap adiciona na lista. Chip
///    "já adicionado" mostra check.
/// 8. Requisitos adicionados: lista com label/target/unit + botão remover
/// 9. Auto-description: cartão em itálico + botão refresh (sorteia outra
///    frase). Aparece após adicionar 1º requirement.
/// 10. Toggle "Repetir diariamente" com copy explicativo
/// 11. Recompensa estimada: card XP/ouro recalculado inline via
///     `MissionBalancerService`. Aparece quando categoria + intensidade
///     + pelo menos 1 requirement preenchidos.
/// 12. Botão "Assumir Compromisso" full-width com cor da categoria
///
/// Fecha via `Navigator.pop(true)` no submit ok; caller trata refresh.
class CreateIndividualMissionSheet extends ConsumerStatefulWidget {
  const CreateIndividualMissionSheet({super.key});

  @override
  ConsumerState<CreateIndividualMissionSheet> createState() =>
      _CreateIndividualMissionSheetState();
}

class _CreateIndividualMissionSheetState
    extends ConsumerState<CreateIndividualMissionSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  MissionCategory _categoria = MissionCategory.fisico;
  Intensity _intensity = Intensity.medium;
  IndividualFrequency _frequencia = IndividualFrequency.dias;
  final List<RequirementItem> _requirements = [];
  String? _autoDescription;
  bool _isRepetivel = false;
  bool _submitting = false;
  String? _error;

  Map<String, dynamic> _templates = const {};

  /// Cache estático pra evitar rebuscar o JSON a cada abertura do sheet
  /// + sanity em widget tests (primeira abertura puxa via rootBundle,
  /// subsequentes leem do cache síncrono).
  static Map<String, dynamic>? _templatesCache;

  static const _categories = [
    (MissionCategory.fisico, 'Físico', Icons.fitness_center, AppColors.hp,
        'physical'),
    (MissionCategory.mental, 'Mental', Icons.psychology_outlined,
        AppColors.mp, 'mental'),
    (
      MissionCategory.espiritual,
      'Espiritual',
      Icons.self_improvement,
      AppColors.shadowStable,
      'spiritual'
    ),
    (MissionCategory.vitalismo, 'Vitalismo', Icons.bolt, AppColors.purple,
        'vitalism'),
  ];

  Color get _catColor => _categories
      .firstWhere((c) => c.$1 == _categoria,
          orElse: () => _categories.first)
      .$4;

  IconData get _catIcon => _categories
      .firstWhere((c) => c.$1 == _categoria,
          orElse: () => _categories.first)
      .$3;

  /// Chave JSON do asset (v0.28.2 usa `physical`/`mental`/`spiritual`/
  /// `vitalism`). Mapeia da enum atual (PT-BR) pro slug EN do JSON.
  String get _catAssetKey => _categories
      .firstWhere((c) => c.$1 == _categoria,
          orElse: () => _categories.first)
      .$5;

  @override
  void initState() {
    super.initState();
    final cached = _templatesCache;
    if (cached != null) {
      _templates = cached;
    } else {
      _loadTemplates();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/quest_templates.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _templatesCache = decoded;
        if (mounted) setState(() => _templates = decoded);
      }
    } catch (_) {
      // Asset ausente / malformado: sheet segue sem templates.
    }
  }

  List<Map<String, dynamic>> get _currentTemplates {
    final cats = _templates['categories'];
    if (cats is! Map<String, dynamic>) return const [];
    final cat = cats[_catAssetKey];
    if (cat is! Map<String, dynamic>) return const [];
    final list = cat['templates'];
    if (list is! List) return const [];
    return list.cast<Map<String, dynamic>>();
  }

  List<String> get _currentDescriptions {
    final cats = _templates['categories'];
    if (cats is! Map<String, dynamic>) return const [];
    final cat = cats[_catAssetKey];
    if (cat is! Map<String, dynamic>) return const [];
    final list = cat['descriptions'];
    if (list is! List) return const [];
    return list.cast<String>();
  }

  void _addTemplate(Map<String, dynamic> t) {
    final label = t['label'] as String?;
    final target = t['defaultTarget'] as int?;
    final unit = t['unit'] as String?;
    if (label == null || target == null || unit == null) return;
    if (_requirements.any((r) => r.label == label)) return;
    setState(() {
      _requirements.add(RequirementItem(
        label: label,
        target: target,
        unit: unit,
      ));
      _refreshAutoDescription();
    });
  }

  void _refreshAutoDescription() {
    final descs = _currentDescriptions;
    if (descs.isEmpty) {
      _autoDescription = null;
      return;
    }
    _autoDescription = descs[Random().nextInt(descs.length)];
  }

  void _changeCategory(MissionCategory cat) {
    if (_categoria == cat) return;
    setState(() {
      _categoria = cat;
      _requirements.clear();
      _autoDescription = null;
    });
  }

  ({int xp, int gold})? get _rewardPreview {
    if (_requirements.isEmpty) return null;
    final reward = ref
        .read(missionBalancerServiceProvider)
        .calculate(BalancerInput(
          categoria: _categoria,
          intensity: _intensity,
          rank: GuildRank.e, // herda — irrelevante visualmente até submit
          isRepetivel: _isRepetivel,
        ));
    return (xp: reward.xp, gold: reward.gold);
  }

  bool get _canSubmit =>
      !_submitting &&
      _nameCtrl.text.trim().isNotEmpty &&
      _requirements.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) {
      setState(() {
        _error = _nameCtrl.text.trim().isEmpty
            ? 'Dê um nome à missão.'
            : 'Adiciona ao menos 1 requisito.';
      });
      return;
    }
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final rank =
        GuildRankSystem.fromString(player.guildRank.toLowerCase());
    try {
      await ref.read(individualCreationServiceProvider).createIndividual(
            IndividualCreationParams(
              playerId: player.id,
              name: _nameCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              autoDescription: _autoDescription,
              categoria: _categoria,
              intensity: _intensity,
              frequencia: _frequencia,
              requirements: List<RequirementItem>.from(_requirements),
              isRepetivel: _isRepetivel,
              rank: rank,
            ),
          );
    } on IndividualLimitExceededException {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Limite de 5 missões individuais ativas atingido. '
          'Delete alguma pra criar nova.',
        ),
      ));
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Falha ao criar: $e';
      });
      return;
    }
    if (!mounted) return;

    await NpcDialogOverlay.show(
      context,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Nova promessa lavrada. Falhar custa o dobro na Sombra.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('NOVA MISSÃO',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('Você se comprometerá com esta missão.',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 20),
              _input(_nameCtrl, 'Nome da missão', Icons.title,
                  fieldKey: 'sheet-name'),
              const SizedBox(height: 10),
              _input(_descCtrl, 'Descrição pessoal (opcional)', Icons.notes,
                  maxLines: 2, fieldKey: 'sheet-description'),
              const SizedBox(height: 18),
              _label('CATEGORIA'),
              const SizedBox(height: 8),
              _buildCategories(),
              const SizedBox(height: 18),
              _label('INTENSIDADE'),
              const SizedBox(height: 8),
              _buildIntensityPills(),
              const SizedBox(height: 18),
              _label('FREQUÊNCIA'),
              const SizedBox(height: 8),
              _buildFrequencyPills(),
              const SizedBox(height: 18),
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
                _buildTemplateChips(),
                const SizedBox(height: 14),
              ],
              if (_requirements.isNotEmpty) ...[
                _label('ADICIONADOS', color: AppColors.gold),
                const SizedBox(height: 8),
                ..._requirements.asMap().entries.map((e) => _buildReqRow(e)),
                if (_autoDescription != null) ...[
                  const SizedBox(height: 8),
                  _buildAutoDescription(),
                ],
                const SizedBox(height: 14),
              ],
              _buildRepetivelToggle(),
              const SizedBox(height: 14),
              if (_rewardPreview != null) _buildRewardPreview(),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: GoogleFonts.roboto(
                        color: AppColors.hp, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {Color? color}) => Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 9,
          color: color ?? AppColors.textMuted,
          letterSpacing: 2,
        ),
      );

  Widget _input(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    String? fieldKey,
  }) {
    return TextField(
      key: fieldKey == null ? null : ValueKey(fieldKey),
      controller: ctrl,
      style: GoogleFonts.roboto(color: AppColors.textPrimary),
      maxLines: maxLines,
      onChanged: (_) => setState(() => _error = null),
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

  Widget _buildCategories() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = _categoria == cat.$1;
          return GestureDetector(
            key: ValueKey('sheet-cat-${cat.$1.storage}'),
            onTap: () => _changeCategory(cat.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 80,
              decoration: BoxDecoration(
                color: sel ? cat.$4.withValues(alpha: 0.15) : Colors.transparent,
                border:
                    Border.all(color: sel ? cat.$4 : AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat.$3,
                      color: sel ? cat.$4 : AppColors.textMuted, size: 20),
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
    );
  }

  Widget _buildIntensityPills() {
    const options = [
      (Intensity.light, 'Leve'),
      (Intensity.medium, 'Médio'),
      (Intensity.heavy, 'Pesado'),
    ];
    return Row(
      children: [
        for (final o in options) ...[
          Expanded(
            child: _pill(
              key: 'sheet-int-${o.$1.name}',
              label: o.$2,
              selected: _intensity == o.$1,
              onTap: () => setState(() => _intensity = o.$1),
            ),
          ),
          if (o != options.last) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _buildFrequencyPills() {
    const options = [
      (IndividualFrequency.oneShot, 'Uma vez'),
      (IndividualFrequency.dias, 'Diária'),
      (IndividualFrequency.semanas, 'Semanal'),
      (IndividualFrequency.mensal, 'Mensal'),
    ];
    return Row(
      children: [
        for (final o in options) ...[
          Expanded(
            child: _pill(
              key: 'sheet-freq-${o.$1.storage}',
              label: o.$2,
              selected: _frequencia == o.$1,
              onTap: () => setState(() => _frequencia = o.$1),
            ),
          ),
          if (o != options.last) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _pill({
    required String key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: ValueKey(key),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _catColor.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(color: selected ? _catColor : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: selected ? _catColor : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _currentTemplates.map((t) {
        final label = t['label'] as String? ?? '?';
        final target = t['defaultTarget'] as int? ?? 0;
        final unit = t['unit'] as String? ?? '';
        final already = _requirements.any((r) => r.label == label);
        return GestureDetector(
          key: ValueKey('sheet-tpl-$label'),
          onTap: already ? null : () => _addTemplate(t),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: already
                  ? _catColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border.all(
                  color: already ? _catColor : AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (already)
                  Icon(Icons.check, color: _catColor, size: 12),
                if (already) const SizedBox(width: 4),
                Text(
                  '$label ($target ${_unitLabel(unit)})',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: already ? _catColor : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReqRow(MapEntry<int, RequirementItem> entry) {
    final req = entry.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _catColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _catColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_catIcon, color: _catColor, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${req.label} — ${req.target} ${req.unitLabel}',
              style: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            key: ValueKey('sheet-req-remove-${entry.key}'),
            onTap: () => setState(() {
              _requirements.removeAt(entry.key);
              if (_requirements.isEmpty) _autoDescription = null;
            }),
            child: const Icon(Icons.close,
                color: AppColors.textMuted, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoDescription() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _catColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _catColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome,
              color: _catColor.withValues(alpha: 0.6), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$_autoDescription"',
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          GestureDetector(
            key: const ValueKey('sheet-auto-refresh'),
            onTap: () => setState(() => _refreshAutoDescription()),
            child: Icon(Icons.refresh,
                color: _catColor.withValues(alpha: 0.6), size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRepetivelToggle() {
    return Container(
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
                  _isRepetivel
                      ? 'Reaparece todo dia, acumula streak.'
                      : 'Some apos concluir (missao unica).',
                  style: GoogleFonts.roboto(
                      fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            key: const ValueKey('sheet-repetivel'),
            value: _isRepetivel,
            onChanged: (v) => setState(() => _isRepetivel = v),
            activeThumbColor: AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardPreview() {
    final p = _rewardPreview!;
    return Container(
      key: const ValueKey('sheet-reward-preview'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _catColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _catColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('RECOMPENSA ESTIMADA',
              style: GoogleFonts.roboto(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5)),
          Row(
            children: [
              Text('${p.xp} XP',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.xp)),
              const SizedBox(width: 12),
              Text('${p.gold} ouro',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.gold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        key: const ValueKey('sheet-submit'),
        onPressed: _canSubmit ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _catColor,
          disabledBackgroundColor: _catColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(
                'Assumir Compromisso',
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  String _unitLabel(String unit) => switch (unit) {
        'reps' => 'x',
        'km' => 'km',
        'min' => 'min',
        'pages' => 'pág',
        'words' => 'pal',
        'glasses' => 'copos',
        'hours' => 'h',
        'cycles' => 'ciclos',
        _ => unit,
      };
}

/// Helper pra abrir o sheet do lugar que for — centraliza as opções
/// de apresentação (`isScrollControlled`, fundo translúcido, handle via
/// `safeArea` top).
Future<bool?> showCreateIndividualMissionSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreateIndividualMissionSheet(),
  );
}
