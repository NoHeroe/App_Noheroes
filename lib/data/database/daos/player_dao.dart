import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/players_table.dart';

part 'player_dao.g.dart';

@DriftAccessor(tables: [PlayersTable])
class PlayerDao extends DatabaseAccessor<AppDatabase> with _$PlayerDaoMixin {
  PlayerDao(super.db);

  Future<PlayersTableData?> findByEmail(String email) {
    return (select(playersTable)
          ..where((t) => t.email.equals(email)))
        .getSingleOrNull();
  }

  Future<PlayersTableData?> findById(int id) {
    return (select(playersTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> createPlayer(PlayersTableCompanion player) {
    return into(playersTable).insert(player);
  }

  Future<void> touchLastLogin(int id) {
    return (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(
            lastLoginAt: Value(DateTime.now())));
  }

  Future<void> completeOnboarding(
      int id, String shadowName, String narrativeMode) {
    return (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(
      onboardingDone: const Value(true),
      shadowName: Value(shadowName),
      narrativeMode: Value(narrativeMode),
    ));
  }
}
