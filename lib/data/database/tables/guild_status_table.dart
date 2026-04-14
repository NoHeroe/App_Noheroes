import 'package:drift/drift.dart';

class GuildStatusTable extends Table {
  @override
  String get tableName => 'guild_status';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer().unique()();
  TextColumn get guildRank => text().withDefault(const Constant('none'))();
  IntColumn get guildReputation => integer().withDefault(const Constant(0))();
  IntColumn get collarLevel => integer().withDefault(const Constant(0))();
  IntColumn get totalGoldSpent => integer().withDefault(const Constant(0))();
  DateTimeColumn get joinedAt => dateTime().nullable()();
  DateTimeColumn get ascensionCooldown => dateTime().nullable()();
}
