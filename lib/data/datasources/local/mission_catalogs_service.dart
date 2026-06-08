import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Sprint 3.1 Bloco 13a — catálogos estáticos de missões (seeds).
///
/// Lê 4 JSONs semânticos separados em memória, pattern
/// `ExtrasCatalogService`. Pra simplificar os services downstream (que
/// consomem JSON bruto com campos heterogêneos: `class_key`, `faction_key`,
/// `ascension_to`), retornamos `Map<String, dynamic>` direto — não vale
/// a pena criar 4 models distintos pro MVP.
///
/// `MissionDefinition` (Bloco 3) tem schema unificado pra daily. Pros
/// outros tipos (class/faction_weekly/ascension), os campos extras
/// (`class_key`, `faction_key`, `ascension_to`) ficam como chaves
/// adicionais no map — `MissionAssignmentService` filtra antes de
/// converter pra `MissionProgress`.
///
/// Lazy + idempotente. Asset ausente = lista vazia (tolerância).
class MissionCatalogsService {
  final AssetBundle _bundle;
  List<Map<String, dynamic>>? _daily;
  List<Map<String, dynamic>>? _class;
  // FATIA B2a — o catálogo semanal mudou de `{"missions":[...]}` (plano)
  // pra raiz PER-FACÇÃO (`{"moon_clan":[...], ...}`). Cacheamos o mapa
  // raiz inteiro e indexamos por facção em `loadFactionWeekly`.
  Map<String, dynamic>? _factionWeeklyMap;
  List<Map<String, dynamic>>? _ascension;

  MissionCatalogsService({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  static const String _dailyPath = 'assets/data/missions_daily.json';
  static const String _classPath = 'assets/data/missions_class.json';
  static const String _factionWeeklyPath =
      'assets/data/missions_faction_weekly.json';
  static const String _ascensionPath = 'assets/data/missions_ascension.json';

  Future<List<Map<String, dynamic>>> loadDaily() async {
    return _daily ??= await _loadArray(_dailyPath);
  }

  Future<List<Map<String, dynamic>>> loadClass(String classKey) async {
    _class ??= await _loadArray(_classPath);
    return _class!
        .where((e) => e['class_key'] == classKey)
        .toList(growable: false);
  }

  /// FATIA B2a — formato PER-FACÇÃO. Lê `json[factionKey]` direto (lista
  /// de missões semanais com `sub_tasks[]`/`reward`). Facção sem pool
  /// (ex: `lone_wolf`/`none`, ou facção sem entry no JSON) → `[]`.
  ///
  /// NÃO usa `_loadArray` (que exige `{"missions":[...]}` — formato dos
  /// outros catálogos, intocado).
  Future<List<Map<String, dynamic>>> loadFactionWeekly(
      String factionKey) async {
    _factionWeeklyMap ??= await _loadObject(_factionWeeklyPath);
    final list = _factionWeeklyMap![factionKey];
    if (list is! List) return const [];
    return list
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> loadAscension(String currentRank) async {
    _ascension ??= await _loadArray(_ascensionPath);
    return _ascension!
        .where((e) => e['rank'] == currentRank)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _loadArray(String path) async {
    final String raw;
    try {
      raw = await _bundle.loadString(path);
    } catch (_) {
      // ignore: avoid_print
      print('[mission-catalogs] asset $path ausente — ignorado');
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException("$path: raiz não é objeto");
    }
    final list = decoded['missions'];
    if (list is! List) {
      throw FormatException("$path: campo 'missions' ausente ou inválido");
    }
    return list
        .map((e) => e as Map<String, dynamic>)
        .toList(growable: false);
  }

  /// FATIA B2a — carrega o mapa raiz de um catálogo cuja estrutura é um
  /// objeto indexado por chave (ex: per-facção). Asset ausente = `{}`.
  Future<Map<String, dynamic>> _loadObject(String path) async {
    final String raw;
    try {
      raw = await _bundle.loadString(path);
    } catch (_) {
      // ignore: avoid_print
      print('[mission-catalogs] asset $path ausente — ignorado');
      return const {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException("$path: raiz não é objeto");
    }
    return decoded;
  }

  /// Testing-only: limpa cache pra re-carregar.
  void resetCacheForTesting() {
    _daily = null;
    _class = null;
    _factionWeeklyMap = null;
    _ascension = null;
  }
}
