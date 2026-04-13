import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class AssetLoader {
  static final _cache = <String, dynamic>{};

  static Future<Map<String, dynamic>> _load(String path) async {
    if (_cache.containsKey(path)) return _cache[path] as Map<String, dynamic>;
    final raw = await rootBundle.loadString(path);
    final data = json.decode(raw) as Map<String, dynamic>;
    _cache[path] = data;
    return data;
  }

  // ── Frases da Sombra ──────────────────────────────────────────────────────

  static Future<String> getShadowPhrase(String state) async {
    final data = await _load('assets/data/shadow_phrases.json');
    final phrases = (data[state] as List?)?.cast<String>() ?? [];
    if (phrases.isEmpty) return 'Sua sombra observa em silêncio.';
    return phrases[Random().nextInt(phrases.length)];
  }

  // ── Diálogos do NPC ───────────────────────────────────────────────────────

  static Future<String> getNpcDailyDialogue(String shadowState, int caelumDay) async {
    final data = await _load('assets/data/npc_dialogues.json');
    final npc = data['unknown_figure'] as Map<String, dynamic>;

    // Verifica se há fala especial para o dia exato
    final byDay = npc['by_caelum_day'] as Map<String, dynamic>;
    if (byDay.containsKey('$caelumDay')) {
      return byDay['$caelumDay'] as String;
    }

    // Senão, fala baseada no estado da sombra
    final byState = (npc['daily_by_shadow_state'] as Map<String, dynamic>);
    final phrases = (byState[shadowState] as List?)?.cast<String>() ?? [];
    if (phrases.isEmpty) return 'Caelum observa.';
    return phrases[Random().nextInt(phrases.length)];
  }

  // ── Missões de Lore ───────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAvailableLoreQuests({
    required int playerLevel,
    required int caelumDay,
  }) async {
    final data = await _load('assets/data/lore_quests.json');
    final quests = (data['lore_quests'] as List).cast<Map<String, dynamic>>();
    return quests.where((q) {
      final minLevel = q['unlock_level'] as int;
      final minDay   = q['unlock_day']   as int;
      return playerLevel >= minLevel && caelumDay >= minDay;
    }).toList();
  }

  static void clearCache() => _cache.clear();
}
