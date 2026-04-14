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

  // Retorna o npcId correto para o jogador baseado na facção
  static String npcIdForFaction(String? factionType) {
    if (factionType == null || factionType.isEmpty ||
        factionType.startsWith('pending:')) {
      return 'unknown_figure';
    }
    return switch (factionType) {
      'moon_clan'    => 'azuos',
      'sun_clan'     => 'koda',
      'black_legion' => 'yuna_lannatary',
      'new_order'    => 'new_order_agent',
      'trinity'      => 'trinity_priest',
      'renegades'    => 'renegade_leader',
      'error'        => 'chrysalis_agent',
      'guild'        => 'noryan_gray',
      _              => 'unknown_figure',
    };
  }

  // Busca diálogo diário do NPC correto por facção + estado da sombra
  static Future<Map<String, String>> getNpcForPlayer({
    required String? factionType,
    required String shadowState,
    required int caelumDay,
    String reputationKey = 'neutral',
  }) async {
    final data = await _load('assets/data/npc_dialogues.json');
    final npcId = npcIdForFaction(factionType);
    final npc = data[npcId] as Map<String, dynamic>;

    // Verifica dia especial primeiro
    final byDay = npc['by_caelum_day'] as Map<String, dynamic>? ?? {};
    String dialogue;
    if (byDay.containsKey('$caelumDay')) {
      dialogue = byDay['$caelumDay'] as String;
    } else {
      final byState = (npc['daily_by_shadow_state']
          as Map<String, dynamic>? ?? {});
      final phrases =
          (byState[shadowState] as List?)?.cast<String>() ?? [];
      dialogue = phrases.isEmpty
          ? 'Caelum observa.'
          : phrases[DateTime.now().millisecond % phrases.length];
    }

    // Diálogo de reputação (se disponível)
    final byRep = npc['by_reputation'] as Map<String, dynamic>? ?? {};
    final repDialogue = byRep[reputationKey] as String? ?? '';

    return {
      'npcId': npcId,
      'name': npc['name'] as String? ?? '???',
      'title': npc['title'] as String? ?? '',
      'dialogue': dialogue,
      'repDialogue': repDialogue,
    };
  }

  static void clearCache() => _cache.clear();
}

