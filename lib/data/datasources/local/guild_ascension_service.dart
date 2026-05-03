import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/services.dart';
import '../../database/app_database.dart';
import '../../database/tables/guild_ascension_table.dart';

class GuildAscensionService {
  final AppDatabase _db;
  GuildAscensionService(this._db);

  static const _rankOrder = ['e', 'd', 'c', 'b', 'a', 's'];

  // Retorna todas as missões do ciclo atual (rank_from = guildRank)
  Future<List<GuildAscensionTableData>> getMissions(
      int playerId, String currentRank) async {
    return (_db.select(_db.guildAscensionTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.rankFrom.equals(currentRank))
          ..orderBy([(t) => OrderingTerm.asc(t.step)]))
        .get();
  }

  // Inicializa as missões do ciclo atual se não existirem
  Future<void> initCycle(int playerId, String currentRank) async {
    final existing = await getMissions(playerId, currentRank);
    if (existing.isNotEmpty) return;

    final raw = await rootBundle.loadString('assets/data/guild_ascension.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final cycles = (json['ascension'] as List).cast<Map<String, dynamic>>();

    final cycle = cycles.firstWhere(
      (c) => c['rank_from'] == currentRank,
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
          rankFrom: Value(currentRank),
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

  // Verifica e completa missão atual, retorna true se completou
  Future<bool> checkCurrentMission(
      int playerId, String currentRank, Map<String, dynamic> ctx) async {
    final missions = await getMissions(playerId, currentRank);
    final current = missions
        .where((m) => !m.completed)
        .fold<GuildAscensionTableData?>(null, (acc, m) {
      if (acc == null) return m;
      return m.step < acc.step ? m : acc;
    });
    if (current == null) return false;

    final params = jsonDecode(current.checkParamsJson) as Map<String, dynamic>;
    final progress = await _calcProgress(
        current.checkType, params, playerId, ctx);

    if (progress >= current.progressTarget) {
      await (_db.update(_db.guildAscensionTable)
            ..where((t) => t.id.equals(current.id)))
          .write(GuildAscensionTableCompanion(
        completed: const Value(true),
        progress: Value(current.progressTarget),
      ));
      await _db.customUpdate(
        'UPDATE players SET total_quests_completed = '
        'total_quests_completed + 1 WHERE id = ?',
        variables: [Variable.withInt(playerId)],
        updates: {_db.playersTable},
      );
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
    if (!await canAscend(playerId, currentRank)) return null;
    final idx = _rankOrder.indexOf(currentRank);
    if (idx < 0 || idx >= _rankOrder.length - 1) return null;
    final newRank = _rankOrder[idx + 1];

    // Sprint 3.4 Etapa A — `players.guild_rank` é canônico (ADR-0009).
    // `guild_status` foi DROPPED — escrita dupla anterior era redundante.
    await _db.customUpdate(
      'UPDATE players SET guild_rank = ? WHERE id = ?',
      variables: [Variable.withString(newRank), Variable.withInt(playerId)],
      updates: {_db.playersTable},
    );
    return newRank;
  }

  Future<int> _calcProgress(String checkType, Map<String, dynamic> params,
      int playerId, Map<String, dynamic> ctx) async {
    switch (checkType) {
      case 'complete_any_total':
        final count = params['count'] as int;
        final rows = await _db.customSelect(
          'SELECT COUNT(*) as c FROM habit_logs WHERE player_id = ?',
          variables: [Variable.withInt(playerId)],
        ).get();
        final found = (rows.first.data['c'] as int?) ?? 0;
        return found.clamp(0, count);

      case 'complete_category_total':
        final count = params['count'] as int;
        final cat = params['category'] as String;
        final rows = await _db.customSelect(
          'SELECT COUNT(*) as c FROM habit_logs hl '
          'JOIN habits h ON hl.habit_id = h.id '
          'WHERE hl.player_id = ? AND h.category = ?',
          variables: [Variable.withInt(playerId), Variable.withString(cat)],
        ).get();
        final found = (rows.first.data['c'] as int?) ?? 0;
        return found.clamp(0, count);

      case 'streak_days':
        final days = params['days'] as int;
        final streak = ctx['streak'] as int? ?? 0;
        return streak.clamp(0, days);

      case 'no_niet_days':
        final days = params['days'] as int;
        final nf = ctx['niet_free_days'] as int? ?? 0;
        return nf.clamp(0, days);

      case 'spend_gold_total':
        final amount = params['amount'] as int;
        final spent = ctx['gold_spent_total'] as int? ?? 0;
        return spent.clamp(0, amount);

      case 'buy_items_total':
        final count = params['count'] as int;
        final bought = ctx['items_bought_total'] as int? ?? 0;
        return bought.clamp(0, count);

      case 'achievements_count':
        final count = params['count'] as int;
        final rows = await _db.customSelect(
          'SELECT COUNT(*) as c FROM player_achievements WHERE player_id = ?',
          variables: [Variable.withInt(playerId)],
        ).get();
        final found = (rows.first.data['c'] as int?) ?? 0;
        return found.clamp(0, count);

      case 'diary_total_words':
        final words = params['words'] as int;
        final rows = await _db.customSelect(
          'SELECT SUM(LENGTH(content) - LENGTH(REPLACE(content," ","")) + 1) as w '
          'FROM diary_entries WHERE player_id = ?',
          variables: [Variable.withInt(playerId)],
        ).get();
        final found = (rows.first.data['w'] as int?) ?? 0;
        return found.clamp(0, words);

      case 'achievements_and_diary':
        // Conta conquistas apenas (simplificado)
        final targetAch = params['achievements'] as int;
        final rows = await _db.customSelect(
          'SELECT COUNT(*) as c FROM player_achievements WHERE player_id = ?',
          variables: [Variable.withInt(playerId)],
        ).get();
        final found = (rows.first.data['c'] as int?) ?? 0;
        return found.clamp(0, targetAch);

      default:
        return 0;
    }
  }

  int _extractTarget(String checkType, Map<String, dynamic> params) {
    switch (checkType) {
      case 'complete_any_total': return params['count'] as int;
      case 'complete_category_total': return params['count'] as int;
      case 'streak_days': return params['days'] as int;
      case 'no_niet_days': return params['days'] as int;
      case 'spend_gold_total': return params['amount'] as int;
      case 'buy_items_total': return params['count'] as int;
      case 'achievements_count': return params['count'] as int;
      case 'diary_total_words': return params['words'] as int;
      case 'achievements_and_diary': return params['achievements'] as int;
      default: return 1;
    }
  }
}
