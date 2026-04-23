import 'dart:async';

import '../../core/events/app_event.dart';
import '../../core/events/app_event_bus.dart';
import '../../data/services/reward_grant_service.dart';
import '../enums/mission_modality.dart';
import '../exceptions/reward_exceptions.dart';
import '../models/mission_context.dart';
import '../models/mission_progress.dart';
import '../models/player_snapshot.dart';
import '../repositories/mission_repository.dart';
import '../strategies/mission_strategy.dart';
import 'reward_resolve_service.dart';

/// Sprint 3.1 Bloco 6 — dispatcher central de progresso de missões.
///
/// Orquestra 3 fluxos:
///   1. **EventBus**: assina [AppEvent] no construtor, roteia pros
///      internal strategies.
///   2. **UI**: [onUserAction] é chamado pela tela (Bloco 10) em ações
///      de botão.
///   3. **Conclusão**: quando a strategy diz `shouldComplete`, dispara
///      [RewardResolveService] + [RewardGrantService] no fim do fluxo.
///
/// ## Idempotência de grant (defense-in-depth)
///
///   - **Check prévio in-memory**: antes de chamar grant, lê
///     `rewardClaimed` do repo. Se já true, retorna sem invocar o
///     granter — evita exception ruidosa no happy path.
///   - **Catch de [RewardAlreadyGrantedException]** como safety net:
///     lida com race residual (2 chamadas simultâneas passando o check
///     ao mesmo tempo). 1 ganha no grant, outra captura exception e
///     retorna silenciosamente.
///   - Não usa lock in-memory (single isolate Flutter + transação
///     Drift já serializa writes).
///
/// ## Dispose guard
///
/// [dispose] seta `_disposed = true` **antes** de cancelar a
/// subscription do EventBus. Todos os entry points (`onUserAction`,
/// `_onEvent`) checam `_disposed` logo no começo e viram noop
/// silencioso se `true`. Cobre teardown Riverpod, hot reload, logout
/// — chamadas tardias não tentam persistir num DB já fechado.
class MissionProgressService {
  final MissionRepository _repo;
  final RewardResolveService _resolver;
  final RewardGrantService _granter;
  final AppEventBus _eventBus;
  final Map<MissionModality, MissionStrategy> _strategies;
  final Future<PlayerSnapshot> Function(int playerId) _resolvePlayer;

  late final StreamSubscription<AppEvent> _subscription;
  bool _disposed = false;

  MissionProgressService({
    required MissionRepository repo,
    required RewardResolveService resolver,
    required RewardGrantService granter,
    required AppEventBus eventBus,
    required Map<MissionModality, MissionStrategy> strategies,
    required Future<PlayerSnapshot> Function(int playerId) resolvePlayer,
  })  : _repo = repo,
        _resolver = resolver,
        _granter = granter,
        _eventBus = eventBus,
        _strategies = strategies,
        _resolvePlayer = resolvePlayer {
    _subscription = _eventBus.on<AppEvent>().listen(_onEvent);
  }

  /// Aplica um delta vindo da UI (botões -25/+25) na missão. Retorna
  /// `null` se disposed, missão inexistente, input rejeitado pela
  /// strategy, ou exception residual de grant.
  Future<MissionProgress?> onUserAction(
    int missionProgressId,
    int delta, {
    int? requirementIndex,
  }) async {
    if (_disposed) return null;
    final mission = await _repo.findById(missionProgressId);
    if (mission == null) return null;
    // Missão já fechada (completa ou falha) não aceita mais input.
    if (mission.completedAt != null || mission.failedAt != null) {
      return mission;
    }
    final input = UserDeltaStrategyInput(delta,
        requirementIndex: requirementIndex);
    return _apply(mission, input);
  }

  /// Missões ativas do jogador — delega pra repo.
  Future<List<MissionProgress>> getActive(int playerId) =>
      _repo.findActive(playerId);

  /// Stream reativa — delega pra repo.
  Stream<List<MissionProgress>> watchActive(int playerId) =>
      _repo.watchActive(playerId);

  /// Fecha a subscription e marca service como descartado. Idempotente.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _subscription.cancel();
  }

  // ─── Privados ──────────────────────────────────────────────────────

  Future<void> _onEvent(AppEvent event) async {
    if (_disposed) return;
    // Descobrir playerId do evento pra filtrar missões candidatas.
    final playerId = _extractPlayerId(event);
    if (playerId == null) return;
    final active = await _repo.findActive(playerId);
    if (_disposed) return;
    for (final mission in active) {
      if (_disposed) return;
      // Só missões com modalidade que escuta eventos (internal ou mixed).
      if (mission.modality != MissionModality.internal &&
          mission.modality != MissionModality.mixed) {
        continue;
      }
      await _apply(mission, EventStrategyInput(event));
    }
  }

  Future<MissionProgress?> _apply(
    MissionProgress mission,
    StrategyInput input,
  ) async {
    if (_disposed) return null;
    final strategy = _strategies[mission.modality];
    if (strategy == null) return null;
    final ctx = _toContext(mission);
    if (!strategy.acceptsInput(ctx, input)) return mission;
    final step = strategy.computeStep(ctx, input);

    await _repo.updateProgress(
      mission.id,
      currentValue: step.newCurrentValue,
      metaJson: step.newMetaJson,
    );
    if (_disposed) return null;

    if (step.shouldComplete) {
      await _maybeTriggerGrant(mission, step.newCurrentValue);
    }

    return _repo.findById(mission.id);
  }

  /// Idempotente por design — ver dartdoc da classe.
  Future<void> _maybeTriggerGrant(
    MissionProgress mission,
    int finalCurrentValue,
  ) async {
    // Check prévio — evita exception ruidosa.
    final refreshed = await _repo.findById(mission.id);
    if (refreshed == null) return;
    if (refreshed.rewardClaimed) return;
    if (_disposed) return;

    final player = await _resolvePlayer(mission.playerId);
    if (_disposed) return;

    // Fórmula 0-300% só pra família real/individual (Diárias) que pode
    // exceder. Outras famílias completam em 100% exato.
    final progressPct = mission.targetValue <= 0
        ? 100
        : ((finalCurrentValue / mission.targetValue) * 100).round();

    final resolved = await _resolver.resolve(
      mission.reward,
      player,
      progressPct: progressPct,
    );
    if (_disposed) return;

    try {
      await _granter.grant(
        missionProgressId: mission.id,
        playerId: mission.playerId,
        resolved: resolved,
      );
    } on RewardAlreadyGrantedException {
      // Race residual — outra chamada ganhou. Silencia (idempotência).
    }
  }

  MissionContext _toContext(MissionProgress m) => MissionContext(
        missionProgressId: m.id,
        playerId: m.playerId,
        missionKey: m.missionKey,
        modality: m.modality,
        tabOrigin: m.tabOrigin,
        currentValue: m.currentValue,
        targetValue: m.targetValue,
        rewardDeclared: m.reward,
        metaJson: m.metaJson,
      );

  /// Todos os AppEvent do Bloco 2 têm `playerId`. Extrai pra filtrar
  /// missões do jogador correto antes de percorrer a lista ativa.
  int? _extractPlayerId(AppEvent event) {
    // Import recursivo seria feio aqui; uso dynamic dispatch simples.
    final e = event as dynamic;
    try {
      final pid = e.playerId;
      return pid is int ? pid : null;
    } catch (_) {
      return null;
    }
  }
}
