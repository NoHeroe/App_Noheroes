import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../database/app_database.dart';
import '../../database/daos/habit_dao.dart';

class ShadowQuestService {
  final AppDatabase _db;
  ShadowQuestService(this._db);

  HabitDao get _habitDao => HabitDao(_db);

  /// Carrega shadow quests do JSON
  Future<List<Map<String, dynamic>>> _loadQuests() async {
    final raw = await rootBundle.loadString('assets/data/shadow_quests.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    return (data['shadow_quests'] as List).cast<Map<String, dynamic>>();
  }

  /// Verifica e atribui shadow quests baseado no estado da sombra atual
  /// Retorna lista de títulos das quests atribuídas
  Future<List<String>> checkAndAssign(int playerId, String shadowState) async {
    final all = await _loadQuests();
    final relevant = all
        .where((q) => q['trigger_state'] == shadowState)
        .toList();

    if (relevant.isEmpty) return [];

    final assigned = <String>[];

    for (final q in relevant) {
      final key = q['key'] as String;
      final title = '[Sombra] ${q['title'] as String}';

      // Verifica se já existe essa shadow quest ativa para o player
      final existing = await (_db.select(_db.habitsTable)
            ..where((t) => t.playerId.equals(playerId))
            ..where((t) => t.title.equals(title)))
          .getSingleOrNull();

      if (existing != null) continue;

      // Cria a shadow quest como system habit
      await _habitDao.createHabit(HabitsTableCompanion(
        playerId:      Value(playerId),
        title:         Value(title),
        description:   Value(q['description'] as String),
        category:      Value(q['category'] as String),
        rank:          Value(q['rank'] as String),
        isSystemHabit: const Value(true),
        isRepeatable:  const Value(false),
        xpReward:      Value(q['xp'] as int? ?? 30),
        goldReward:    Value(q['gold'] as int? ?? 15),
      ));

      assigned.add(q['title'] as String);
    }

    return assigned;
  }

  /// Remove shadow quests antigas quando estado muda
  Future<void> clearOldShadowQuests(int playerId, String newState) async {
    // Busca todas shadow quests do player
    final all = await (_db.select(_db.habitsTable)
          ..where((t) => t.playerId.equals(playerId))
          ..where((t) => t.isSystemHabit.equals(true))
          ..where((t) => t.title.like('[Sombra]%')))
        .get();

    final validStates = [newState];
    final jsonQuests = await _loadQuests();

    for (final habit in all) {
      // Verifica se essa quest ainda é válida para o estado atual
      final matchingQuest = jsonQuests.firstWhere(
        (q) => '[Sombra] ${q['title']}' == habit.title,
        orElse: () => {},
      );
      if (matchingQuest.isEmpty) continue;

      final triggerState = matchingQuest['trigger_state'] as String;
      if (!validStates.contains(triggerState)) {
        // Remove se não for do estado atual e não tiver log hoje
        final todayLog = await _habitDao.getTodayLog(habit.id, playerId);
        if (todayLog == null) {
          await (_db.delete(_db.habitsTable)
                ..where((t) => t.id.equals(habit.id)))
              .go();
        }
      }
    }
  }
}
