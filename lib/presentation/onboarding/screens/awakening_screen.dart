import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/tutorial_service.dart';
import '../../../domain/enums/intensity.dart';
import '../../../domain/enums/mission_category.dart';
import '../../../domain/enums/mission_style.dart';
import '../../../domain/models/extras_mission_spec.dart';
import '../../../domain/models/mission_preferences.dart';
import '../../../domain/services/body_metrics_service.dart';

/// Sprint 3.1 Bloco 14.6a — Onboarding Soulslike Fundido.
///
/// Funde o awakening narrativo (v0.28.2) com o quiz de calibração
/// (Bloco 9) numa cerimônia única executada no despertar. Substitui a
/// phase13 do TutorialManager — que foi removida do `runAll` — e grava
/// as preferências de missão direto do Awakening.
///
/// ## Fluxo
///   0. Ruínas: "Você desperta entre ruínas..."
///   1. O Vazio: "Você não é de Caelum..."
///   2. Nome: "Como devemos lhe chamar?"
///   3. Encruzilhada: escolha direta entre os 4 pilares (peso x2)
///   4-6. Três cenários morais, cada um com 4 opções mapeadas aos pilares
///   7. Conclusão: "Vai. Que Caelum reconheça..."
///
/// ## Compilação do foco
/// Votação ponderada: direta conta 2, cada cenário conta 1. Empate
/// resolvido pela escolha direta. Lógica isolada em [AwakeningCeremony]
/// pra ser coberta por testes unitários.
///
/// ## Efeitos colaterais no finish
///   - `AuthLocalDs.completeOnboarding` (name + narrativeMode='longa')
///   - `MissionPreferencesService.save` (primaryFocus + defaults)
///   - 4x `MissionRepository.insert` (uma missão por pilar, modality
///     `real`, tab `individual`, reward calculada pelo
///     [MissionBalancerService])
///   - `TutorialService.markDone(phase0_onboarding)` +
///     `markDone(phase13_mission_calibration)` — este último pra não
///     disparar o quiz antigo via drawer residual
///   - `context.go('/sanctuary')`
class AwakeningScreen extends ConsumerStatefulWidget {
  const AwakeningScreen({super.key});
  @override
  ConsumerState<AwakeningScreen> createState() => _AwakeningScreenState();
}

