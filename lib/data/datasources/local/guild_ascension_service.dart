import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/services.dart';
import '../../../core/utils/guild_rank.dart';
import '../../database/app_database.dart';
import '../../database/tables/guild_ascension_table.dart';
import 'player_rank_service.dart';

class GuildAscensionService {
  final AppDatabase _db;
  // A.1 — escrita de rank unificada: ascend() delega a PlayerRankService
  // (grava o canon MAIÚSCULO + evolui o Colar da Guilda).
  final PlayerRankService _rankService;
  GuildAscensionService(this._db, {PlayerRankService? rankService})
      : _rankService = rankService ?? PlayerRankService(_db);

  /// A.1 — normaliza um rank cru pro canon MAIÚSCULO ('E'..'S'). `none`/
  /// vazio é preservado como sentinela (não casa com nenhum ciclo).
  /// `GuildRankSystem.fromString` tolera ambas as caixas (cobre legado).
  String _canonRank(String raw) {
    final r = raw.trim();
    if (r.isEmpty || r.toLowerCase() == 'none') return 'none';
    return GuildRankSystem.fromString(r).name.toUpperCase();
  }

  // Retorna todas as missões do ciclo atual (rank_from = guildRank)
  Future<List<GuildAscensionTableData>> getMissions(
      int playerId, String currentRank) async {
    final canon = _canonRank(currentRank);
    return (_db.select(_db.guildAscensionTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.rankFrom.equals(canon))
          ..orderBy([(t) => OrderingTerm.asc(t.step)]))
        .get();
  }

