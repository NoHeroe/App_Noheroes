import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../domain/enums/intensity.dart';
import '../../../domain/enums/mission_category.dart';
import '../../../domain/services/individual_creation_service.dart';
import '../../../domain/services/mission_balancer_service.dart';
import '../../mission_calibration/widgets/quiz_option_tile.dart';
import '../../shared/widgets/npc_dialog_overlay.dart';

/// Sprint 3.1 Bloco 11b.1 — form de criação de missão individual
/// (ADR 0014 §Família Individual + DESIGN_DOC §4 + §8).
///
/// Pattern reuso do `MissionCalibrationScreen` (Bloco 9): multi-step
/// via `_stepIndex` + setState, validação por step desabilita botão
/// Próximo, NPC overlay na conclusão, `ctx.go('/quests')` final.
///
/// ## 4 Steps
///
///   1. Identity: nome (TextField) + descrição (TextField multiline)
///   2. Focus & Intensity: categoria (4 chips) + intensidade (3 chips)
///   3. Frequency & Quantity: frequência (4 chips) + quantidade (numeric)
///   4. Review: resumo + toggle repetível + preview reward ao vivo +
///      botão "Criar missão"
///
/// ## Preview reward
///
/// **Inline no `build()`** — sem cache em field. Toggle repetível roda
/// `setState`, `build` re-executa, `balancer.calculate` recomputa. Função
/// pura, recálculo barato. Cache + invalidação manual seria bug
/// silencioso (copy-paste decisão do CEO).
///
/// ## Error handling
///
/// `IndividualLimitExceededException` → SnackBar curta + mantém na
/// tela (jogador aperta Voltar ou vai apagar missão ativa).
/// Outros erros → SnackBar genérica.
class IndividualCreationScreen extends ConsumerStatefulWidget {
  const IndividualCreationScreen({super.key});

  @override
  ConsumerState<IndividualCreationScreen> createState() =>
      _IndividualCreationScreenState();
}

enum _Step { identity, focusIntensity, frequencyQuantity, review }

