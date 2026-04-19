import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../database/daos/player_dao.dart';
import '../../../core/utils/vitalism_calculator.dart';
import '../../../domain/enums/class_type.dart';

// Ponto único de cura de HP. Garante que a regra de regen proporcional de
// vitalismo (ADR 0002) seja aplicada sempre, em qualquer fonte de cura futura.
//
// TODO: teste de integração em sprint futura (quando houver setup de banco
// em memória). A lógica de cálculo puro está testada via computeHealResult.
class PlayerHealService {
  final AppDatabase _db;
  PlayerHealService(this._db);

  PlayerDao get _dao => PlayerDao(_db);

  Future<void> applyHpHealWithVitalismRegen({
    required int playerId,
    required int hpGained,
  }) async {
    if (hpGained <= 0) return;

    final player = await _dao.findById(playerId);
    if (player == null) return;

    // Usamos maxHp persistido (não recalculamos via calcMaxHp) pra que
    // multiplicadores temporários futuros (buffs de item, rituais) sejam
    // respeitados sem precisar replicar a lógica aqui.
    final hpMax = player.maxHp;
    final parsedClass = ClassType.values.asNameMap()[player.classType];
    final vitalismMax = parsedClass != null
        ? VitalismCalculator.calculateMaxVitalism(
            hp: hpMax,
            classType: parsedClass,
            level: player.level,
          )
        : 0;

    final result = computeHealResult(
      currentHp: player.hp,
      currentVitalism: player.currentVitalism,
      hpGained: hpGained,
      hpMax: hpMax,
      vitalismMax: vitalismMax,
    );

    await (_db.update(_db.playersTable)
          ..where((t) => t.id.equals(playerId)))
        .write(PlayersTableCompanion(
      hp:              Value(result.newHp),
      currentVitalism: Value(result.newCurrentVitalism),
    ));
  }
}

class HealResult {
  final int newHp;
  final int newCurrentVitalism;
  const HealResult({required this.newHp, required this.newCurrentVitalism});
}

HealResult computeHealResult({
  required int currentHp,
  required int currentVitalism,
  required int hpGained,
  required int hpMax,
  required int vitalismMax,
}) {
  final newHp = (currentHp + hpGained).clamp(0, hpMax);
  final hpGainedReal = newHp - currentHp;

  if (vitalismMax <= 0 || hpMax <= 0 || hpGainedReal <= 0) {
    return HealResult(newHp: newHp, newCurrentVitalism: currentVitalism);
  }

  final percGanho = hpGainedReal / hpMax;
  final vitalismoGanho = (vitalismMax * percGanho).round();
  final newCurrentVitalism =
      (currentVitalism + vitalismoGanho).clamp(0, vitalismMax);

  return HealResult(
    newHp: newHp,
    newCurrentVitalism: newCurrentVitalism,
  );
}
