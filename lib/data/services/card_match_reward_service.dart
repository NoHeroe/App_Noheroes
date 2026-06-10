import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/player_events.dart';

/// Recompensa concedida por uma partida PvE do Card Game (ponto #1).
///
/// Server-authoritative: o cliente só informa win/loss; a RPC
/// `grant_card_match_reward` decide os valores (teto diário, pacote na 1ª
/// vitória, consolação na derrota) e credita atomicamente.
class CardMatchReward {
  const CardMatchReward({
    required this.won,
    required this.xp,
    required this.gold,
    required this.packs,
    required this.winNumber,
    this.levelUp,
  });

  final bool won;
  final int xp;
  final int gold;

  /// Pacotes de cartas concedidos (1 na 1ª vitória do dia; 0 nas demais).
  final int packs;

  /// Nº da vitória do dia (1 = primeira). 0 quando derrota.
  final int winNumber;

  /// Subida de nível disparada pelo XP creditado (`null` se não subiu).
  final LevelUp? levelUp;

  bool get isFirstWinOfDay => won && winNumber == 1;

  factory CardMatchReward.fromRpc(String playerId, Map<String, dynamic> json) {
    final xpResult = json['xp_result'];
    LevelUp? levelUp;
    if (xpResult is Map) {
      final prev = (xpResult['previous_level'] as num?)?.toInt();
      final next = (xpResult['new_level'] as num?)?.toInt();
      if (prev != null && next != null && next > prev) {
        levelUp = LevelUp(playerId: playerId, newLevel: next, previousLevel: prev);
      }
    }
    return CardMatchReward(
      won: json['won'] as bool? ?? false,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      packs: (json['packs'] as num?)?.toInt() ?? 0,
      winNumber: (json['win_number'] as num?)?.toInt() ?? 0,
      levelUp: levelUp,
    );
  }
}

/// Porta da RPC `grant_card_match_reward`. Credita a recompensa da partida PvE
/// e publica `LevelUp` no bus quando o XP fez subir de nível (mesmo contrato do
/// `RewardGrantService`). O refresh do `currentPlayer` é responsabilidade do
/// chamador (a tela), pois XP/gold mudam mesmo sem level-up.
class CardMatchRewardService {
  CardMatchRewardService({
    required SupabaseClient client,
    required AppEventBus eventBus,
  })  : _client = client,
        _eventBus = eventBus;

  final SupabaseClient _client;
  final AppEventBus _eventBus;

  Future<CardMatchReward> grant({
    required String playerId,
    required bool won,
  }) async {
    final res = (await _client.rpc('grant_card_match_reward', params: {
      'p_player': playerId,
      'p_won': won,
    })) as Map<String, dynamic>;

    final reward = CardMatchReward.fromRpc(playerId, res);
    // LevelUp emitido depois do RPC OK (igual aos demais grants). O listener
    // `PlayerStateSyncService` refaz o fetch do player no level-up.
    if (reward.levelUp != null) _eventBus.publish(reward.levelUp!);
    return reward;
  }
}
