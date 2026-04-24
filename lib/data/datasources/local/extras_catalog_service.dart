import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/extras_mission_spec.dart';

/// Sprint 3.1 Bloco 11a — catálogo das missões Extras (DESIGN_DOC §8).
/// Sprint 3.1 Bloco 14.5 — ganho dinâmico por jogador (Awakening extra).
///
/// Carrega três fontes e combina:
///
///   - `assets/data/lore_quests.json` — 8 entries existentes de Lore
///     (formato legacy: `lore_quests: [{id, title, description, ...}]`)
///   - `assets/data/extras_catalog.json` — catálogo novo do Bloco 11a
///     (formato: `extras: [{key, type, title, description, narrative,
///     unlock_level, is_secret, reward_xp, reward_gold}]`)
///   - **SharedPreferences** `awakening_extra_<playerId>` — spec dinâmica
///     salva pelo `AwakeningScreen` (Bloco 14.5) com o pilar escolhido
///     pelo jogador. 1 spec por jogador, persistida como JSON.
///
/// Lore entries são mapeadas pro novo schema (`type: lore`, `key: lq_XXX`,
/// `rewardXp/Gold` direto das colunas legacy). Demais tipos (npc/secret/
/// event) vêm do `extras_catalog.json`. A awakening extra usa
/// `type: npc` (doada pelo Vazio).
///
/// Individuais criadas pelo jogador **não entram** neste catálogo — elas
/// são `MissionProgress` persistidas com `metaJson['user_created']=true`
/// e o `QuestsScreenNotifier` faz o merge na renderização da aba.
///
/// ## Pattern de persistência da Awakening extra
///
/// Decisão 14.5 (CEO): spec por jogador vive em `SharedPreferences` em
/// vez de tabela nova. Motivação:
///   - 1 entry por jogador, imutável após criação
///   - evita migration pra schema 26
///   - coerente com `TutorialService` (Bloco 1)
///   - menos invasivo
///
/// Key: `awakening_extra_<playerId>` contém o JSON serializado via
/// `ExtrasMissionSpec.toJson()`.
///
/// ## Lazy + idempotente
///
/// `loadAll` carrega 1x e memoiza os assets estáticos. A spec dinâmica
/// é lida a cada chamada de `loadAllForPlayer` (pequena, sem cache —
/// mantém simples e sempre atualizada).
class ExtrasCatalogService {
  final AssetBundle _bundle;

  List<ExtrasMissionSpec>? _staticCache;

  ExtrasCatalogService({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  static const String _extrasAssetPath = 'assets/data/extras_catalog.json';
  static const String _loreAssetPath = 'assets/data/lore_quests.json';

  /// Prefixo da chave em SharedPreferences. Full key: `awakening_extra_$playerId`.
  static const String awakeningExtraKeyPrefix = 'awakening_extra_';

  /// Specs estáticas (catálogo JSON + lore). Sem gate de jogador — todas.
  Future<List<ExtrasMissionSpec>> loadAll() async {
    if (_staticCache != null) return _staticCache!;
    final out = <ExtrasMissionSpec>[];
    out.addAll(await _loadExtras());
    out.addAll(await _loadLoreAsExtras());
    _staticCache = List.unmodifiable(out);
    return _staticCache!;
  }

  /// Sprint 14.5 — lista completa pro jogador: estáticas + awakening
  /// extra (se existir). Consumido pelo `QuestsScreenNotifier` no redesign
  /// 14.6c pra renderizar a seção EXTRAS.
  Future<List<ExtrasMissionSpec>> loadAllForPlayer(int playerId) async {
    final statics = await loadAll();
    final dynamicSpec = await _loadAwakeningExtra(playerId);
    if (dynamicSpec == null) return statics;
    // Awakening extra vai no topo — primeira da lista pro jogador ver
    // logo após cerimônia.
    return List<ExtrasMissionSpec>.unmodifiable(
        [dynamicSpec, ...statics]);
  }

  /// Persiste a spec do Awakening pro jogador. Idempotente: sobrescreve
  /// se já existe (caso jogador faça onboarding 2x — edge case).
  Future<void> saveAwakeningExtra(
    int playerId,
    ExtrasMissionSpec spec,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$awakeningExtraKeyPrefix$playerId',
      jsonEncode(spec.toJson()),
    );
  }

  Future<ExtrasMissionSpec?> _loadAwakeningExtra(int playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$awakeningExtraKeyPrefix$playerId');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return ExtrasMissionSpec.fromJson(decoded);
    } catch (_) {
      // Entry malformada — tolerado (retorna null; jogador só não vê
      // a awakening extra, sem crash).
      // ignore: avoid_print
      print('[extras-catalog] awakening_extra_$playerId malformado — skip');
      return null;
    }
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
      return const [];
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
      // ignore: avoid_print
      print('[extras-catalog] asset $path ausente — ignorado');
      return '';
    }
  }

  /// Testing-only: limpa cache pra re-carregar.
  void resetCacheForTesting() => _staticCache = null;
}
