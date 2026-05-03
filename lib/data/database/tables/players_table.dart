import 'package:drift/drift.dart';

class PlayersTable extends Table {
  @override
  String get tableName => 'players';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get shadowName => text().withDefault(const Constant('Sombra'))();

  // Progressão
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get xpToNext => integer().withDefault(const Constant(100))();
  IntColumn get attributePoints => integer().withDefault(const Constant(0))();

  // Vitalismo (progressão — só usado por classes vitalistas)
  IntColumn get vitalismLevel => integer().withDefault(const Constant(0))();
  IntColumn get vitalismXp => integer().withDefault(const Constant(0))();

  // Atributos base
  IntColumn get strength => integer().withDefault(const Constant(1))();
  IntColumn get dexterity => integer().withDefault(const Constant(1))();
  IntColumn get intelligence => integer().withDefault(const Constant(1))();
  IntColumn get constitution => integer().withDefault(const Constant(1))();
  IntColumn get spirit => integer().withDefault(const Constant(1))();
  IntColumn get charisma => integer().withDefault(const Constant(1))();

  // Status derivados (calculados)
  IntColumn get hp => integer().withDefault(const Constant(100))();
  IntColumn get maxHp => integer().withDefault(const Constant(100))();
  IntColumn get mp => integer().withDefault(const Constant(90))();
  IntColumn get maxMp => integer().withDefault(const Constant(90))();
  IntColumn get currentVitalism => integer().withDefault(const Constant(0))();

  // Economia
  IntColumn get gold => integer().withDefault(const Constant(0))();
  IntColumn get gems => integer().withDefault(const Constant(0))();

  // Progressão narrativa
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  IntColumn get caelumDay => integer().withDefault(const Constant(1))();
  TextColumn get shadowState => text().withDefault(const Constant('stable'))();
  IntColumn get shadowCorruption => integer().withDefault(const Constant(0))();

  // Classe e facção
  TextColumn get classType => text().nullable()();
  TextColumn get factionType => text().nullable()();

  // Rank da Guilda de Aventureiros (e/d/c/b/a/s)
  TextColumn get guildRank => text().withDefault(const Constant('none'))();

  // Contador de missões concluídas (ADR candidata 0012 — Sprint 2.2).
  // Incrementado em class_quest / faction_quest / guild_ascension ao marcar
  // completed=true. Usado como gate de admissão da Guilda (>=25 missões).
  IntColumn get totalQuestsCompleted =>
      integer().withDefault(const Constant(0))();

  // Preferências
  TextColumn get narrativeMode => text().withDefault(const Constant('longa'))();
  BoolColumn get onboardingDone => boolean().withDefault(const Constant(false))();
  TextColumn get playStyle => text().withDefault(const Constant('none'))(); // none/solo/duo/team

  // Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLoginAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastStreakDate => dateTime().nullable()();

  // Sprint 3.1 Bloco 13b — boot-check do DailyResetService/WeeklyResetService
  // (ms epoch). Null = nunca resetou. Atualiza no fim da transação de reset
  // via PlayerDao.markDailyReset/markWeeklyReset.
  IntColumn get lastDailyReset => integer().nullable()();
  IntColumn get lastWeeklyReset => integer().nullable()();

  // Sprint 3.2 Etapa 1.0 — dados físicos coletados na "Calibração do Sistema"
  // (pós-cerimônia, pré-missões iniciais). Editáveis depois em /perfil.
  // Null = jogador pré-3.2 que não passou pelo upgrade ainda.
  IntColumn get weightKg => integer().nullable()();
  IntColumn get heightCm => integer().nullable()();

  // Sprint 3.2 Etapa 1.2 — boot-check do DailyMissionRolloverService
  // (ms epoch). Independente de `lastDailyReset` (DailyResetService cuida
  // do fluxo legacy de MissionProgress). Null = jogador novo, primeira
  // chamada do rollover roda incondicional.
  IntColumn get lastDailyMissionRollover => integer().nullable()();

  // Streak SOMENTE de missões diárias (3/3 100%) — separada de
  // `streakDays` (login streak). Resetada a 0 se qualquer dia tem
  // missão failed/partial.
  IntColumn get dailyMissionsStreak =>
      integer().withDefault(const Constant(0))();

  // Sprint 3.3 Etapa 2.1c-α — contadores all-time pra triggers de
  // conquista. Não-daily; populados por:
  //   - total_gems_spent: PlayerCurrencyStatsService (listener GemsSpent)
  //   - peak_level: PlayerDao.addXp quando newLevel > peak_level.
  //                 Migration 28→29 backfilla peak_level = level.
  //   - total_attribute_points_spent: PlayerDao.distributePoint
  IntColumn get totalGemsSpent =>
      integer().withDefault(const Constant(0))();
  IntColumn get peakLevel =>
      integer().withDefault(const Constant(1))();
  IntColumn get totalAttributePointsSpent =>
      integer().withDefault(const Constant(0))();

  // Sprint 3.3 Etapa 2.1c-β — modo automático de daily missions.
  // Toggle exposto em /perfil. Quando true, missões com 100% em todas
  // as sub-tarefas são auto-completed no rollover diário (madrugada),
  // sem exigir clique manual no ✓. Default false (manual = comportamento
  // legacy preservado pra players existentes).
  BoolColumn get autoConfirmEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Sprint 3.3 Etapa 2.1c-γ — CSV de paths visitados (`/perfil,/quests,
  /// /shops`). Single writer: `PlayerScreensVisitedService`. Read via
  /// queries pra trigger `event_screen_visited`.
  ///
  /// Decisão arquitetural (CSV em TEXT vs bitmask INT):
  /// - Set de telas é pequeno (~30 paths)
  /// - Operação dominante é `contains` (exact match) e count distinto
  /// - CSV é self-describing — bitmask exigiria mapeamento estático
  ///   key→bit que rasga ao adicionar tela nova
  /// - Paths excluídos do tracking: `/`, `/login`, `/register` (splash
  ///   e auth boilerplate não são "visitas conscientes")
  ///
  /// Default `''` (vazio). Schema 32 adiciona via `m.addColumn`.
  TextColumn get screensVisitedKeys =>
      text().withDefault(const Constant(''))();

  /// Sprint 3.4 Etapa B (Sub-Etapa B.1) — contador all-time de ouro
  /// recebido como reward de quest (qualquer modalidade: daily/class/
  /// faction/individual/admission). NÃO inclui gold de outras fontes
  /// (loot, gift, gold_admin, etc).
  ///
  /// Foundation pro sub-type `admission_gold_earned_via_quests_window`
  /// do `FactionAdmissionValidator`: validator captura snapshot deste
  /// contador no momento de unlock da missão de admissão e compara
  /// `current - baseline >= target`.
  ///
  /// Single writer: `QuestRewardStatsService` (listener de `RewardGranted`
  /// + `DailyMissionCompleted`). Schema 35 adiciona via `m.addColumn`.
  IntColumn get totalGoldEarnedViaQuests =>
      integer().withDefault(const Constant(0))();
}