class _AwakeningScreenState extends ConsumerState<AwakeningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _dialogCtrl;
  late final Animation<double> _bgFade;
  late final Animation<Offset> _dialogSlide;
  late final Animation<double> _dialogFade;

  int _step = 0;
  final _nameCtrl = TextEditingController();
  MissionCategory? _directChoice;
  final List<MissionCategory?> _scenarioChoices = [null, null, null];
  bool _ready = false;
  bool _finishing = false;

  // Sprint 3.2 Etapa 1.0 — Calibração do Sistema (pós-cerimônia, pré-finish).
  // Visual separado da cerimônia: sem _SceneBg, sem narrativa do Vazio.
  bool _inCalibration = false;
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String? _weightError;
  String? _heightError;

  List<_Scene> get _scenes => [
        // 0 — Ruínas
        const _Scene(
          npc: null,
          text:
              'Você desperta entre ruínas antigas…\n\nA luz do céu parece quebrada.\n\nHá algo errado com seu corpo.',
          mood: _Mood.ruins,
        ),
        // 1 — O Vazio se apresenta
        const _Scene(
          npc: 'O Vazio',
          text:
              '"Você não é de Caelum.\n\nSua forma aqui é uma Sombra — ainda instável.\n\nSe quiser sobreviver, vai precisar aprender rápido."',
          mood: _Mood.npc,
          isVoid: true,
        ),
        // 2 — Nome
        const _Scene(
          npc: 'O Vazio',
          text: 'Como devemos lhe chamar?',
          mood: _Mood.identity,
          isNameInput: true,
          isVoid: true,
        ),
        // 3 — Encruzilhada (direta, peso x2)
        const _Scene(
          npc: 'O Vazio',
          text:
              '"Quatro pilares sustentam quem caminha em Caelum.\n\nQual deles chama teu nome primeiro?"',
          mood: _Mood.crossroads,
          isDirectChoice: true,
          isVoid: true,
        ),
        // 4 — Cenário 1: Besta Ferida
        _scenarioScene(0),
        // 5 — Cenário 2: Torre em Ruínas
        _scenarioScene(1),
        // 6 — Cenário 3: Pacto Oferecido
        _scenarioScene(2),
        // 7 — Conclusão
        const _Scene(
          npc: 'O Vazio',
          text:
              '"Tuas escolhas pesaram.\n\nCaelum já reconhece por onde vais andar.\n\nVai. A Sombra te segue."',
          mood: _Mood.conclusion,
          isFinish: true,
          isVoid: true,
        ),
      ];

  _Scene _scenarioScene(int index) {
    final scenario = AwakeningCeremony.scenarios[index];
    return _Scene(
      npc: 'O Vazio',
      text: scenario.prompt,
      mood: _Mood.scenario,
      isScenario: true,
      scenarioIndex: index,
      isVoid: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _dialogCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);
    _dialogSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _dialogCtrl, curve: Curves.easeOut));
    _dialogFade = CurvedAnimation(parent: _dialogCtrl, curve: Curves.easeIn);

    _bgCtrl.forward().then((_) {
      _dialogCtrl.forward().then((_) => setState(() => _ready = true));
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _dialogCtrl.dispose();
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _advance() async {
    if (!_ready || _finishing) return;
    final scene = _scenes[_step];

    if (scene.isNameInput && _nameCtrl.text.trim().isEmpty) return;
    if (scene.isDirectChoice && _directChoice == null) return;
    if (scene.isScenario && _scenarioChoices[scene.scenarioIndex!] == null) {
      return;
    }

    if (scene.isFinish) {
      // Sprint 3.2 Etapa 1.0 — antes do finish narrativo, exibe a tela
      // separada de Calibração do Sistema (peso/altura). Visual rompe
      // com a cerimônia de propósito — é setup técnico funcional.
      setState(() => _inCalibration = true);
      return;
    }

    if (_step >= _scenes.length - 1) {
      setState(() => _inCalibration = true);
      return;
    }

    setState(() => _ready = false);
    await _dialogCtrl.reverse();
    setState(() => _step++);
    await _dialogCtrl.forward();
    setState(() => _ready = true);
  }

  /// Sprint 3.2 Etapa 1.0 — confirma a Calibração do Sistema.
  /// Valida ranges, persiste peso/altura e dispara o `_finish` narrativo
  /// original (preferences + extras + onboarding done + nav /sanctuary).
  Future<void> _confirmCalibration() async {
    if (_finishing) return;
    final weight = int.tryParse(_weightCtrl.text.trim());
    final height = int.tryParse(_heightCtrl.text.trim());
    final service = ref.read(bodyMetricsServiceProvider);
    final wOk = weight != null && service.isValidWeight(weight);
    final hOk = height != null && service.isValidHeight(height);
    setState(() {
      _weightError = wOk
          ? null
          : 'Use um valor entre ${BodyMetricsService.minWeightKg} e '
              '${BodyMetricsService.maxWeightKg} kg';
      _heightError = hOk
          ? null
          : 'Use um valor entre ${BodyMetricsService.minHeightCm} e '
              '${BodyMetricsService.maxHeightCm} cm';
    });
    if (!wOk || !hOk) return;

    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      if (mounted) context.go('/sanctuary');
      return;
    }
    await service.save(
        playerId: player.id, weightKg: weight, heightCm: height);
    await _finish();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      if (mounted) context.go('/sanctuary');
      return;
    }

    final primaryFocus = AwakeningCeremony.compilePrimaryFocus(
      direct: _directChoice!,
      scenarios: List<MissionCategory>.from(
          _scenarioChoices.map((c) => c!)),
    );

    final now = DateTime.now();
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Sombra'
        : _nameCtrl.text.trim();

    final authDs = ref.read(authDsProvider);
    await authDs.completeOnboarding(player.id, name, 'longa');

    await ref.read(missionPreferencesServiceProvider).save(
          MissionPreferences(
            playerId: player.id,
            primaryFocus: primaryFocus,
            intensity: Intensity.medium,
            missionStyle: MissionStyle.mixed,
            createdAt: now,
            updatedAt: now,
          ),
        );

    // Sprint 3.1 Bloco 14.5 — ao invés de inserir 4 MissionProgress
    // (padrão abandonado pelo CEO), salva 1 `ExtrasMissionSpec`
    // dinâmica em `SharedPreferences`. O `ExtrasCatalogService` faz
    // merge com o catálogo estático e o `QuestsScreenNotifier` (14.6c)
    // renderiza na seção EXTRAS de `/quests`.
    final extraSpec = AwakeningCeremony.awakeningExtraFor(primaryFocus);
    await ref
        .read(extrasCatalogServiceProvider)
        .saveAwakeningExtra(player.id, extraSpec);

    await TutorialService.markDone(TutorialPhase.phase0_onboarding);
    await TutorialService.markDone(TutorialPhase.phase13_mission_calibration);

    final updated = await authDs.currentSession();
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    context.go('/sanctuary');
  }

  @override
  Widget build(BuildContext context) {
    if (_inCalibration) return _buildCalibrationScreen();

    final scene = _scenes[_step];
    final tapAdvances = !scene.isNameInput &&
        !scene.isDirectChoice &&
        !scene.isScenario &&
        !scene.isFinish;
    return GestureDetector(
      onTap: tapAdvances ? _advance : null,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(opacity: _bgFade, child: _SceneBg(mood: scene.mood)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            if (scene.npc == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: FadeTransition(
                    opacity: _dialogFade,
                    child: Text(
                      scene.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                        height: 1.8,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ),
            if (scene.npc != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SlideTransition(
                  position: _dialogSlide,
                  child: FadeTransition(
                    opacity: _dialogFade,
                    child: _buildBottomDialog(scene),
                  ),
                ),
              ),
            if (tapAdvances)
              Align(
                alignment: const Alignment(0, -0.3),
                child: FadeTransition(
                  opacity: _dialogFade,
                  child: _PulsingTapHint(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Sprint 3.2 Etapa 1.0 — tela "Calibração do Sistema".
  ///
  /// Visualmente separada da cerimônia de propósito (sem _SceneBg/animação,
  /// sem narrativa do Vazio). É setup técnico funcional — pense nas telas
  /// de alocação inicial de Dark Souls. Estética soulslike preservada via
  /// CinzelDecorative + gold contido + borda gold simples.
  Widget _buildCalibrationScreen() {
    return Scaffold(
      backgroundColor: AppColors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CALIBRAÇÃO DO SISTEMA',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 14,
                      color: AppColors.gold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Antes de iniciar tuas missões, o sistema precisa calibrar tuas medidas pra calcular hidratação e nutrição corretas.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildCalibrationField(
                    keyName: 'calibration-weight',
                    label: 'Peso',
                    unit: 'kg',
                    controller: _weightCtrl,
                    error: _weightError,
                  ),
                  const SizedBox(height: 12),
                  _buildCalibrationField(
                    keyName: 'calibration-height',
                    label: 'Altura',
                    unit: 'cm',
                    controller: _heightCtrl,
                    error: _heightError,
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: Listenable.merge([_weightCtrl, _heightCtrl]),
                    builder: (_, __) {
                      final w = int.tryParse(_weightCtrl.text.trim());
                      final h = int.tryParse(_heightCtrl.text.trim());
                      final svc = ref.read(bodyMetricsServiceProvider);
                      final enabled = !_finishing &&
                          w != null &&
                          h != null &&
                          svc.isValidWeight(w) &&
                          svc.isValidHeight(h);
                      return _buildCalibrationBtn(enabled);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalibrationField({
    required String keyName,
    required String label,
    required String unit,
    required TextEditingController controller,
    required String? error,
  }) {
    return TextField(
      key: ValueKey(keyName),
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.roboto(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        labelStyle: GoogleFonts.roboto(color: AppColors.textMuted),
        suffixStyle: GoogleFonts.roboto(color: AppColors.textMuted),
        errorText: error,
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.7), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCalibrationBtn(bool enabled) {
    return GestureDetector(
      key: const ValueKey('calibration-continue'),
      onTap: enabled ? _confirmCalibration : null,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.25),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
          color: enabled
              ? AppColors.gold.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Center(
          child: Text(
            _finishing ? 'CALIBRANDO…' : 'CONTINUAR',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 12,
              color: enabled ? AppColors.gold : AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomDialog(_Scene scene) {
    final isVoid = scene.isVoid;
    final color = isVoid ? AppColors.purple : AppColors.gold;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0010).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.shadowVoid,
                      border: Border.all(
                          color: color.withValues(alpha: 0.7), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 12)
                      ],
                    ),
                    child: Icon(
                        isVoid ? Icons.blur_on : Icons.person_outline,
                        color: color,
                        size: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(scene.npc!,
                      style: GoogleFonts.roboto(
                          fontSize: 8, color: color, letterSpacing: 1),
                      textAlign: TextAlign.center),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    border:
                        Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    scene.text,
                    style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ],
          ),
          if (scene.isNameInput) ...[
            const SizedBox(height: 16),
            _buildNameInput(),
            const SizedBox(height: 12),
            _buildBtn('Confirmar', _advance),
          ],
          if (scene.isDirectChoice) ...[
            const SizedBox(height: 14),
            _buildDirectChoice(),
            if (_directChoice != null) ...[
              const SizedBox(height: 10),
              _buildBtn('Continuar', _advance),
            ],
          ],
          if (scene.isScenario) ...[
            const SizedBox(height: 14),
            _buildScenarioChoice(scene.scenarioIndex!),
            if (_scenarioChoices[scene.scenarioIndex!] != null) ...[
              const SizedBox(height: 10),
              _buildBtn('Seguir adiante', _advance),
            ],
          ],
          if (scene.isFinish) ...[
            const SizedBox(height: 14),
            _buildBtn('Despertar', _advance),
          ],
        ],
      ),
    );
  }

  Widget _buildNameInput() => TextField(
        controller: _nameCtrl,
        style: GoogleFonts.cinzelDecorative(
            color: AppColors.textPrimary, fontSize: 16),
        textAlign: TextAlign.center,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Nome da sua Sombra',
          hintStyle: GoogleFonts.roboto(color: AppColors.textMuted),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.purple)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.purple, width: 1.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
        ),
      );

  Widget _buildDirectChoice() => Column(
        children: MissionCategory.values.map((cat) {
          final selected = _directChoice == cat;
          return _ChoiceTile(
            label: cat.display,
            hint: _pillarHint(cat),
            selected: selected,
            onTap: () => setState(() => _directChoice = cat),
          );
        }).toList(),
      );

  Widget _buildScenarioChoice(int index) {
    final scenario = AwakeningCeremony.scenarios[index];
    return Column(
      children: scenario.options.map((opt) {
        final selected = _scenarioChoices[index] == opt.mapsTo;
        return _ChoiceTile(
          label: opt.label,
          hint: null,
          selected: selected,
          onTap: () => setState(() => _scenarioChoices[index] = opt.mapsTo),
        );
      }).toList(),
    );
  }

  String _pillarHint(MissionCategory cat) => switch (cat) {
        MissionCategory.fisico => 'Corpo que resiste. Força forjada na carne.',
        MissionCategory.mental => 'Mente afiada. Estudo e estratégia.',
        MissionCategory.espiritual =>
          'Silêncio interno. Rituais e presença.',
        MissionCategory.vitalismo =>
          'Ciclo entre os pilares. Fluxo que integra.',
      };

  Widget _buildBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: _finishing ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.purple, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.purple.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5)),
          ),
        ),
      );
}

/// Cerimônia do Awakening 14.6a — lógica pura extraída do widget pra ser
/// coberta por testes unitários. A tela consome diretamente via chamadas
/// estáticas, mantendo `AwakeningScreen` enxuto.
class AwakeningCeremony {
  const AwakeningCeremony._();

  /// Votação ponderada: direta pesa 2, cada cenário pesa 1. Empate é
  /// resolvido pela escolha direta (sempre entra no pool de empatados
  /// por construção).
  static MissionCategory compilePrimaryFocus({
    required MissionCategory direct,
    required List<MissionCategory> scenarios,
  }) {
    final votes = <MissionCategory, int>{for (final c in MissionCategory.values) c: 0};
    votes[direct] = (votes[direct] ?? 0) + 2;
    for (final s in scenarios) {
      votes[s] = (votes[s] ?? 0) + 1;
    }
    var maxVotes = -1;
    final leaders = <MissionCategory>[];
    for (final entry in votes.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        leaders
          ..clear()
          ..add(entry.key);
      } else if (entry.value == maxVotes) {
        leaders.add(entry.key);
      }
    }
    if (leaders.contains(direct)) return direct;
    return leaders.first;
  }

  /// Sprint 3.1 Bloco 14.5 — retorna a `ExtrasMissionSpec` baseada no
  /// pilar compilado no quiz. 1 entry por jogador, doada pelo "O Vazio"
  /// (type: npc). Copy canônico (aprovado CEO 14.5).
  ///
  /// Rewards zeradas — é missão narrativa sem rastreio quantitativo
  /// de progresso; o botão "Aceitar" é placeholder no Bloco 11a
  /// (débito em `DEBITO_EXTRAS_GATE.md`).
  static ExtrasMissionSpec awakeningExtraFor(MissionCategory pillar) =>
      switch (pillar) {
        MissionCategory.fisico => const ExtrasMissionSpec(
            key: 'awakening_primeira_forja',
            type: ExtraMissionType.npc,
            title: 'A Primeira Forja',
            description:
                'O Vazio observa teus músculos despertarem. Forje teu corpo pela primeira vez.',
          ),
        MissionCategory.mental => const ExtrasMissionSpec(
            key: 'awakening_primeiro_veu',
            type: ExtraMissionType.npc,
            title: 'O Primeiro Véu',
            description:
                'O Vazio te oferece uma página em branco. Que tua mente lave o que vê.',
          ),
        MissionCategory.espiritual => const ExtrasMissionSpec(
            key: 'awakening_primeiro_silencio',
            type: ExtraMissionType.npc,
            title: 'O Primeiro Silêncio',
            description:
                'O Vazio te convida ao silêncio. Escuta o que o mundo esconde.',
          ),
        MissionCategory.vitalismo => const ExtrasMissionSpec(
            key: 'awakening_primeiro_ciclo',
            type: ExtraMissionType.npc,
            title: 'O Primeiro Ciclo',
            description:
                'O Vazio observa teu equilíbrio. Une corpo, mente e alma pela primeira vez.',
          ),
      };

  static const List<AwakeningScenario> scenarios = [
    AwakeningScenario(
      prompt:
          '"Uma besta ferida — teu companheiro de caminho — agoniza aos teus pés. O que fazes?"',
      options: [
        AwakeningOption(
            label: 'Pôr fim ao sofrimento de uma vez, com tuas próprias mãos',
            mapsTo: MissionCategory.fisico),
        AwakeningOption(
            label: 'Abandonar o aliado e seguir adiante',
            mapsTo: MissionCategory.mental),
        AwakeningOption(
            label: 'Tentar curá-lo — não sabes ainda como',
            mapsTo: MissionCategory.espiritual),
        AwakeningOption(
            label: 'Velar ao lado dele até o ciclo se fechar',
            mapsTo: MissionCategory.vitalismo),
      ],
    ),
    AwakeningScenario(
      prompt:
          '"Uma torre em ruínas ergue-se à frente. Na base, gravado em pedra: \'Só os dignos entram\'. E agora?"',
      options: [
        AwakeningOption(
            label: 'Forçar a entrada a golpes — a dignidade se prova na ação',
            mapsTo: MissionCategory.fisico),
        AwakeningOption(
            label: 'Decifrar a inscrição antes de tocar em nada',
            mapsTo: MissionCategory.mental),
        AwakeningOption(
            label: 'Ajoelhar e pedir permissão ao que habita ali',
            mapsTo: MissionCategory.espiritual),
        AwakeningOption(
            label: 'Rodear a torre até achar outra passagem',
            mapsTo: MissionCategory.vitalismo),
      ],
    ),
    AwakeningScenario(
      prompt:
          '"Uma entidade sem forma te oferece poder em troca de um fragmento da tua alma. Resposta?"',
      options: [
        AwakeningOption(
            label: 'Aceitar e carregar o peso',
            mapsTo: MissionCategory.fisico),
        AwakeningOption(
            label: 'Negociar as condições, frase por frase',
            mapsTo: MissionCategory.mental),
        AwakeningOption(
            label: 'Recusar — a alma não é moeda',
            mapsTo: MissionCategory.espiritual),
        AwakeningOption(
            label: 'Provar o pacto e ver até onde vai',
            mapsTo: MissionCategory.vitalismo),
      ],
    ),
  ];
}

class AwakeningScenario {
  final String prompt;
  final List<AwakeningOption> options;
  const AwakeningScenario({required this.prompt, required this.options});
}

class AwakeningOption {
  final String label;
  final MissionCategory mapsTo;
  const AwakeningOption({required this.label, required this.mapsTo});
}

class _Scene {
  final String? npc;
  final String text;
  final _Mood mood;
  final bool isNameInput;
  final bool isDirectChoice;
  final bool isScenario;
  final int? scenarioIndex;
  final bool isFinish;
  final bool isVoid;
  const _Scene({
    required this.npc,
    required this.text,
    required this.mood,
    this.isNameInput = false,
    this.isDirectChoice = false,
    this.isScenario = false,
    this.scenarioIndex,
    this.isFinish = false,
    this.isVoid = false,
  });
}

enum _Mood { ruins, npc, identity, crossroads, scenario, conclusion }

class _ChoiceTile extends StatelessWidget {
  final String label;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? AppColors.gold : AppColors.border,
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? AppColors.gold.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 12,
                        color:
                            selected ? AppColors.gold : AppColors.textPrimary),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 3),
                    Text(hint!,
                        style: GoogleFonts.roboto(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: AppColors.gold, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SceneBg extends StatefulWidget {
  final _Mood mood;
  const _SceneBg({required this.mood});
  @override
  State<_SceneBg> createState() => _SceneBgState();
}

class _SceneBgState extends State<_SceneBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
            painter: _BgPainter(mood: widget.mood, t: _ctrl.value),
            child: Container()),
      );
}

