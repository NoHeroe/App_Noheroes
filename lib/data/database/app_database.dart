import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/players_table.dart';
import 'tables/habits_table.dart';
import 'tables/habit_logs_table.dart';
import 'daos/player_dao.dart';
import 'daos/habit_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [PlayersTable, HabitsTable, HabitLogsTable],
    daos: [PlayerDao, HabitDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(habitsTable);
        await m.createTable(habitLogsTable);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'noheroes.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
