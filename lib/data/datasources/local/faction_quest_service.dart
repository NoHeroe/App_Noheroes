import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/services.dart';
import '../../database/app_database.dart';
import '../../database/tables/faction_quests_table.dart';


class FactionQuestService {
  final AppDatabase _db;
  FactionQuestService(this._db);

  static String weekStart([DateTime? ref]) {
    final now = ref ?? DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2,'0')}-${monday.day.toString().padLeft(2,'0')}';
  }

  static Duration timeUntilNextWeek() {
    final now = DateTime.now();
    final nextMonday = now.add(Duration(days: 8 - now.weekday));
    final reset = DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
    return reset.difference(now);
  }

  Future<FactionQuestsTableData?> getActiveQuest(
      int playerId, String factionId) async {
    final ws = weekStart();
    return (_db.select(_db.factionQuestsTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.factionId.equals(factionId) &
              t.weekStart.equals(ws)))
        .getSingleOrNull();
  }

  Future<FactionQuestsTableData?> assignWeeklyQuest(
      int playerId, String factionId) async {
    final existing = await getActiveQuest(playerId, factionId);
    if (existing != null) return existing;

    final raw = await rootBundle
        .loadString('assets/data/faction_quests_weekly.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final pool = (json['faction_quests'][factionId] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    if (pool.isEmpty) return null;

    // Pega a última quest para não repetir
    final lastRow = await (_db.select(_db.factionQuestsTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.factionId.equals(factionId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    final lastKey = lastRow?.questKey ?? '';

    final available = pool.where((q) => q['key'] != lastKey).toList();
    final candidates = available.isEmpty ? pool : available;
    candidates.shuffle(Random());
    final q = candidates.first;

    final params = q['check_params'] as Map<String, dynamic>;
    final target = _extractTarget(q['check_type'] as String, params);

    return _db.into(_db.factionQuestsTable).insertReturning(
      FactionQuestsTableCompanion(
        playerId: Value(playerId),
        factionId: Value(factionId),
        questKey: Value(q['key'] as String),
        title: Value(q['title'] as String),
        description: Value(q['description'] as String),
        checkType: Value(q['check_type'] as String),
        checkParamsJson: Value(jsonEncode(params)),
        xpReward: Value(q['xp'] as int),
        goldReward: Value(q['gold'] as int),
        factionItemChance: Value((q['faction_item_chance'] as num).toDouble()),
        weekStart: Value(weekStart()),
        progressTarget: Value(target),
      ),
    );
  }

  // Retorna true se completou agora
  Future<bool> checkAndComplete(
      int playerId, String factionId, Map<String, dynamic> ctx) async {
    final quest = await getActiveQuest(playerId, factionId);
    if (quest == null || quest.completed) return false;

    final params = jsonDecode(quest.checkParamsJson) as Map<String, dynamic>;
    final progress = await _calcProgress(
        quest.checkType, params, playerId, ctx);

    if (progress >= quest.progressTarget) {
      await (_db.update(_db.factionQuestsTable)
            ..where((t) => t.id.equals(quest.id)))
          .write(FactionQuestsTableCompanion(
        completed: const Value(true),
        progress: Value(quest.progressTarget),
      ));
      return true;
    }

    if (progress != quest.progress) {
      await (_db.update(_db.factionQuestsTable)
            ..where((t) => t.id.equals(quest.id)))
          .write(FactionQuestsTableCompanion(progress: Value(progress)));
    }
    return false;
  }

  // Calcula loot ao completar: baú garantido (raridade aleatória, rank do player) + 5% item de facção
  static Map<String, dynamic> calcLoot(String playerRank, double factionItemChance) {
    final rng = Random();
    // Baú: raridade baseada no rank
    final chestRarity = _chestRarityForRank(playerRank, rng);
    final hasFactionItem = rng.nextDouble() < factionItemChance;
    return {
      'chest_rarity': chestRarity,
      'has_faction_item': hasFactionItem,
    };
  }

  static String _chestRarityForRank(String rank, Random rng) {
    // rank e/d -> comum/incomum, c/b -> raro/épico, a/s -> épico/lendário
    final roll = rng.nextDouble();
    switch (rank.toLowerCase()) {
      case 's':
        return roll < 0.5 ? 'legendary' : 'epic';
      case 'a':
        return roll < 0.4 ? 'epic' : (roll < 0.8 ? 'rare' : 'legendary');
      case 'b':
        return roll < 0.5 ? 'rare' : (roll < 0.85 ? 'uncommon' : 'epic');
      case 'c':
        return roll < 0.5 ? 'uncommon' : (roll < 0.85 ? 'rare' : 'common');
      case 'd':
        return roll < 0.6 ? 'common' : 'uncommon';
      default: // e
        return roll < 0.8 ? 'common' : 'uncommon';
    }
  }

  Future<int> _calcProgress(String checkType, Map<String, dynamic> params,
      int playerId, Map<String, dynamic> ctx) async {
    // Reutiliza mesma lógica do ClassQuestService mas com escopo semanal
    switch (checkType) {
      case 'complete_category_week':
        final cat = params['category'] as String;
        final ws = weekStart();
        final logs = await _db.customSelect(
          'SELECT COUNT(*) as c FROM habit_logs hl '
          'JOIN habits h ON hl.habit_id = h.id '
          'WHERE hl.player_id = ? AND h.category = ? '
          'AND date(hl.completed_at) >= ?',
          variables: [
            Variable.withInt(playerId),
            Variable.withString(cat),
            Variable.withString(ws),
          ],
        ).get();
        return (logs.first.data['c'] as int?) ?? 0;

      case 'complete_any_week':
        final ws = weekStart();
        final logs = await _db.customSelect(
          'SELECT COUNT(*) as c FROM habit_logs '
          'WHERE player_id = ? AND date(completed_at) >= ?',
          variables: [Variable.withInt(playerId), Variable.withString(ws)],
        ).get();
        return (logs.first.data['c'] as int?) ?? 0;

      case 'complete_categories_today':
        final count = params['count'] as int;
        final cats = await _db.customSelect(
          'SELECT COUNT(DISTINCT h.category) as c FROM habit_logs hl '
          'JOIN habits h ON hl.habit_id = h.id '
          'WHERE hl.player_id = ? AND date(hl.completed_at) = date("now","localtime")',
          variables: [Variable.withInt(playerId)],
        ).get();
        final found = (cats.first.data['c'] as int?) ?? 0;
        return found >= count ? count : found;

      case 'no_niet_days':
        final days = params['days'] as int;
        final streak = ctx['niet_free_days'] as int? ?? 0;
        return streak >= days ? days : streak;

      case 'streak_days':
        final days = params['days'] as int;
        final streak = ctx['streak'] as int? ?? 0;
        return streak >= days ? days : streak;

      case 'spend_gold':
        final amount = params['amount'] as int;
        final ws = weekStart();
        // Total gasto desde segunda
        final spent = ctx['gold_spent_week'] as int? ?? 0;
        return spent >= amount ? amount : spent;

      case 'buy_item':
        final count = params['count'] as int;
        final bought = ctx['items_bought_week'] as int? ?? 0;
        return bought >= count ? count : bought;

      case 'write_diary':
        final minWords = params['min_words'] as int;
        final ws = weekStart();
        final entries = await _db.customSelect(
          'SELECT SUM(LENGTH(content) - LENGTH(REPLACE(content," ","")) + 1) as words '
          'FROM diary_entries WHERE player_id = ? AND date(created_at) >= ?',
          variables: [Variable.withInt(playerId), Variable.withString(ws)],
        ).get();
        final words = (entries.first.data['words'] as int?) ?? 0;
        return words >= minWords ? minWords : words;

      default:
        return 0;
    }
  }

  int _extractTarget(String checkType, Map<String, dynamic> params) {
    switch (checkType) {
      case 'complete_category_week': return params['count'] as int;
      case 'complete_any_week': return params['count'] as int;
      case 'complete_categories_today': return params['count'] as int;
      case 'no_niet_days': return params['days'] as int;
      case 'streak_days': return params['days'] as int;
      case 'spend_gold': return params['amount'] as int;
      case 'buy_item': return params['count'] as int;
      case 'write_diary': return params['min_words'] as int;
      default: return 1;
    }
  }
}
