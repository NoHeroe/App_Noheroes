import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../data/database/app_database.dart';
import '../enums/mission_category.dart';
import '../models/daily_modalidade_pool.dart';
import '../models/daily_sub_task_spec.dart';
import '../models/vitalismo_pool.dart';
import 'body_metrics_service.dart';

/// Sprint 3.2 Etapa 1.1 — carrega os 4 pools de missões diárias dos
/// assets `daily_pool_*.json` e expõe consulta por modalidade / por key.
///
/// **Sem mecânica de geração** — só estrutura de carregamento. Etapa 1.2
/// implementa o sorteio diário usando estes pools.
///
/// `loadAll()` é race-free (mesmo padrão do AchievementsService da 3.1
/// Hotfix v0.29.1) — múltiplos callers concorrentes awaitam a mesma
/// Future em vez de cada um popular o cache.
class DailyPoolService {
  static const String fisicoAsset = 'assets/data/daily_pool_fisico.json';
  static const String mentalAsset = 'assets/data/daily_pool_mental.json';
  static const String espiritualAsset =
      'assets/data/daily_pool_espiritual.json';
  static const String vitalismoAsset =
      'assets/data/daily_pool_vitalismo.json';

  // Fallbacks pra água/proteína quando o jogador não preencheu
  // peso/altura na Calibração do Sistema (Etapa 1.0).
  static const int fallbackWaterMl = 2000;
  static const int fallbackProteinG = 80;

  static const String waterKey = 'agua_diaria';
  static const String proteinKey = 'proteina_diaria';

  final AssetBundle _assetBundle;

  DailyModalidadePool? _fisico;
  DailyModalidadePool? _mental;
  DailyModalidadePool? _espiritual;
  VitalismoPool? _vitalismo;
  final Map<String, DailySubTaskSpec> _byKey = {};

  bool _loaded = false;
  Future<void>? _loadingFuture;

  DailyPoolService({AssetBundle? assetBundle})
      : _assetBundle = assetBundle ?? rootBundle;

  /// Carrega os 4 JSONs dos assets em memória. Idempotente + race-free.
  /// Lança [FormatException] se algum JSON estiver malformado.
  Future<void> loadAll() async {
    if (_loaded) return;
    _loadingFuture ??= _doLoad();
    await _loadingFuture;
  }

  Future<void> _doLoad() async {
    final fisico = await _loadModalidade(fisicoAsset);
    final mental = await _loadModalidade(mentalAsset);
    final espiritual = await _loadModalidade(espiritualAsset);
    final vitalismo = await _loadVitalismo(vitalismoAsset);

    _fisico = fisico;
    _mental = mental;
    _espiritual = espiritual;
    _vitalismo = vitalismo;

    for (final pool in [fisico, mental, espiritual]) {
      for (final spec in pool.subTarefas) {
        if (_byKey.containsKey(spec.key)) {
          throw FormatException(
              "daily_pool: key duplicada '${spec.key}' (entre pools)");
        }
        _byKey[spec.key] = spec;
      }
    }
    _loaded = true;
  }

  Future<DailyModalidadePool> _loadModalidade(String path) async {
    final raw = await _assetBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException("$path: raiz não é objeto");
    }
    return DailyModalidadePool.fromJson(decoded);
  }

  Future<VitalismoPool> _loadVitalismo(String path) async {
    final raw = await _assetBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException("$path: raiz não é objeto");
    }
    return VitalismoPool.fromJson(decoded);
  }

  /// Retorna o pool de uma modalidade. Físico/Mental/Espiritual
  /// retornam [DailyModalidadePool]; Vitalismo retorna [VitalismoPool].
  /// Lança [StateError] se [loadAll] ainda não foi chamado.
  Object poolFor(MissionCategory category) {
    if (!_loaded) {
      throw StateError('DailyPoolService.loadAll() não foi chamado ainda');
    }
    return switch (category) {
      MissionCategory.fisico => _fisico!,
      MissionCategory.mental => _mental!,
      MissionCategory.espiritual => _espiritual!,
      MissionCategory.vitalismo => _vitalismo!,
    };
  }

  /// Atalhos tipados — evitam cast no caller.
  DailyModalidadePool fisicoPool() {
    if (!_loaded) throw StateError('DailyPoolService.loadAll() não chamado');
    return _fisico!;
  }

  DailyModalidadePool mentalPool() {
    if (!_loaded) throw StateError('DailyPoolService.loadAll() não chamado');
    return _mental!;
  }

  DailyModalidadePool espiritualPool() {
    if (!_loaded) throw StateError('DailyPoolService.loadAll() não chamado');
    return _espiritual!;
  }

  VitalismoPool vitalismoPool() {
    if (!_loaded) throw StateError('DailyPoolService.loadAll() não chamado');
    return _vitalismo!;
  }

  /// Busca cross-pool por key. Retorna null se a key não existe em
  /// nenhum dos 3 pools com sub-tarefas (Vitalismo não tem sub-tarefas).
  DailySubTaskSpec? subTaskByKey(String key) => _byKey[key];

  /// Resolve a escala efetiva pra um jogador num rank dado.
  ///
  /// - Se `requerImc`: usa [BodyMetricsService] (água ⇒
  ///   `recommendedWaterMl`, proteína ⇒ `recommendedProteinG`). Cai
  ///   pros fallbacks 2000ml/80g se peso ausente.
  /// - Senão: lê `escalaPorRank[rank]`. `0` significa "sub-tarefa não
  ///   disponível pro rank" — caller (Etapa 1.2) filtra.
  ///
  /// Lança [ArgumentError] se [rank] não é um dos 6 canônicos
  /// (E/D/C/B/A/S).
  int resolveScale({
    required DailySubTaskSpec spec,
    required String rank,
    required BodyMetricsService bodyMetrics,
    required PlayersTableData player,
  }) {
    if (!const {'E', 'D', 'C', 'B', 'A', 'S'}.contains(rank)) {
      throw ArgumentError("rank inválido '$rank' (esperado E/D/C/B/A/S)");
    }
    if (spec.requerImc) {
      return switch (spec.key) {
        waterKey =>
          bodyMetrics.recommendedWaterMl(player) ?? fallbackWaterMl,
        proteinKey =>
          bodyMetrics.recommendedProteinG(player) ?? fallbackProteinG,
        // Sub-tarefa marcada requer_imc mas com key desconhecida — defesa
        // em profundidade: cai pra escala fixa (deve ser 0 nesses casos).
        _ => spec.escalaPorRank[rank] ?? 0,
      };
    }
    return spec.escalaPorRank[rank] ?? 0;
  }
}
