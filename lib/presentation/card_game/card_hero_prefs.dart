import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/card_game/card_game.dart';

/// Persistência LOCAL do herói representante escolhido (ADR-0028 Fase B). MVP:
/// SharedPreferences — sem migração de DB. Sync com `player_decks.hero_id` fica
/// como follow-up (precisa de `db push` autorizado pelo CEO).
class CardHeroPrefs {
  static const _key = 'cardgame_hero';
  static const _bonusKey = 'cardgame_hero_bonus';

  /// Herói escolhido (default: Trapaceiro).
  static Future<HeroId> get() async {
    final prefs = await SharedPreferences.getInstance();
    return heroIdFromString(prefs.getString(_key)) ?? HeroId.trapaceiro;
  }

  static Future<void> set(HeroId hero) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, heroIdToString(hero));
  }

  /// Id da carta-bônus do Cartomante (ADR-0028 Fase C); null se não escolhida.
  /// Definida na montagem e injetada no deck após o turno 4.
  static Future<String?> getBonusCardId() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bonusKey);
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  static Future<void> setBonusCardId(String? cardId) async {
    final prefs = await SharedPreferences.getInstance();
    if (cardId == null || cardId.isEmpty) {
      await prefs.remove(_bonusKey);
    } else {
      await prefs.setString(_bonusKey, cardId);
    }
  }
}
