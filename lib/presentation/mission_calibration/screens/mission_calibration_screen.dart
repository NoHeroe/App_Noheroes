import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../domain/enums/intensity.dart';
import '../../../domain/enums/mission_category.dart';
import '../../../domain/enums/mission_style.dart';
import '../../../domain/models/mission_preferences.dart';
import '../widgets/quiz_option_tile.dart';

/// Sprint 3.1 Bloco 9 — tela do quiz de calibração (DESIGN_DOC §7).
///
/// **UI mínima funcional**. Sem animações, sem partículas, sem NPC
/// overlay polido. Bloco 10 consolida estética com as outras telas.
///
/// Fluxo:
///   1. 7 perguntas sequenciais (P1-P7), P4/P5/P6 condicionais ao
///      `primaryFocus` escolhido em P1.
///   2. Obrigatórios: P1, P2, P3, P7. Subfocus (P4/P5/P6) aceitam 0-3.
///   3. Submit → `MissionPreferencesService.save` → emite
///      `MissionPreferencesChanged` → navega pra `/quests`.
///
/// Wipe de subfocus ao mudar P1 fica em `MissionPreferences.withPrimaryFocus`
/// (Bloco 9). Aqui o draft local replica a mesma semântica durante a
/// navegação do quiz.
class MissionCalibrationScreen extends ConsumerStatefulWidget {
  const MissionCalibrationScreen({super.key});

  @override
  ConsumerState<MissionCalibrationScreen> createState() =>
      _MissionCalibrationScreenState();
}

enum _QuizStep { focus, intensity, style, physical, mental, spiritual, time }