class _IndividualCreationScreenState
    extends ConsumerState<IndividualCreationScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  MissionCategory? _categoria;
  Intensity? _intensity;
  IndividualFrequency? _frequencia;
  bool _repetivel = false;

  int _stepIndex = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  _Step get _step => _Step.values[_stepIndex];

  bool get _nameValid {
    final t = _nameCtrl.text.trim();
    return t.isNotEmpty && t.length <= 100;
  }

  bool get _descriptionValid {
    final t = _descCtrl.text.trim();
    return t.isNotEmpty && t.length <= 500;
  }

  int? get _qtyParsed {
    final n = int.tryParse(_qtyCtrl.text.trim());
    if (n == null || n <= 0 || n >= 10000) return null;
    return n;
  }

  bool get _canAdvance {
    switch (_step) {
      case _Step.identity:
        return _nameValid && _descriptionValid;
      case _Step.focusIntensity:
        return _categoria != null && _intensity != null;
      case _Step.frequencyQuantity:
        return _frequencia != null && _qtyParsed != null;
      case _Step.review:
        return !_submitting;
    }
  }

  Future<void> _next() async {
    if (_step == _Step.review) {
      await _submit();
      return;
    }
    setState(() => _stepIndex++);
  }

  void _back() {
    if (_stepIndex > 0) setState(() => _stepIndex--);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final qty = _qtyParsed;
    if (qty == null ||
        _categoria == null ||
        _intensity == null ||
        _frequencia == null) {
      return;
    }
    final rank =
        GuildRankSystem.fromString(player.guildRank.toLowerCase());

    setState(() => _submitting = true);
    try {
      await ref.read(individualCreationServiceProvider).createIndividual(
            IndividualCreationParams(
              playerId: player.id,
              name: _nameCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              categoria: _categoria!,
              intensity: _intensity!,
              frequencia: _frequencia!,
              quantityTarget: qty,
              isRepetivel: _repetivel,
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
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao criar: $e')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    await NpcDialogOverlay.show(
      context,
      npcName: 'O Vazio',
      npcTitle: 'Presenca silenciosa',
      message: 'Nova promessa lavrada. Falhar custa o dobro na Sombra.',
    );
    if (!mounted) return;
    // Regra 4 N/A: IndividualCreationService não invalida playersTable.
    // QuestsScreenNotifier recebe IndividualCreated via bus listener
    // (Bloco 11b.2 adiciona o listener pra reagir).
    context.go('/quests');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar missão individual'),
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
                value: (_stepIndex + 1) / _Step.values.length,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(child: _buildStep(_step)),
              ),
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
                      key: const ValueKey('creation-next'),
                      onPressed:
                          (_canAdvance && !_submitting) ? _next : null,
                      child: Text(_step == _Step.review
                          ? 'Criar missão'
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

  Widget _buildStep(_Step s) {
    return switch (s) {
      _Step.identity => _buildIdentity(),
      _Step.focusIntensity => _buildFocusIntensity(),
      _Step.frequencyQuantity => _buildFrequencyQuantity(),
      _Step.review => _buildReview(),
    };
  }

  Widget _buildIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Descreve tua missão',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('creation-name'),
          controller: _nameCtrl,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: 'Nome',
            hintText: 'ex: Flexões da manhã',
            errorText: _nameCtrl.text.isNotEmpty && !_nameValid
                ? 'Nome não pode ser vazio e tem que caber em 100 caracteres'
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('creation-description'),
          controller: _descCtrl,
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Descrição',
            hintText: 'ex: 3 séries de 20 repetições',
            errorText: _descCtrl.text.isNotEmpty && !_descriptionValid
                ? 'Descrição não pode ser vazia e tem que caber em 500 caracteres'
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildFocusIntensity() {
    const categories = [
      (MissionCategory.fisico, 'Físico', 'Corpo, disciplina física'),
      (MissionCategory.mental, 'Mental', 'Mente, estudo, foco'),
      (MissionCategory.espiritual, 'Espiritual', 'Propósito, silêncio'),
      (MissionCategory.vitalismo, 'Vitalismo', 'Equilíbrio, presença'),
    ];
    const intensities = [
      (Intensity.light, 'Leve'),
      (Intensity.medium, 'Médio'),
      (Intensity.heavy, 'Pesado'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Qual caminho e esforço?',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        const Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final c in categories)
          QuizOptionTile(
            key: ValueKey('creation-cat-${c.$1.storage}'),
            label: c.$2,
            description: c.$3,
            selected: _categoria == c.$1,
            onTap: () => setState(() => _categoria = c.$1),
          ),
        const SizedBox(height: 16),
        const Text('Intensidade',
            style: TextStyle(fontWeight: FontWeight.bold)),
        for (final i in intensities)
          QuizOptionTile(
            key: ValueKey('creation-int-${i.$1.name}'),
            label: i.$2,
            selected: _intensity == i.$1,
            onTap: () => setState(() => _intensity = i.$1),
          ),
      ],
    );
  }

  Widget _buildFrequencyQuantity() {
    const freqs = [
      (IndividualFrequency.oneShot, 'Uma vez', 'Sem prazo — completa quando marcar'),
      (IndividualFrequency.dias, 'Diária', 'Prazo 1 dia'),
      (IndividualFrequency.semanas, 'Semanal', 'Prazo 7 dias'),
      (IndividualFrequency.mensal, 'Mensal', 'Prazo 30 dias'),
    ];
    final qtyErr = _qtyCtrl.text.isNotEmpty && _qtyParsed == null
        ? 'Entre 1 e 9999'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quando e quanto?',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        const Text('Frequência',
            style: TextStyle(fontWeight: FontWeight.bold)),
        for (final f in freqs)
          QuizOptionTile(
            key: ValueKey('creation-freq-${f.$1.storage}'),
            label: f.$2,
            description: f.$3,
            selected: _frequencia == f.$1,
            onTap: () => setState(() => _frequencia = f.$1),
          ),
        const SizedBox(height: 16),
        const Text('Quantidade alvo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('creation-qty'),
          controller: _qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Meta numérica',
            hintText: 'ex: 20',
            errorText: qtyErr,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final delta in const [-10, -1, 1, 10])
              OutlinedButton(
                key: ValueKey('creation-qty-stepper-$delta'),
                onPressed: () {
                  final current = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
                  final next = (current + delta).clamp(0, 9999);
                  _qtyCtrl.text = next == 0 ? '' : next.toString();
                  setState(() {});
                },
                child: Text(delta > 0 ? '+$delta' : '$delta'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReview() {
    // Preview do reward é computado INLINE aqui. Se faltar algum campo
    // (usuário conseguiu chegar no step 4 sem preencher), mostra dash.
    final player = ref.read(currentPlayerProvider);
    int? xp;
    int? gold;
    if (player != null &&
        _categoria != null &&
        _intensity != null &&
        _frequencia != null &&
        _qtyParsed != null) {
      final rank =
          GuildRankSystem.fromString(player.guildRank.toLowerCase());
      final reward =
          ref.read(missionBalancerServiceProvider).calculate(
                BalancerInput(
                  categoria: _categoria!,
                  intensity: _intensity!,
                  rank: rank,
                  isRepetivel: _repetivel,
                ),
              );
      xp = reward.xp;
      gold = reward.gold;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Revisa e confirma',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Nome', _nameCtrl.text.trim()),
                _kv('Descrição', _descCtrl.text.trim()),
                _kv('Categoria', _categoria?.display ?? '-'),
                _kv('Intensidade', _intensity?.display ?? '-'),
                _kv('Frequência',
                    _frequencia == null ? '-' : _freqLabel(_frequencia!)),
                _kv('Quantidade', '${_qtyParsed ?? "-"}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          key: const ValueKey('creation-repetivel'),
          title: const Text('Missão repetível'),
          subtitle: Text(_repetivel
              ? 'Reward reduzida 30% — vira diária'
              : 'Marca uma única vez'),
          value: _repetivel,
          onChanged: (v) => setState(() => _repetivel = v),
        ),
        const SizedBox(height: 12),
        Card(
          key: const ValueKey('creation-reward-preview'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Reward estimada:',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('${xp ?? "-"} XP',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('${gold ?? "-"} ouro',
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:')),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis, maxLines: 2)),
        ],
      ),
    );
  }

  String _freqLabel(IndividualFrequency f) => switch (f) {
        IndividualFrequency.oneShot => 'Uma vez',
        IndividualFrequency.dias => 'Diária',
        IndividualFrequency.semanas => 'Semanal',
        IndividualFrequency.mensal => 'Mensal',
      };
}
