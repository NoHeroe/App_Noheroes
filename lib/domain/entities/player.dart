/// Modelo de jogador full-online (Época 2, S2 — ADR-0024).
///
/// Substitui o `PlayersTableData` (Drift) como o objeto em memória carregado
/// em `currentPlayerProvider`. Espelha a MESMA API de getters (camelCase) pra
/// que o código de UI siga lendo `player.maxHp`, `player.gold`, etc. sem
/// mudança — a ÚNICA diferença é que [id] agora é `String` (uuid do Supabase
/// Auth, = `auth.users.id`), não mais `int`.
///
/// `fromMap` lê as chaves snake_case da row do Postgres (REST/PostgREST do
/// Supabase). `toMap` serializa de volta pra updates parciais.
class Player {
  final String id;
  final String? email;
  final String shadowName;

  // Progressão
  final int level;
  final int xp;
  final int xpToNext;
  final int attributePoints;

  // Vitalismo
  final int vitalismLevel;
  final int vitalismXp;

  // Atributos base
  final int strength;
  final int dexterity;
  final int intelligence;
  final int constitution;
  final int spirit;
  final int charisma;

  // Status derivados
  final int hp;
  final int maxHp;
  final int mp;
  final int maxMp;
  final int currentVitalism;

  // Economia
  final int gold;
  final int gems;
  final int insignias;

  // Narrativa
  final int streakDays;
  final int caelumDay;
  final String shadowState;
  final int shadowCorruption;

  // Classe / facção / rank
  final String? classType;
  final String? factionType;
  final String guildRank;
  final int totalQuestsCompleted;

  // Preferências
  final String narrativeMode;
  final bool onboardingDone;
  final String playStyle;

  // Timestamps
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime? lastStreakDate;

  // Boot-checks de reset (ms epoch)
  final int? lastDailyReset;
  final int? lastWeeklyReset;
  final int? lastDailyMissionRollover;

  // Dados físicos
  final int? weightKg;
  final int? heightCm;

  // Streaks / contadores
  final int dailyMissionsStreak;
  final int totalGemsSpent;
  final int peakLevel;
  final int totalAttributePointsSpent;
  final bool autoConfirmEnabled;
  final String screensVisitedKeys;
  final int totalGoldEarnedViaQuests;
  final int totalGoldEarnedLifetime;

  const Player({
    required this.id,
    this.email,
    this.shadowName = 'Sombra',
    this.level = 1,
    this.xp = 0,
    this.xpToNext = 100,
    this.attributePoints = 0,
    this.vitalismLevel = 0,
    this.vitalismXp = 0,
    this.strength = 1,
    this.dexterity = 1,
    this.intelligence = 1,
    this.constitution = 1,
    this.spirit = 1,
    this.charisma = 1,
    this.hp = 100,
    this.maxHp = 100,
    this.mp = 90,
    this.maxMp = 90,
    this.currentVitalism = 0,
    this.gold = 0,
    this.gems = 0,
    this.insignias = 0,
    this.streakDays = 0,
    this.caelumDay = 1,
    this.shadowState = 'stable',
    this.shadowCorruption = 0,
    this.classType,
    this.factionType,
    this.guildRank = 'none',
    this.totalQuestsCompleted = 0,
    this.narrativeMode = 'longa',
    this.onboardingDone = false,
    this.playStyle = 'none',
    required this.createdAt,
    required this.lastLoginAt,
    this.lastStreakDate,
    this.lastDailyReset,
    this.lastWeeklyReset,
    this.lastDailyMissionRollover,
    this.weightKg,
    this.heightCm,
    this.dailyMissionsStreak = 0,
    this.totalGemsSpent = 0,
    this.peakLevel = 1,
    this.totalAttributePointsSpent = 0,
    this.autoConfirmEnabled = false,
    this.screensVisitedKeys = '',
    this.totalGoldEarnedViaQuests = 0,
    this.totalGoldEarnedLifetime = 0,
  });

  static int _int(Object? v, [int fallback = 0]) =>
      v == null ? fallback : (v as num).toInt();

  static DateTime _dt(Object? v) =>
      v == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(v as String);

