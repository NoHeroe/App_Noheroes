import 'package:drift/drift.dart';

class ClassQuestsTable extends Table {
  String get tableName => 'active_class_quests';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get classType => text()();
  TextColumn get questKey => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get checkType => text()();
  TextColumn get checkParamsJson => text()();
  IntColumn get xpReward => integer().withDefault(const Constant(0))();
  IntColumn get goldReward => integer().withDefault(const Constant(0))();
  TextColumn get assignedDate => text()(); // yyyy-MM-dd
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get progressTarget => integer().withDefault(const Constant(1))();
}
