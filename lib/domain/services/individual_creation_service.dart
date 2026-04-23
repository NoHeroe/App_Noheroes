import 'dart:convert';

import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/utils/guild_rank.dart';
import '../../core/utils/requirements_helper.dart';
import '../../data/database/app_database.dart';
import '../balance/individual_creation_balance.dart';
import '../enums/intensity.dart';
import '../enums/mission_category.dart';
import '../enums/mission_modality.dart';
import '../enums/mission_tab_origin.dart';
import '../models/mission_progress.dart';
import '../repositories/mission_repository.dart';
import 'mission_balancer_service.dart';

/// Lançada quando o jogador atinge o limite de missões individuais ativas
/// do tier (FREE=5). ADR 0014 §Família Individual. UI consome pra mostrar
/// mensagem amigável + upgrade prompt futuro.
class IndividualLimitExceededException implements Exception {
  final int playerId;
  final int limit;
  final int current;
  const IndividualLimitExceededException({
    required this.playerId,
    required this.limit,
    required this.current,
  });

  @override
  String toString() =>
      'IndividualLimitExceeded(player=$playerId, $current/$limit)';
}

/// Frequência de execução de missão individual (DESIGN_DOC §8 + ADR 0014).
enum IndividualFrequency { oneShot, dias, semanas, mensal }

extension IndividualFrequencyExt on IndividualFrequency {
  String get storage => switch (this) {
        IndividualFrequency.oneShot => 'one_shot',
        IndividualFrequency.dias => 'dias',
        IndividualFrequency.semanas => 'semanas',
        IndividualFrequency.mensal => 'mensal',
      };

  /// Converte frequência em timestamp de `deadline_at` no `metaJson`.
  /// `oneShot` retorna `null` (sem deadline — completa quando jogador
  /// marcar). Outras calculam `now + N dias` pro sweep de expiração do
  /// Bloco 13 detectar.
  DateTime? deadlineFrom(DateTime now) => switch (this) {
        IndividualFrequency.oneShot => null,
        IndividualFrequency.dias => now.add(const Duration(days: 1)),
        IndividualFrequency.semanas => now.add(const Duration(days: 7)),
        IndividualFrequency.mensal => now.add(const Duration(days: 30)),
      };
}

/// Parâmetros pra `IndividualCreationService.createIndividual`. Imutável.
///
/// Sprint 3.1 Bloco 14.6b — requirements múltiplos restaurados
/// (fidelidade v0.28.2). Campo `quantityTarget` único vira lista de
/// [RequirementItem]. `targetValue` da row é `sum(requirements.target)`.
class IndividualCreationParams {
  final int playerId;
  final String name;

  /// Descrição pessoal livre do jogador (opcional). v0.28.2 era livre
  /// no TextField, pode ficar vazia.
  final String description;

  /// Descrição narrativa sorteada de `quest_templates.json` por
  /// categoria (v0.28.2 pattern). Opcional — jogador pode rejeitar.
  final String? autoDescription;

  final MissionCategory categoria;
  final Intensity intensity;
  final IndividualFrequency frequencia;

  /// Sub-requirements compostos (v0.28.2 pattern). Cada item tem
  /// `label`/`target`/`unit`. Mínimo 1 requirement. `targetValue` da
  /// missão = `requirements.fold((s, r) => s + r.target)`.
  final List<RequirementItem> requirements;

  final bool isRepetivel;
  final GuildRank rank;

  const IndividualCreationParams({
    required this.playerId,
    required this.name,
    required this.description,
    required this.categoria,
    required this.intensity,
    required this.frequencia,
    required this.requirements,
    required this.isRepetivel,
    required this.rank,
    this.autoDescription,
  });
}

