// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guild_dao.dart';

// ignore_for_file: type=lint
mixin _$GuildDaoMixin on DatabaseAccessor<AppDatabase> {
  $GuildStatusTableTable get guildStatusTable =>
      attachedDatabase.guildStatusTable;
  GuildDaoManager get managers => GuildDaoManager(this);
}

class GuildDaoManager {
  final _$GuildDaoMixin _db;
  GuildDaoManager(this._db);
  $$GuildStatusTableTableTableManager get guildStatusTable =>
      $$GuildStatusTableTableTableManager(
          _db.attachedDatabase, _db.guildStatusTable);
}
