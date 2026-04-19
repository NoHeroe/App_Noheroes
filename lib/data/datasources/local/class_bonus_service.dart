import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../database/daos/player_dao.dart';
import '../../../core/utils/vitalism_calculator.dart';
import '../../../domain/enums/class_type.dart';

class ClassBonusService {
  final AppDatabase _db;
  ClassBonusService(this._db);

  PlayerDao get _dao => PlayerDao(_db);

  static const _bonuses = {
    'warrior':      {'strength': 4, 'constitution': 3, 'dexterity': 2, 'intelligence': 1, 'spirit': 1, 'charisma': 1},
    'colossus':     {'strength': 5, 'constitution': 4, 'dexterity': 1, 'intelligence': 1, 'spirit': 1, 'charisma': 0},
    'monk':         {'strength': 2, 'constitution': 2, 'dexterity': 3, 'intelligence': 2, 'spirit': 4, 'charisma': 1},
    'rogue':        {'strength': 2, 'constitution': 1, 'dexterity': 5, 'intelligence': 3, 'spirit': 1, 'charisma': 2},
    'hunter':       {'strength': 2, 'constitution': 2, 'dexterity': 4, 'intelligence': 3, 'spirit': 2, 'charisma': 1},
    'druid':        {'strength': 1, 'constitution': 2, 'dexterity': 2, 'intelligence': 3, 'spirit': 5, 'charisma': 1},
    'mage':         {'strength': 1, 'constitution': 1, 'dexterity': 2, 'intelligence': 5, 'spirit': 3, 'charisma': 2},
    'shadowWeaver': {'strength': 2, 'constitution': 2, 'dexterity': 2, 'intelligence': 2, 'spirit': 2, 'charisma': 2},
  };

  Future<void> applyClassBonus(int playerId, String classId) async {
    final player = await _dao.findById(playerId);
    if (player == null) return;

    final bonus = _bonuses[classId];
    if (bonus == null) return;

    final maxHp = 100 + (bonus['constitution']! * 10) + (player.level * 5);
    final maxMp = (maxHp * 0.9).round();

    final parsedClass = ClassType.values.asNameMap()[classId];
    final maxVitalism = parsedClass != null
        ? VitalismCalculator.calculateMaxVitalism(
            hp: maxHp,
            classType: parsedClass,
            level: player.level,
          )
        : 0;

    await (_db.update(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .write(PlayersTableCompanion(
      classType:        Value(classId),
      strength:         Value(bonus['strength']!),
      constitution:     Value(bonus['constitution']!),
      dexterity:        Value(bonus['dexterity']!),
      intelligence:     Value(bonus['intelligence']!),
      spirit:           Value(bonus['spirit']!),
      charisma:         Value(bonus['charisma']!),
      maxHp:            Value(maxHp),
      hp:               Value(maxHp),
      maxMp:            Value(maxMp),
      mp:               Value(maxMp),
      currentVitalism:  Value(maxVitalism),
    ));
  }

  Future<void> applyFactionChoice(int playerId, String factionId) async {
    await (_db.update(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .write(PlayersTableCompanion(factionType: Value(factionId)));
  }
}
