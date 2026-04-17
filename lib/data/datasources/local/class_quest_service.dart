import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/services.dart';
import '../../database/app_database.dart';
import '../../database/tables/class_quests_table.dart';

class ClassQuestService {
  final AppDatabase _db;
  ClassQuestService(this._db);

  // Sorteia 3 missões do dia para a classe, sem repetir as de ontem
  Future<List<ClassQuestsTableData>> assignDailyQuests(
      int playerId, String classType) async {
    final today = _todayStr();

    // Já tem missões hoje?
    final existing = await (_db.select(_db.classQuestsTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.assignedDate.equals(today)))
        .get();
    if (existing.isNotEmpty) return existing;

    // Carrega pool da classe
    final raw = await rootBundle
        .loadString('assets/data/class_quests_daily.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final pool = (json['class_quests'][classType] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    if (pool.isEmpty) return [];

    // Pega chaves de ontem para não repetir
    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final yesterdayKeys = (await (_db.select(_db.classQuestsTable)
              ..where((t) =>
                  t.playerId.equals(playerId) &
                  t.assignedDate.equals(yesterday)))
            .get())
        .map((e) => e.questKey)
        .toSet();

    // Filtra e sorteia 3
    final available = pool.where((q) => !yesterdayKeys.contains(q['key'])).toList();
    final candidates = available.isEmpty ? pool : available;
    candidates.shuffle(Random());
    final selected = candidates.take(3).toList();

    // Insere no banco
    final result = <ClassQuestsTableData>[];
    for (final q in selected) {
      final params = q['check_params'] as Map<String, dynamic>;
      final target = _extractTarget(q['check_type'] as String, params);
      final row = await _db.into(_db.classQuestsTable).insertReturning(
        ClassQuestsTableCompanion(
          playerId: Value(playerId),
          classType: Value(classType),
          questKey: Value(q['key'] as String),
          title: Value(q['title'] as String),
          description: Value(q['description'] as String),
          checkType: Value(q['check_type'] as String),
          checkParamsJson: Value(jsonEncode(params)),
          xpReward: Value(q['xp'] as int),
          goldReward: Value(q['gold'] as int),
          assignedDate: Value(today),
          progressTarget: Value(target),
        ),
      );
      result.add(row);
    }
    return result;
  }

  Future<List<ClassQuestsTableData>> getTodayQuests(
      int playerId) async {
    final today = _todayStr();
    return (_db.select(_db.classQuestsTable)
          ..where((t) =>
              t.playerId.equals(playerId) &
              t.assignedDate.equals(today) &
              t.completed.equals(false)))
        .get();
  }

  // Checa todas as missões do dia e retorna as recém completadas
  Future<List<ClassQuestsTableData>> checkAndComplete(
      int playerId, Map<String, dynamic> context) async {
    final quests = await getTodayQuests(playerId);
    final completed = <ClassQuestsTableData>[];

    for (final quest in quests) {
      final params = jsonDecode(quest.checkParamsJson) as Map<String, dynamic>;
      final progress = await _calcProgress(quest.checkType, params, playerId, context);

      if (progress >= quest.progressTarget) {
        await (_db.update(_db.classQuestsTable)
              ..where((t) => t.id.equals(quest.id)))
            .write(ClassQuestsTableCompanion(
          completed: const Value(true),
          progress: Value(quest.progressTarget),
        ));
        completed.add(quest);
      } else if (progress != quest.progress) {
        await (_db.update(_db.classQuestsTable)
              ..where((t) => t.id.equals(quest.id)))
            .write(ClassQuestsTableCompanion(progress: Value(progress)));
      }
    }
    return completed;
  }

  Future<int> _calcProgress(String checkType, Map<String, dynamic> params,
      int playerId, Map<String, dynamic> ctx) async {
    switch (checkType) {
      case 'complete_category_today':
        final cat = params['category'] as String;
        final logs = await _db.customSelect(
          'SELECT COUNT(*) as c FROM habit_logs hl '
          'JOIN habits h ON hl.habit_id = h.id '
          'WHERE hl.player_id = ? AND h.category = ? '
          'AND date(hl.log_date) = date("now","localtime")',
          variables: [Variable.withInt(playerId), Variable.withString(cat)],
        ).get();
        return (logs.first.data['c'] as int?) ?? 0;

      case 'complete_any_today':
        final logs = await _db.customSelect(
          'SELECT COUNT(*) as c FROM habit_logs '
          'WHERE player_id = ? AND date(log_date) = date("now","localtime")',
          variables: [Variable.withInt(playerId)],
        ).get();
        return (logs.first.data['c'] as int?) ?? 0;

      case 'complete_categories_today':
        final count = params['count'] as int;
        final cats = await _db.customSelect(
          'SELECT COUNT(DISTINCT h.category) as c FROM habit_logs hl '
          'JOIN habits h ON hl.habit_id = h.id '
          'WHERE hl.player_id = ? AND date(hl.log_date) = date("now","localtime")',
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
        final spent = ctx['gold_spent_today'] as int? ?? 0;
        return spent >= amount ? amount : spent;

      case 'buy_item':
        final count = params['count'] as int;
        final bought = ctx['items_bought_today'] as int? ?? 0;
        return bought >= count ? count : bought;

      case 'write_diary':
        final minWords = params['min_words'] as int;
        final words = ctx['diary_words_today'] as int? ?? 0;
        return words >= minWords ? minWords : words;

      case 'talk_npc':
        final npcId = params['npc_id'] as String;
        final talked = ctx['talked_npc'] as String? ?? '';
        return talked == npcId ? 1 : 0;

      case 'increase_attribute':
        final amount = params['amount'] as int;
        final gained = ctx['attribute_points_gained'] as int? ?? 0;
        return gained >= amount ? amount : gained;

      default:
        return 0;
    }
  }

  int _extractTarget(String checkType, Map<String, dynamic> params) {
    switch (checkType) {
      case 'complete_category_today':
        return params['count'] as int;
      case 'complete_any_today':
        return params['count'] as int;
      case 'complete_categories_today':
        return params['count'] as int;
      case 'no_niet_days':
        return params['days'] as int;
      case 'streak_days':
        return params['days'] as int;
      case 'spend_gold':
        return params['amount'] as int;
      case 'buy_item':
        return params['count'] as int;
      case 'write_diary':
        return params['min_words'] as int;
      case 'talk_npc':
        return 1;
      case 'increase_attribute':
        return params['amount'] as int;
      default:
        return 1;
    }
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  String _dateStr(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }
}
