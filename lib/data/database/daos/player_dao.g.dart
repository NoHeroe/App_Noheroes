// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_dao.dart';

// ignore_for_file: type=lint
mixin _$PlayerDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlayersTableTable get playersTable => attachedDatabase.playersTable;
  PlayerDaoManager get managers => PlayerDaoManager(this);
}

class PlayerDaoManager {
  final _$PlayerDaoMixin _db;
  PlayerDaoManager(this._db);
  $$PlayersTableTableTableManager get playersTable =>
      $$PlayersTableTableTableManager(_db.attachedDatabase, _db.playersTable);
}
