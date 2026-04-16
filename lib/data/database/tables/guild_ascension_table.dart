import 'package:drift/drift.dart';

class GuildAscensionTable extends Table {
  String get tableName => 'guild_ascension_progress';
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer()();
  TextColumn get rankFrom => text()(); // e, d, c, b, a
  TextColumn get rankTo => text()();
  IntColumn get step => integer()(); // 1, 2, 3, (4 para A→S)
  TextColumn get questKey => text()(); // opção sorteada (ed1a, ed1b...)
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get checkType => text()();
  TextColumn get checkParamsJson => text()();
  IntColumn get unlockLevel => integer()();
  IntColumn get xpReward => integer()();
  IntColumn get goldReward => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get progressTarget => integer().withDefault(const Constant(1))();
}
