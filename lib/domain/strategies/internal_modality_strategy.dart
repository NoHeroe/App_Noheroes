import 'dart:convert';

import '../../core/events/app_event.dart';
import '../../core/events/crafting_events.dart';
import '../../core/events/faction_events.dart';
import '../../core/events/player_events.dart';
import '../../core/events/reward_events.dart';
import '../../core/events/streak_events.dart';
import '../models/mission_context.dart';
import 'mission_strategy.dart';

/// Sprint 3.1 Bloco 6 — família Internal (sistema detecta via EventBus).
///
/// Missão carrega em `metaJson` o nome do AppEvent que dispara progresso:
///
/// ```json
/// {"internal_event": "ItemCrafted"}
/// ```
///
/// Cada evento válido incrementa o contador em 1. Chega em `targetValue`
/// → `shouldComplete: true`.
///
/// Usada por: Classe, Facção, Admissão, e eventos narrativos.
class InternalModalityStrategy implements MissionStrategy {
  @override
  bool acceptsInput(MissionContext ctx, StrategyInput input) {
    if (input is! EventStrategyInput) return false;
    final meta = _parseMeta(ctx.metaJson);
    final expectedName = meta['internal_event'] as String?;
    if (expectedName == null) return false;
    return _eventTypeMatches(input.event, expectedName) &&
        _eventPlayerMatches(input.event, ctx.playerId);
  }

  @override
  StrategyStep computeStep(MissionContext ctx, StrategyInput input) {
    // Precondição: acceptsInput retornou true.
    final newValue = ctx.currentValue + 1;
    return StrategyStep(
      newCurrentValue: newValue,
      newMetaJson: ctx.metaJson,
      shouldComplete: newValue >= ctx.targetValue,
    );
  }

  Map<String, dynamic> _parseMeta(String raw) {
    if (raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return decoded.cast<String, dynamic>();
  }

  /// Mapa nome → type-check. Switch explícito por tipo, não por
  /// `runtimeType.toString()` (frágil).
  ///
  // TODO(extension-hazard): switch sobre string name. Se lista de
  // eventos crescer além de 20, migrar pra `Map<Type, bool Function(AppEvent)>`
  // pra evitar que novo AppEvent no Bloco 2 futuro seja silenciosamente
  // não-reconhecido aqui.
  bool _eventTypeMatches(AppEvent event, String expectedName) {
    return switch (expectedName) {
      'ItemCrafted' => event is ItemCrafted,
      'ItemEnchanted' => event is ItemEnchanted,
      'LevelUp' => event is LevelUp,
      'GoldSpent' => event is GoldSpent,
      'GemsSpent' => event is GemsSpent,
      'StreakMaintained' => event is StreakMaintained,
      'StreakBroken' => event is StreakBroken,
      'AchievementUnlocked' => event is AchievementUnlocked,
      'RewardGranted' => event is RewardGranted,
      'ClassSelected' => event is ClassSelected,
      'FactionJoined' => event is FactionJoined,
      'FactionLeft' => event is FactionLeft,
      _ => false,
    };
  }

  /// Extrai `playerId` do evento (todos do Bloco 2 têm o campo) e
  /// compara. Missão do jogador X só avança por evento do jogador X.
  bool _eventPlayerMatches(AppEvent event, int expectedPlayerId) {
    return switch (event) {
      ItemCrafted(:final playerId) => playerId == expectedPlayerId,
      ItemEnchanted(:final playerId) => playerId == expectedPlayerId,
      LevelUp(:final playerId) => playerId == expectedPlayerId,
      GoldSpent(:final playerId) => playerId == expectedPlayerId,
      GemsSpent(:final playerId) => playerId == expectedPlayerId,
      StreakMaintained(:final playerId) => playerId == expectedPlayerId,
      StreakBroken(:final playerId) => playerId == expectedPlayerId,
      AchievementUnlocked(:final playerId) => playerId == expectedPlayerId,
      RewardGranted(:final playerId) => playerId == expectedPlayerId,
      ClassSelected(:final playerId) => playerId == expectedPlayerId,
      FactionJoined(:final playerId) => playerId == expectedPlayerId,
      FactionLeft(:final playerId) => playerId == expectedPlayerId,
      _ => false,
    };
  }
}