  /// Constrói a partir de uma row do Postgres (chaves snake_case).
  factory Player.fromMap(Map<String, dynamic> m) => Player(
        id: m['id'] as String,
        email: m['email'] as String?,
        shadowName: (m['shadow_name'] as String?) ?? 'Sombra',
        level: _int(m['level'], 1),
        xp: _int(m['xp']),
        xpToNext: _int(m['xp_to_next'], 100),
        attributePoints: _int(m['attribute_points']),
        vitalismLevel: _int(m['vitalism_level']),
        vitalismXp: _int(m['vitalism_xp']),
        strength: _int(m['strength'], 1),
        dexterity: _int(m['dexterity'], 1),
        intelligence: _int(m['intelligence'], 1),
        constitution: _int(m['constitution'], 1),
        spirit: _int(m['spirit'], 1),
        charisma: _int(m['charisma'], 1),
        hp: _int(m['hp'], 100),
        maxHp: _int(m['max_hp'], 100),
        mp: _int(m['mp'], 90),
        maxMp: _int(m['max_mp'], 90),
        currentVitalism: _int(m['current_vitalism']),
        gold: _int(m['gold']),
        gems: _int(m['gems']),
        insignias: _int(m['insignias']),
        streakDays: _int(m['streak_days']),
        caelumDay: _int(m['caelum_day'], 1),
        shadowState: (m['shadow_state'] as String?) ?? 'stable',
        shadowCorruption: _int(m['shadow_corruption']),
        classType: m['class_type'] as String?,
        factionType: m['faction_type'] as String?,
        guildRank: (m['guild_rank'] as String?) ?? 'none',
        totalQuestsCompleted: _int(m['total_quests_completed']),
        narrativeMode: (m['narrative_mode'] as String?) ?? 'longa',
        onboardingDone: (m['onboarding_done'] as bool?) ?? false,
        playStyle: (m['play_style'] as String?) ?? 'none',
        createdAt: _dt(m['created_at']),
        lastLoginAt: _dt(m['last_login_at']),
        lastStreakDate:
            m['last_streak_date'] == null ? null : DateTime.parse(m['last_streak_date'] as String),
        lastDailyReset: (m['last_daily_reset'] as num?)?.toInt(),
        lastWeeklyReset: (m['last_weekly_reset'] as num?)?.toInt(),
        lastDailyMissionRollover: (m['last_daily_mission_rollover'] as num?)?.toInt(),
        weightKg: (m['weight_kg'] as num?)?.toInt(),
        heightCm: (m['height_cm'] as num?)?.toInt(),
        dailyMissionsStreak: _int(m['daily_missions_streak']),
        totalGemsSpent: _int(m['total_gems_spent']),
        peakLevel: _int(m['peak_level'], 1),
        totalAttributePointsSpent: _int(m['total_attribute_points_spent']),
        autoConfirmEnabled: (m['auto_confirm_enabled'] as bool?) ?? false,
        screensVisitedKeys: (m['screens_visited_keys'] as String?) ?? '',
        totalGoldEarnedViaQuests: _int(m['total_gold_earned_via_quests']),
        totalGoldEarnedLifetime: _int(m['total_gold_earned_lifetime']),
      );

  /// Serializa pra update parcial (snake_case). Inclui só campos mutáveis em
  /// gameplay; id/created_at não são reescritos.
  Map<String, dynamic> toMap() => {
        'email': email,
        'shadow_name': shadowName,
        'level': level,
        'xp': xp,
        'xp_to_next': xpToNext,
        'attribute_points': attributePoints,
        'vitalism_level': vitalismLevel,
        'vitalism_xp': vitalismXp,
        'strength': strength,
        'dexterity': dexterity,
        'intelligence': intelligence,
        'constitution': constitution,
        'spirit': spirit,
        'charisma': charisma,
        'hp': hp,
        'max_hp': maxHp,
        'mp': mp,
        'max_mp': maxMp,
        'current_vitalism': currentVitalism,
        'gold': gold,
        'gems': gems,
        'insignias': insignias,
        'streak_days': streakDays,
        'caelum_day': caelumDay,
        'shadow_state': shadowState,
        'shadow_corruption': shadowCorruption,
        'class_type': classType,
        'faction_type': factionType,
        'guild_rank': guildRank,
        'total_quests_completed': totalQuestsCompleted,
        'narrative_mode': narrativeMode,
        'onboarding_done': onboardingDone,
        'play_style': playStyle,
        'last_login_at': lastLoginAt.toIso8601String(),
        'last_streak_date': lastStreakDate?.toIso8601String(),
        'last_daily_reset': lastDailyReset,
        'last_weekly_reset': lastWeeklyReset,
        'last_daily_mission_rollover': lastDailyMissionRollover,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'daily_missions_streak': dailyMissionsStreak,
        'total_gems_spent': totalGemsSpent,
        'peak_level': peakLevel,
        'total_attribute_points_spent': totalAttributePointsSpent,
        'auto_confirm_enabled': autoConfirmEnabled,
        'screens_visited_keys': screensVisitedKeys,
        'total_gold_earned_via_quests': totalGoldEarnedViaQuests,
        'total_gold_earned_lifetime': totalGoldEarnedLifetime,
      };

