import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../database/app_database.dart';
import '../../database/daos/habit_dao.dart';
import '../../database/daos/player_dao.dart';
import '../../database/tables/habits_table.dart';

class QuestAdmissionService {
  final AppDatabase _db;
  QuestAdmissionService(this._db);

  HabitDao get _habitDao => HabitDao(_db);
  PlayerDao get _playerDao => PlayerDao(_db);

  // Cria as 3 quests de classe e confirma a classe
  Future<void> startClassQuests(int playerId, String classId) async {
    final raw = await rootBundle.loadString('assets/data/class_quests.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final quests = (data[classId] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Confirma a classe imediatamente
    await (_db.update(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .write(PlayersTableCompanion(classType: Value(classId)));

    // Cria as 3 missões temáticas da classe
    for (final q in quests) {
      await _habitDao.createHabit(HabitsTableCompanion(
        playerId:      Value(playerId),
        title:         Value('[${_classLabel(classId)}] ${q['title']}'),
        description:   Value(q['description'] as String),
        category:      Value(q['category'] as String),
        rank:          Value(q['rank'] as String),
        isSystemHabit: const Value(true),
        isRepeatable:  const Value(false),
        xpReward:      Value(q['xp'] as int),
        goldReward:    Value(q['gold'] as int),
      ));
    }
  }

  // Cria as 3 missões de admissão da facção (sem confirmar ainda)
  Future<void> startFactionAdmission(int playerId, String factionId) async {
    final raw = await rootBundle.loadString('assets/data/faction_admission_quests.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final quests = (data[factionId] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Salva a facção pendente no campo factionType com prefixo "pending:"
    await (_db.update(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .write(PlayersTableCompanion(
          factionType: Value('pending:$factionId'),
        ));

    // Cria as 3 missões de admissão
    for (final q in quests) {
      await _habitDao.createHabit(HabitsTableCompanion(
        playerId:      Value(playerId),
        title:         Value('[Admissão] ${q['title']}'),
        description:   Value(q['description'] as String),
        category:      Value(q['category'] as String),
        rank:          Value(q['rank'] as String),
        isSystemHabit: const Value(true),
        isRepeatable:  const Value(false),
        xpReward:      Value(q['xp'] as int),
        goldReward:    Value(q['gold'] as int),
      ));
    }
  }

  // Verifica se as 3 missões de admissão foram completadas
  Future<bool> checkFactionAdmission(int playerId, String factionId) async {
    final habits = await _habitDao.getHabits(playerId);
    final admissionHabits = habits.where(
      (h) => h.title.startsWith('[Admissão]') && h.isSystemHabit,
    ).toList();

    if (admissionHabits.isEmpty) return false;

    // Verifica se todas têm log de completado
    int completed = 0;
    for (final h in admissionHabits) {
      final logs = await (_db.select(_db.habitLogsTable)
            ..where((t) => t.habitId.equals(h.id))
            ..where((t) => t.playerId.equals(playerId)))
          .get();
      if (logs.any((l) => l.status == 'completed' || l.status == 'partial')) {
        completed++;
      }
    }

    return completed >= admissionHabits.length;
  }

  // Confirma entrada na facção após admissão
  Future<void> confirmFaction(int playerId, String factionId) async {
    await (_db.update(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .write(PlayersTableCompanion(factionType: Value(factionId)));

    // Remove missões de admissão
    final habits = await _habitDao.getHabits(playerId);
    for (final h in habits.where((h) => h.title.startsWith('[Admissão]'))) {
      await _habitDao.deleteHabit(h.id);
    }
  }

  // Falha na admissão — penaliza e limpa
  Future<void> failFactionAdmission(int playerId) async {
    await (_db.update(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .write(const PlayersTableCompanion(factionType: Value(null)));

    await _playerDao.updateShadow(playerId, -15);

    final habits = await _habitDao.getHabits(playerId);
    for (final h in habits.where((h) => h.title.startsWith('[Admissão]'))) {
      await _habitDao.deleteHabit(h.id);
    }
  }

  String _classLabel(String id) => switch (id) {
    'warrior'      => 'Guerreiro',
    'colossus'     => 'Colosso',
    'monk'         => 'Monge',
    'rogue'        => 'Ladino',
    'hunter'       => 'Caçador',
    'druid'        => 'Druida',
    'mage'         => 'Mago',
    'shadowWeaver' => 'Tecelão',
    _              => 'Classe',
  };
}
