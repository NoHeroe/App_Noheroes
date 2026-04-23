import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../../domain/models/extras_mission_spec.dart';

/// Sprint 3.1 Bloco 11a — catálogo das missões Extras (DESIGN_DOC §8).
///
/// Carrega dois JSONs em memória e combina:
///
///   - `assets/data/lore_quests.json` — 8 entries existentes de Lore
///     (formato legacy: `lore_quests: [{id, title, description, ...}]`)
///   - `assets/data/extras_catalog.json` — catálogo novo do Bloco 11a
///     (formato: `extras: [{key, type, title, description, narrative,
///     unlock_level, is_secret, reward_xp, reward_gold}]`)
///
/// Lore entries são mapeadas pro novo schema (`type: lore`, `key: lq_XXX`,
/// `rewardXp/Gold` direto das colunas legacy). Demais tipos (npc/secret/
/// event) vêm do `extras_catalog.json`.
///
/// Individuais criadas pelo jogador **não entram** neste catálogo — elas
/// são `MissionProgress` persistidas com `metaJson['user_created']=true`
/// e o `QuestsScreenNotifier` faz o merge na renderização da aba.
///
/// ## Lazy + idempotente
///
/// `loadAll` carrega 1x e memoiza. Chamar 2x retorna a mesma lista.
/// Asset ausente é tolerado (retorna lista vazia + log) pra não travar
/// a tela quando algum JSON for removido acidentalmente.
class ExtrasCatalogService {
  final AssetBundle _bundle;

  List<ExtrasMissionSpec>? _cache;

  ExtrasCatalogService({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  static const String _extrasAssetPath = 'assets/data/extras_catalog.json';
  static const String _loreAssetPath = 'assets/data/lore_quests.json';

  Future<List<ExtrasMissionSpec>> loadAll() async {
    if (_cache != null) return _cache!;
    final out = <ExtrasMissionSpec>[];
    out.addAll(await _loadExtras());
    out.addAll(await _loadLoreAsExtras());
    _cache = List.unmodifiable(out);
    return _cache!;
  }

  Future<List<ExtrasMissionSpec>> _loadExtras() async {
    final raw = await _readOrEmpty(_extrasAssetPath);
    if (raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          "extras_catalog.json: raiz não é objeto");
    }
    final list = decoded['extras'];
    if (list is! List) {
      throw const FormatException(
          "extras_catalog.json: campo 'extras' ausente ou inválido");
    }
    return list
        .map((e) => ExtrasMissionSpec.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<ExtrasMissionSpec>> _loadLoreAsExtras() async {
    final raw = await _readOrEmpty(_loreAssetPath);
    if (raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const []; // tolerância: lore_quests com formato inesperado
    }
    final list = decoded['lore_quests'];
    if (list is! List) return const [];
    final out = <ExtrasMissionSpec>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['id'];
      final title = entry['title'];
      final description = entry['description'];
      if (id is! String || title is! String || description is! String) {
        continue;
      }
      out.add(ExtrasMissionSpec(
        key: id,
        type: ExtraMissionType.lore,
        title: title,
        description: description,
        narrative: entry['narrative'] as String?,
        unlockLevel: entry['unlock_level'] as int?,
        rewardXp: (entry['reward_xp'] as int?) ?? 0,
        rewardGold: (entry['reward_gold'] as int?) ?? 0,
      ));
    }
    return out;
  }

  Future<String> _readOrEmpty(String path) async {
    try {
      return await _bundle.loadString(path);
    } catch (_) {
      // Asset ausente — tolerado. Pattern consistente com
      // AchievementsService (Bloco 8).
      // ignore: avoid_print
      print('[extras-catalog] asset $path ausente — ignorado');
      return '';
    }
  }

  /// Testing-only: limpa cache pra re-carregar.
  void resetCacheForTesting() => _cache = null;
}
