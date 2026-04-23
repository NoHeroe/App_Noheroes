import 'dart:convert';

import '../../core/events/app_event_bus.dart';
import '../../core/events/mission_events.dart';
import '../../core/utils/guild_rank.dart';
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
class IndividualCreationParams {
  final int playerId;
  final String name;
  final String description;
  final MissionCategory categoria;
  final Intensity intensity;
  final IndividualFrequency frequencia;
  final int quantityTarget;
  final bool isRepetivel;
  final GuildRank rank;

  const IndividualCreationParams({
    required this.playerId,
    required this.name,
    required this.description,
    required this.categoria,
    required this.intensity,
    required this.frequencia,
    required this.quantityTarget,
    required this.isRepetivel,
    required this.rank,
  });
}

/// Sprint 3.1 Bloco 11a — cria missão individual (Família Individual,
/// ADR 0014).
///
/// ## Atomicidade
///
/// Toda a operação fica numa `db.transaction`:
///
///   1. Valida entrada básica (nome/descrição não vazios, quantityTarget > 0)
///   2. Conta individuais ativas do jogador (`modality == individual`,
///      `completed_at IS NULL`, `failed_at IS NULL`)
///   3. Se count >= `kMaxActiveIndividualsFree` → `IndividualLimitExceededException`
///   4. Calcula reward via `MissionBalancerService`
///   5. Gera `missionKey = IND_USER_<timestamp>_<counter>`
///      (colisões improváveis; se o jogador criar 2 no mesmo ms, contador
///      distingue)
///   6. Persiste `MissionProgress` com `metaJson` extendido:
///      ```json
///      {
///        "name": "...",
///        "description": "...",
///        "frequencia": "dias|semanas|mensal|one_shot",
///        "quantity_target": N,
///        "deadline_at": <millis | null>,
///        "is_repetivel": true|false,
///        "user_created": true
///      }
///      ```
///
/// Emite `IndividualCreated` pós-commit. Caller decide navegação.
///
/// ## Persistência direta (sem tabela custom_missions)
///
/// Decisão Q4 do plan-first: schema 24 não ganha tabela nova. Tudo
/// vira `player_mission_progress` com `missionKey` gerado + metaJson
/// carregando os campos de criação. Bloco 14 (assignment) usa
/// `metaJson['is_repetivel']` pra decidir reassign após completar.
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
    // 1. Validação de entrada (fora da transação — falha rápida).
    if (params.name.trim().isEmpty) {
      throw ArgumentError.value(
          params.name, 'name', 'nome não pode ser vazio');
    }
    if (params.description.trim().isEmpty) {
      throw ArgumentError.value(
          params.description, 'description', 'descrição não pode ser vazia');
    }
    if (params.quantityTarget <= 0) {
      throw ArgumentError.value(params.quantityTarget, 'quantityTarget',
          'quantity_target deve ser > 0');
    }

    // 2. Balancer (puro — fora da transação).
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

    final metaJson = jsonEncode({
      'name': params.name,
      'description': params.description,
      'frequencia': params.frequencia.storage,
      'quantity_target': params.quantityTarget,
      'deadline_at': deadline?.millisecondsSinceEpoch,
      'is_repetivel': params.isRepetivel,
      'user_created': true,
      // Categoria na meta pra filtros do QuestsScreenNotifier (Bloco 10a.1)
      // pegarem. Chave alinhada com o parser `_categoryOf`.
      'category': params.categoria.storage,
    });

    final missionProgressId = await _db.transaction(() async {
      // 3. Conta ativas — DENTRO da tx pra evitar race (outro caller
      //    criando ao mesmo tempo).
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

      // 4. Persiste MissionProgress.
      return _missionRepo.insert(MissionProgress(
        id: 0,
        playerId: params.playerId,
        missionKey: missionKey,
        modality: MissionModality.individual,
        tabOrigin: MissionTabOrigin.extras,
        rank: params.rank,
        targetValue: params.quantityTarget,
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
