import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/players_table.dart';
import '../../../core/events/player_events.dart';
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

  /// Credita XP ao jogador, recalculando level / xpToNext / HP máximo /
  /// attribute points conforme marcos de scaling (10,15,20,25,30,40,50,
  /// 60,70,80,99 — varia por classe).
  ///
  /// Sprint 3.1 Bloco 7a — retorna `LevelUp` event (não publicado) quando
  /// o level mudou; caller publica no [AppEventBus] se houver.
  /// Exemplo canônico:
  /// ```dart
  /// final evt = await playerDao.addXp(id, 100);
  /// if (evt != null) eventBus.publish(evt);
  /// ```
  /// PlayerDao fica desacoplado do EventBus — camada data não conhece
  /// camada core/events (ADR 0016).
  ///
  /// Nenhum caller vivo chama addXp hoje (callers antigos foram .bakados
  /// no Bloco 1). `LevelUp` event fica dormente até Bloco 14 (assignment)
  /// e Bloco 15.5 (fix do RewardGrantService usar addXp dentro da
  /// transaction) ligarem.
  Future<LevelUp?> addXp(int id, int xpAmount) async {
    final player = await findById(id);
    if (player == null) return null;

    int newXp = player.xp + xpAmount;
    int newLevel = player.level;
    int newXpToNext = player.xpToNext;
    int newAttrPoints = player.attributePoints;

    final oldLevel = player.level;
    while (newXp >= newXpToNext) {
      newXp -= newXpToNext;
      newLevel++;
      newAttrPoints++;
      newXpToNext = XpCalculator.xpToNextLevel(newLevel);
    }
    // Bônus de scaling nos marcos (10,15,20,25,30,40,50,60,70,80,99)
    final scalingMarcos = [10,15,20,25,30,40,50,60,70,80,99];
    for (final marco in scalingMarcos) {
      if (oldLevel < marco && newLevel >= marco) {
        newAttrPoints += _scalingBonusPoints(player.classType, marco);
      }
    }
    // Bônus de scaling nos marcos (10,15,20,25,30,40,50,60,70,80,99)


    final newMaxHp = XpCalculator.calcMaxHp(player.constitution, newLevel);
    final newMaxMp = XpCalculator.calcMaxMp(player.spirit, player.constitution, newLevel);

    // Sprint 3.3 Etapa 2.1c-α — peak_level all-time. Foundation pra
    // shell #4 (Queda do Vidente) detectar retorno de level superior.
    // Só sobe; nunca decresce mesmo que sistema futuro reduza level.
    final newPeakLevel = newLevel > player.peakLevel
        ? newLevel
        : player.peakLevel;

    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(
      xp: Value(newXp),
      level: Value(newLevel),
      xpToNext: Value(newXpToNext),
      attributePoints: Value(newAttrPoints),
      maxHp: Value(newMaxHp),
      maxMp: Value(newMaxMp),
      peakLevel: Value(newPeakLevel),
    ));

    // Sprint 3.1 Bloco 7a — retorna LevelUp quando level mudou.
    // Caller publica no bus (PlayerDao é camada data — desacoplada
    // do EventBus por ADR 0016).
    if (newLevel > oldLevel) {
      return LevelUp(
        playerId: id,
        newLevel: newLevel,
        previousLevel: oldLevel,
      );
    }
    return null;
  }

  // Pontos de atributo extras nos marcos de nível por classe
  int _scalingBonusPoints(String? classType, int marco) {
    // Tecelão evolui mais lento — menos bônus
    if (classType == 'shadowWeaver') return 1;
    // Marcos maiores dão mais bônus
    if (marco >= 50) return 3;
    if (marco >= 25) return 2;
    return 1;
  }

  // Pontos de atributo extras nos marcos de nível por classe


  /// Sprint 3.4 Etapa A hotfix — setter direto pra `xpToNext`. Usado
  /// pelo backfill defensivo `applyXpToNextBackfill` (em `app_listeners.
  /// dart`) que corrige players legacy criados com `xpToNext=100` (DB
  /// default antigo) pra `200` (`XpCalculator.xpToNextLevel(1)`).
  /// Idempotente — caller checa condição antes de chamar.
  Future<void> setXpToNext(int id, int value) async {
    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(xpToNext: Value(value)));
  }

  /// Sprint 3.1 Bloco 13b — marca timestamp do último daily reset.
  /// `DailyResetService` chama dentro da transação de reset.
  Future<void> markDailyReset(int id, DateTime at) async {
    await (update(playersTable)..where((t) => t.id.equals(id))).write(
        PlayersTableCompanion(lastDailyReset: Value(at.millisecondsSinceEpoch)));
  }

  /// Sprint 3.1 Bloco 13b — análogo pro weekly.
  Future<void> markWeeklyReset(int id, DateTime at) async {
    await (update(playersTable)..where((t) => t.id.equals(id))).write(
        PlayersTableCompanion(lastWeeklyReset: Value(at.millisecondsSinceEpoch)));
  }

  /// Sprint 3.2 Etapa 1.0 — persiste peso/altura coletados na Calibração do
  /// Sistema (onboarding) ou via edição inline na tela /perfil.
  /// Ranges validados pelo BodyMetricsService antes de chegar aqui:
  /// 20-300kg, 100-250cm.
  Future<void> updateBodyMetrics(int id, {int? weightKg, int? heightCm}) async {
    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(
      weightKg: weightKg == null ? const Value.absent() : Value(weightKg),
      heightCm: heightCm == null ? const Value.absent() : Value(heightCm),
    ));
  }

  /// Sprint 3.2 Etapa 1.2 — marca timestamp do último rollover de
  /// missões diárias. Independente de `lastDailyReset`.
  Future<void> markDailyMissionRollover(int id, DateTime at) async {
    await (update(playersTable)..where((t) => t.id.equals(id))).write(
        PlayersTableCompanion(
            lastDailyMissionRollover: Value(at.millisecondsSinceEpoch)));
  }

  /// Incrementa streak de missões diárias 100%. Chamado pelo rollover
  /// quando todas as 3 missões do dia anterior fecharam `completed`.
  Future<void> incrementDailyMissionsStreak(int id) async {
    final p = await findById(id);
    if (p == null) return;
    await (update(playersTable)..where((t) => t.id.equals(id))).write(
        PlayersTableCompanion(
            dailyMissionsStreak: Value(p.dailyMissionsStreak + 1)));
  }

  /// Reseta streak de missões diárias a 0. Qualquer falha ou parcial
  /// quebra a sequência.
  Future<void> resetDailyMissionsStreak(int id) async {
    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(const PlayersTableCompanion(dailyMissionsStreak: Value(0)));
  }

  /// Sprint 3.3 Etapa 2.1c-β — toggle de modo automático.
  ///
  /// Persiste preferência do jogador. Quando `true`,
  /// `DailyMissionRolloverService` auto-completa missões com 100% em
  /// todas as sub-tarefas no rollover diário sem exigir clique manual.
  /// Caller deve atualizar `currentPlayerProvider` após chamar este
  /// método pra UI reagir imediatamente.
  Future<void> setAutoConfirmEnabled(int id, bool value) async {
    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(autoConfirmEnabled: Value(value)));
  }

  /// Sprint 3.3 Etapa 2.1c-γ — persiste CSV de paths visitados.
  ///
  /// Chamado pelo `PlayerScreensVisitedService.recordVisit` dentro de
  /// uma transação atômica (read-modify-write em CSV). Caller controla
  /// formato; este método só persiste o valor recebido.
  Future<void> setScreensVisitedKeys(int id, String csv) async {
    await (update(playersTable)..where((t) => t.id.equals(id)))
        .write(PlayersTableCompanion(screensVisitedKeys: Value(csv)));
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

  /// Distribui 1 ponto de atributo. Retorna `null` em sucesso ou string
  /// de erro em falha.
  ///
  /// **OBRIGAÇÃO DO CALLER (Sprint 3.3 Etapa 2.1c-α):** após receber
  /// resultado `null` (sucesso), publicar `AttributePointSpent` no
  /// AppEventBus. Veja [distributePointWithEvent] que retorna o evento
  /// pronto pra publicar — preferir esse helper em código novo. Esta
  /// função é mantida pra callers legacy.
  ///
  /// PlayerDao não conhece AppEventBus por contrato (ADR 0016 — camada
  /// data desacoplada de events). Mesmo padrão do `addXp` retornando
  /// `LevelUp?`.
  Future<String?> distributePoint(int id, String attribute) async {
    final result = await distributePointWithEvent(id, attribute);
    return result.error;
  }

  /// Sprint 3.3 Etapa 2.1c-α — variante que retorna o `AttributePointSpent`
  /// pré-construído pra caller publicar. Em sucesso, `error == null` e
  /// `event != null`. Em falha, vice-versa.
  ///
  /// Incrementa `total_attribute_points_spent` atomicamente junto com
  /// o write — alimenta o trigger `event_attribute_point_spent`.
  Future<DistributePointResult> distributePointWithEvent(
      int id, String attribute) async {
    final player = await findById(id);
    if (player == null) {
      return const DistributePointResult.error('Jogador não encontrado');
    }
    if (player.attributePoints <= 0) {
      return const DistributePointResult.error('Sem pontos disponíveis');
    }

    final pts = player.attributePoints - 1;
    final newTotalSpent = player.totalAttributePointsSpent + 1;
    PlayersTableCompanion data;
    int newValue;

    switch (attribute) {
      case 'strength':
        newValue = player.strength + 1;
        data = PlayersTableCompanion(
            strength: Value(newValue),
            attributePoints: Value(pts),
            totalAttributePointsSpent: Value(newTotalSpent));
        break;
      case 'dexterity':
        newValue = player.dexterity + 1;
        data = PlayersTableCompanion(
            dexterity: Value(newValue),
            attributePoints: Value(pts),
            totalAttributePointsSpent: Value(newTotalSpent));
        break;
      case 'intelligence':
        newValue = player.intelligence + 1;
        data = PlayersTableCompanion(
            intelligence: Value(newValue),
            attributePoints: Value(pts),
            totalAttributePointsSpent: Value(newTotalSpent));
        break;
      case 'constitution':
        final newCon = player.constitution + 1;
        newValue = newCon;
        final newMaxHp = XpCalculator.calcMaxHp(newCon, player.level);
        final newMaxMp = XpCalculator.calcMaxMp(player.spirit, newCon, player.level);
        data = PlayersTableCompanion(
            constitution: Value(newCon),
            maxHp: Value(newMaxHp),
            maxMp: Value(newMaxMp),
            hp: Value(newMaxHp),
            attributePoints: Value(pts),
            totalAttributePointsSpent: Value(newTotalSpent));
        break;
      case 'spirit':
        final newSpi = player.spirit + 1;
        newValue = newSpi;
        final newMaxMp = XpCalculator.calcMaxMp(newSpi, player.constitution, player.level);
        data = PlayersTableCompanion(
            spirit: Value(newSpi),
            maxMp: Value(newMaxMp),
            attributePoints: Value(pts),
            totalAttributePointsSpent: Value(newTotalSpent));
        break;
      case 'charisma':
        newValue = player.charisma + 1;
        data = PlayersTableCompanion(
            charisma: Value(newValue),
            attributePoints: Value(pts),
            totalAttributePointsSpent: Value(newTotalSpent));
        break;
      default:
        return const DistributePointResult.error('Atributo inválido');
    }

    await (db.update(db.playersTable)..where((t) => t.id.equals(id))).write(data);
    return DistributePointResult.ok(AttributePointSpent(
      playerId: id,
      attributeKey: attribute,
      newValue: newValue,
    ));
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

/// Sprint 3.3 Etapa 2.1c-α — resultado imutável de
/// [PlayerDao.distributePointWithEvent]. Em sucesso, [event] é non-null
/// e [error] é null. Em falha, vice-versa.
class DistributePointResult {
  final AttributePointSpent? event;
  final String? error;

  const DistributePointResult.ok(AttributePointSpent this.event)
      : error = null;
  const DistributePointResult.error(String this.error) : event = null;

  bool get isOk => event != null;
}
