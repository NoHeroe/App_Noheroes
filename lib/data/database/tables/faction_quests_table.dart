import 'package:drift/drift.dart';

class FactionQuestsTable extends Table {
  String get tableName => 'active_faction_quests';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get factionId => text()();
  TextColumn get questKey => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get checkType => text()();
  TextColumn get checkParamsJson => text()();
  IntColumn get xpReward => integer().withDefault(const Constant(0))();
  IntColumn get goldReward => integer().withDefault(const Constant(0))();
  RealColumn get factionItemChance => real().withDefault(const Constant(0.05))();
  TextColumn get weekStart => text()(); // yyyy-MM-dd da segunda-feira
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get progressTarget => integer().withDefault(const Constant(1))();
  TextColumn get lastQuestKey => text().withDefault(const Constant(''))(); // evita repetição
}