class _BgPainter extends CustomPainter {
  final _Mood mood;
  final double t;
  _BgPainter({required this.mood, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    switch (mood) {
      case _Mood.ruins:
        _bg(canvas, size, p, const Color(0xFF0A0015),
            const Color(0xFF1A0A2E));
        _drawRuins(canvas, size, p);
        break;
      case _Mood.npc:
        _bg(canvas, size, p, const Color(0xFF0D0010),
            const Color(0xFF120820));
        _glow(canvas, size, p, const Color(0xFF4A1080));
        break;
      case _Mood.identity:
        _bg(canvas, size, p, const Color(0xFF080010),
            const Color(0xFF0F0520));
        _glow(canvas, size, p, const Color(0xFF7C3AED));
        _goldGlow(canvas, size, p);
        break;
      case _Mood.crossroads:
        _bg(canvas, size, p, const Color(0xFF0A0010),
            const Color(0xFF180A30));
        _glow(canvas, size, p, const Color(0xFF8B3DFF));
        _goldGlow(canvas, size, p);
        break;
      case _Mood.scenario:
        _bg(canvas, size, p, const Color(0xFF0B0014),
            const Color(0xFF1A0628));
        _glow(canvas, size, p, const Color(0xFF5A1F90));
        break;
      case _Mood.conclusion:
        _bg(canvas, size, p, const Color(0xFF0A0005),
            const Color(0xFF1A0530));
        _glow(canvas, size, p, const Color(0xFF8B3DFF));
        _goldGlow(canvas, size, p);
        break;
    }
  }

  void _bg(Canvas c, Size s, Paint p, Color top, Color bot) {
    p.shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bot])
        .createShader(Offset.zero & s);
    c.drawRect(Offset.zero & s, p);
    p.shader = null;
  }

  void _drawRuins(Canvas c, Size s, Paint p) {
    p.color = const Color(0xFF3D1F6E).withValues(alpha: 0.4 + t * 0.2);
    p.strokeWidth = 1.5;
    p.style = PaintingStyle.stroke;
    final lines = [
      [Offset(0, s.height * 0.15), Offset(s.width * 0.4, s.height * 0.12)],
      [
        Offset(s.width * 0.4, s.height * 0.12),
        Offset(s.width * 0.7, s.height * 0.18)
      ],
      [
        Offset(s.width * 0.7, s.height * 0.18),
        Offset(s.width, s.height * 0.14)
      ],
      [Offset(s.width * 0.1, s.height * 0.12), Offset(s.width * 0.1, s.height * 0.45)],
      [Offset(s.width * 0.9, s.height * 0.14), Offset(s.width * 0.9, s.height * 0.42)],
      [Offset(s.width * 0.4, s.height * 0.08), Offset(s.width * 0.4, s.height * 0.35)],
    ];
    for (final l in lines) {
      c.drawLine(l[0], l[1], p);
    }
    p.style = PaintingStyle.fill;
    p.color = const Color(0xFF8B3DFF).withValues(alpha: 0.3 + t * 0.3);
    for (final l in lines) {
      c.drawCircle(l[0], 2 + t * 1.5, p);
    }
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 8; i++) {
      final x = s.width * (0.1 + i * 0.1 + t * 0.02);
      final y = s.height * (0.1 + (i % 3) * 0.08 + t * 0.015);
      p.color = const Color(0xFF8B3DFF).withValues(alpha: 0.2 + t * 0.15);
      c.drawCircle(Offset(x, y), 1.5 + t, p);
    }
    p.maskFilter = null;
  }

  void _glow(Canvas c, Size s, Paint p, Color color) {
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    p.color = color.withValues(alpha: 0.15 + t * 0.08);
    c.drawCircle(Offset(s.width * .5, s.height * .3), s.width * .6, p);
    p.maskFilter = null;
  }

  void _goldGlow(Canvas c, Size s, Paint p) {
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    p.color = const Color(0xFFC2A05A).withValues(alpha: 0.06 + t * 0.04);
    c.drawCircle(Offset(s.width * .8, s.height * .7), s.width * .4, p);
    p.maskFilter = null;
  }

  @override
  bool shouldRepaint(covariant _BgPainter o) => o.t != t || o.mood != mood;
}

class _PulsingTapHint extends StatefulWidget {
  @override
  State<_PulsingTapHint> createState() => _PulsingTapHintState();
}

class _PulsingTapHintState extends State<_PulsingTapHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textMuted, width: 1),
            ),
            child: const Icon(Icons.touch_app_outlined,
                color: AppColors.textMuted, size: 16),
          ),
        ],
      ),
    );
  }
}