/// Sprint 3.1 Bloco 11a (refatorado no 14.6b) — cria missão individual
/// (Família Individual, ADR 0014) com requirements múltiplos.
///
/// ## Atomicidade
///
/// Toda a operação fica numa `db.transaction`:
///
///   1. Valida entrada básica (nome não vazio, requirements não vazia,
///      cada `target > 0`)
///   2. Conta individuais ativas do jogador (`modality == individual`,
///      `completed_at IS NULL`, `failed_at IS NULL`)
///   3. Se count >= `kMaxActiveIndividualsFree` → `IndividualLimitExceededException`
///   4. Calcula reward via `MissionBalancerService`
///   5. Gera `missionKey = IND_USER_<timestamp>_<counter>`
///   6. Persiste `MissionProgress` com `metaJson`:
///      ```json
///      {
///        "name": "...",
///        "description": "...",
///        "auto_description": "...",
///        "category": "fisico",
///        "frequencia": "dias|semanas|mensal|one_shot",
///        "deadline_at": <millis | null>,
///        "is_repetivel": true|false,
///        "user_created": true,
///        "requirements": "[{...RequirementItem...}]"
///      }
///      ```
///
/// Emite `IndividualCreated` pós-commit.
class IndividualCreationService {
  final AppDatabase _db;
  final MissionRepository _missionRepo;
  final MissionBalancerService _balancer;
  final AppEventBus _bus;

  int _keyCounter = 0;

  IndividualCreationService({
    required AppDatabase db,
    required MissionRepository missionRepo,
    required MissionBalancerService balancer,
    required AppEventBus bus,
  })  : _db = db,
        _missionRepo = missionRepo,
        _balancer = balancer,
        _bus = bus;

  Future<int> createIndividual(IndividualCreationParams params) async {
    if (params.name.trim().isEmpty) {
      throw ArgumentError.value(
          params.name, 'name', 'nome não pode ser vazio');
    }
    if (params.requirements.isEmpty) {
      throw ArgumentError.value(params.requirements, 'requirements',
          'pelo menos 1 requisito é obrigatório');
    }
    for (final r in params.requirements) {
      if (r.target <= 0) {
        throw ArgumentError.value(r.target,
            'requirements[${params.requirements.indexOf(r)}].target',
            'target deve ser > 0');
      }
    }

    final reward = _balancer.calculate(BalancerInput(
      categoria: params.categoria,
      intensity: params.intensity,
      rank: params.rank,
      isRepetivel: params.isRepetivel,
    ));

    final now = DateTime.now();
    final deadline = params.frequencia.deadlineFrom(now);
    final missionKey =
        'IND_USER_${now.millisecondsSinceEpoch}_${_keyCounter++}';
    final targetSum =
        params.requirements.fold<int>(0, (s, r) => s + r.target);

    final metaJson = jsonEncode({
      'name': params.name,
      'description': params.description,
      'auto_description': params.autoDescription,
      'frequencia': params.frequencia.storage,
      'deadline_at': deadline?.millisecondsSinceEpoch,
      'is_repetivel': params.isRepetivel,
      'user_created': true,
      'category': params.categoria.storage,
      'requirements': RequirementsHelper.serialize(params.requirements),
    });

    final missionProgressId = await _db.transaction(() async {
      final active = await _missionRepo.findActive(params.playerId);
      final individualsAtivas = active
          .where((m) => m.modality == MissionModality.individual)
          .length;
      if (individualsAtivas >=
          IndividualCreationBalance.kMaxActiveIndividualsFree) {
        throw IndividualLimitExceededException(
          playerId: params.playerId,
          limit: IndividualCreationBalance.kMaxActiveIndividualsFree,
          current: individualsAtivas,
        );
      }

      return _missionRepo.insert(MissionProgress(
        id: 0,
        playerId: params.playerId,
        missionKey: missionKey,
        modality: MissionModality.individual,
        tabOrigin: MissionTabOrigin.extras,
        rank: params.rank,
        targetValue: targetSum,
        currentValue: 0,
        reward: reward,
        startedAt: now,
        rewardClaimed: false,
        metaJson: metaJson,
      ));
    });

    _bus.publish(IndividualCreated(
      playerId: params.playerId,
      missionProgressId: missionProgressId,
      missionKey: missionKey,
      categoria: params.categoria.storage,
    ));

    return missionProgressId;
  }
}
