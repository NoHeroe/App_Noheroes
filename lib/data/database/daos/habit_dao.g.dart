// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitsTableTable get habitsTable => attachedDatabase.habitsTable;
  $HabitLogsTableTable get habitLogsTable => attachedDatabase.habitLogsTable;
  HabitDaoManager get managers => HabitDaoManager(this);
}

class HabitDaoManager {
  final _$HabitDaoMixin _db;
  HabitDaoManager(this._db);
  $$HabitsTableTableTableManager get habitsTable =>
      $$HabitsTableTableTableManager(_db.attachedDatabase, _db.habitsTable);
  $$HabitLogsTableTableTableManager get habitLogsTable =>
      $$HabitLogsTableTableTableManager(
          _db.attachedDatabase, _db.habitLogsTable);
}