  Player copyWith({
    String? email,
    String? shadowName,
    int? level,
    int? xp,
    int? xpToNext,
    int? attributePoints,
    int? vitalismLevel,
    int? vitalismXp,
    int? strength,
    int? dexterity,
    int? intelligence,
    int? constitution,
    int? spirit,
    int? charisma,
    int? hp,
    int? maxHp,
    int? mp,
    int? maxMp,
    int? currentVitalism,
    int? gold,
    int? gems,
    int? insignias,
    int? streakDays,
    int? caelumDay,
    String? shadowState,
    int? shadowCorruption,
    String? classType,
    String? factionType,
    String? guildRank,
    int? totalQuestsCompleted,
    String? narrativeMode,
    bool? onboardingDone,
    String? playStyle,
    DateTime? lastLoginAt,
    DateTime? lastStreakDate,
    int? lastDailyReset,
    int? lastWeeklyReset,
    int? lastDailyMissionRollover,
    int? weightKg,
    int? heightCm,
    int? dailyMissionsStreak,
    int? totalGemsSpent,
    int? peakLevel,
    int? totalAttributePointsSpent,
    bool? autoConfirmEnabled,
    String? screensVisitedKeys,
    int? totalGoldEarnedViaQuests,
    int? totalGoldEarnedLifetime,
  }) =>
      Player(
        id: id,
        email: email ?? this.email,
        shadowName: shadowName ?? this.shadowName,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        xpToNext: xpToNext ?? this.xpToNext,
        attributePoints: attributePoints ?? this.attributePoints,
        vitalismLevel: vitalismLevel ?? this.vitalismLevel,
        vitalismXp: vitalismXp ?? this.vitalismXp,
        strength: strength ?? this.strength,
        dexterity: dexterity ?? this.dexterity,
        intelligence: intelligence ?? this.intelligence,
        constitution: constitution ?? this.constitution,
        spirit: spirit ?? this.spirit,
        charisma: charisma ?? this.charisma,
        hp: hp ?? this.hp,
        maxHp: maxHp ?? this.maxHp,
        mp: mp ?? this.mp,
        maxMp: maxMp ?? this.maxMp,
        currentVitalism: currentVitalism ?? this.currentVitalism,
        gold: gold ?? this.gold,
        gems: gems ?? this.gems,
        insignias: insignias ?? this.insignias,
        streakDays: streakDays ?? this.streakDays,
        caelumDay: caelumDay ?? this.caelumDay,
        shadowState: shadowState ?? this.shadowState,
        shadowCorruption: shadowCorruption ?? this.shadowCorruption,
        classType: classType ?? this.classType,
        factionType: factionType ?? this.factionType,
        guildRank: guildRank ?? this.guildRank,
        totalQuestsCompleted: totalQuestsCompleted ?? this.totalQuestsCompleted,
        narrativeMode: narrativeMode ?? this.narrativeMode,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        playStyle: playStyle ?? this.playStyle,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        lastStreakDate: lastStreakDate ?? this.lastStreakDate,
        lastDailyReset: lastDailyReset ?? this.lastDailyReset,
        lastWeeklyReset: lastWeeklyReset ?? this.lastWeeklyReset,
        lastDailyMissionRollover:
            lastDailyMissionRollover ?? this.lastDailyMissionRollover,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        dailyMissionsStreak: dailyMissionsStreak ?? this.dailyMissionsStreak,
        totalGemsSpent: totalGemsSpent ?? this.totalGemsSpent,
        peakLevel: peakLevel ?? this.peakLevel,
        totalAttributePointsSpent:
            totalAttributePointsSpent ?? this.totalAttributePointsSpent,
        autoConfirmEnabled: autoConfirmEnabled ?? this.autoConfirmEnabled,
        screensVisitedKeys: screensVisitedKeys ?? this.screensVisitedKeys,
        totalGoldEarnedViaQuests:
            totalGoldEarnedViaQuests ?? this.totalGoldEarnedViaQuests,
        totalGoldEarnedLifetime:
            totalGoldEarnedLifetime ?? this.totalGoldEarnedLifetime,
      );
}