  // Inicializa as missões do ciclo atual se não existirem
  Future<void> initCycle(int playerId, String currentRank) async {
    final canon = _canonRank(currentRank);
    final existing = await getMissions(playerId, canon);
    if (existing.isNotEmpty) return;

    final raw = await rootBundle.loadString('assets/data/guild_ascension.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final cycles = (json['ascension'] as List).cast<Map<String, dynamic>>();

    final cycle = cycles.firstWhere(
      (c) => c['rank_from'] == canon,
      orElse: () => {},
    );
    if (cycle.isEmpty) return;

    final missions = (cycle['missions'] as List).cast<Map<String, dynamic>>();
    for (final m in missions) {
      final options = (m['options'] as List).cast<Map<String, dynamic>>();
      options.shuffle(Random());
      final chosen = options.first;
      final params = chosen['check_params'] as Map<String, dynamic>;
      final target = _extractTarget(chosen['check_type'] as String, params);

      await _db.into(_db.guildAscensionTable).insert(
        GuildAscensionTableCompanion(
          playerId: Value(playerId),
          rankFrom: Value(canon),
          rankTo: Value(cycle['rank_to'] as String),
          step: Value(m['step'] as int),
          questKey: Value(chosen['key'] as String),
          title: Value(chosen['title'] as String),
          description: Value(chosen['description'] as String),
          checkType: Value(chosen['check_type'] as String),
          checkParamsJson: Value(jsonEncode(params)),
          unlockLevel: Value(m['unlock_level'] as int),
          xpReward: Value(m['xp'] as int),
          goldReward: Value(m['gold'] as int),
          progressTarget: Value(target),
        ),
      );
    }
  }

  /// A.2 — avalia a missão de menor `step` incompleta do ciclo via DADOS
  /// VIVOS (sem `ctx`): grava `progress` e marca `completed` ao bater o
  /// target. Retorna true se completou (o caller pode re-chamar pra
  /// avançar o próximo step que já esteja satisfeito por contador
  /// lifetime). NÃO ascende (o `ascend()` continua manual no botão) e
  /// NÃO incrementa `total_quests_completed` (evita feedback-loop com
  /// `complete_any_total`, que LÊ esse contador).
  Future<bool> checkCurrentMission(int playerId, String currentRank) async {
    final canon = _canonRank(currentRank);
    final missions = await getMissions(playerId, canon);
    final current = missions
        .where((m) => !m.completed)
        .fold<GuildAscensionTableData?>(null, (acc, m) {
      if (acc == null) return m;
      return m.step < acc.step ? m : acc;
    });
    if (current == null) return false;

    final params = jsonDecode(current.checkParamsJson) as Map<String, dynamic>;
    final progress = await _calcProgress(current.checkType, params, playerId);

    if (progress >= current.progressTarget) {
      await (_db.update(_db.guildAscensionTable)
            ..where((t) => t.id.equals(current.id)))
          .write(GuildAscensionTableCompanion(
        completed: const Value(true),
        progress: Value(current.progressTarget),
      ));
      return true;
    }

    if (progress != current.progress) {
      await (_db.update(_db.guildAscensionTable)
            ..where((t) => t.id.equals(current.id)))
          .write(GuildAscensionTableCompanion(progress: Value(progress)));
    }
    return false;
  }

  // Verifica se todas missões do ciclo estão completas → sobe o rank
  Future<bool> canAscend(int playerId, String currentRank) async {
    final missions = await getMissions(playerId, currentRank);
    if (missions.isEmpty) return false;
    return missions.every((m) => m.completed);
  }

  Future<String?> ascend(int playerId, String currentRank) async {
    final canon = _canonRank(currentRank);
    if (canon == 'none') return null;
    if (!await canAscend(playerId, canon)) return null;
    final next = GuildRankSystem.next(GuildRankSystem.fromString(canon));
    if (next == null) return null; // já é S

    // A.1 — escrita unificada: delega a PlayerRankService.setRank, que
    // grava o canon MAIÚSCULO em players.guild_rank E evolui o Colar da
    // Guilda (evolution_stage). Substitui o customUpdate direto anterior,
    // que gravava minúsculo e NÃO evoluía o colar (ADR-0009).
    await _rankService.setRank(playerId, next);
    return next.name.toUpperCase();
  }

  /// A.2 — mapeia a `category` do catálogo (inglês) pra grafia REAL da
  /// `daily_missions.modalidade` (PT-BR). Sem este mapa, a query contaria
  /// 0 silenciosamente.
  static const Map<String, String> _categoryToModalidade = {
    'physical': 'fisico',
    'mental': 'mental',
    'spiritual': 'espiritual',
  };

  /// A.2 — progresso contra DADOS VIVOS (sem `ctx`, sem `habit_logs`):
  ///  - complete_any_total      → players.total_quests_completed
  ///  - complete_category_total → COUNT(daily_missions) por modalidade
  ///  - streak_days             → players.streak_days
  ///  - achievements_count      → COUNT(player_achievements)
  ///  - diary_total_words       → SUM de palavras em diary_entries
  Future<int> _calcProgress(
      String checkType, Map<String, dynamic> params, int playerId) async {
    switch (checkType) {
      case 'complete_any_total':
        final count = params['count'] as int;
        final rows = await _db.customSelect(
          'SELECT total_quests_completed AS c FROM players WHERE id = ?',
          variables: [Variable.withInt(playerId)],
        ).get();
        final found = (rows.first.data['c'] as int?) ?? 0;
        return found.clamp(0, count);

      case 'complete_category_total':
        final count = params['count'] as int;
        final cat = params['category'] as String;
        final modalidade = _categoryToModalidade[cat];
        if (modalidade == null) return 0;
        final rows = await _db.customSelect(
          "SELECT COUNT(*) AS c FROM daily_missions "
          "WHERE player_id = ? AND completed_at IS NOT NULL "
          "AND status IN ('completed', 'partial') AND modalidade = ?",
          variables: [
            Variable.withInt(playerId),
            Variable.withString(modalidade),
          ],
        ).get();
        final found = (rows.first.data['c'] as int?) ?? 0;
        return found.clamp(0, count);

      case 'streak_days':
        final days = params['days'] as int;
        final rows = await _db.customSelect(
          'SELECT streak_days AS s FROM players WHERE id = ?',
          variables: [Variable.withInt(playerId)],
        ).get();
        final streak = (rows.first.data['s'] as int?) ?? 0;
        return streak.clamp(0, days);

      case 'achievements_count':
        final count = params['count'] as int;
        final rows = await _db.customSelect(
          'SELECT COUNT(*) AS c FROM player_achievements_completed '
          'WHERE player_id = ?',
          variables: [Variable.withInt(playerId)],
        ).get();
        final found = (rows.first.data['c'] as int?) ?? 0;
        return found.clamp(0, count);

      case 'diary_total_words':
        final words = params['words'] as int;
        final rows = await _db.customSelect(
          "SELECT SUM(LENGTH(content) - LENGTH(REPLACE(content, ' ', '')) + 1) "
          'AS w FROM diary_entries WHERE player_id = ?',
          variables: [Variable.withInt(playerId)],
        ).get();
        final found = (rows.first.data['w'] as int?) ?? 0;
        return found.clamp(0, words);

      default:
        return 0;
    }
  }

  int _extractTarget(String checkType, Map<String, dynamic> params) {
    switch (checkType) {
      case 'complete_any_total': return params['count'] as int;
      case 'complete_category_total': return params['count'] as int;
      case 'streak_days': return params['days'] as int;
      case 'achievements_count': return params['count'] as int;
      case 'diary_total_words': return params['words'] as int;
      default: return 1;
    }
  }
}
