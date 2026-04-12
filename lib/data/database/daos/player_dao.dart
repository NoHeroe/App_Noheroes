import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/players_table.dart';
import '../../../core/utils/xp_calculator.dart';

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

  Future<void> touchLastLogin(int id) async {
    final player = await findById(id);
    if (player == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = player.lastLoginAt;
    final lastLoginDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);

    if (lastLoginDay == today) return;

    int newStreak = player.streakDays;
    final lastStreak = player.lastStreakDate;
    if (XpCalculator.isStreakValid(lastStreak)) {
      newStreak++;
    } else {
      newStreak = 1;
    }

    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(
      lastLoginAt: Value(now),
      lastStreakDate: Value(today),
      streakDays: Value(newStreak),
      caelumDay: Value(player.caelumDay + 1),
    ));
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

  Future<void> addXp(int id, int xpAmount) async {
    final player = await findById(id);
    if (player == null) return;

    int newXp = player.xp + xpAmount;
    int newLevel = player.level;
    int newXpToNext = player.xpToNext;
    int newAttrPoints = player.attributePoints;

    while (newXp >= newXpToNext) {
      newXp -= newXpToNext;
      newLevel++;
      newAttrPoints++;
      newXpToNext = XpCalculator.xpToNextLevel(newLevel);
    }

    final newMaxHp = XpCalculator.calcMaxHp(player.constitution, newLevel);
    final newMaxMp = XpCalculator.calcMaxMp(player.spirit, player.constitution, newLevel);

    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(
      xp: Value(newXp),
      level: Value(newLevel),
      xpToNext: Value(newXpToNext),
      attributePoints: Value(newAttrPoints),
      maxHp: Value(newMaxHp),
      maxMp: Value(newMaxMp),
    ));
  }

  Future<void> addGold(int id, int amount) async {
    final player = await findById(id);
    if (player == null) return;
    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(gold: Value(player.gold + amount)));
  }

  Future<void> updateShadow(int id, int shadowImpact) async {
    final player = await findById(id);
    if (player == null) return;
    int newCorruption = (player.shadowCorruption - shadowImpact).clamp(0, 100);
    final newState = XpCalculator.calcShadowState(newCorruption);
    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(
      shadowCorruption: Value(newCorruption),
      shadowState: Value(newState),
    ));
  }

  Future<String?> distributePoint(int id, String attribute) async {
    final player = await findById(id);
    if (player == null) return 'Jogador não encontrado';
    if (player.attributePoints <= 0) return 'Sem pontos disponíveis';

    final pts = player.attributePoints - 1;
    PlayersTableCompanion data;

    switch (attribute) {
      case 'strength':
        data = PlayersTableCompanion(
            strength: Value(player.strength + 1),
            attributePoints: Value(pts));
        break;
      case 'dexterity':
        data = PlayersTableCompanion(
            dexterity: Value(player.dexterity + 1),
            attributePoints: Value(pts));
        break;
      case 'intelligence':
        data = PlayersTableCompanion(
            intelligence: Value(player.intelligence + 1),
            attributePoints: Value(pts));
        break;
      case 'constitution':
        final newCon = player.constitution + 1;
        final newMaxHp = XpCalculator.calcMaxHp(newCon, player.level);
        final newMaxMp = XpCalculator.calcMaxMp(player.spirit, newCon, player.level);
        data = PlayersTableCompanion(
            constitution: Value(newCon),
            maxHp: Value(newMaxHp),
            maxMp: Value(newMaxMp),
            hp: Value(newMaxHp),
            attributePoints: Value(pts));
        break;
      case 'spirit':
        final newSpi = player.spirit + 1;
        final newMaxMp = XpCalculator.calcMaxMp(newSpi, player.constitution, player.level);
        data = PlayersTableCompanion(
            spirit: Value(newSpi),
            maxMp: Value(newMaxMp),
            attributePoints: Value(pts));
        break;
      case 'charisma':
        data = PlayersTableCompanion(
            charisma: Value(player.charisma + 1),
            attributePoints: Value(pts));
        break;
      default:
        return 'Atributo inválido';
    }

    await (db.update(db.playersTable)..where((t) => t.id.equals(id))).write(data);
    return null;
  }

  Future<void> resetLevelAttributes(int id, int level, int goldCost) async {
    final player = await findById(id);
    if (player == null) return;
    final pointsFromLevel = level - 1;
    await (db.update(db.playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(
      strength:        const Value(1),
      dexterity:       const Value(1),
      intelligence:    const Value(1),
      constitution:    const Value(1),
      spirit:          const Value(1),
      charisma:        const Value(1),
      attributePoints: Value(pointsFromLevel),
      gold:            Value(player.gold - goldCost),
    ));
  }
}