class _MissionCalibrationScreenState
    extends ConsumerState<MissionCalibrationScreen> {
  MissionCategory? _focus;
  Intensity? _intensity;
  MissionStyle? _style;
  final Set<String> _physical = {};
  final Set<String> _mental = {};
  final Set<String> _spiritual = {};
  int? _timeMinutes;

  int _stepIndex = 0;
  bool _submitting = false;

  // Ordem dinâmica conforme foco — recalculada a cada build.
  List<_QuizStep> get _visibleSteps {
    final base = <_QuizStep>[
      _QuizStep.focus,
      _QuizStep.intensity,
      _QuizStep.style,
    ];
    switch (_focus) {
      case MissionCategory.fisico:
        base.add(_QuizStep.physical);
        break;
      case MissionCategory.mental:
        base.add(_QuizStep.mental);
        break;
      case MissionCategory.espiritual:
        base.add(_QuizStep.spiritual);
        break;
      case MissionCategory.vitalismo:
        base.addAll([
          _QuizStep.physical,
          _QuizStep.mental,
          _QuizStep.spiritual,
        ]);
        break;
      case null:
        // sem foco ainda — só as 3 primeiras renderizam
        break;
    }
    base.add(_QuizStep.time);
    return base;
  }

  bool get _canAdvance {
    if (_stepIndex >= _visibleSteps.length) return false;
    final step = _visibleSteps[_stepIndex];
    return switch (step) {
      _QuizStep.focus => _focus != null,
      _QuizStep.intensity => _intensity != null,
      _QuizStep.style => _style != null,
      _QuizStep.physical => true, // subfocus opcional
      _QuizStep.mental => true,
      _QuizStep.spiritual => true,
      _QuizStep.time => _timeMinutes != null,
    };
  }

  void _selectFocus(MissionCategory value) {
    setState(() {
      _focus = value;
      // Wipe condicional — espelha MissionPreferences.withPrimaryFocus.
      switch (value) {
        case MissionCategory.fisico:
          _mental.clear();
          _spiritual.clear();
          break;
        case MissionCategory.mental:
          _physical.clear();
          _spiritual.clear();
          break;
        case MissionCategory.espiritual:
          _physical.clear();
          _mental.clear();
          break;
        case MissionCategory.vitalismo:
          break; // preserva todos
      }
    });
  }

  void _toggleSubfocus(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else if (set.length < 3) {
        set.add(value);
      }
      // Se já tem 3 e tenta adicionar 4º → ignora silenciosamente.
    });
  }

  Future<void> _next() async {
    if (_stepIndex < _visibleSteps.length - 1) {
      setState(() => _stepIndex++);
    } else {
      await _submit();
    }
  }

  void _back() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    if (_focus == null ||
        _intensity == null ||
        _style == null ||
        _timeMinutes == null) {
      return;
    }
    setState(() => _submitting = true);
    final now = DateTime.now();
    final draft = MissionPreferences(
      playerId: player.id,
      primaryFocus: _focus!,
      intensity: _intensity!,
      missionStyle: _style!,
      physicalSubfocus: _physical.toList(growable: false),
      mentalSubfocus: _mental.toList(growable: false),
      spiritualSubfocus: _spiritual.toList(growable: false),
      timeDailyMinutes: _timeMinutes!,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await ref.read(missionPreferencesServiceProvider).save(draft);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;
    // TODO(bloco10): copy final polida via NPC overlay dark-fantasy.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Calibrado'),
        content: const Text(
            'Teu caminho está calibrado. Que Caelum reconheça.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Prosseguir'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.go('/quests');
  }

  @override
  Widget build(BuildContext context) {
    final steps = _visibleSteps;
    final step = steps[_stepIndex.clamp(0, steps.length - 1)];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibração'),
        leading: _stepIndex == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _back,
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_stepIndex + 1) / steps.length,
              ),
              const SizedBox(height: 16),
              Expanded(child: SingleChildScrollView(child: _buildStep(step))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _stepIndex == 0 ? null : _back,
                      child: const Text('Voltar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          (_canAdvance && !_submitting) ? _next : null,
                      child: Text(_stepIndex == steps.length - 1
                          ? 'Confirmar'
                          : 'Próximo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(_QuizStep step) {
    return switch (step) {
      _QuizStep.focus => _buildFocus(),
      _QuizStep.intensity => _buildIntensity(),
      _QuizStep.style => _buildStyle(),
      _QuizStep.physical => _buildSubfocus(
          title: 'Sub-foco físico',
          hint: 'Escolha até 3 áreas.',
          options: const ['Força', 'Cardio', 'Flexibilidade', 'Nutrição', 'Sono'],
          selected: _physical,
        ),
      _QuizStep.mental => _buildSubfocus(
          title: 'Sub-foco mental',
          hint: 'Escolha até 3 áreas.',
          options: const [
            'Leitura',
            'Escrita',
            'Estudo',
            'Criatividade',
            'Aprendizado'
          ],
          selected: _mental,
        ),
      _QuizStep.spiritual => _buildSubfocus(
          title: 'Sub-foco espiritual',
          hint: 'Escolha até 3 áreas.',
          options: const [
            'Meditação',
            'Journaling',
            'Ritual',
            'Organização',
            'Desapego'
          ],
          selected: _spiritual,
        ),
      _QuizStep.time => _buildTime(),
    };
  }

  Widget _buildFocus() {
    const entries = [
      (
        MissionCategory.fisico,
        'Físico',
        'Forjar o corpo. Treino, corrida, disciplina alimentar, descanso.'
      ),
      (
        MissionCategory.mental,
        'Mental',
        'Forjar a mente. Leitura, estudo, foco, organização, aprendizado.'
      ),
      (
        MissionCategory.espiritual,
        'Espiritual',
        'Forjar a alma. Meditação, propósito, valores, silêncio.'
      ),
      (
        MissionCategory.vitalismo,
        'Vitalismo',
        'Forjar o todo. Disciplina que une os pilares. Equilíbrio e presença.'
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Foco primário',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Qual caminho te move?'),
        const SizedBox(height: 16),
        for (final entry in entries)
          QuizOptionTile(
            label: entry.$2,
            description: entry.$3,
            selected: _focus == entry.$1,
            onTap: () => _selectFocus(entry.$1),
          ),
      ],
    );
  }

  Widget _buildIntensity() {
    const entries = [
      (Intensity.light, 'Leve'),
      (Intensity.medium, 'Médio'),
      (Intensity.heavy, 'Pesado'),
      (Intensity.adaptive, 'Adaptativo'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Intensidade',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (final entry in entries)
          QuizOptionTile(
            label: entry.$2,
            selected: _intensity == entry.$1,
            onTap: () => setState(() => _intensity = entry.$1),
          ),
      ],
    );
  }

  Widget _buildStyle() {
    const entries = [
      (MissionStyle.real, 'Tarefas reais'),
      (MissionStyle.internal, 'Sistema interno'),
      (MissionStyle.mixed, 'Misto'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Estilo',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (final entry in entries)
          QuizOptionTile(
            label: entry.$2,
            selected: _style == entry.$1,
            onTap: () => setState(() => _style = entry.$1),
          ),
      ],
    );
  }

  Widget _buildSubfocus({
    required String title,
    required String hint,
    required List<String> options,
    required Set<String> selected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(hint),
        const SizedBox(height: 16),
        for (final opt in options)
          QuizOptionTile(
            label: opt,
            selected: selected.contains(opt),
            checkboxMode: true,
            disabled: selected.length >= 3 && !selected.contains(opt),
            onTap: () => _toggleSubfocus(selected, opt),
          ),
      ],
    );
  }

  Widget _buildTime() {
    // P7 → timeDailyMinutes: midpoints (<15→10, 15-30→22, 30-60→45,
    // 60-120→90, Livre→0). Bloco 14 consome.
    const entries = [
      (10, '< 15 min'),
      (22, '15-30 min'),
      (45, '30-60 min'),
      (90, '60-120 min'),
      (0, 'Livre'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tempo disponível',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (final entry in entries)
          QuizOptionTile(
            label: entry.$2,
            selected: _timeMinutes == entry.$1,
            onTap: () => setState(() => _timeMinutes = entry.$1),
          ),
      ],
    );
  }
}
