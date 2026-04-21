// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlayersTableTable extends PlayersTable
    with TableInfo<$PlayersTableTable, PlayersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _passwordHashMeta =
      const VerificationMeta('passwordHash');
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
      'password_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shadowNameMeta =
      const VerificationMeta('shadowName');
  @override
  late final GeneratedColumn<String> shadowName = GeneratedColumn<String>(
      'shadow_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Sombra'));
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
      'xp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _xpToNextMeta =
      const VerificationMeta('xpToNext');
  @override
  late final GeneratedColumn<int> xpToNext = GeneratedColumn<int>(
      'xp_to_next', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _attributePointsMeta =
      const VerificationMeta('attributePoints');
  @override
  late final GeneratedColumn<int> attributePoints = GeneratedColumn<int>(
      'attribute_points', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _vitalismLevelMeta =
      const VerificationMeta('vitalismLevel');
  @override
  late final GeneratedColumn<int> vitalismLevel = GeneratedColumn<int>(
      'vitalism_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _vitalismXpMeta =
      const VerificationMeta('vitalismXp');
  @override
  late final GeneratedColumn<int> vitalismXp = GeneratedColumn<int>(
      'vitalism_xp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _strengthMeta =
      const VerificationMeta('strength');
  @override
  late final GeneratedColumn<int> strength = GeneratedColumn<int>(
      'strength', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _dexterityMeta =
      const VerificationMeta('dexterity');
  @override
  late final GeneratedColumn<int> dexterity = GeneratedColumn<int>(
      'dexterity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _intelligenceMeta =
      const VerificationMeta('intelligence');
  @override
  late final GeneratedColumn<int> intelligence = GeneratedColumn<int>(
      'intelligence', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _constitutionMeta =
      const VerificationMeta('constitution');
  @override
  late final GeneratedColumn<int> constitution = GeneratedColumn<int>(
      'constitution', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _spiritMeta = const VerificationMeta('spirit');
  @override
  late final GeneratedColumn<int> spirit = GeneratedColumn<int>(
      'spirit', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _charismaMeta =
      const VerificationMeta('charisma');
  @override
  late final GeneratedColumn<int> charisma = GeneratedColumn<int>(
      'charisma', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _hpMeta = const VerificationMeta('hp');
  @override
  late final GeneratedColumn<int> hp = GeneratedColumn<int>(
      'hp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _maxHpMeta = const VerificationMeta('maxHp');
  @override
  late final GeneratedColumn<int> maxHp = GeneratedColumn<int>(
      'max_hp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(100));
  static const VerificationMeta _mpMeta = const VerificationMeta('mp');
  @override
  late final GeneratedColumn<int> mp = GeneratedColumn<int>(
      'mp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(90));
  static const VerificationMeta _maxMpMeta = const VerificationMeta('maxMp');
  @override
  late final GeneratedColumn<int> maxMp = GeneratedColumn<int>(
      'max_mp', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(90));
  static const VerificationMeta _currentVitalismMeta =
      const VerificationMeta('currentVitalism');
  @override
  late final GeneratedColumn<int> currentVitalism = GeneratedColumn<int>(
      'current_vitalism', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _goldMeta = const VerificationMeta('gold');
  @override
  late final GeneratedColumn<int> gold = GeneratedColumn<int>(
      'gold', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _gemsMeta = const VerificationMeta('gems');
  @override
  late final GeneratedColumn<int> gems = GeneratedColumn<int>(
      'gems', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _streakDaysMeta =
      const VerificationMeta('streakDays');
  @override
  late final GeneratedColumn<int> streakDays = GeneratedColumn<int>(
      'streak_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _caelumDayMeta =
      const VerificationMeta('caelumDay');
  @override
  late final GeneratedColumn<int> caelumDay = GeneratedColumn<int>(
      'caelum_day', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _shadowStateMeta =
      const VerificationMeta('shadowState');
  @override
  late final GeneratedColumn<String> shadowState = GeneratedColumn<String>(
      'shadow_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('stable'));
  static const VerificationMeta _shadowCorruptionMeta =
      const VerificationMeta('shadowCorruption');
  @override
  late final GeneratedColumn<int> shadowCorruption = GeneratedColumn<int>(
      'shadow_corruption', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _classTypeMeta =
      const VerificationMeta('classType');
  @override
  late final GeneratedColumn<String> classType = GeneratedColumn<String>(
      'class_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _factionTypeMeta =
      const VerificationMeta('factionType');
  @override
  late final GeneratedColumn<String> factionType = GeneratedColumn<String>(
      'faction_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _guildRankMeta =
      const VerificationMeta('guildRank');
  @override
  late final GeneratedColumn<String> guildRank = GeneratedColumn<String>(
      'guild_rank', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _totalQuestsCompletedMeta =
      const VerificationMeta('totalQuestsCompleted');
  @override
  late final GeneratedColumn<int> totalQuestsCompleted = GeneratedColumn<int>(
      'total_quests_completed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _narrativeModeMeta =
      const VerificationMeta('narrativeMode');
  @override
  late final GeneratedColumn<String> narrativeMode = GeneratedColumn<String>(
      'narrative_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('longa'));
  static const VerificationMeta _onboardingDoneMeta =
      const VerificationMeta('onboardingDone');
  @override
  late final GeneratedColumn<bool> onboardingDone = GeneratedColumn<bool>(
      'onboarding_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("onboarding_done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _playStyleMeta =
      const VerificationMeta('playStyle');
  @override
  late final GeneratedColumn<String> playStyle = GeneratedColumn<String>(
      'play_style', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastLoginAtMeta =
      const VerificationMeta('lastLoginAt');
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
      'last_login_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastStreakDateMeta =
      const VerificationMeta('lastStreakDate');
  @override
  late final GeneratedColumn<DateTime> lastStreakDate =
      GeneratedColumn<DateTime>('last_streak_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        email,
        passwordHash,
        shadowName,
        level,
        xp,
        xpToNext,
        attributePoints,
        vitalismLevel,
        vitalismXp,
        strength,
        dexterity,
        intelligence,
        constitution,
        spirit,
        charisma,
        hp,
        maxHp,
        mp,
        maxMp,
        currentVitalism,
        gold,
        gems,
        streakDays,
        caelumDay,
        shadowState,
        shadowCorruption,
        classType,
        factionType,
        guildRank,
        totalQuestsCompleted,
        narrativeMode,
        onboardingDone,
        playStyle,
        createdAt,
        lastLoginAt,
        lastStreakDate
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(Insertable<PlayersTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
          _passwordHashMeta,
          passwordHash.isAcceptableOrUnknown(
              data['password_hash']!, _passwordHashMeta));
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('shadow_name')) {
      context.handle(
          _shadowNameMeta,
          shadowName.isAcceptableOrUnknown(
              data['shadow_name']!, _shadowNameMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    if (data.containsKey('xp_to_next')) {
      context.handle(_xpToNextMeta,
          xpToNext.isAcceptableOrUnknown(data['xp_to_next']!, _xpToNextMeta));
    }
    if (data.containsKey('attribute_points')) {
      context.handle(
          _attributePointsMeta,
          attributePoints.isAcceptableOrUnknown(
              data['attribute_points']!, _attributePointsMeta));
    }
    if (data.containsKey('vitalism_level')) {
      context.handle(
          _vitalismLevelMeta,
          vitalismLevel.isAcceptableOrUnknown(
              data['vitalism_level']!, _vitalismLevelMeta));
    }
    if (data.containsKey('vitalism_xp')) {
      context.handle(
          _vitalismXpMeta,
          vitalismXp.isAcceptableOrUnknown(
              data['vitalism_xp']!, _vitalismXpMeta));
    }
    if (data.containsKey('strength')) {
      context.handle(_strengthMeta,
          strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta));
    }
    if (data.containsKey('dexterity')) {
      context.handle(_dexterityMeta,
          dexterity.isAcceptableOrUnknown(data['dexterity']!, _dexterityMeta));
    }
    if (data.containsKey('intelligence')) {
      context.handle(
          _intelligenceMeta,
          intelligence.isAcceptableOrUnknown(
              data['intelligence']!, _intelligenceMeta));
    }
    if (data.containsKey('constitution')) {
      context.handle(
          _constitutionMeta,
          constitution.isAcceptableOrUnknown(
              data['constitution']!, _constitutionMeta));
    }
    if (data.containsKey('spirit')) {
      context.handle(_spiritMeta,
          spirit.isAcceptableOrUnknown(data['spirit']!, _spiritMeta));
    }
    if (data.containsKey('charisma')) {
      context.handle(_charismaMeta,
          charisma.isAcceptableOrUnknown(data['charisma']!, _charismaMeta));
    }
    if (data.containsKey('hp')) {
      context.handle(_hpMeta, hp.isAcceptableOrUnknown(data['hp']!, _hpMeta));
    }
    if (data.containsKey('max_hp')) {
      context.handle(
          _maxHpMeta, maxHp.isAcceptableOrUnknown(data['max_hp']!, _maxHpMeta));
    }
    if (data.containsKey('mp')) {
      context.handle(_mpMeta, mp.isAcceptableOrUnknown(data['mp']!, _mpMeta));
    }
    if (data.containsKey('max_mp')) {
      context.handle(
          _maxMpMeta, maxMp.isAcceptableOrUnknown(data['max_mp']!, _maxMpMeta));
    }
    if (data.containsKey('current_vitalism')) {
      context.handle(
          _currentVitalismMeta,
          currentVitalism.isAcceptableOrUnknown(
              data['current_vitalism']!, _currentVitalismMeta));
    }
    if (data.containsKey('gold')) {
      context.handle(
          _goldMeta, gold.isAcceptableOrUnknown(data['gold']!, _goldMeta));
    }
    if (data.containsKey('gems')) {
      context.handle(
          _gemsMeta, gems.isAcceptableOrUnknown(data['gems']!, _gemsMeta));
    }
    if (data.containsKey('streak_days')) {
      context.handle(
          _streakDaysMeta,
          streakDays.isAcceptableOrUnknown(
              data['streak_days']!, _streakDaysMeta));
    }
    if (data.containsKey('caelum_day')) {
      context.handle(_caelumDayMeta,
          caelumDay.isAcceptableOrUnknown(data['caelum_day']!, _caelumDayMeta));
    }
    if (data.containsKey('shadow_state')) {
      context.handle(
          _shadowStateMeta,
          shadowState.isAcceptableOrUnknown(
              data['shadow_state']!, _shadowStateMeta));
    }
    if (data.containsKey('shadow_corruption')) {
      context.handle(
          _shadowCorruptionMeta,
          shadowCorruption.isAcceptableOrUnknown(
              data['shadow_corruption']!, _shadowCorruptionMeta));
    }
    if (data.containsKey('class_type')) {
      context.handle(_classTypeMeta,
          classType.isAcceptableOrUnknown(data['class_type']!, _classTypeMeta));
    }
    if (data.containsKey('faction_type')) {
      context.handle(
          _factionTypeMeta,
          factionType.isAcceptableOrUnknown(
              data['faction_type']!, _factionTypeMeta));
    }
    if (data.containsKey('guild_rank')) {
      context.handle(_guildRankMeta,
          guildRank.isAcceptableOrUnknown(data['guild_rank']!, _guildRankMeta));
    }
    if (data.containsKey('total_quests_completed')) {
      context.handle(
          _totalQuestsCompletedMeta,
          totalQuestsCompleted.isAcceptableOrUnknown(
              data['total_quests_completed']!, _totalQuestsCompletedMeta));
    }
    if (data.containsKey('narrative_mode')) {
      context.handle(
          _narrativeModeMeta,
          narrativeMode.isAcceptableOrUnknown(
              data['narrative_mode']!, _narrativeModeMeta));
    }
    if (data.containsKey('onboarding_done')) {
      context.handle(
          _onboardingDoneMeta,
          onboardingDone.isAcceptableOrUnknown(
              data['onboarding_done']!, _onboardingDoneMeta));
    }
    if (data.containsKey('play_style')) {
      context.handle(_playStyleMeta,
          playStyle.isAcceptableOrUnknown(data['play_style']!, _playStyleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
          _lastLoginAtMeta,
          lastLoginAt.isAcceptableOrUnknown(
              data['last_login_at']!, _lastLoginAtMeta));
    }
    if (data.containsKey('last_streak_date')) {
      context.handle(
          _lastStreakDateMeta,
          lastStreakDate.isAcceptableOrUnknown(
              data['last_streak_date']!, _lastStreakDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayersTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      passwordHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password_hash'])!,
      shadowName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shadow_name'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
      xp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp'])!,
      xpToNext: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_to_next'])!,
      attributePoints: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attribute_points'])!,
      vitalismLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}vitalism_level'])!,
      vitalismXp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}vitalism_xp'])!,
      strength: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}strength'])!,
      dexterity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dexterity'])!,
      intelligence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}intelligence'])!,
      constitution: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}constitution'])!,
      spirit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}spirit'])!,
      charisma: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}charisma'])!,
      hp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hp'])!,
      maxHp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_hp'])!,
      mp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mp'])!,
      maxMp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_mp'])!,
      currentVitalism: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_vitalism'])!,
      gold: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gold'])!,
      gems: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gems'])!,
      streakDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}streak_days'])!,
      caelumDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}caelum_day'])!,
      shadowState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shadow_state'])!,
      shadowCorruption: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shadow_corruption'])!,
      classType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_type']),
      factionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}faction_type']),
      guildRank: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}guild_rank'])!,
      totalQuestsCompleted: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_quests_completed'])!,
      narrativeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}narrative_mode'])!,
      onboardingDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}onboarding_done'])!,
      playStyle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}play_style'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastLoginAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_login_at'])!,
      lastStreakDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_streak_date']),
    );
  }

  @override
  $PlayersTableTable createAlias(String alias) {
    return $PlayersTableTable(attachedDatabase, alias);
  }
}

class PlayersTableData extends DataClass
    implements Insertable<PlayersTableData> {
  final int id;
  final String email;
  final String passwordHash;
  final String shadowName;
  final int level;
  final int xp;
  final int xpToNext;
  final int attributePoints;
  final int vitalismLevel;
  final int vitalismXp;
  final int strength;
  final int dexterity;
  final int intelligence;
  final int constitution;
  final int spirit;
  final int charisma;
  final int hp;
  final int maxHp;
  final int mp;
  final int maxMp;
  final int currentVitalism;
  final int gold;
  final int gems;
  final int streakDays;
  final int caelumDay;
  final String shadowState;
  final int shadowCorruption;
  final String? classType;
  final String? factionType;
  final String guildRank;
  final int totalQuestsCompleted;
  final String narrativeMode;
  final bool onboardingDone;
  final String playStyle;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime? lastStreakDate;
  const PlayersTableData(
      {required this.id,
      required this.email,
      required this.passwordHash,
      required this.shadowName,
      required this.level,
      required this.xp,
      required this.xpToNext,
      required this.attributePoints,
      required this.vitalismLevel,
      required this.vitalismXp,
      required this.strength,
      required this.dexterity,
      required this.intelligence,
      required this.constitution,
      required this.spirit,
      required this.charisma,
      required this.hp,
      required this.maxHp,
      required this.mp,
      required this.maxMp,
      required this.currentVitalism,
      required this.gold,
      required this.gems,
      required this.streakDays,
      required this.caelumDay,
      required this.shadowState,
      required this.shadowCorruption,
      this.classType,
      this.factionType,
      required this.guildRank,
      required this.totalQuestsCompleted,
      required this.narrativeMode,
      required this.onboardingDone,
      required this.playStyle,
      required this.createdAt,
      required this.lastLoginAt,
      this.lastStreakDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['shadow_name'] = Variable<String>(shadowName);
    map['level'] = Variable<int>(level);
    map['xp'] = Variable<int>(xp);
    map['xp_to_next'] = Variable<int>(xpToNext);
    map['attribute_points'] = Variable<int>(attributePoints);
    map['vitalism_level'] = Variable<int>(vitalismLevel);
    map['vitalism_xp'] = Variable<int>(vitalismXp);
    map['strength'] = Variable<int>(strength);
    map['dexterity'] = Variable<int>(dexterity);
    map['intelligence'] = Variable<int>(intelligence);
    map['constitution'] = Variable<int>(constitution);
    map['spirit'] = Variable<int>(spirit);
    map['charisma'] = Variable<int>(charisma);
    map['hp'] = Variable<int>(hp);
    map['max_hp'] = Variable<int>(maxHp);
    map['mp'] = Variable<int>(mp);
    map['max_mp'] = Variable<int>(maxMp);
    map['current_vitalism'] = Variable<int>(currentVitalism);
    map['gold'] = Variable<int>(gold);
    map['gems'] = Variable<int>(gems);
    map['streak_days'] = Variable<int>(streakDays);
    map['caelum_day'] = Variable<int>(caelumDay);
    map['shadow_state'] = Variable<String>(shadowState);
    map['shadow_corruption'] = Variable<int>(shadowCorruption);
    if (!nullToAbsent || classType != null) {
      map['class_type'] = Variable<String>(classType);
    }
    if (!nullToAbsent || factionType != null) {
      map['faction_type'] = Variable<String>(factionType);
    }
    map['guild_rank'] = Variable<String>(guildRank);
    map['total_quests_completed'] = Variable<int>(totalQuestsCompleted);
    map['narrative_mode'] = Variable<String>(narrativeMode);
    map['onboarding_done'] = Variable<bool>(onboardingDone);
    map['play_style'] = Variable<String>(playStyle);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    if (!nullToAbsent || lastStreakDate != null) {
      map['last_streak_date'] = Variable<DateTime>(lastStreakDate);
    }
    return map;
  }

  PlayersTableCompanion toCompanion(bool nullToAbsent) {
    return PlayersTableCompanion(
      id: Value(id),
      email: Value(email),
      passwordHash: Value(passwordHash),
      shadowName: Value(shadowName),
      level: Value(level),
      xp: Value(xp),
      xpToNext: Value(xpToNext),
      attributePoints: Value(attributePoints),
      vitalismLevel: Value(vitalismLevel),
      vitalismXp: Value(vitalismXp),
      strength: Value(strength),
      dexterity: Value(dexterity),
      intelligence: Value(intelligence),
      constitution: Value(constitution),
      spirit: Value(spirit),
      charisma: Value(charisma),
      hp: Value(hp),
      maxHp: Value(maxHp),
      mp: Value(mp),
      maxMp: Value(maxMp),
      currentVitalism: Value(currentVitalism),
      gold: Value(gold),
      gems: Value(gems),
      streakDays: Value(streakDays),
      caelumDay: Value(caelumDay),
      shadowState: Value(shadowState),
      shadowCorruption: Value(shadowCorruption),
      classType: classType == null && nullToAbsent
          ? const Value.absent()
          : Value(classType),
      factionType: factionType == null && nullToAbsent
          ? const Value.absent()
          : Value(factionType),
      guildRank: Value(guildRank),
      totalQuestsCompleted: Value(totalQuestsCompleted),
      narrativeMode: Value(narrativeMode),
      onboardingDone: Value(onboardingDone),
      playStyle: Value(playStyle),
      createdAt: Value(createdAt),
      lastLoginAt: Value(lastLoginAt),
      lastStreakDate: lastStreakDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastStreakDate),
    );
  }

  factory PlayersTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayersTableData(
      id: serializer.fromJson<int>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      shadowName: serializer.fromJson<String>(json['shadowName']),
      level: serializer.fromJson<int>(json['level']),
      xp: serializer.fromJson<int>(json['xp']),
      xpToNext: serializer.fromJson<int>(json['xpToNext']),
      attributePoints: serializer.fromJson<int>(json['attributePoints']),
      vitalismLevel: serializer.fromJson<int>(json['vitalismLevel']),
      vitalismXp: serializer.fromJson<int>(json['vitalismXp']),
      strength: serializer.fromJson<int>(json['strength']),
      dexterity: serializer.fromJson<int>(json['dexterity']),
      intelligence: serializer.fromJson<int>(json['intelligence']),
      constitution: serializer.fromJson<int>(json['constitution']),
      spirit: serializer.fromJson<int>(json['spirit']),
      charisma: serializer.fromJson<int>(json['charisma']),
      hp: serializer.fromJson<int>(json['hp']),
      maxHp: serializer.fromJson<int>(json['maxHp']),
      mp: serializer.fromJson<int>(json['mp']),
      maxMp: serializer.fromJson<int>(json['maxMp']),
      currentVitalism: serializer.fromJson<int>(json['currentVitalism']),
      gold: serializer.fromJson<int>(json['gold']),
      gems: serializer.fromJson<int>(json['gems']),
      streakDays: serializer.fromJson<int>(json['streakDays']),
      caelumDay: serializer.fromJson<int>(json['caelumDay']),
      shadowState: serializer.fromJson<String>(json['shadowState']),
      shadowCorruption: serializer.fromJson<int>(json['shadowCorruption']),
      classType: serializer.fromJson<String?>(json['classType']),
      factionType: serializer.fromJson<String?>(json['factionType']),
      guildRank: serializer.fromJson<String>(json['guildRank']),
      totalQuestsCompleted:
          serializer.fromJson<int>(json['totalQuestsCompleted']),
      narrativeMode: serializer.fromJson<String>(json['narrativeMode']),
      onboardingDone: serializer.fromJson<bool>(json['onboardingDone']),
      playStyle: serializer.fromJson<String>(json['playStyle']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastLoginAt: serializer.fromJson<DateTime>(json['lastLoginAt']),
      lastStreakDate: serializer.fromJson<DateTime?>(json['lastStreakDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'shadowName': serializer.toJson<String>(shadowName),
      'level': serializer.toJson<int>(level),
      'xp': serializer.toJson<int>(xp),
      'xpToNext': serializer.toJson<int>(xpToNext),
      'attributePoints': serializer.toJson<int>(attributePoints),
      'vitalismLevel': serializer.toJson<int>(vitalismLevel),
      'vitalismXp': serializer.toJson<int>(vitalismXp),
      'strength': serializer.toJson<int>(strength),
      'dexterity': serializer.toJson<int>(dexterity),
      'intelligence': serializer.toJson<int>(intelligence),
      'constitution': serializer.toJson<int>(constitution),
      'spirit': serializer.toJson<int>(spirit),
      'charisma': serializer.toJson<int>(charisma),
      'hp': serializer.toJson<int>(hp),
      'maxHp': serializer.toJson<int>(maxHp),
      'mp': serializer.toJson<int>(mp),
      'maxMp': serializer.toJson<int>(maxMp),
      'currentVitalism': serializer.toJson<int>(currentVitalism),
      'gold': serializer.toJson<int>(gold),
      'gems': serializer.toJson<int>(gems),
      'streakDays': serializer.toJson<int>(streakDays),
      'caelumDay': serializer.toJson<int>(caelumDay),
      'shadowState': serializer.toJson<String>(shadowState),
      'shadowCorruption': serializer.toJson<int>(shadowCorruption),
      'classType': serializer.toJson<String?>(classType),
      'factionType': serializer.toJson<String?>(factionType),
      'guildRank': serializer.toJson<String>(guildRank),
      'totalQuestsCompleted': serializer.toJson<int>(totalQuestsCompleted),
      'narrativeMode': serializer.toJson<String>(narrativeMode),
      'onboardingDone': serializer.toJson<bool>(onboardingDone),
      'playStyle': serializer.toJson<String>(playStyle),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastLoginAt': serializer.toJson<DateTime>(lastLoginAt),
      'lastStreakDate': serializer.toJson<DateTime?>(lastStreakDate),
    };
  }

  PlayersTableData copyWith(
          {int? id,
          String? email,
          String? passwordHash,
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
          int? streakDays,
          int? caelumDay,
          String? shadowState,
          int? shadowCorruption,
          Value<String?> classType = const Value.absent(),
          Value<String?> factionType = const Value.absent(),
          String? guildRank,
          int? totalQuestsCompleted,
          String? narrativeMode,
          bool? onboardingDone,
          String? playStyle,
          DateTime? createdAt,
          DateTime? lastLoginAt,
          Value<DateTime?> lastStreakDate = const Value.absent()}) =>
      PlayersTableData(
        id: id ?? this.id,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
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
        streakDays: streakDays ?? this.streakDays,
        caelumDay: caelumDay ?? this.caelumDay,
        shadowState: shadowState ?? this.shadowState,
        shadowCorruption: shadowCorruption ?? this.shadowCorruption,
        classType: classType.present ? classType.value : this.classType,
        factionType: factionType.present ? factionType.value : this.factionType,
        guildRank: guildRank ?? this.guildRank,
        totalQuestsCompleted: totalQuestsCompleted ?? this.totalQuestsCompleted,
        narrativeMode: narrativeMode ?? this.narrativeMode,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        playStyle: playStyle ?? this.playStyle,
        createdAt: createdAt ?? this.createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        lastStreakDate:
            lastStreakDate.present ? lastStreakDate.value : this.lastStreakDate,
      );
  PlayersTableData copyWithCompanion(PlayersTableCompanion data) {
    return PlayersTableData(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      shadowName:
          data.shadowName.present ? data.shadowName.value : this.shadowName,
      level: data.level.present ? data.level.value : this.level,
      xp: data.xp.present ? data.xp.value : this.xp,
      xpToNext: data.xpToNext.present ? data.xpToNext.value : this.xpToNext,
      attributePoints: data.attributePoints.present
          ? data.attributePoints.value
          : this.attributePoints,
      vitalismLevel: data.vitalismLevel.present
          ? data.vitalismLevel.value
          : this.vitalismLevel,
      vitalismXp:
          data.vitalismXp.present ? data.vitalismXp.value : this.vitalismXp,
      strength: data.strength.present ? data.strength.value : this.strength,
      dexterity: data.dexterity.present ? data.dexterity.value : this.dexterity,
      intelligence: data.intelligence.present
          ? data.intelligence.value
          : this.intelligence,
      constitution: data.constitution.present
          ? data.constitution.value
          : this.constitution,
      spirit: data.spirit.present ? data.spirit.value : this.spirit,
      charisma: data.charisma.present ? data.charisma.value : this.charisma,
      hp: data.hp.present ? data.hp.value : this.hp,
      maxHp: data.maxHp.present ? data.maxHp.value : this.maxHp,
      mp: data.mp.present ? data.mp.value : this.mp,
      maxMp: data.maxMp.present ? data.maxMp.value : this.maxMp,
      currentVitalism: data.currentVitalism.present
          ? data.currentVitalism.value
          : this.currentVitalism,
      gold: data.gold.present ? data.gold.value : this.gold,
      gems: data.gems.present ? data.gems.value : this.gems,
      streakDays:
          data.streakDays.present ? data.streakDays.value : this.streakDays,
      caelumDay: data.caelumDay.present ? data.caelumDay.value : this.caelumDay,
      shadowState:
          data.shadowState.present ? data.shadowState.value : this.shadowState,
      shadowCorruption: data.shadowCorruption.present
          ? data.shadowCorruption.value
          : this.shadowCorruption,
      classType: data.classType.present ? data.classType.value : this.classType,
      factionType:
          data.factionType.present ? data.factionType.value : this.factionType,
      guildRank: data.guildRank.present ? data.guildRank.value : this.guildRank,
      totalQuestsCompleted: data.totalQuestsCompleted.present
          ? data.totalQuestsCompleted.value
          : this.totalQuestsCompleted,
      narrativeMode: data.narrativeMode.present
          ? data.narrativeMode.value
          : this.narrativeMode,
      onboardingDone: data.onboardingDone.present
          ? data.onboardingDone.value
          : this.onboardingDone,
      playStyle: data.playStyle.present ? data.playStyle.value : this.playStyle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastLoginAt:
          data.lastLoginAt.present ? data.lastLoginAt.value : this.lastLoginAt,
      lastStreakDate: data.lastStreakDate.present
          ? data.lastStreakDate.value
          : this.lastStreakDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayersTableData(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('shadowName: $shadowName, ')
          ..write('level: $level, ')
          ..write('xp: $xp, ')
          ..write('xpToNext: $xpToNext, ')
          ..write('attributePoints: $attributePoints, ')
          ..write('vitalismLevel: $vitalismLevel, ')
          ..write('vitalismXp: $vitalismXp, ')
          ..write('strength: $strength, ')
          ..write('dexterity: $dexterity, ')
          ..write('intelligence: $intelligence, ')
          ..write('constitution: $constitution, ')
          ..write('spirit: $spirit, ')
          ..write('charisma: $charisma, ')
          ..write('hp: $hp, ')
          ..write('maxHp: $maxHp, ')
          ..write('mp: $mp, ')
          ..write('maxMp: $maxMp, ')
          ..write('currentVitalism: $currentVitalism, ')
          ..write('gold: $gold, ')
          ..write('gems: $gems, ')
          ..write('streakDays: $streakDays, ')
          ..write('caelumDay: $caelumDay, ')
          ..write('shadowState: $shadowState, ')
          ..write('shadowCorruption: $shadowCorruption, ')
          ..write('classType: $classType, ')
          ..write('factionType: $factionType, ')
          ..write('guildRank: $guildRank, ')
          ..write('totalQuestsCompleted: $totalQuestsCompleted, ')
          ..write('narrativeMode: $narrativeMode, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('playStyle: $playStyle, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('lastStreakDate: $lastStreakDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        email,
        passwordHash,
        shadowName,
        level,
        xp,
        xpToNext,
        attributePoints,
        vitalismLevel,
        vitalismXp,
        strength,
        dexterity,
        intelligence,
        constitution,
        spirit,
        charisma,
        hp,
        maxHp,
        mp,
        maxMp,
        currentVitalism,
        gold,
        gems,
        streakDays,
        caelumDay,
        shadowState,
        shadowCorruption,
        classType,
        factionType,
        guildRank,
        totalQuestsCompleted,
        narrativeMode,
        onboardingDone,
        playStyle,
        createdAt,
        lastLoginAt,
        lastStreakDate
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayersTableData &&
          other.id == this.id &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.shadowName == this.shadowName &&
          other.level == this.level &&
          other.xp == this.xp &&
          other.xpToNext == this.xpToNext &&
          other.attributePoints == this.attributePoints &&
          other.vitalismLevel == this.vitalismLevel &&
          other.vitalismXp == this.vitalismXp &&
          other.strength == this.strength &&
          other.dexterity == this.dexterity &&
          other.intelligence == this.intelligence &&
          other.constitution == this.constitution &&
          other.spirit == this.spirit &&
          other.charisma == this.charisma &&
          other.hp == this.hp &&
          other.maxHp == this.maxHp &&
          other.mp == this.mp &&
          other.maxMp == this.maxMp &&
          other.currentVitalism == this.currentVitalism &&
          other.gold == this.gold &&
          other.gems == this.gems &&
          other.streakDays == this.streakDays &&
          other.caelumDay == this.caelumDay &&
          other.shadowState == this.shadowState &&
          other.shadowCorruption == this.shadowCorruption &&
          other.classType == this.classType &&
          other.factionType == this.factionType &&
          other.guildRank == this.guildRank &&
          other.totalQuestsCompleted == this.totalQuestsCompleted &&
          other.narrativeMode == this.narrativeMode &&
          other.onboardingDone == this.onboardingDone &&
          other.playStyle == this.playStyle &&
          other.createdAt == this.createdAt &&
          other.lastLoginAt == this.lastLoginAt &&
          other.lastStreakDate == this.lastStreakDate);
}

class PlayersTableCompanion extends UpdateCompanion<PlayersTableData> {
  final Value<int> id;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<String> shadowName;
  final Value<int> level;
  final Value<int> xp;
  final Value<int> xpToNext;
  final Value<int> attributePoints;
  final Value<int> vitalismLevel;
  final Value<int> vitalismXp;
  final Value<int> strength;
  final Value<int> dexterity;
  final Value<int> intelligence;
  final Value<int> constitution;
  final Value<int> spirit;
  final Value<int> charisma;
  final Value<int> hp;
  final Value<int> maxHp;
  final Value<int> mp;
  final Value<int> maxMp;
  final Value<int> currentVitalism;
  final Value<int> gold;
  final Value<int> gems;
  final Value<int> streakDays;
  final Value<int> caelumDay;
  final Value<String> shadowState;
  final Value<int> shadowCorruption;
  final Value<String?> classType;
  final Value<String?> factionType;
  final Value<String> guildRank;
  final Value<int> totalQuestsCompleted;
  final Value<String> narrativeMode;
  final Value<bool> onboardingDone;
  final Value<String> playStyle;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastLoginAt;
  final Value<DateTime?> lastStreakDate;
  const PlayersTableCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.shadowName = const Value.absent(),
    this.level = const Value.absent(),
    this.xp = const Value.absent(),
    this.xpToNext = const Value.absent(),
    this.attributePoints = const Value.absent(),
    this.vitalismLevel = const Value.absent(),
    this.vitalismXp = const Value.absent(),
    this.strength = const Value.absent(),
    this.dexterity = const Value.absent(),
    this.intelligence = const Value.absent(),
    this.constitution = const Value.absent(),
    this.spirit = const Value.absent(),
    this.charisma = const Value.absent(),
    this.hp = const Value.absent(),
    this.maxHp = const Value.absent(),
    this.mp = const Value.absent(),
    this.maxMp = const Value.absent(),
    this.currentVitalism = const Value.absent(),
    this.gold = const Value.absent(),
    this.gems = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.caelumDay = const Value.absent(),
    this.shadowState = const Value.absent(),
    this.shadowCorruption = const Value.absent(),
    this.classType = const Value.absent(),
    this.factionType = const Value.absent(),
    this.guildRank = const Value.absent(),
    this.totalQuestsCompleted = const Value.absent(),
    this.narrativeMode = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.playStyle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.lastStreakDate = const Value.absent(),
  });
  PlayersTableCompanion.insert({
    this.id = const Value.absent(),
    required String email,
    required String passwordHash,
    this.shadowName = const Value.absent(),
    this.level = const Value.absent(),
    this.xp = const Value.absent(),
    this.xpToNext = const Value.absent(),
    this.attributePoints = const Value.absent(),
    this.vitalismLevel = const Value.absent(),
    this.vitalismXp = const Value.absent(),
    this.strength = const Value.absent(),
    this.dexterity = const Value.absent(),
    this.intelligence = const Value.absent(),
    this.constitution = const Value.absent(),
    this.spirit = const Value.absent(),
    this.charisma = const Value.absent(),
    this.hp = const Value.absent(),
    this.maxHp = const Value.absent(),
    this.mp = const Value.absent(),
    this.maxMp = const Value.absent(),
    this.currentVitalism = const Value.absent(),
    this.gold = const Value.absent(),
    this.gems = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.caelumDay = const Value.absent(),
    this.shadowState = const Value.absent(),
    this.shadowCorruption = const Value.absent(),
    this.classType = const Value.absent(),
    this.factionType = const Value.absent(),
    this.guildRank = const Value.absent(),
    this.totalQuestsCompleted = const Value.absent(),
    this.narrativeMode = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.playStyle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
    this.lastStreakDate = const Value.absent(),
  })  : email = Value(email),
        passwordHash = Value(passwordHash);
  static Insertable<PlayersTableData> custom({
    Expression<int>? id,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? shadowName,
    Expression<int>? level,
    Expression<int>? xp,
    Expression<int>? xpToNext,
    Expression<int>? attributePoints,
    Expression<int>? vitalismLevel,
    Expression<int>? vitalismXp,
    Expression<int>? strength,
    Expression<int>? dexterity,
    Expression<int>? intelligence,
    Expression<int>? constitution,
    Expression<int>? spirit,
    Expression<int>? charisma,
    Expression<int>? hp,
    Expression<int>? maxHp,
    Expression<int>? mp,
    Expression<int>? maxMp,
    Expression<int>? currentVitalism,
    Expression<int>? gold,
    Expression<int>? gems,
    Expression<int>? streakDays,
    Expression<int>? caelumDay,
    Expression<String>? shadowState,
    Expression<int>? shadowCorruption,
    Expression<String>? classType,
    Expression<String>? factionType,
    Expression<String>? guildRank,
    Expression<int>? totalQuestsCompleted,
    Expression<String>? narrativeMode,
    Expression<bool>? onboardingDone,
    Expression<String>? playStyle,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastLoginAt,
    Expression<DateTime>? lastStreakDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (shadowName != null) 'shadow_name': shadowName,
      if (level != null) 'level': level,
      if (xp != null) 'xp': xp,
      if (xpToNext != null) 'xp_to_next': xpToNext,
      if (attributePoints != null) 'attribute_points': attributePoints,
      if (vitalismLevel != null) 'vitalism_level': vitalismLevel,
      if (vitalismXp != null) 'vitalism_xp': vitalismXp,
      if (strength != null) 'strength': strength,
      if (dexterity != null) 'dexterity': dexterity,
      if (intelligence != null) 'intelligence': intelligence,
      if (constitution != null) 'constitution': constitution,
      if (spirit != null) 'spirit': spirit,
      if (charisma != null) 'charisma': charisma,
      if (hp != null) 'hp': hp,
      if (maxHp != null) 'max_hp': maxHp,
      if (mp != null) 'mp': mp,
      if (maxMp != null) 'max_mp': maxMp,
      if (currentVitalism != null) 'current_vitalism': currentVitalism,
      if (gold != null) 'gold': gold,
      if (gems != null) 'gems': gems,
      if (streakDays != null) 'streak_days': streakDays,
      if (caelumDay != null) 'caelum_day': caelumDay,
      if (shadowState != null) 'shadow_state': shadowState,
      if (shadowCorruption != null) 'shadow_corruption': shadowCorruption,
      if (classType != null) 'class_type': classType,
      if (factionType != null) 'faction_type': factionType,
      if (guildRank != null) 'guild_rank': guildRank,
      if (totalQuestsCompleted != null)
        'total_quests_completed': totalQuestsCompleted,
      if (narrativeMode != null) 'narrative_mode': narrativeMode,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
      if (playStyle != null) 'play_style': playStyle,
      if (createdAt != null) 'created_at': createdAt,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
      if (lastStreakDate != null) 'last_streak_date': lastStreakDate,
    });
  }

  PlayersTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? email,
      Value<String>? passwordHash,
      Value<String>? shadowName,
      Value<int>? level,
      Value<int>? xp,
      Value<int>? xpToNext,
      Value<int>? attributePoints,
      Value<int>? vitalismLevel,
      Value<int>? vitalismXp,
      Value<int>? strength,
      Value<int>? dexterity,
      Value<int>? intelligence,
      Value<int>? constitution,
      Value<int>? spirit,
      Value<int>? charisma,
      Value<int>? hp,
      Value<int>? maxHp,
      Value<int>? mp,
      Value<int>? maxMp,
      Value<int>? currentVitalism,
      Value<int>? gold,
      Value<int>? gems,
      Value<int>? streakDays,
      Value<int>? caelumDay,
      Value<String>? shadowState,
      Value<int>? shadowCorruption,
      Value<String?>? classType,
      Value<String?>? factionType,
      Value<String>? guildRank,
      Value<int>? totalQuestsCompleted,
      Value<String>? narrativeMode,
      Value<bool>? onboardingDone,
      Value<String>? playStyle,
      Value<DateTime>? createdAt,
      Value<DateTime>? lastLoginAt,
      Value<DateTime?>? lastStreakDate}) {
    return PlayersTableCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
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
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (shadowName.present) {
      map['shadow_name'] = Variable<String>(shadowName.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (xpToNext.present) {
      map['xp_to_next'] = Variable<int>(xpToNext.value);
    }
    if (attributePoints.present) {
      map['attribute_points'] = Variable<int>(attributePoints.value);
    }
    if (vitalismLevel.present) {
      map['vitalism_level'] = Variable<int>(vitalismLevel.value);
    }
    if (vitalismXp.present) {
      map['vitalism_xp'] = Variable<int>(vitalismXp.value);
    }
    if (strength.present) {
      map['strength'] = Variable<int>(strength.value);
    }
    if (dexterity.present) {
      map['dexterity'] = Variable<int>(dexterity.value);
    }
    if (intelligence.present) {
      map['intelligence'] = Variable<int>(intelligence.value);
    }
    if (constitution.present) {
      map['constitution'] = Variable<int>(constitution.value);
    }
    if (spirit.present) {
      map['spirit'] = Variable<int>(spirit.value);
    }
    if (charisma.present) {
      map['charisma'] = Variable<int>(charisma.value);
    }
    if (hp.present) {
      map['hp'] = Variable<int>(hp.value);
    }
    if (maxHp.present) {
      map['max_hp'] = Variable<int>(maxHp.value);
    }
    if (mp.present) {
      map['mp'] = Variable<int>(mp.value);
    }
    if (maxMp.present) {
      map['max_mp'] = Variable<int>(maxMp.value);
    }
    if (currentVitalism.present) {
      map['current_vitalism'] = Variable<int>(currentVitalism.value);
    }
    if (gold.present) {
      map['gold'] = Variable<int>(gold.value);
    }
    if (gems.present) {
      map['gems'] = Variable<int>(gems.value);
    }
    if (streakDays.present) {
      map['streak_days'] = Variable<int>(streakDays.value);
    }
    if (caelumDay.present) {
      map['caelum_day'] = Variable<int>(caelumDay.value);
    }
    if (shadowState.present) {
      map['shadow_state'] = Variable<String>(shadowState.value);
    }
    if (shadowCorruption.present) {
      map['shadow_corruption'] = Variable<int>(shadowCorruption.value);
    }
    if (classType.present) {
      map['class_type'] = Variable<String>(classType.value);
    }
    if (factionType.present) {
      map['faction_type'] = Variable<String>(factionType.value);
    }
    if (guildRank.present) {
      map['guild_rank'] = Variable<String>(guildRank.value);
    }
    if (totalQuestsCompleted.present) {
      map['total_quests_completed'] = Variable<int>(totalQuestsCompleted.value);
    }
    if (narrativeMode.present) {
      map['narrative_mode'] = Variable<String>(narrativeMode.value);
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<bool>(onboardingDone.value);
    }
    if (playStyle.present) {
      map['play_style'] = Variable<String>(playStyle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    if (lastStreakDate.present) {
      map['last_streak_date'] = Variable<DateTime>(lastStreakDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersTableCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('shadowName: $shadowName, ')
          ..write('level: $level, ')
          ..write('xp: $xp, ')
          ..write('xpToNext: $xpToNext, ')
          ..write('attributePoints: $attributePoints, ')
          ..write('vitalismLevel: $vitalismLevel, ')
          ..write('vitalismXp: $vitalismXp, ')
          ..write('strength: $strength, ')
          ..write('dexterity: $dexterity, ')
          ..write('intelligence: $intelligence, ')
          ..write('constitution: $constitution, ')
          ..write('spirit: $spirit, ')
          ..write('charisma: $charisma, ')
          ..write('hp: $hp, ')
          ..write('maxHp: $maxHp, ')
          ..write('mp: $mp, ')
          ..write('maxMp: $maxMp, ')
          ..write('currentVitalism: $currentVitalism, ')
          ..write('gold: $gold, ')
          ..write('gems: $gems, ')
          ..write('streakDays: $streakDays, ')
          ..write('caelumDay: $caelumDay, ')
          ..write('shadowState: $shadowState, ')
          ..write('shadowCorruption: $shadowCorruption, ')
          ..write('classType: $classType, ')
          ..write('factionType: $factionType, ')
          ..write('guildRank: $guildRank, ')
          ..write('totalQuestsCompleted: $totalQuestsCompleted, ')
          ..write('narrativeMode: $narrativeMode, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('playStyle: $playStyle, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt, ')
          ..write('lastStreakDate: $lastStreakDate')
          ..write(')'))
        .toString();
  }
}

class $HabitsTableTable extends HabitsTable
    with TableInfo<$HabitsTableTable, HabitsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<String> rank = GeneratedColumn<String>(
      'rank', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('e'));
  static const VerificationMeta _isSystemHabitMeta =
      const VerificationMeta('isSystemHabit');
  @override
  late final GeneratedColumn<bool> isSystemHabit = GeneratedColumn<bool>(
      'is_system_habit', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_system_habit" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isRepeatableMeta =
      const VerificationMeta('isRepeatable');
  @override
  late final GeneratedColumn<bool> isRepeatable = GeneratedColumn<bool>(
      'is_repeatable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_repeatable" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isPausedMeta =
      const VerificationMeta('isPaused');
  @override
  late final GeneratedColumn<bool> isPaused = GeneratedColumn<bool>(
      'is_paused', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_paused" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _xpRewardMeta =
      const VerificationMeta('xpReward');
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
      'xp_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(20));
  static const VerificationMeta _goldRewardMeta =
      const VerificationMeta('goldReward');
  @override
  late final GeneratedColumn<int> goldReward = GeneratedColumn<int>(
      'gold_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _streakCountMeta =
      const VerificationMeta('streakCount');
  @override
  late final GeneratedColumn<int> streakCount = GeneratedColumn<int>(
      'streak_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalCompletedMeta =
      const VerificationMeta('totalCompleted');
  @override
  late final GeneratedColumn<int> totalCompleted = GeneratedColumn<int>(
      'total_completed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _requirementsMeta =
      const VerificationMeta('requirements');
  @override
  late final GeneratedColumn<String> requirements = GeneratedColumn<String>(
      'requirements', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _questTypeMeta =
      const VerificationMeta('questType');
  @override
  late final GeneratedColumn<String> questType = GeneratedColumn<String>(
      'quest_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('individual'));
  static const VerificationMeta _metricUnitMeta =
      const VerificationMeta('metricUnit');
  @override
  late final GeneratedColumn<String> metricUnit = GeneratedColumn<String>(
      'metric_unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('reps'));
  static const VerificationMeta _autoDescriptionMeta =
      const VerificationMeta('autoDescription');
  @override
  late final GeneratedColumn<String> autoDescription = GeneratedColumn<String>(
      'auto_description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playerId,
        title,
        description,
        category,
        rank,
        isSystemHabit,
        isRepeatable,
        isPaused,
        xpReward,
        goldReward,
        streakCount,
        totalCompleted,
        requirements,
        questType,
        metricUnit,
        autoDescription,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(Insertable<HabitsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
          _rankMeta, rank.isAcceptableOrUnknown(data['rank']!, _rankMeta));
    }
    if (data.containsKey('is_system_habit')) {
      context.handle(
          _isSystemHabitMeta,
          isSystemHabit.isAcceptableOrUnknown(
              data['is_system_habit']!, _isSystemHabitMeta));
    }
    if (data.containsKey('is_repeatable')) {
      context.handle(
          _isRepeatableMeta,
          isRepeatable.isAcceptableOrUnknown(
              data['is_repeatable']!, _isRepeatableMeta));
    }
    if (data.containsKey('is_paused')) {
      context.handle(_isPausedMeta,
          isPaused.isAcceptableOrUnknown(data['is_paused']!, _isPausedMeta));
    }
    if (data.containsKey('xp_reward')) {
      context.handle(_xpRewardMeta,
          xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta));
    }
    if (data.containsKey('gold_reward')) {
      context.handle(
          _goldRewardMeta,
          goldReward.isAcceptableOrUnknown(
              data['gold_reward']!, _goldRewardMeta));
    }
    if (data.containsKey('streak_count')) {
      context.handle(
          _streakCountMeta,
          streakCount.isAcceptableOrUnknown(
              data['streak_count']!, _streakCountMeta));
    }
    if (data.containsKey('total_completed')) {
      context.handle(
          _totalCompletedMeta,
          totalCompleted.isAcceptableOrUnknown(
              data['total_completed']!, _totalCompletedMeta));
    }
    if (data.containsKey('requirements')) {
      context.handle(
          _requirementsMeta,
          requirements.isAcceptableOrUnknown(
              data['requirements']!, _requirementsMeta));
    }
    if (data.containsKey('quest_type')) {
      context.handle(_questTypeMeta,
          questType.isAcceptableOrUnknown(data['quest_type']!, _questTypeMeta));
    }
    if (data.containsKey('metric_unit')) {
      context.handle(
          _metricUnitMeta,
          metricUnit.isAcceptableOrUnknown(
              data['metric_unit']!, _metricUnitMeta));
    }
    if (data.containsKey('auto_description')) {
      context.handle(
          _autoDescriptionMeta,
          autoDescription.isAcceptableOrUnknown(
              data['auto_description']!, _autoDescriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      rank: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rank'])!,
      isSystemHabit: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_system_habit'])!,
      isRepeatable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_repeatable'])!,
      isPaused: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_paused'])!,
      xpReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_reward'])!,
      goldReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gold_reward'])!,
      streakCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}streak_count'])!,
      totalCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_completed'])!,
      requirements: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}requirements']),
      questType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quest_type'])!,
      metricUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metric_unit'])!,
      autoDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}auto_description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HabitsTableTable createAlias(String alias) {
    return $HabitsTableTable(attachedDatabase, alias);
  }
}

class HabitsTableData extends DataClass implements Insertable<HabitsTableData> {
  final int id;
  final int playerId;
  final String title;
  final String description;
  final String category;
  final String rank;
  final bool isSystemHabit;
  final bool isRepeatable;
  final bool isPaused;
  final int xpReward;
  final int goldReward;
  final int streakCount;
  final int totalCompleted;
  final String? requirements;
  final String questType;
  final String metricUnit;
  final String? autoDescription;
  final DateTime createdAt;
  const HabitsTableData(
      {required this.id,
      required this.playerId,
      required this.title,
      required this.description,
      required this.category,
      required this.rank,
      required this.isSystemHabit,
      required this.isRepeatable,
      required this.isPaused,
      required this.xpReward,
      required this.goldReward,
      required this.streakCount,
      required this.totalCompleted,
      this.requirements,
      required this.questType,
      required this.metricUnit,
      this.autoDescription,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['rank'] = Variable<String>(rank);
    map['is_system_habit'] = Variable<bool>(isSystemHabit);
    map['is_repeatable'] = Variable<bool>(isRepeatable);
    map['is_paused'] = Variable<bool>(isPaused);
    map['xp_reward'] = Variable<int>(xpReward);
    map['gold_reward'] = Variable<int>(goldReward);
    map['streak_count'] = Variable<int>(streakCount);
    map['total_completed'] = Variable<int>(totalCompleted);
    if (!nullToAbsent || requirements != null) {
      map['requirements'] = Variable<String>(requirements);
    }
    map['quest_type'] = Variable<String>(questType);
    map['metric_unit'] = Variable<String>(metricUnit);
    if (!nullToAbsent || autoDescription != null) {
      map['auto_description'] = Variable<String>(autoDescription);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HabitsTableCompanion toCompanion(bool nullToAbsent) {
    return HabitsTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      rank: Value(rank),
      isSystemHabit: Value(isSystemHabit),
      isRepeatable: Value(isRepeatable),
      isPaused: Value(isPaused),
      xpReward: Value(xpReward),
      goldReward: Value(goldReward),
      streakCount: Value(streakCount),
      totalCompleted: Value(totalCompleted),
      requirements: requirements == null && nullToAbsent
          ? const Value.absent()
          : Value(requirements),
      questType: Value(questType),
      metricUnit: Value(metricUnit),
      autoDescription: autoDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(autoDescription),
      createdAt: Value(createdAt),
    );
  }

  factory HabitsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitsTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      rank: serializer.fromJson<String>(json['rank']),
      isSystemHabit: serializer.fromJson<bool>(json['isSystemHabit']),
      isRepeatable: serializer.fromJson<bool>(json['isRepeatable']),
      isPaused: serializer.fromJson<bool>(json['isPaused']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
      goldReward: serializer.fromJson<int>(json['goldReward']),
      streakCount: serializer.fromJson<int>(json['streakCount']),
      totalCompleted: serializer.fromJson<int>(json['totalCompleted']),
      requirements: serializer.fromJson<String?>(json['requirements']),
      questType: serializer.fromJson<String>(json['questType']),
      metricUnit: serializer.fromJson<String>(json['metricUnit']),
      autoDescription: serializer.fromJson<String?>(json['autoDescription']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'rank': serializer.toJson<String>(rank),
      'isSystemHabit': serializer.toJson<bool>(isSystemHabit),
      'isRepeatable': serializer.toJson<bool>(isRepeatable),
      'isPaused': serializer.toJson<bool>(isPaused),
      'xpReward': serializer.toJson<int>(xpReward),
      'goldReward': serializer.toJson<int>(goldReward),
      'streakCount': serializer.toJson<int>(streakCount),
      'totalCompleted': serializer.toJson<int>(totalCompleted),
      'requirements': serializer.toJson<String?>(requirements),
      'questType': serializer.toJson<String>(questType),
      'metricUnit': serializer.toJson<String>(metricUnit),
      'autoDescription': serializer.toJson<String?>(autoDescription),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HabitsTableData copyWith(
          {int? id,
          int? playerId,
          String? title,
          String? description,
          String? category,
          String? rank,
          bool? isSystemHabit,
          bool? isRepeatable,
          bool? isPaused,
          int? xpReward,
          int? goldReward,
          int? streakCount,
          int? totalCompleted,
          Value<String?> requirements = const Value.absent(),
          String? questType,
          String? metricUnit,
          Value<String?> autoDescription = const Value.absent(),
          DateTime? createdAt}) =>
      HabitsTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        rank: rank ?? this.rank,
        isSystemHabit: isSystemHabit ?? this.isSystemHabit,
        isRepeatable: isRepeatable ?? this.isRepeatable,
        isPaused: isPaused ?? this.isPaused,
        xpReward: xpReward ?? this.xpReward,
        goldReward: goldReward ?? this.goldReward,
        streakCount: streakCount ?? this.streakCount,
        totalCompleted: totalCompleted ?? this.totalCompleted,
        requirements:
            requirements.present ? requirements.value : this.requirements,
        questType: questType ?? this.questType,
        metricUnit: metricUnit ?? this.metricUnit,
        autoDescription: autoDescription.present
            ? autoDescription.value
            : this.autoDescription,
        createdAt: createdAt ?? this.createdAt,
      );
  HabitsTableData copyWithCompanion(HabitsTableCompanion data) {
    return HabitsTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      category: data.category.present ? data.category.value : this.category,
      rank: data.rank.present ? data.rank.value : this.rank,
      isSystemHabit: data.isSystemHabit.present
          ? data.isSystemHabit.value
          : this.isSystemHabit,
      isRepeatable: data.isRepeatable.present
          ? data.isRepeatable.value
          : this.isRepeatable,
      isPaused: data.isPaused.present ? data.isPaused.value : this.isPaused,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
      goldReward:
          data.goldReward.present ? data.goldReward.value : this.goldReward,
      streakCount:
          data.streakCount.present ? data.streakCount.value : this.streakCount,
      totalCompleted: data.totalCompleted.present
          ? data.totalCompleted.value
          : this.totalCompleted,
      requirements: data.requirements.present
          ? data.requirements.value
          : this.requirements,
      questType: data.questType.present ? data.questType.value : this.questType,
      metricUnit:
          data.metricUnit.present ? data.metricUnit.value : this.metricUnit,
      autoDescription: data.autoDescription.present
          ? data.autoDescription.value
          : this.autoDescription,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitsTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('rank: $rank, ')
          ..write('isSystemHabit: $isSystemHabit, ')
          ..write('isRepeatable: $isRepeatable, ')
          ..write('isPaused: $isPaused, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('streakCount: $streakCount, ')
          ..write('totalCompleted: $totalCompleted, ')
          ..write('requirements: $requirements, ')
          ..write('questType: $questType, ')
          ..write('metricUnit: $metricUnit, ')
          ..write('autoDescription: $autoDescription, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      playerId,
      title,
      description,
      category,
      rank,
      isSystemHabit,
      isRepeatable,
      isPaused,
      xpReward,
      goldReward,
      streakCount,
      totalCompleted,
      requirements,
      questType,
      metricUnit,
      autoDescription,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitsTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.rank == this.rank &&
          other.isSystemHabit == this.isSystemHabit &&
          other.isRepeatable == this.isRepeatable &&
          other.isPaused == this.isPaused &&
          other.xpReward == this.xpReward &&
          other.goldReward == this.goldReward &&
          other.streakCount == this.streakCount &&
          other.totalCompleted == this.totalCompleted &&
          other.requirements == this.requirements &&
          other.questType == this.questType &&
          other.metricUnit == this.metricUnit &&
          other.autoDescription == this.autoDescription &&
          other.createdAt == this.createdAt);
}

class HabitsTableCompanion extends UpdateCompanion<HabitsTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> title;
  final Value<String> description;
  final Value<String> category;
  final Value<String> rank;
  final Value<bool> isSystemHabit;
  final Value<bool> isRepeatable;
  final Value<bool> isPaused;
  final Value<int> xpReward;
  final Value<int> goldReward;
  final Value<int> streakCount;
  final Value<int> totalCompleted;
  final Value<String?> requirements;
  final Value<String> questType;
  final Value<String> metricUnit;
  final Value<String?> autoDescription;
  final Value<DateTime> createdAt;
  const HabitsTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.rank = const Value.absent(),
    this.isSystemHabit = const Value.absent(),
    this.isRepeatable = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.goldReward = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.totalCompleted = const Value.absent(),
    this.requirements = const Value.absent(),
    this.questType = const Value.absent(),
    this.metricUnit = const Value.absent(),
    this.autoDescription = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitsTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required String title,
    this.description = const Value.absent(),
    required String category,
    this.rank = const Value.absent(),
    this.isSystemHabit = const Value.absent(),
    this.isRepeatable = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.goldReward = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.totalCompleted = const Value.absent(),
    this.requirements = const Value.absent(),
    this.questType = const Value.absent(),
    this.metricUnit = const Value.absent(),
    this.autoDescription = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : playerId = Value(playerId),
        title = Value(title),
        category = Value(category);
  static Insertable<HabitsTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? rank,
    Expression<bool>? isSystemHabit,
    Expression<bool>? isRepeatable,
    Expression<bool>? isPaused,
    Expression<int>? xpReward,
    Expression<int>? goldReward,
    Expression<int>? streakCount,
    Expression<int>? totalCompleted,
    Expression<String>? requirements,
    Expression<String>? questType,
    Expression<String>? metricUnit,
    Expression<String>? autoDescription,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (rank != null) 'rank': rank,
      if (isSystemHabit != null) 'is_system_habit': isSystemHabit,
      if (isRepeatable != null) 'is_repeatable': isRepeatable,
      if (isPaused != null) 'is_paused': isPaused,
      if (xpReward != null) 'xp_reward': xpReward,
      if (goldReward != null) 'gold_reward': goldReward,
      if (streakCount != null) 'streak_count': streakCount,
      if (totalCompleted != null) 'total_completed': totalCompleted,
      if (requirements != null) 'requirements': requirements,
      if (questType != null) 'quest_type': questType,
      if (metricUnit != null) 'metric_unit': metricUnit,
      if (autoDescription != null) 'auto_description': autoDescription,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitsTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<String>? title,
      Value<String>? description,
      Value<String>? category,
      Value<String>? rank,
      Value<bool>? isSystemHabit,
      Value<bool>? isRepeatable,
      Value<bool>? isPaused,
      Value<int>? xpReward,
      Value<int>? goldReward,
      Value<int>? streakCount,
      Value<int>? totalCompleted,
      Value<String?>? requirements,
      Value<String>? questType,
      Value<String>? metricUnit,
      Value<String?>? autoDescription,
      Value<DateTime>? createdAt}) {
    return HabitsTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      rank: rank ?? this.rank,
      isSystemHabit: isSystemHabit ?? this.isSystemHabit,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      isPaused: isPaused ?? this.isPaused,
      xpReward: xpReward ?? this.xpReward,
      goldReward: goldReward ?? this.goldReward,
      streakCount: streakCount ?? this.streakCount,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      requirements: requirements ?? this.requirements,
      questType: questType ?? this.questType,
      metricUnit: metricUnit ?? this.metricUnit,
      autoDescription: autoDescription ?? this.autoDescription,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (rank.present) {
      map['rank'] = Variable<String>(rank.value);
    }
    if (isSystemHabit.present) {
      map['is_system_habit'] = Variable<bool>(isSystemHabit.value);
    }
    if (isRepeatable.present) {
      map['is_repeatable'] = Variable<bool>(isRepeatable.value);
    }
    if (isPaused.present) {
      map['is_paused'] = Variable<bool>(isPaused.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    if (goldReward.present) {
      map['gold_reward'] = Variable<int>(goldReward.value);
    }
    if (streakCount.present) {
      map['streak_count'] = Variable<int>(streakCount.value);
    }
    if (totalCompleted.present) {
      map['total_completed'] = Variable<int>(totalCompleted.value);
    }
    if (requirements.present) {
      map['requirements'] = Variable<String>(requirements.value);
    }
    if (questType.present) {
      map['quest_type'] = Variable<String>(questType.value);
    }
    if (metricUnit.present) {
      map['metric_unit'] = Variable<String>(metricUnit.value);
    }
    if (autoDescription.present) {
      map['auto_description'] = Variable<String>(autoDescription.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('rank: $rank, ')
          ..write('isSystemHabit: $isSystemHabit, ')
          ..write('isRepeatable: $isRepeatable, ')
          ..write('isPaused: $isPaused, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('streakCount: $streakCount, ')
          ..write('totalCompleted: $totalCompleted, ')
          ..write('requirements: $requirements, ')
          ..write('questType: $questType, ')
          ..write('metricUnit: $metricUnit, ')
          ..write('autoDescription: $autoDescription, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $HabitLogsTableTable extends HabitLogsTable
    with TableInfo<$HabitLogsTableTable, HabitLogsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _habitIdMeta =
      const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
      'habit_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _xpGainedMeta =
      const VerificationMeta('xpGained');
  @override
  late final GeneratedColumn<int> xpGained = GeneratedColumn<int>(
      'xp_gained', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _goldGainedMeta =
      const VerificationMeta('goldGained');
  @override
  late final GeneratedColumn<int> goldGained = GeneratedColumn<int>(
      'gold_gained', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _shadowImpactMeta =
      const VerificationMeta('shadowImpact');
  @override
  late final GeneratedColumn<int> shadowImpact = GeneratedColumn<int>(
      'shadow_impact', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _logDateMeta =
      const VerificationMeta('logDate');
  @override
  late final GeneratedColumn<DateTime> logDate = GeneratedColumn<DateTime>(
      'log_date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        habitId,
        playerId,
        status,
        xpGained,
        goldGained,
        shadowImpact,
        logDate
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<HabitLogsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta,
          habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('xp_gained')) {
      context.handle(_xpGainedMeta,
          xpGained.isAcceptableOrUnknown(data['xp_gained']!, _xpGainedMeta));
    }
    if (data.containsKey('gold_gained')) {
      context.handle(
          _goldGainedMeta,
          goldGained.isAcceptableOrUnknown(
              data['gold_gained']!, _goldGainedMeta));
    }
    if (data.containsKey('shadow_impact')) {
      context.handle(
          _shadowImpactMeta,
          shadowImpact.isAcceptableOrUnknown(
              data['shadow_impact']!, _shadowImpactMeta));
    }
    if (data.containsKey('log_date')) {
      context.handle(_logDateMeta,
          logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitLogsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLogsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      habitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}habit_id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      xpGained: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_gained'])!,
      goldGained: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gold_gained'])!,
      shadowImpact: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shadow_impact'])!,
      logDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}log_date'])!,
    );
  }

  @override
  $HabitLogsTableTable createAlias(String alias) {
    return $HabitLogsTableTable(attachedDatabase, alias);
  }
}

class HabitLogsTableData extends DataClass
    implements Insertable<HabitLogsTableData> {
  final int id;
  final int habitId;
  final int playerId;
  final String status;
  final int xpGained;
  final int goldGained;
  final int shadowImpact;
  final DateTime logDate;
  const HabitLogsTableData(
      {required this.id,
      required this.habitId,
      required this.playerId,
      required this.status,
      required this.xpGained,
      required this.goldGained,
      required this.shadowImpact,
      required this.logDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['player_id'] = Variable<int>(playerId);
    map['status'] = Variable<String>(status);
    map['xp_gained'] = Variable<int>(xpGained);
    map['gold_gained'] = Variable<int>(goldGained);
    map['shadow_impact'] = Variable<int>(shadowImpact);
    map['log_date'] = Variable<DateTime>(logDate);
    return map;
  }

  HabitLogsTableCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsTableCompanion(
      id: Value(id),
      habitId: Value(habitId),
      playerId: Value(playerId),
      status: Value(status),
      xpGained: Value(xpGained),
      goldGained: Value(goldGained),
      shadowImpact: Value(shadowImpact),
      logDate: Value(logDate),
    );
  }

  factory HabitLogsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitLogsTableData(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      playerId: serializer.fromJson<int>(json['playerId']),
      status: serializer.fromJson<String>(json['status']),
      xpGained: serializer.fromJson<int>(json['xpGained']),
      goldGained: serializer.fromJson<int>(json['goldGained']),
      shadowImpact: serializer.fromJson<int>(json['shadowImpact']),
      logDate: serializer.fromJson<DateTime>(json['logDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'playerId': serializer.toJson<int>(playerId),
      'status': serializer.toJson<String>(status),
      'xpGained': serializer.toJson<int>(xpGained),
      'goldGained': serializer.toJson<int>(goldGained),
      'shadowImpact': serializer.toJson<int>(shadowImpact),
      'logDate': serializer.toJson<DateTime>(logDate),
    };
  }

  HabitLogsTableData copyWith(
          {int? id,
          int? habitId,
          int? playerId,
          String? status,
          int? xpGained,
          int? goldGained,
          int? shadowImpact,
          DateTime? logDate}) =>
      HabitLogsTableData(
        id: id ?? this.id,
        habitId: habitId ?? this.habitId,
        playerId: playerId ?? this.playerId,
        status: status ?? this.status,
        xpGained: xpGained ?? this.xpGained,
        goldGained: goldGained ?? this.goldGained,
        shadowImpact: shadowImpact ?? this.shadowImpact,
        logDate: logDate ?? this.logDate,
      );
  HabitLogsTableData copyWithCompanion(HabitLogsTableCompanion data) {
    return HabitLogsTableData(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      status: data.status.present ? data.status.value : this.status,
      xpGained: data.xpGained.present ? data.xpGained.value : this.xpGained,
      goldGained:
          data.goldGained.present ? data.goldGained.value : this.goldGained,
      shadowImpact: data.shadowImpact.present
          ? data.shadowImpact.value
          : this.shadowImpact,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsTableData(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('playerId: $playerId, ')
          ..write('status: $status, ')
          ..write('xpGained: $xpGained, ')
          ..write('goldGained: $goldGained, ')
          ..write('shadowImpact: $shadowImpact, ')
          ..write('logDate: $logDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, playerId, status, xpGained,
      goldGained, shadowImpact, logDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLogsTableData &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.playerId == this.playerId &&
          other.status == this.status &&
          other.xpGained == this.xpGained &&
          other.goldGained == this.goldGained &&
          other.shadowImpact == this.shadowImpact &&
          other.logDate == this.logDate);
}

class HabitLogsTableCompanion extends UpdateCompanion<HabitLogsTableData> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<int> playerId;
  final Value<String> status;
  final Value<int> xpGained;
  final Value<int> goldGained;
  final Value<int> shadowImpact;
  final Value<DateTime> logDate;
  const HabitLogsTableCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.status = const Value.absent(),
    this.xpGained = const Value.absent(),
    this.goldGained = const Value.absent(),
    this.shadowImpact = const Value.absent(),
    this.logDate = const Value.absent(),
  });
  HabitLogsTableCompanion.insert({
    this.id = const Value.absent(),
    required int habitId,
    required int playerId,
    required String status,
    this.xpGained = const Value.absent(),
    this.goldGained = const Value.absent(),
    this.shadowImpact = const Value.absent(),
    this.logDate = const Value.absent(),
  })  : habitId = Value(habitId),
        playerId = Value(playerId),
        status = Value(status);
  static Insertable<HabitLogsTableData> custom({
    Expression<int>? id,
    Expression<int>? habitId,
    Expression<int>? playerId,
    Expression<String>? status,
    Expression<int>? xpGained,
    Expression<int>? goldGained,
    Expression<int>? shadowImpact,
    Expression<DateTime>? logDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (playerId != null) 'player_id': playerId,
      if (status != null) 'status': status,
      if (xpGained != null) 'xp_gained': xpGained,
      if (goldGained != null) 'gold_gained': goldGained,
      if (shadowImpact != null) 'shadow_impact': shadowImpact,
      if (logDate != null) 'log_date': logDate,
    });
  }

  HabitLogsTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? habitId,
      Value<int>? playerId,
      Value<String>? status,
      Value<int>? xpGained,
      Value<int>? goldGained,
      Value<int>? shadowImpact,
      Value<DateTime>? logDate}) {
    return HabitLogsTableCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      playerId: playerId ?? this.playerId,
      status: status ?? this.status,
      xpGained: xpGained ?? this.xpGained,
      goldGained: goldGained ?? this.goldGained,
      shadowImpact: shadowImpact ?? this.shadowImpact,
      logDate: logDate ?? this.logDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (xpGained.present) {
      map['xp_gained'] = Variable<int>(xpGained.value);
    }
    if (goldGained.present) {
      map['gold_gained'] = Variable<int>(goldGained.value);
    }
    if (shadowImpact.present) {
      map['shadow_impact'] = Variable<int>(shadowImpact.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<DateTime>(logDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('playerId: $playerId, ')
          ..write('status: $status, ')
          ..write('xpGained: $xpGained, ')
          ..write('goldGained: $goldGained, ')
          ..write('shadowImpact: $shadowImpact, ')
          ..write('logDate: $logDate')
          ..write(')'))
        .toString();
  }
}

class $ItemsTableTable extends ItemsTable
    with TableInfo<$ItemsTableTable, ItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<String> rarity = GeneratedColumn<String>(
      'rarity', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('common'));
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _goldValueMeta =
      const VerificationMeta('goldValue');
  @override
  late final GeneratedColumn<int> goldValue = GeneratedColumn<int>(
      'gold_value', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _gemValueMeta =
      const VerificationMeta('gemValue');
  @override
  late final GeneratedColumn<int> gemValue = GeneratedColumn<int>(
      'gem_value', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _strBonusMeta =
      const VerificationMeta('strBonus');
  @override
  late final GeneratedColumn<int> strBonus = GeneratedColumn<int>(
      'str_bonus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dexBonusMeta =
      const VerificationMeta('dexBonus');
  @override
  late final GeneratedColumn<int> dexBonus = GeneratedColumn<int>(
      'dex_bonus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _intBonusMeta =
      const VerificationMeta('intBonus');
  @override
  late final GeneratedColumn<int> intBonus = GeneratedColumn<int>(
      'int_bonus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _conBonusMeta =
      const VerificationMeta('conBonus');
  @override
  late final GeneratedColumn<int> conBonus = GeneratedColumn<int>(
      'con_bonus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _spiBonusMeta =
      const VerificationMeta('spiBonus');
  @override
  late final GeneratedColumn<int> spiBonus = GeneratedColumn<int>(
      'spi_bonus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _hpBonusMeta =
      const VerificationMeta('hpBonus');
  @override
  late final GeneratedColumn<int> hpBonus = GeneratedColumn<int>(
      'hp_bonus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _mpBonusMeta =
      const VerificationMeta('mpBonus');
  @override
  late final GeneratedColumn<int> mpBonus = GeneratedColumn<int>(
      'mp_bonus', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isConsumableMeta =
      const VerificationMeta('isConsumable');
  @override
  late final GeneratedColumn<bool> isConsumable = GeneratedColumn<bool>(
      'is_consumable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_consumable" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isStackableMeta =
      const VerificationMeta('isStackable');
  @override
  late final GeneratedColumn<bool> isStackable = GeneratedColumn<bool>(
      'is_stackable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_stackable" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('item'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        type,
        rarity,
        slot,
        goldValue,
        gemValue,
        strBonus,
        dexBonus,
        intBonus,
        conBonus,
        spiBonus,
        hpBonus,
        mpBonus,
        isConsumable,
        isStackable,
        iconName
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(Insertable<ItemsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('rarity')) {
      context.handle(_rarityMeta,
          rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta));
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    }
    if (data.containsKey('gold_value')) {
      context.handle(_goldValueMeta,
          goldValue.isAcceptableOrUnknown(data['gold_value']!, _goldValueMeta));
    }
    if (data.containsKey('gem_value')) {
      context.handle(_gemValueMeta,
          gemValue.isAcceptableOrUnknown(data['gem_value']!, _gemValueMeta));
    }
    if (data.containsKey('str_bonus')) {
      context.handle(_strBonusMeta,
          strBonus.isAcceptableOrUnknown(data['str_bonus']!, _strBonusMeta));
    }
    if (data.containsKey('dex_bonus')) {
      context.handle(_dexBonusMeta,
          dexBonus.isAcceptableOrUnknown(data['dex_bonus']!, _dexBonusMeta));
    }
    if (data.containsKey('int_bonus')) {
      context.handle(_intBonusMeta,
          intBonus.isAcceptableOrUnknown(data['int_bonus']!, _intBonusMeta));
    }
    if (data.containsKey('con_bonus')) {
      context.handle(_conBonusMeta,
          conBonus.isAcceptableOrUnknown(data['con_bonus']!, _conBonusMeta));
    }
    if (data.containsKey('spi_bonus')) {
      context.handle(_spiBonusMeta,
          spiBonus.isAcceptableOrUnknown(data['spi_bonus']!, _spiBonusMeta));
    }
    if (data.containsKey('hp_bonus')) {
      context.handle(_hpBonusMeta,
          hpBonus.isAcceptableOrUnknown(data['hp_bonus']!, _hpBonusMeta));
    }
    if (data.containsKey('mp_bonus')) {
      context.handle(_mpBonusMeta,
          mpBonus.isAcceptableOrUnknown(data['mp_bonus']!, _mpBonusMeta));
    }
    if (data.containsKey('is_consumable')) {
      context.handle(
          _isConsumableMeta,
          isConsumable.isAcceptableOrUnknown(
              data['is_consumable']!, _isConsumableMeta));
    }
    if (data.containsKey('is_stackable')) {
      context.handle(
          _isStackableMeta,
          isStackable.isAcceptableOrUnknown(
              data['is_stackable']!, _isStackableMeta));
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      rarity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rarity'])!,
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot']),
      goldValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gold_value'])!,
      gemValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gem_value'])!,
      strBonus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}str_bonus'])!,
      dexBonus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dex_bonus'])!,
      intBonus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}int_bonus'])!,
      conBonus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}con_bonus'])!,
      spiBonus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}spi_bonus'])!,
      hpBonus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hp_bonus'])!,
      mpBonus: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}mp_bonus'])!,
      isConsumable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_consumable'])!,
      isStackable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_stackable'])!,
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name'])!,
    );
  }

  @override
  $ItemsTableTable createAlias(String alias) {
    return $ItemsTableTable(attachedDatabase, alias);
  }
}

class ItemsTableData extends DataClass implements Insertable<ItemsTableData> {
  final int id;
  final String name;
  final String description;
  final String type;
  final String rarity;
  final String? slot;
  final int goldValue;
  final int gemValue;
  final int strBonus;
  final int dexBonus;
  final int intBonus;
  final int conBonus;
  final int spiBonus;
  final int hpBonus;
  final int mpBonus;
  final bool isConsumable;
  final bool isStackable;
  final String iconName;
  const ItemsTableData(
      {required this.id,
      required this.name,
      required this.description,
      required this.type,
      required this.rarity,
      this.slot,
      required this.goldValue,
      required this.gemValue,
      required this.strBonus,
      required this.dexBonus,
      required this.intBonus,
      required this.conBonus,
      required this.spiBonus,
      required this.hpBonus,
      required this.mpBonus,
      required this.isConsumable,
      required this.isStackable,
      required this.iconName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    map['rarity'] = Variable<String>(rarity);
    if (!nullToAbsent || slot != null) {
      map['slot'] = Variable<String>(slot);
    }
    map['gold_value'] = Variable<int>(goldValue);
    map['gem_value'] = Variable<int>(gemValue);
    map['str_bonus'] = Variable<int>(strBonus);
    map['dex_bonus'] = Variable<int>(dexBonus);
    map['int_bonus'] = Variable<int>(intBonus);
    map['con_bonus'] = Variable<int>(conBonus);
    map['spi_bonus'] = Variable<int>(spiBonus);
    map['hp_bonus'] = Variable<int>(hpBonus);
    map['mp_bonus'] = Variable<int>(mpBonus);
    map['is_consumable'] = Variable<bool>(isConsumable);
    map['is_stackable'] = Variable<bool>(isStackable);
    map['icon_name'] = Variable<String>(iconName);
    return map;
  }

  ItemsTableCompanion toCompanion(bool nullToAbsent) {
    return ItemsTableCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      rarity: Value(rarity),
      slot: slot == null && nullToAbsent ? const Value.absent() : Value(slot),
      goldValue: Value(goldValue),
      gemValue: Value(gemValue),
      strBonus: Value(strBonus),
      dexBonus: Value(dexBonus),
      intBonus: Value(intBonus),
      conBonus: Value(conBonus),
      spiBonus: Value(spiBonus),
      hpBonus: Value(hpBonus),
      mpBonus: Value(mpBonus),
      isConsumable: Value(isConsumable),
      isStackable: Value(isStackable),
      iconName: Value(iconName),
    );
  }

  factory ItemsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      rarity: serializer.fromJson<String>(json['rarity']),
      slot: serializer.fromJson<String?>(json['slot']),
      goldValue: serializer.fromJson<int>(json['goldValue']),
      gemValue: serializer.fromJson<int>(json['gemValue']),
      strBonus: serializer.fromJson<int>(json['strBonus']),
      dexBonus: serializer.fromJson<int>(json['dexBonus']),
      intBonus: serializer.fromJson<int>(json['intBonus']),
      conBonus: serializer.fromJson<int>(json['conBonus']),
      spiBonus: serializer.fromJson<int>(json['spiBonus']),
      hpBonus: serializer.fromJson<int>(json['hpBonus']),
      mpBonus: serializer.fromJson<int>(json['mpBonus']),
      isConsumable: serializer.fromJson<bool>(json['isConsumable']),
      isStackable: serializer.fromJson<bool>(json['isStackable']),
      iconName: serializer.fromJson<String>(json['iconName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'rarity': serializer.toJson<String>(rarity),
      'slot': serializer.toJson<String?>(slot),
      'goldValue': serializer.toJson<int>(goldValue),
      'gemValue': serializer.toJson<int>(gemValue),
      'strBonus': serializer.toJson<int>(strBonus),
      'dexBonus': serializer.toJson<int>(dexBonus),
      'intBonus': serializer.toJson<int>(intBonus),
      'conBonus': serializer.toJson<int>(conBonus),
      'spiBonus': serializer.toJson<int>(spiBonus),
      'hpBonus': serializer.toJson<int>(hpBonus),
      'mpBonus': serializer.toJson<int>(mpBonus),
      'isConsumable': serializer.toJson<bool>(isConsumable),
      'isStackable': serializer.toJson<bool>(isStackable),
      'iconName': serializer.toJson<String>(iconName),
    };
  }

  ItemsTableData copyWith(
          {int? id,
          String? name,
          String? description,
          String? type,
          String? rarity,
          Value<String?> slot = const Value.absent(),
          int? goldValue,
          int? gemValue,
          int? strBonus,
          int? dexBonus,
          int? intBonus,
          int? conBonus,
          int? spiBonus,
          int? hpBonus,
          int? mpBonus,
          bool? isConsumable,
          bool? isStackable,
          String? iconName}) =>
      ItemsTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        rarity: rarity ?? this.rarity,
        slot: slot.present ? slot.value : this.slot,
        goldValue: goldValue ?? this.goldValue,
        gemValue: gemValue ?? this.gemValue,
        strBonus: strBonus ?? this.strBonus,
        dexBonus: dexBonus ?? this.dexBonus,
        intBonus: intBonus ?? this.intBonus,
        conBonus: conBonus ?? this.conBonus,
        spiBonus: spiBonus ?? this.spiBonus,
        hpBonus: hpBonus ?? this.hpBonus,
        mpBonus: mpBonus ?? this.mpBonus,
        isConsumable: isConsumable ?? this.isConsumable,
        isStackable: isStackable ?? this.isStackable,
        iconName: iconName ?? this.iconName,
      );
  ItemsTableData copyWithCompanion(ItemsTableCompanion data) {
    return ItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      type: data.type.present ? data.type.value : this.type,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      slot: data.slot.present ? data.slot.value : this.slot,
      goldValue: data.goldValue.present ? data.goldValue.value : this.goldValue,
      gemValue: data.gemValue.present ? data.gemValue.value : this.gemValue,
      strBonus: data.strBonus.present ? data.strBonus.value : this.strBonus,
      dexBonus: data.dexBonus.present ? data.dexBonus.value : this.dexBonus,
      intBonus: data.intBonus.present ? data.intBonus.value : this.intBonus,
      conBonus: data.conBonus.present ? data.conBonus.value : this.conBonus,
      spiBonus: data.spiBonus.present ? data.spiBonus.value : this.spiBonus,
      hpBonus: data.hpBonus.present ? data.hpBonus.value : this.hpBonus,
      mpBonus: data.mpBonus.present ? data.mpBonus.value : this.mpBonus,
      isConsumable: data.isConsumable.present
          ? data.isConsumable.value
          : this.isConsumable,
      isStackable:
          data.isStackable.present ? data.isStackable.value : this.isStackable,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('rarity: $rarity, ')
          ..write('slot: $slot, ')
          ..write('goldValue: $goldValue, ')
          ..write('gemValue: $gemValue, ')
          ..write('strBonus: $strBonus, ')
          ..write('dexBonus: $dexBonus, ')
          ..write('intBonus: $intBonus, ')
          ..write('conBonus: $conBonus, ')
          ..write('spiBonus: $spiBonus, ')
          ..write('hpBonus: $hpBonus, ')
          ..write('mpBonus: $mpBonus, ')
          ..write('isConsumable: $isConsumable, ')
          ..write('isStackable: $isStackable, ')
          ..write('iconName: $iconName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      type,
      rarity,
      slot,
      goldValue,
      gemValue,
      strBonus,
      dexBonus,
      intBonus,
      conBonus,
      spiBonus,
      hpBonus,
      mpBonus,
      isConsumable,
      isStackable,
      iconName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.type == this.type &&
          other.rarity == this.rarity &&
          other.slot == this.slot &&
          other.goldValue == this.goldValue &&
          other.gemValue == this.gemValue &&
          other.strBonus == this.strBonus &&
          other.dexBonus == this.dexBonus &&
          other.intBonus == this.intBonus &&
          other.conBonus == this.conBonus &&
          other.spiBonus == this.spiBonus &&
          other.hpBonus == this.hpBonus &&
          other.mpBonus == this.mpBonus &&
          other.isConsumable == this.isConsumable &&
          other.isStackable == this.isStackable &&
          other.iconName == this.iconName);
}

class ItemsTableCompanion extends UpdateCompanion<ItemsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> type;
  final Value<String> rarity;
  final Value<String?> slot;
  final Value<int> goldValue;
  final Value<int> gemValue;
  final Value<int> strBonus;
  final Value<int> dexBonus;
  final Value<int> intBonus;
  final Value<int> conBonus;
  final Value<int> spiBonus;
  final Value<int> hpBonus;
  final Value<int> mpBonus;
  final Value<bool> isConsumable;
  final Value<bool> isStackable;
  final Value<String> iconName;
  const ItemsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.rarity = const Value.absent(),
    this.slot = const Value.absent(),
    this.goldValue = const Value.absent(),
    this.gemValue = const Value.absent(),
    this.strBonus = const Value.absent(),
    this.dexBonus = const Value.absent(),
    this.intBonus = const Value.absent(),
    this.conBonus = const Value.absent(),
    this.spiBonus = const Value.absent(),
    this.hpBonus = const Value.absent(),
    this.mpBonus = const Value.absent(),
    this.isConsumable = const Value.absent(),
    this.isStackable = const Value.absent(),
    this.iconName = const Value.absent(),
  });
  ItemsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required String type,
    this.rarity = const Value.absent(),
    this.slot = const Value.absent(),
    this.goldValue = const Value.absent(),
    this.gemValue = const Value.absent(),
    this.strBonus = const Value.absent(),
    this.dexBonus = const Value.absent(),
    this.intBonus = const Value.absent(),
    this.conBonus = const Value.absent(),
    this.spiBonus = const Value.absent(),
    this.hpBonus = const Value.absent(),
    this.mpBonus = const Value.absent(),
    this.isConsumable = const Value.absent(),
    this.isStackable = const Value.absent(),
    this.iconName = const Value.absent(),
  })  : name = Value(name),
        type = Value(type);
  static Insertable<ItemsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? rarity,
    Expression<String>? slot,
    Expression<int>? goldValue,
    Expression<int>? gemValue,
    Expression<int>? strBonus,
    Expression<int>? dexBonus,
    Expression<int>? intBonus,
    Expression<int>? conBonus,
    Expression<int>? spiBonus,
    Expression<int>? hpBonus,
    Expression<int>? mpBonus,
    Expression<bool>? isConsumable,
    Expression<bool>? isStackable,
    Expression<String>? iconName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (rarity != null) 'rarity': rarity,
      if (slot != null) 'slot': slot,
      if (goldValue != null) 'gold_value': goldValue,
      if (gemValue != null) 'gem_value': gemValue,
      if (strBonus != null) 'str_bonus': strBonus,
      if (dexBonus != null) 'dex_bonus': dexBonus,
      if (intBonus != null) 'int_bonus': intBonus,
      if (conBonus != null) 'con_bonus': conBonus,
      if (spiBonus != null) 'spi_bonus': spiBonus,
      if (hpBonus != null) 'hp_bonus': hpBonus,
      if (mpBonus != null) 'mp_bonus': mpBonus,
      if (isConsumable != null) 'is_consumable': isConsumable,
      if (isStackable != null) 'is_stackable': isStackable,
      if (iconName != null) 'icon_name': iconName,
    });
  }

  ItemsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? description,
      Value<String>? type,
      Value<String>? rarity,
      Value<String?>? slot,
      Value<int>? goldValue,
      Value<int>? gemValue,
      Value<int>? strBonus,
      Value<int>? dexBonus,
      Value<int>? intBonus,
      Value<int>? conBonus,
      Value<int>? spiBonus,
      Value<int>? hpBonus,
      Value<int>? mpBonus,
      Value<bool>? isConsumable,
      Value<bool>? isStackable,
      Value<String>? iconName}) {
    return ItemsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      slot: slot ?? this.slot,
      goldValue: goldValue ?? this.goldValue,
      gemValue: gemValue ?? this.gemValue,
      strBonus: strBonus ?? this.strBonus,
      dexBonus: dexBonus ?? this.dexBonus,
      intBonus: intBonus ?? this.intBonus,
      conBonus: conBonus ?? this.conBonus,
      spiBonus: spiBonus ?? this.spiBonus,
      hpBonus: hpBonus ?? this.hpBonus,
      mpBonus: mpBonus ?? this.mpBonus,
      isConsumable: isConsumable ?? this.isConsumable,
      isStackable: isStackable ?? this.isStackable,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<String>(rarity.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (goldValue.present) {
      map['gold_value'] = Variable<int>(goldValue.value);
    }
    if (gemValue.present) {
      map['gem_value'] = Variable<int>(gemValue.value);
    }
    if (strBonus.present) {
      map['str_bonus'] = Variable<int>(strBonus.value);
    }
    if (dexBonus.present) {
      map['dex_bonus'] = Variable<int>(dexBonus.value);
    }
    if (intBonus.present) {
      map['int_bonus'] = Variable<int>(intBonus.value);
    }
    if (conBonus.present) {
      map['con_bonus'] = Variable<int>(conBonus.value);
    }
    if (spiBonus.present) {
      map['spi_bonus'] = Variable<int>(spiBonus.value);
    }
    if (hpBonus.present) {
      map['hp_bonus'] = Variable<int>(hpBonus.value);
    }
    if (mpBonus.present) {
      map['mp_bonus'] = Variable<int>(mpBonus.value);
    }
    if (isConsumable.present) {
      map['is_consumable'] = Variable<bool>(isConsumable.value);
    }
    if (isStackable.present) {
      map['is_stackable'] = Variable<bool>(isStackable.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('rarity: $rarity, ')
          ..write('slot: $slot, ')
          ..write('goldValue: $goldValue, ')
          ..write('gemValue: $gemValue, ')
          ..write('strBonus: $strBonus, ')
          ..write('dexBonus: $dexBonus, ')
          ..write('intBonus: $intBonus, ')
          ..write('conBonus: $conBonus, ')
          ..write('spiBonus: $spiBonus, ')
          ..write('hpBonus: $hpBonus, ')
          ..write('mpBonus: $mpBonus, ')
          ..write('isConsumable: $isConsumable, ')
          ..write('isStackable: $isStackable, ')
          ..write('iconName: $iconName')
          ..write(')'))
        .toString();
  }
}

class $InventoryTableTable extends InventoryTable
    with TableInfo<$InventoryTableTable, InventoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _isEquippedMeta =
      const VerificationMeta('isEquipped');
  @override
  late final GeneratedColumn<bool> isEquipped = GeneratedColumn<bool>(
      'is_equipped', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_equipped" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _equippedSlotMeta =
      const VerificationMeta('equippedSlot');
  @override
  late final GeneratedColumn<String> equippedSlot = GeneratedColumn<String>(
      'equipped_slot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _acquiredAtMeta =
      const VerificationMeta('acquiredAt');
  @override
  late final GeneratedColumn<DateTime> acquiredAt = GeneratedColumn<DateTime>(
      'acquired_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, playerId, itemId, quantity, isEquipped, equippedSlot, acquiredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('is_equipped')) {
      context.handle(
          _isEquippedMeta,
          isEquipped.isAcceptableOrUnknown(
              data['is_equipped']!, _isEquippedMeta));
    }
    if (data.containsKey('equipped_slot')) {
      context.handle(
          _equippedSlotMeta,
          equippedSlot.isAcceptableOrUnknown(
              data['equipped_slot']!, _equippedSlotMeta));
    }
    if (data.containsKey('acquired_at')) {
      context.handle(
          _acquiredAtMeta,
          acquiredAt.isAcceptableOrUnknown(
              data['acquired_at']!, _acquiredAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      isEquipped: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_equipped'])!,
      equippedSlot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}equipped_slot']),
      acquiredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}acquired_at'])!,
    );
  }

  @override
  $InventoryTableTable createAlias(String alias) {
    return $InventoryTableTable(attachedDatabase, alias);
  }
}

class InventoryTableData extends DataClass
    implements Insertable<InventoryTableData> {
  final int id;
  final int playerId;
  final int itemId;
  final int quantity;
  final bool isEquipped;
  final String? equippedSlot;
  final DateTime acquiredAt;
  const InventoryTableData(
      {required this.id,
      required this.playerId,
      required this.itemId,
      required this.quantity,
      required this.isEquipped,
      this.equippedSlot,
      required this.acquiredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['item_id'] = Variable<int>(itemId);
    map['quantity'] = Variable<int>(quantity);
    map['is_equipped'] = Variable<bool>(isEquipped);
    if (!nullToAbsent || equippedSlot != null) {
      map['equipped_slot'] = Variable<String>(equippedSlot);
    }
    map['acquired_at'] = Variable<DateTime>(acquiredAt);
    return map;
  }

  InventoryTableCompanion toCompanion(bool nullToAbsent) {
    return InventoryTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      itemId: Value(itemId),
      quantity: Value(quantity),
      isEquipped: Value(isEquipped),
      equippedSlot: equippedSlot == null && nullToAbsent
          ? const Value.absent()
          : Value(equippedSlot),
      acquiredAt: Value(acquiredAt),
    );
  }

  factory InventoryTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      itemId: serializer.fromJson<int>(json['itemId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      isEquipped: serializer.fromJson<bool>(json['isEquipped']),
      equippedSlot: serializer.fromJson<String?>(json['equippedSlot']),
      acquiredAt: serializer.fromJson<DateTime>(json['acquiredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'itemId': serializer.toJson<int>(itemId),
      'quantity': serializer.toJson<int>(quantity),
      'isEquipped': serializer.toJson<bool>(isEquipped),
      'equippedSlot': serializer.toJson<String?>(equippedSlot),
      'acquiredAt': serializer.toJson<DateTime>(acquiredAt),
    };
  }

  InventoryTableData copyWith(
          {int? id,
          int? playerId,
          int? itemId,
          int? quantity,
          bool? isEquipped,
          Value<String?> equippedSlot = const Value.absent(),
          DateTime? acquiredAt}) =>
      InventoryTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        itemId: itemId ?? this.itemId,
        quantity: quantity ?? this.quantity,
        isEquipped: isEquipped ?? this.isEquipped,
        equippedSlot:
            equippedSlot.present ? equippedSlot.value : this.equippedSlot,
        acquiredAt: acquiredAt ?? this.acquiredAt,
      );
  InventoryTableData copyWithCompanion(InventoryTableCompanion data) {
    return InventoryTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      isEquipped:
          data.isEquipped.present ? data.isEquipped.value : this.isEquipped,
      equippedSlot: data.equippedSlot.present
          ? data.equippedSlot.value
          : this.equippedSlot,
      acquiredAt:
          data.acquiredAt.present ? data.acquiredAt.value : this.acquiredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('isEquipped: $isEquipped, ')
          ..write('equippedSlot: $equippedSlot, ')
          ..write('acquiredAt: $acquiredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, playerId, itemId, quantity, isEquipped, equippedSlot, acquiredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.itemId == this.itemId &&
          other.quantity == this.quantity &&
          other.isEquipped == this.isEquipped &&
          other.equippedSlot == this.equippedSlot &&
          other.acquiredAt == this.acquiredAt);
}

class InventoryTableCompanion extends UpdateCompanion<InventoryTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<int> itemId;
  final Value<int> quantity;
  final Value<bool> isEquipped;
  final Value<String?> equippedSlot;
  final Value<DateTime> acquiredAt;
  const InventoryTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.isEquipped = const Value.absent(),
    this.equippedSlot = const Value.absent(),
    this.acquiredAt = const Value.absent(),
  });
  InventoryTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required int itemId,
    this.quantity = const Value.absent(),
    this.isEquipped = const Value.absent(),
    this.equippedSlot = const Value.absent(),
    this.acquiredAt = const Value.absent(),
  })  : playerId = Value(playerId),
        itemId = Value(itemId);
  static Insertable<InventoryTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<int>? itemId,
    Expression<int>? quantity,
    Expression<bool>? isEquipped,
    Expression<String>? equippedSlot,
    Expression<DateTime>? acquiredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (itemId != null) 'item_id': itemId,
      if (quantity != null) 'quantity': quantity,
      if (isEquipped != null) 'is_equipped': isEquipped,
      if (equippedSlot != null) 'equipped_slot': equippedSlot,
      if (acquiredAt != null) 'acquired_at': acquiredAt,
    });
  }

  InventoryTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<int>? itemId,
      Value<int>? quantity,
      Value<bool>? isEquipped,
      Value<String?>? equippedSlot,
      Value<DateTime>? acquiredAt}) {
    return InventoryTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      isEquipped: isEquipped ?? this.isEquipped,
      equippedSlot: equippedSlot ?? this.equippedSlot,
      acquiredAt: acquiredAt ?? this.acquiredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (isEquipped.present) {
      map['is_equipped'] = Variable<bool>(isEquipped.value);
    }
    if (equippedSlot.present) {
      map['equipped_slot'] = Variable<String>(equippedSlot.value);
    }
    if (acquiredAt.present) {
      map['acquired_at'] = Variable<DateTime>(acquiredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('isEquipped: $isEquipped, ')
          ..write('equippedSlot: $equippedSlot, ')
          ..write('acquiredAt: $acquiredAt')
          ..write(')'))
        .toString();
  }
}

class $ShopItemsTableTable extends ShopItemsTable
    with TableInfo<$ShopItemsTableTable, ShopItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('gold'));
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
      'price', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isAvailableMeta =
      const VerificationMeta('isAvailable');
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
      'is_available', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_available" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _requiredLevelMeta =
      const VerificationMeta('requiredLevel');
  @override
  late final GeneratedColumn<int> requiredLevel = GeneratedColumn<int>(
      'required_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns =>
      [id, itemId, currency, price, isAvailable, requiredLevel];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shop_items';
  @override
  VerificationContext validateIntegrity(Insertable<ShopItemsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('is_available')) {
      context.handle(
          _isAvailableMeta,
          isAvailable.isAcceptableOrUnknown(
              data['is_available']!, _isAvailableMeta));
    }
    if (data.containsKey('required_level')) {
      context.handle(
          _requiredLevelMeta,
          requiredLevel.isAcceptableOrUnknown(
              data['required_level']!, _requiredLevelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShopItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShopItemsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price'])!,
      isAvailable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_available'])!,
      requiredLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}required_level'])!,
    );
  }

  @override
  $ShopItemsTableTable createAlias(String alias) {
    return $ShopItemsTableTable(attachedDatabase, alias);
  }
}

class ShopItemsTableData extends DataClass
    implements Insertable<ShopItemsTableData> {
  final int id;
  final int itemId;
  final String currency;
  final int price;
  final bool isAvailable;
  final int requiredLevel;
  const ShopItemsTableData(
      {required this.id,
      required this.itemId,
      required this.currency,
      required this.price,
      required this.isAvailable,
      required this.requiredLevel});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['currency'] = Variable<String>(currency);
    map['price'] = Variable<int>(price);
    map['is_available'] = Variable<bool>(isAvailable);
    map['required_level'] = Variable<int>(requiredLevel);
    return map;
  }

  ShopItemsTableCompanion toCompanion(bool nullToAbsent) {
    return ShopItemsTableCompanion(
      id: Value(id),
      itemId: Value(itemId),
      currency: Value(currency),
      price: Value(price),
      isAvailable: Value(isAvailable),
      requiredLevel: Value(requiredLevel),
    );
  }

  factory ShopItemsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShopItemsTableData(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      currency: serializer.fromJson<String>(json['currency']),
      price: serializer.fromJson<int>(json['price']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      requiredLevel: serializer.fromJson<int>(json['requiredLevel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'currency': serializer.toJson<String>(currency),
      'price': serializer.toJson<int>(price),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'requiredLevel': serializer.toJson<int>(requiredLevel),
    };
  }

  ShopItemsTableData copyWith(
          {int? id,
          int? itemId,
          String? currency,
          int? price,
          bool? isAvailable,
          int? requiredLevel}) =>
      ShopItemsTableData(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        currency: currency ?? this.currency,
        price: price ?? this.price,
        isAvailable: isAvailable ?? this.isAvailable,
        requiredLevel: requiredLevel ?? this.requiredLevel,
      );
  ShopItemsTableData copyWithCompanion(ShopItemsTableCompanion data) {
    return ShopItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      currency: data.currency.present ? data.currency.value : this.currency,
      price: data.price.present ? data.price.value : this.price,
      isAvailable:
          data.isAvailable.present ? data.isAvailable.value : this.isAvailable,
      requiredLevel: data.requiredLevel.present
          ? data.requiredLevel.value
          : this.requiredLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShopItemsTableData(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('currency: $currency, ')
          ..write('price: $price, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('requiredLevel: $requiredLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, itemId, currency, price, isAvailable, requiredLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShopItemsTableData &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.currency == this.currency &&
          other.price == this.price &&
          other.isAvailable == this.isAvailable &&
          other.requiredLevel == this.requiredLevel);
}

class ShopItemsTableCompanion extends UpdateCompanion<ShopItemsTableData> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> currency;
  final Value<int> price;
  final Value<bool> isAvailable;
  final Value<int> requiredLevel;
  const ShopItemsTableCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.currency = const Value.absent(),
    this.price = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.requiredLevel = const Value.absent(),
  });
  ShopItemsTableCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    this.currency = const Value.absent(),
    required int price,
    this.isAvailable = const Value.absent(),
    this.requiredLevel = const Value.absent(),
  })  : itemId = Value(itemId),
        price = Value(price);
  static Insertable<ShopItemsTableData> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? currency,
    Expression<int>? price,
    Expression<bool>? isAvailable,
    Expression<int>? requiredLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (currency != null) 'currency': currency,
      if (price != null) 'price': price,
      if (isAvailable != null) 'is_available': isAvailable,
      if (requiredLevel != null) 'required_level': requiredLevel,
    });
  }

  ShopItemsTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? itemId,
      Value<String>? currency,
      Value<int>? price,
      Value<bool>? isAvailable,
      Value<int>? requiredLevel}) {
    return ShopItemsTableCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      currency: currency ?? this.currency,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      requiredLevel: requiredLevel ?? this.requiredLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (requiredLevel.present) {
      map['required_level'] = Variable<int>(requiredLevel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('currency: $currency, ')
          ..write('price: $price, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('requiredLevel: $requiredLevel')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTableTable extends AchievementsTable
    with TableInfo<$AchievementsTableTable, AchievementsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconNameMeta =
      const VerificationMeta('iconName');
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
      'icon_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('star'));
  static const VerificationMeta _xpRewardMeta =
      const VerificationMeta('xpReward');
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
      'xp_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(50));
  static const VerificationMeta _goldRewardMeta =
      const VerificationMeta('goldReward');
  @override
  late final GeneratedColumn<int> goldReward = GeneratedColumn<int>(
      'gold_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(25));
  static const VerificationMeta _gemRewardMeta =
      const VerificationMeta('gemReward');
  @override
  late final GeneratedColumn<int> gemReward = GeneratedColumn<int>(
      'gem_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isSecretMeta =
      const VerificationMeta('isSecret');
  @override
  late final GeneratedColumn<bool> isSecret = GeneratedColumn<bool>(
      'is_secret', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_secret" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<String> rarity = GeneratedColumn<String>(
      'rarity', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('common'));
  static const VerificationMeta _titleRewardMeta =
      const VerificationMeta('titleReward');
  @override
  late final GeneratedColumn<String> titleReward = GeneratedColumn<String>(
      'title_reward', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _category2Meta =
      const VerificationMeta('category2');
  @override
  late final GeneratedColumn<String> category2 = GeneratedColumn<String>(
      'category2', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        key,
        title,
        description,
        category,
        iconName,
        xpReward,
        goldReward,
        gemReward,
        isSecret,
        rarity,
        titleReward,
        category2
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
      Insertable<AchievementsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(_iconNameMeta,
          iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta));
    }
    if (data.containsKey('xp_reward')) {
      context.handle(_xpRewardMeta,
          xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta));
    }
    if (data.containsKey('gold_reward')) {
      context.handle(
          _goldRewardMeta,
          goldReward.isAcceptableOrUnknown(
              data['gold_reward']!, _goldRewardMeta));
    }
    if (data.containsKey('gem_reward')) {
      context.handle(_gemRewardMeta,
          gemReward.isAcceptableOrUnknown(data['gem_reward']!, _gemRewardMeta));
    }
    if (data.containsKey('is_secret')) {
      context.handle(_isSecretMeta,
          isSecret.isAcceptableOrUnknown(data['is_secret']!, _isSecretMeta));
    }
    if (data.containsKey('rarity')) {
      context.handle(_rarityMeta,
          rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta));
    }
    if (data.containsKey('title_reward')) {
      context.handle(
          _titleRewardMeta,
          titleReward.isAcceptableOrUnknown(
              data['title_reward']!, _titleRewardMeta));
    }
    if (data.containsKey('category2')) {
      context.handle(_category2Meta,
          category2.isAcceptableOrUnknown(data['category2']!, _category2Meta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AchievementsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AchievementsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      iconName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_name'])!,
      xpReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_reward'])!,
      goldReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gold_reward'])!,
      gemReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gem_reward'])!,
      isSecret: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_secret'])!,
      rarity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rarity'])!,
      titleReward: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_reward']),
      category2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category2']),
    );
  }

  @override
  $AchievementsTableTable createAlias(String alias) {
    return $AchievementsTableTable(attachedDatabase, alias);
  }
}

class AchievementsTableData extends DataClass
    implements Insertable<AchievementsTableData> {
  final int id;
  final String key;
  final String title;
  final String description;
  final String category;
  final String iconName;
  final int xpReward;
  final int goldReward;
  final int gemReward;
  final bool isSecret;
  final String rarity;
  final String? titleReward;
  final String? category2;
  const AchievementsTableData(
      {required this.id,
      required this.key,
      required this.title,
      required this.description,
      required this.category,
      required this.iconName,
      required this.xpReward,
      required this.goldReward,
      required this.gemReward,
      required this.isSecret,
      required this.rarity,
      this.titleReward,
      this.category2});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['icon_name'] = Variable<String>(iconName);
    map['xp_reward'] = Variable<int>(xpReward);
    map['gold_reward'] = Variable<int>(goldReward);
    map['gem_reward'] = Variable<int>(gemReward);
    map['is_secret'] = Variable<bool>(isSecret);
    map['rarity'] = Variable<String>(rarity);
    if (!nullToAbsent || titleReward != null) {
      map['title_reward'] = Variable<String>(titleReward);
    }
    if (!nullToAbsent || category2 != null) {
      map['category2'] = Variable<String>(category2);
    }
    return map;
  }

  AchievementsTableCompanion toCompanion(bool nullToAbsent) {
    return AchievementsTableCompanion(
      id: Value(id),
      key: Value(key),
      title: Value(title),
      description: Value(description),
      category: Value(category),
      iconName: Value(iconName),
      xpReward: Value(xpReward),
      goldReward: Value(goldReward),
      gemReward: Value(gemReward),
      isSecret: Value(isSecret),
      rarity: Value(rarity),
      titleReward: titleReward == null && nullToAbsent
          ? const Value.absent()
          : Value(titleReward),
      category2: category2 == null && nullToAbsent
          ? const Value.absent()
          : Value(category2),
    );
  }

  factory AchievementsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AchievementsTableData(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      iconName: serializer.fromJson<String>(json['iconName']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
      goldReward: serializer.fromJson<int>(json['goldReward']),
      gemReward: serializer.fromJson<int>(json['gemReward']),
      isSecret: serializer.fromJson<bool>(json['isSecret']),
      rarity: serializer.fromJson<String>(json['rarity']),
      titleReward: serializer.fromJson<String?>(json['titleReward']),
      category2: serializer.fromJson<String?>(json['category2']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'iconName': serializer.toJson<String>(iconName),
      'xpReward': serializer.toJson<int>(xpReward),
      'goldReward': serializer.toJson<int>(goldReward),
      'gemReward': serializer.toJson<int>(gemReward),
      'isSecret': serializer.toJson<bool>(isSecret),
      'rarity': serializer.toJson<String>(rarity),
      'titleReward': serializer.toJson<String?>(titleReward),
      'category2': serializer.toJson<String?>(category2),
    };
  }

  AchievementsTableData copyWith(
          {int? id,
          String? key,
          String? title,
          String? description,
          String? category,
          String? iconName,
          int? xpReward,
          int? goldReward,
          int? gemReward,
          bool? isSecret,
          String? rarity,
          Value<String?> titleReward = const Value.absent(),
          Value<String?> category2 = const Value.absent()}) =>
      AchievementsTableData(
        id: id ?? this.id,
        key: key ?? this.key,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        iconName: iconName ?? this.iconName,
        xpReward: xpReward ?? this.xpReward,
        goldReward: goldReward ?? this.goldReward,
        gemReward: gemReward ?? this.gemReward,
        isSecret: isSecret ?? this.isSecret,
        rarity: rarity ?? this.rarity,
        titleReward: titleReward.present ? titleReward.value : this.titleReward,
        category2: category2.present ? category2.value : this.category2,
      );
  AchievementsTableData copyWithCompanion(AchievementsTableCompanion data) {
    return AchievementsTableData(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      category: data.category.present ? data.category.value : this.category,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
      goldReward:
          data.goldReward.present ? data.goldReward.value : this.goldReward,
      gemReward: data.gemReward.present ? data.gemReward.value : this.gemReward,
      isSecret: data.isSecret.present ? data.isSecret.value : this.isSecret,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      titleReward:
          data.titleReward.present ? data.titleReward.value : this.titleReward,
      category2: data.category2.present ? data.category2.value : this.category2,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsTableData(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('iconName: $iconName, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('gemReward: $gemReward, ')
          ..write('isSecret: $isSecret, ')
          ..write('rarity: $rarity, ')
          ..write('titleReward: $titleReward, ')
          ..write('category2: $category2')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      key,
      title,
      description,
      category,
      iconName,
      xpReward,
      goldReward,
      gemReward,
      isSecret,
      rarity,
      titleReward,
      category2);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AchievementsTableData &&
          other.id == this.id &&
          other.key == this.key &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.iconName == this.iconName &&
          other.xpReward == this.xpReward &&
          other.goldReward == this.goldReward &&
          other.gemReward == this.gemReward &&
          other.isSecret == this.isSecret &&
          other.rarity == this.rarity &&
          other.titleReward == this.titleReward &&
          other.category2 == this.category2);
}

class AchievementsTableCompanion
    extends UpdateCompanion<AchievementsTableData> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> title;
  final Value<String> description;
  final Value<String> category;
  final Value<String> iconName;
  final Value<int> xpReward;
  final Value<int> goldReward;
  final Value<int> gemReward;
  final Value<bool> isSecret;
  final Value<String> rarity;
  final Value<String?> titleReward;
  final Value<String?> category2;
  const AchievementsTableCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.iconName = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.goldReward = const Value.absent(),
    this.gemReward = const Value.absent(),
    this.isSecret = const Value.absent(),
    this.rarity = const Value.absent(),
    this.titleReward = const Value.absent(),
    this.category2 = const Value.absent(),
  });
  AchievementsTableCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String title,
    required String description,
    required String category,
    this.iconName = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.goldReward = const Value.absent(),
    this.gemReward = const Value.absent(),
    this.isSecret = const Value.absent(),
    this.rarity = const Value.absent(),
    this.titleReward = const Value.absent(),
    this.category2 = const Value.absent(),
  })  : key = Value(key),
        title = Value(title),
        description = Value(description),
        category = Value(category);
  static Insertable<AchievementsTableData> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? iconName,
    Expression<int>? xpReward,
    Expression<int>? goldReward,
    Expression<int>? gemReward,
    Expression<bool>? isSecret,
    Expression<String>? rarity,
    Expression<String>? titleReward,
    Expression<String>? category2,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (iconName != null) 'icon_name': iconName,
      if (xpReward != null) 'xp_reward': xpReward,
      if (goldReward != null) 'gold_reward': goldReward,
      if (gemReward != null) 'gem_reward': gemReward,
      if (isSecret != null) 'is_secret': isSecret,
      if (rarity != null) 'rarity': rarity,
      if (titleReward != null) 'title_reward': titleReward,
      if (category2 != null) 'category2': category2,
    });
  }

  AchievementsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? key,
      Value<String>? title,
      Value<String>? description,
      Value<String>? category,
      Value<String>? iconName,
      Value<int>? xpReward,
      Value<int>? goldReward,
      Value<int>? gemReward,
      Value<bool>? isSecret,
      Value<String>? rarity,
      Value<String?>? titleReward,
      Value<String?>? category2}) {
    return AchievementsTableCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      xpReward: xpReward ?? this.xpReward,
      goldReward: goldReward ?? this.goldReward,
      gemReward: gemReward ?? this.gemReward,
      isSecret: isSecret ?? this.isSecret,
      rarity: rarity ?? this.rarity,
      titleReward: titleReward ?? this.titleReward,
      category2: category2 ?? this.category2,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    if (goldReward.present) {
      map['gold_reward'] = Variable<int>(goldReward.value);
    }
    if (gemReward.present) {
      map['gem_reward'] = Variable<int>(gemReward.value);
    }
    if (isSecret.present) {
      map['is_secret'] = Variable<bool>(isSecret.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<String>(rarity.value);
    }
    if (titleReward.present) {
      map['title_reward'] = Variable<String>(titleReward.value);
    }
    if (category2.present) {
      map['category2'] = Variable<String>(category2.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsTableCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('iconName: $iconName, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('gemReward: $gemReward, ')
          ..write('isSecret: $isSecret, ')
          ..write('rarity: $rarity, ')
          ..write('titleReward: $titleReward, ')
          ..write('category2: $category2')
          ..write(')'))
        .toString();
  }
}

class $PlayerAchievementsTableTable extends PlayerAchievementsTable
    with TableInfo<$PlayerAchievementsTableTable, PlayerAchievementsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerAchievementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _achievementKeyMeta =
      const VerificationMeta('achievementKey');
  @override
  late final GeneratedColumn<String> achievementKey = GeneratedColumn<String>(
      'achievement_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unlockedAtMeta =
      const VerificationMeta('unlockedAt');
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
      'unlocked_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _collectedAtMeta =
      const VerificationMeta('collectedAt');
  @override
  late final GeneratedColumn<DateTime> collectedAt = GeneratedColumn<DateTime>(
      'collected_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, playerId, achievementKey, unlockedAt, collectedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_achievements';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlayerAchievementsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('achievement_key')) {
      context.handle(
          _achievementKeyMeta,
          achievementKey.isAcceptableOrUnknown(
              data['achievement_key']!, _achievementKeyMeta));
    } else if (isInserting) {
      context.missing(_achievementKeyMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
          _unlockedAtMeta,
          unlockedAt.isAcceptableOrUnknown(
              data['unlocked_at']!, _unlockedAtMeta));
    }
    if (data.containsKey('collected_at')) {
      context.handle(
          _collectedAtMeta,
          collectedAt.isAcceptableOrUnknown(
              data['collected_at']!, _collectedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerAchievementsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerAchievementsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      achievementKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}achievement_key'])!,
      unlockedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}unlocked_at'])!,
      collectedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}collected_at']),
    );
  }

  @override
  $PlayerAchievementsTableTable createAlias(String alias) {
    return $PlayerAchievementsTableTable(attachedDatabase, alias);
  }
}

class PlayerAchievementsTableData extends DataClass
    implements Insertable<PlayerAchievementsTableData> {
  final int id;
  final int playerId;
  final String achievementKey;
  final DateTime unlockedAt;
  final DateTime? collectedAt;
  const PlayerAchievementsTableData(
      {required this.id,
      required this.playerId,
      required this.achievementKey,
      required this.unlockedAt,
      this.collectedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['achievement_key'] = Variable<String>(achievementKey);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    if (!nullToAbsent || collectedAt != null) {
      map['collected_at'] = Variable<DateTime>(collectedAt);
    }
    return map;
  }

  PlayerAchievementsTableCompanion toCompanion(bool nullToAbsent) {
    return PlayerAchievementsTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      achievementKey: Value(achievementKey),
      unlockedAt: Value(unlockedAt),
      collectedAt: collectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(collectedAt),
    );
  }

  factory PlayerAchievementsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerAchievementsTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      achievementKey: serializer.fromJson<String>(json['achievementKey']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
      collectedAt: serializer.fromJson<DateTime?>(json['collectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'achievementKey': serializer.toJson<String>(achievementKey),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
      'collectedAt': serializer.toJson<DateTime?>(collectedAt),
    };
  }

  PlayerAchievementsTableData copyWith(
          {int? id,
          int? playerId,
          String? achievementKey,
          DateTime? unlockedAt,
          Value<DateTime?> collectedAt = const Value.absent()}) =>
      PlayerAchievementsTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        achievementKey: achievementKey ?? this.achievementKey,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        collectedAt: collectedAt.present ? collectedAt.value : this.collectedAt,
      );
  PlayerAchievementsTableData copyWithCompanion(
      PlayerAchievementsTableCompanion data) {
    return PlayerAchievementsTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      achievementKey: data.achievementKey.present
          ? data.achievementKey.value
          : this.achievementKey,
      unlockedAt:
          data.unlockedAt.present ? data.unlockedAt.value : this.unlockedAt,
      collectedAt:
          data.collectedAt.present ? data.collectedAt.value : this.collectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerAchievementsTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('achievementKey: $achievementKey, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('collectedAt: $collectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playerId, achievementKey, unlockedAt, collectedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerAchievementsTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.achievementKey == this.achievementKey &&
          other.unlockedAt == this.unlockedAt &&
          other.collectedAt == this.collectedAt);
}

class PlayerAchievementsTableCompanion
    extends UpdateCompanion<PlayerAchievementsTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> achievementKey;
  final Value<DateTime> unlockedAt;
  final Value<DateTime?> collectedAt;
  const PlayerAchievementsTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.achievementKey = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.collectedAt = const Value.absent(),
  });
  PlayerAchievementsTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required String achievementKey,
    this.unlockedAt = const Value.absent(),
    this.collectedAt = const Value.absent(),
  })  : playerId = Value(playerId),
        achievementKey = Value(achievementKey);
  static Insertable<PlayerAchievementsTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? achievementKey,
    Expression<DateTime>? unlockedAt,
    Expression<DateTime>? collectedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (achievementKey != null) 'achievement_key': achievementKey,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (collectedAt != null) 'collected_at': collectedAt,
    });
  }

  PlayerAchievementsTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<String>? achievementKey,
      Value<DateTime>? unlockedAt,
      Value<DateTime?>? collectedAt}) {
    return PlayerAchievementsTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      achievementKey: achievementKey ?? this.achievementKey,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      collectedAt: collectedAt ?? this.collectedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (achievementKey.present) {
      map['achievement_key'] = Variable<String>(achievementKey.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (collectedAt.present) {
      map['collected_at'] = Variable<DateTime>(collectedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerAchievementsTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('achievementKey: $achievementKey, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('collectedAt: $collectedAt')
          ..write(')'))
        .toString();
  }
}

class $GuildStatusTableTable extends GuildStatusTable
    with TableInfo<$GuildStatusTableTable, GuildStatusTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuildStatusTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _guildRankMeta =
      const VerificationMeta('guildRank');
  @override
  late final GeneratedColumn<String> guildRank = GeneratedColumn<String>(
      'guild_rank', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _guildReputationMeta =
      const VerificationMeta('guildReputation');
  @override
  late final GeneratedColumn<int> guildReputation = GeneratedColumn<int>(
      'guild_reputation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _collarLevelMeta =
      const VerificationMeta('collarLevel');
  @override
  late final GeneratedColumn<int> collarLevel = GeneratedColumn<int>(
      'collar_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalGoldSpentMeta =
      const VerificationMeta('totalGoldSpent');
  @override
  late final GeneratedColumn<int> totalGoldSpent = GeneratedColumn<int>(
      'total_gold_spent', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _joinedAtMeta =
      const VerificationMeta('joinedAt');
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
      'joined_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _ascensionCooldownMeta =
      const VerificationMeta('ascensionCooldown');
  @override
  late final GeneratedColumn<DateTime> ascensionCooldown =
      GeneratedColumn<DateTime>('ascension_cooldown', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playerId,
        guildRank,
        guildReputation,
        collarLevel,
        totalGoldSpent,
        joinedAt,
        ascensionCooldown
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guild_status';
  @override
  VerificationContext validateIntegrity(
      Insertable<GuildStatusTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('guild_rank')) {
      context.handle(_guildRankMeta,
          guildRank.isAcceptableOrUnknown(data['guild_rank']!, _guildRankMeta));
    }
    if (data.containsKey('guild_reputation')) {
      context.handle(
          _guildReputationMeta,
          guildReputation.isAcceptableOrUnknown(
              data['guild_reputation']!, _guildReputationMeta));
    }
    if (data.containsKey('collar_level')) {
      context.handle(
          _collarLevelMeta,
          collarLevel.isAcceptableOrUnknown(
              data['collar_level']!, _collarLevelMeta));
    }
    if (data.containsKey('total_gold_spent')) {
      context.handle(
          _totalGoldSpentMeta,
          totalGoldSpent.isAcceptableOrUnknown(
              data['total_gold_spent']!, _totalGoldSpentMeta));
    }
    if (data.containsKey('joined_at')) {
      context.handle(_joinedAtMeta,
          joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta));
    }
    if (data.containsKey('ascension_cooldown')) {
      context.handle(
          _ascensionCooldownMeta,
          ascensionCooldown.isAcceptableOrUnknown(
              data['ascension_cooldown']!, _ascensionCooldownMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GuildStatusTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GuildStatusTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      guildRank: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}guild_rank'])!,
      guildReputation: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}guild_reputation'])!,
      collarLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}collar_level'])!,
      totalGoldSpent: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_gold_spent'])!,
      joinedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}joined_at']),
      ascensionCooldown: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}ascension_cooldown']),
    );
  }

  @override
  $GuildStatusTableTable createAlias(String alias) {
    return $GuildStatusTableTable(attachedDatabase, alias);
  }
}

class GuildStatusTableData extends DataClass
    implements Insertable<GuildStatusTableData> {
  final int id;
  final int playerId;
  final String guildRank;
  final int guildReputation;
  final int collarLevel;
  final int totalGoldSpent;
  final DateTime? joinedAt;
  final DateTime? ascensionCooldown;
  const GuildStatusTableData(
      {required this.id,
      required this.playerId,
      required this.guildRank,
      required this.guildReputation,
      required this.collarLevel,
      required this.totalGoldSpent,
      this.joinedAt,
      this.ascensionCooldown});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['guild_rank'] = Variable<String>(guildRank);
    map['guild_reputation'] = Variable<int>(guildReputation);
    map['collar_level'] = Variable<int>(collarLevel);
    map['total_gold_spent'] = Variable<int>(totalGoldSpent);
    if (!nullToAbsent || joinedAt != null) {
      map['joined_at'] = Variable<DateTime>(joinedAt);
    }
    if (!nullToAbsent || ascensionCooldown != null) {
      map['ascension_cooldown'] = Variable<DateTime>(ascensionCooldown);
    }
    return map;
  }

  GuildStatusTableCompanion toCompanion(bool nullToAbsent) {
    return GuildStatusTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      guildRank: Value(guildRank),
      guildReputation: Value(guildReputation),
      collarLevel: Value(collarLevel),
      totalGoldSpent: Value(totalGoldSpent),
      joinedAt: joinedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(joinedAt),
      ascensionCooldown: ascensionCooldown == null && nullToAbsent
          ? const Value.absent()
          : Value(ascensionCooldown),
    );
  }

  factory GuildStatusTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GuildStatusTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      guildRank: serializer.fromJson<String>(json['guildRank']),
      guildReputation: serializer.fromJson<int>(json['guildReputation']),
      collarLevel: serializer.fromJson<int>(json['collarLevel']),
      totalGoldSpent: serializer.fromJson<int>(json['totalGoldSpent']),
      joinedAt: serializer.fromJson<DateTime?>(json['joinedAt']),
      ascensionCooldown:
          serializer.fromJson<DateTime?>(json['ascensionCooldown']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'guildRank': serializer.toJson<String>(guildRank),
      'guildReputation': serializer.toJson<int>(guildReputation),
      'collarLevel': serializer.toJson<int>(collarLevel),
      'totalGoldSpent': serializer.toJson<int>(totalGoldSpent),
      'joinedAt': serializer.toJson<DateTime?>(joinedAt),
      'ascensionCooldown': serializer.toJson<DateTime?>(ascensionCooldown),
    };
  }

  GuildStatusTableData copyWith(
          {int? id,
          int? playerId,
          String? guildRank,
          int? guildReputation,
          int? collarLevel,
          int? totalGoldSpent,
          Value<DateTime?> joinedAt = const Value.absent(),
          Value<DateTime?> ascensionCooldown = const Value.absent()}) =>
      GuildStatusTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        guildRank: guildRank ?? this.guildRank,
        guildReputation: guildReputation ?? this.guildReputation,
        collarLevel: collarLevel ?? this.collarLevel,
        totalGoldSpent: totalGoldSpent ?? this.totalGoldSpent,
        joinedAt: joinedAt.present ? joinedAt.value : this.joinedAt,
        ascensionCooldown: ascensionCooldown.present
            ? ascensionCooldown.value
            : this.ascensionCooldown,
      );
  GuildStatusTableData copyWithCompanion(GuildStatusTableCompanion data) {
    return GuildStatusTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      guildRank: data.guildRank.present ? data.guildRank.value : this.guildRank,
      guildReputation: data.guildReputation.present
          ? data.guildReputation.value
          : this.guildReputation,
      collarLevel:
          data.collarLevel.present ? data.collarLevel.value : this.collarLevel,
      totalGoldSpent: data.totalGoldSpent.present
          ? data.totalGoldSpent.value
          : this.totalGoldSpent,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      ascensionCooldown: data.ascensionCooldown.present
          ? data.ascensionCooldown.value
          : this.ascensionCooldown,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GuildStatusTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('guildRank: $guildRank, ')
          ..write('guildReputation: $guildReputation, ')
          ..write('collarLevel: $collarLevel, ')
          ..write('totalGoldSpent: $totalGoldSpent, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('ascensionCooldown: $ascensionCooldown')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, playerId, guildRank, guildReputation,
      collarLevel, totalGoldSpent, joinedAt, ascensionCooldown);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GuildStatusTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.guildRank == this.guildRank &&
          other.guildReputation == this.guildReputation &&
          other.collarLevel == this.collarLevel &&
          other.totalGoldSpent == this.totalGoldSpent &&
          other.joinedAt == this.joinedAt &&
          other.ascensionCooldown == this.ascensionCooldown);
}

class GuildStatusTableCompanion extends UpdateCompanion<GuildStatusTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> guildRank;
  final Value<int> guildReputation;
  final Value<int> collarLevel;
  final Value<int> totalGoldSpent;
  final Value<DateTime?> joinedAt;
  final Value<DateTime?> ascensionCooldown;
  const GuildStatusTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.guildRank = const Value.absent(),
    this.guildReputation = const Value.absent(),
    this.collarLevel = const Value.absent(),
    this.totalGoldSpent = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.ascensionCooldown = const Value.absent(),
  });
  GuildStatusTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    this.guildRank = const Value.absent(),
    this.guildReputation = const Value.absent(),
    this.collarLevel = const Value.absent(),
    this.totalGoldSpent = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.ascensionCooldown = const Value.absent(),
  }) : playerId = Value(playerId);
  static Insertable<GuildStatusTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? guildRank,
    Expression<int>? guildReputation,
    Expression<int>? collarLevel,
    Expression<int>? totalGoldSpent,
    Expression<DateTime>? joinedAt,
    Expression<DateTime>? ascensionCooldown,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (guildRank != null) 'guild_rank': guildRank,
      if (guildReputation != null) 'guild_reputation': guildReputation,
      if (collarLevel != null) 'collar_level': collarLevel,
      if (totalGoldSpent != null) 'total_gold_spent': totalGoldSpent,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (ascensionCooldown != null) 'ascension_cooldown': ascensionCooldown,
    });
  }

  GuildStatusTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<String>? guildRank,
      Value<int>? guildReputation,
      Value<int>? collarLevel,
      Value<int>? totalGoldSpent,
      Value<DateTime?>? joinedAt,
      Value<DateTime?>? ascensionCooldown}) {
    return GuildStatusTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      guildRank: guildRank ?? this.guildRank,
      guildReputation: guildReputation ?? this.guildReputation,
      collarLevel: collarLevel ?? this.collarLevel,
      totalGoldSpent: totalGoldSpent ?? this.totalGoldSpent,
      joinedAt: joinedAt ?? this.joinedAt,
      ascensionCooldown: ascensionCooldown ?? this.ascensionCooldown,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (guildRank.present) {
      map['guild_rank'] = Variable<String>(guildRank.value);
    }
    if (guildReputation.present) {
      map['guild_reputation'] = Variable<int>(guildReputation.value);
    }
    if (collarLevel.present) {
      map['collar_level'] = Variable<int>(collarLevel.value);
    }
    if (totalGoldSpent.present) {
      map['total_gold_spent'] = Variable<int>(totalGoldSpent.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (ascensionCooldown.present) {
      map['ascension_cooldown'] = Variable<DateTime>(ascensionCooldown.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuildStatusTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('guildRank: $guildRank, ')
          ..write('guildReputation: $guildReputation, ')
          ..write('collarLevel: $collarLevel, ')
          ..write('totalGoldSpent: $totalGoldSpent, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('ascensionCooldown: $ascensionCooldown')
          ..write(')'))
        .toString();
  }
}

class $NpcReputationTableTable extends NpcReputationTable
    with TableInfo<$NpcReputationTableTable, NpcReputationTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NpcReputationTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _npcIdMeta = const VerificationMeta('npcId');
  @override
  late final GeneratedColumn<String> npcId = GeneratedColumn<String>(
      'npc_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reputationMeta =
      const VerificationMeta('reputation');
  @override
  late final GeneratedColumn<int> reputation = GeneratedColumn<int>(
      'reputation', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(50));
  static const VerificationMeta _lastGainAtMeta =
      const VerificationMeta('lastGainAt');
  @override
  late final GeneratedColumn<DateTime> lastGainAt = GeneratedColumn<DateTime>(
      'last_gain_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _dailyGainedMeta =
      const VerificationMeta('dailyGained');
  @override
  late final GeneratedColumn<int> dailyGained = GeneratedColumn<int>(
      'daily_gained', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, playerId, npcId, reputation, lastGainAt, dailyGained];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'npc_reputation';
  @override
  VerificationContext validateIntegrity(
      Insertable<NpcReputationTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('npc_id')) {
      context.handle(
          _npcIdMeta, npcId.isAcceptableOrUnknown(data['npc_id']!, _npcIdMeta));
    } else if (isInserting) {
      context.missing(_npcIdMeta);
    }
    if (data.containsKey('reputation')) {
      context.handle(
          _reputationMeta,
          reputation.isAcceptableOrUnknown(
              data['reputation']!, _reputationMeta));
    }
    if (data.containsKey('last_gain_at')) {
      context.handle(
          _lastGainAtMeta,
          lastGainAt.isAcceptableOrUnknown(
              data['last_gain_at']!, _lastGainAtMeta));
    }
    if (data.containsKey('daily_gained')) {
      context.handle(
          _dailyGainedMeta,
          dailyGained.isAcceptableOrUnknown(
              data['daily_gained']!, _dailyGainedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NpcReputationTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NpcReputationTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      npcId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}npc_id'])!,
      reputation: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reputation'])!,
      lastGainAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_gain_at']),
      dailyGained: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}daily_gained'])!,
    );
  }

  @override
  $NpcReputationTableTable createAlias(String alias) {
    return $NpcReputationTableTable(attachedDatabase, alias);
  }
}

class NpcReputationTableData extends DataClass
    implements Insertable<NpcReputationTableData> {
  final int id;
  final int playerId;
  final String npcId;
  final int reputation;
  final DateTime? lastGainAt;
  final int dailyGained;
  const NpcReputationTableData(
      {required this.id,
      required this.playerId,
      required this.npcId,
      required this.reputation,
      this.lastGainAt,
      required this.dailyGained});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['npc_id'] = Variable<String>(npcId);
    map['reputation'] = Variable<int>(reputation);
    if (!nullToAbsent || lastGainAt != null) {
      map['last_gain_at'] = Variable<DateTime>(lastGainAt);
    }
    map['daily_gained'] = Variable<int>(dailyGained);
    return map;
  }

  NpcReputationTableCompanion toCompanion(bool nullToAbsent) {
    return NpcReputationTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      npcId: Value(npcId),
      reputation: Value(reputation),
      lastGainAt: lastGainAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGainAt),
      dailyGained: Value(dailyGained),
    );
  }

  factory NpcReputationTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NpcReputationTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      npcId: serializer.fromJson<String>(json['npcId']),
      reputation: serializer.fromJson<int>(json['reputation']),
      lastGainAt: serializer.fromJson<DateTime?>(json['lastGainAt']),
      dailyGained: serializer.fromJson<int>(json['dailyGained']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'npcId': serializer.toJson<String>(npcId),
      'reputation': serializer.toJson<int>(reputation),
      'lastGainAt': serializer.toJson<DateTime?>(lastGainAt),
      'dailyGained': serializer.toJson<int>(dailyGained),
    };
  }

  NpcReputationTableData copyWith(
          {int? id,
          int? playerId,
          String? npcId,
          int? reputation,
          Value<DateTime?> lastGainAt = const Value.absent(),
          int? dailyGained}) =>
      NpcReputationTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        npcId: npcId ?? this.npcId,
        reputation: reputation ?? this.reputation,
        lastGainAt: lastGainAt.present ? lastGainAt.value : this.lastGainAt,
        dailyGained: dailyGained ?? this.dailyGained,
      );
  NpcReputationTableData copyWithCompanion(NpcReputationTableCompanion data) {
    return NpcReputationTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      npcId: data.npcId.present ? data.npcId.value : this.npcId,
      reputation:
          data.reputation.present ? data.reputation.value : this.reputation,
      lastGainAt:
          data.lastGainAt.present ? data.lastGainAt.value : this.lastGainAt,
      dailyGained:
          data.dailyGained.present ? data.dailyGained.value : this.dailyGained,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NpcReputationTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('npcId: $npcId, ')
          ..write('reputation: $reputation, ')
          ..write('lastGainAt: $lastGainAt, ')
          ..write('dailyGained: $dailyGained')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playerId, npcId, reputation, lastGainAt, dailyGained);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NpcReputationTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.npcId == this.npcId &&
          other.reputation == this.reputation &&
          other.lastGainAt == this.lastGainAt &&
          other.dailyGained == this.dailyGained);
}

class NpcReputationTableCompanion
    extends UpdateCompanion<NpcReputationTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> npcId;
  final Value<int> reputation;
  final Value<DateTime?> lastGainAt;
  final Value<int> dailyGained;
  const NpcReputationTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.npcId = const Value.absent(),
    this.reputation = const Value.absent(),
    this.lastGainAt = const Value.absent(),
    this.dailyGained = const Value.absent(),
  });
  NpcReputationTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required String npcId,
    this.reputation = const Value.absent(),
    this.lastGainAt = const Value.absent(),
    this.dailyGained = const Value.absent(),
  })  : playerId = Value(playerId),
        npcId = Value(npcId);
  static Insertable<NpcReputationTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? npcId,
    Expression<int>? reputation,
    Expression<DateTime>? lastGainAt,
    Expression<int>? dailyGained,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (npcId != null) 'npc_id': npcId,
      if (reputation != null) 'reputation': reputation,
      if (lastGainAt != null) 'last_gain_at': lastGainAt,
      if (dailyGained != null) 'daily_gained': dailyGained,
    });
  }

  NpcReputationTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<String>? npcId,
      Value<int>? reputation,
      Value<DateTime?>? lastGainAt,
      Value<int>? dailyGained}) {
    return NpcReputationTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      npcId: npcId ?? this.npcId,
      reputation: reputation ?? this.reputation,
      lastGainAt: lastGainAt ?? this.lastGainAt,
      dailyGained: dailyGained ?? this.dailyGained,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (npcId.present) {
      map['npc_id'] = Variable<String>(npcId.value);
    }
    if (reputation.present) {
      map['reputation'] = Variable<int>(reputation.value);
    }
    if (lastGainAt.present) {
      map['last_gain_at'] = Variable<DateTime>(lastGainAt.value);
    }
    if (dailyGained.present) {
      map['daily_gained'] = Variable<int>(dailyGained.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NpcReputationTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('npcId: $npcId, ')
          ..write('reputation: $reputation, ')
          ..write('lastGainAt: $lastGainAt, ')
          ..write('dailyGained: $dailyGained')
          ..write(')'))
        .toString();
  }
}

class $DiaryEntriesTableTable extends DiaryEntriesTable
    with TableInfo<$DiaryEntriesTableTable, DiaryEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _wordCountMeta =
      const VerificationMeta('wordCount');
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
      'word_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _entryDateMeta =
      const VerificationMeta('entryDate');
  @override
  late final GeneratedColumn<DateTime> entryDate = GeneratedColumn<DateTime>(
      'entry_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, playerId, content, wordCount, entryDate, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<DiaryEntriesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('word_count')) {
      context.handle(_wordCountMeta,
          wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta));
    }
    if (data.containsKey('entry_date')) {
      context.handle(_entryDateMeta,
          entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta));
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiaryEntriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryEntriesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      wordCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_count'])!,
      entryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}entry_date'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DiaryEntriesTableTable createAlias(String alias) {
    return $DiaryEntriesTableTable(attachedDatabase, alias);
  }
}

class DiaryEntriesTableData extends DataClass
    implements Insertable<DiaryEntriesTableData> {
  final int id;
  final int playerId;
  final String content;
  final int wordCount;
  final DateTime entryDate;
  final DateTime updatedAt;
  const DiaryEntriesTableData(
      {required this.id,
      required this.playerId,
      required this.content,
      required this.wordCount,
      required this.entryDate,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['content'] = Variable<String>(content);
    map['word_count'] = Variable<int>(wordCount);
    map['entry_date'] = Variable<DateTime>(entryDate);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DiaryEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return DiaryEntriesTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      content: Value(content),
      wordCount: Value(wordCount),
      entryDate: Value(entryDate),
      updatedAt: Value(updatedAt),
    );
  }

  factory DiaryEntriesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryEntriesTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      content: serializer.fromJson<String>(json['content']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      entryDate: serializer.fromJson<DateTime>(json['entryDate']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'content': serializer.toJson<String>(content),
      'wordCount': serializer.toJson<int>(wordCount),
      'entryDate': serializer.toJson<DateTime>(entryDate),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DiaryEntriesTableData copyWith(
          {int? id,
          int? playerId,
          String? content,
          int? wordCount,
          DateTime? entryDate,
          DateTime? updatedAt}) =>
      DiaryEntriesTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        content: content ?? this.content,
        wordCount: wordCount ?? this.wordCount,
        entryDate: entryDate ?? this.entryDate,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DiaryEntriesTableData copyWithCompanion(DiaryEntriesTableCompanion data) {
    return DiaryEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      content: data.content.present ? data.content.value : this.content,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntriesTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('content: $content, ')
          ..write('wordCount: $wordCount, ')
          ..write('entryDate: $entryDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playerId, content, wordCount, entryDate, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryEntriesTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.content == this.content &&
          other.wordCount == this.wordCount &&
          other.entryDate == this.entryDate &&
          other.updatedAt == this.updatedAt);
}

class DiaryEntriesTableCompanion
    extends UpdateCompanion<DiaryEntriesTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> content;
  final Value<int> wordCount;
  final Value<DateTime> entryDate;
  final Value<DateTime> updatedAt;
  const DiaryEntriesTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.content = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DiaryEntriesTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    this.content = const Value.absent(),
    this.wordCount = const Value.absent(),
    required DateTime entryDate,
    this.updatedAt = const Value.absent(),
  })  : playerId = Value(playerId),
        entryDate = Value(entryDate);
  static Insertable<DiaryEntriesTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? content,
    Expression<int>? wordCount,
    Expression<DateTime>? entryDate,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (content != null) 'content': content,
      if (wordCount != null) 'word_count': wordCount,
      if (entryDate != null) 'entry_date': entryDate,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DiaryEntriesTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<String>? content,
      Value<int>? wordCount,
      Value<DateTime>? entryDate,
      Value<DateTime>? updatedAt}) {
    return DiaryEntriesTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      content: content ?? this.content,
      wordCount: wordCount ?? this.wordCount,
      entryDate: entryDate ?? this.entryDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<DateTime>(entryDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('content: $content, ')
          ..write('wordCount: $wordCount, ')
          ..write('entryDate: $entryDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ClassQuestsTableTable extends ClassQuestsTable
    with TableInfo<$ClassQuestsTableTable, ClassQuestsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassQuestsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _classTypeMeta =
      const VerificationMeta('classType');
  @override
  late final GeneratedColumn<String> classType = GeneratedColumn<String>(
      'class_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questKeyMeta =
      const VerificationMeta('questKey');
  @override
  late final GeneratedColumn<String> questKey = GeneratedColumn<String>(
      'quest_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checkTypeMeta =
      const VerificationMeta('checkType');
  @override
  late final GeneratedColumn<String> checkType = GeneratedColumn<String>(
      'check_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checkParamsJsonMeta =
      const VerificationMeta('checkParamsJson');
  @override
  late final GeneratedColumn<String> checkParamsJson = GeneratedColumn<String>(
      'check_params_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _xpRewardMeta =
      const VerificationMeta('xpReward');
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
      'xp_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _goldRewardMeta =
      const VerificationMeta('goldReward');
  @override
  late final GeneratedColumn<int> goldReward = GeneratedColumn<int>(
      'gold_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _assignedDateMeta =
      const VerificationMeta('assignedDate');
  @override
  late final GeneratedColumn<String> assignedDate = GeneratedColumn<String>(
      'assigned_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _progressTargetMeta =
      const VerificationMeta('progressTarget');
  @override
  late final GeneratedColumn<int> progressTarget = GeneratedColumn<int>(
      'progress_target', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playerId,
        classType,
        questKey,
        title,
        description,
        checkType,
        checkParamsJson,
        xpReward,
        goldReward,
        assignedDate,
        completed,
        progress,
        progressTarget
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_class_quests';
  @override
  VerificationContext validateIntegrity(
      Insertable<ClassQuestsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('class_type')) {
      context.handle(_classTypeMeta,
          classType.isAcceptableOrUnknown(data['class_type']!, _classTypeMeta));
    } else if (isInserting) {
      context.missing(_classTypeMeta);
    }
    if (data.containsKey('quest_key')) {
      context.handle(_questKeyMeta,
          questKey.isAcceptableOrUnknown(data['quest_key']!, _questKeyMeta));
    } else if (isInserting) {
      context.missing(_questKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('check_type')) {
      context.handle(_checkTypeMeta,
          checkType.isAcceptableOrUnknown(data['check_type']!, _checkTypeMeta));
    } else if (isInserting) {
      context.missing(_checkTypeMeta);
    }
    if (data.containsKey('check_params_json')) {
      context.handle(
          _checkParamsJsonMeta,
          checkParamsJson.isAcceptableOrUnknown(
              data['check_params_json']!, _checkParamsJsonMeta));
    } else if (isInserting) {
      context.missing(_checkParamsJsonMeta);
    }
    if (data.containsKey('xp_reward')) {
      context.handle(_xpRewardMeta,
          xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta));
    }
    if (data.containsKey('gold_reward')) {
      context.handle(
          _goldRewardMeta,
          goldReward.isAcceptableOrUnknown(
              data['gold_reward']!, _goldRewardMeta));
    }
    if (data.containsKey('assigned_date')) {
      context.handle(
          _assignedDateMeta,
          assignedDate.isAcceptableOrUnknown(
              data['assigned_date']!, _assignedDateMeta));
    } else if (isInserting) {
      context.missing(_assignedDateMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('progress_target')) {
      context.handle(
          _progressTargetMeta,
          progressTarget.isAcceptableOrUnknown(
              data['progress_target']!, _progressTargetMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassQuestsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassQuestsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      classType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_type'])!,
      questKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quest_key'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      checkType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_type'])!,
      checkParamsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}check_params_json'])!,
      xpReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_reward'])!,
      goldReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gold_reward'])!,
      assignedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assigned_date'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      progressTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress_target'])!,
    );
  }

  @override
  $ClassQuestsTableTable createAlias(String alias) {
    return $ClassQuestsTableTable(attachedDatabase, alias);
  }
}

class ClassQuestsTableData extends DataClass
    implements Insertable<ClassQuestsTableData> {
  final int id;
  final int playerId;
  final String classType;
  final String questKey;
  final String title;
  final String description;
  final String checkType;
  final String checkParamsJson;
  final int xpReward;
  final int goldReward;
  final String assignedDate;
  final bool completed;
  final int progress;
  final int progressTarget;
  const ClassQuestsTableData(
      {required this.id,
      required this.playerId,
      required this.classType,
      required this.questKey,
      required this.title,
      required this.description,
      required this.checkType,
      required this.checkParamsJson,
      required this.xpReward,
      required this.goldReward,
      required this.assignedDate,
      required this.completed,
      required this.progress,
      required this.progressTarget});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['class_type'] = Variable<String>(classType);
    map['quest_key'] = Variable<String>(questKey);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['check_type'] = Variable<String>(checkType);
    map['check_params_json'] = Variable<String>(checkParamsJson);
    map['xp_reward'] = Variable<int>(xpReward);
    map['gold_reward'] = Variable<int>(goldReward);
    map['assigned_date'] = Variable<String>(assignedDate);
    map['completed'] = Variable<bool>(completed);
    map['progress'] = Variable<int>(progress);
    map['progress_target'] = Variable<int>(progressTarget);
    return map;
  }

  ClassQuestsTableCompanion toCompanion(bool nullToAbsent) {
    return ClassQuestsTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      classType: Value(classType),
      questKey: Value(questKey),
      title: Value(title),
      description: Value(description),
      checkType: Value(checkType),
      checkParamsJson: Value(checkParamsJson),
      xpReward: Value(xpReward),
      goldReward: Value(goldReward),
      assignedDate: Value(assignedDate),
      completed: Value(completed),
      progress: Value(progress),
      progressTarget: Value(progressTarget),
    );
  }

  factory ClassQuestsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassQuestsTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      classType: serializer.fromJson<String>(json['classType']),
      questKey: serializer.fromJson<String>(json['questKey']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      checkType: serializer.fromJson<String>(json['checkType']),
      checkParamsJson: serializer.fromJson<String>(json['checkParamsJson']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
      goldReward: serializer.fromJson<int>(json['goldReward']),
      assignedDate: serializer.fromJson<String>(json['assignedDate']),
      completed: serializer.fromJson<bool>(json['completed']),
      progress: serializer.fromJson<int>(json['progress']),
      progressTarget: serializer.fromJson<int>(json['progressTarget']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'classType': serializer.toJson<String>(classType),
      'questKey': serializer.toJson<String>(questKey),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'checkType': serializer.toJson<String>(checkType),
      'checkParamsJson': serializer.toJson<String>(checkParamsJson),
      'xpReward': serializer.toJson<int>(xpReward),
      'goldReward': serializer.toJson<int>(goldReward),
      'assignedDate': serializer.toJson<String>(assignedDate),
      'completed': serializer.toJson<bool>(completed),
      'progress': serializer.toJson<int>(progress),
      'progressTarget': serializer.toJson<int>(progressTarget),
    };
  }

  ClassQuestsTableData copyWith(
          {int? id,
          int? playerId,
          String? classType,
          String? questKey,
          String? title,
          String? description,
          String? checkType,
          String? checkParamsJson,
          int? xpReward,
          int? goldReward,
          String? assignedDate,
          bool? completed,
          int? progress,
          int? progressTarget}) =>
      ClassQuestsTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        classType: classType ?? this.classType,
        questKey: questKey ?? this.questKey,
        title: title ?? this.title,
        description: description ?? this.description,
        checkType: checkType ?? this.checkType,
        checkParamsJson: checkParamsJson ?? this.checkParamsJson,
        xpReward: xpReward ?? this.xpReward,
        goldReward: goldReward ?? this.goldReward,
        assignedDate: assignedDate ?? this.assignedDate,
        completed: completed ?? this.completed,
        progress: progress ?? this.progress,
        progressTarget: progressTarget ?? this.progressTarget,
      );
  ClassQuestsTableData copyWithCompanion(ClassQuestsTableCompanion data) {
    return ClassQuestsTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      classType: data.classType.present ? data.classType.value : this.classType,
      questKey: data.questKey.present ? data.questKey.value : this.questKey,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      checkType: data.checkType.present ? data.checkType.value : this.checkType,
      checkParamsJson: data.checkParamsJson.present
          ? data.checkParamsJson.value
          : this.checkParamsJson,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
      goldReward:
          data.goldReward.present ? data.goldReward.value : this.goldReward,
      assignedDate: data.assignedDate.present
          ? data.assignedDate.value
          : this.assignedDate,
      completed: data.completed.present ? data.completed.value : this.completed,
      progress: data.progress.present ? data.progress.value : this.progress,
      progressTarget: data.progressTarget.present
          ? data.progressTarget.value
          : this.progressTarget,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassQuestsTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('classType: $classType, ')
          ..write('questKey: $questKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('checkType: $checkType, ')
          ..write('checkParamsJson: $checkParamsJson, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('assignedDate: $assignedDate, ')
          ..write('completed: $completed, ')
          ..write('progress: $progress, ')
          ..write('progressTarget: $progressTarget')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      playerId,
      classType,
      questKey,
      title,
      description,
      checkType,
      checkParamsJson,
      xpReward,
      goldReward,
      assignedDate,
      completed,
      progress,
      progressTarget);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassQuestsTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.classType == this.classType &&
          other.questKey == this.questKey &&
          other.title == this.title &&
          other.description == this.description &&
          other.checkType == this.checkType &&
          other.checkParamsJson == this.checkParamsJson &&
          other.xpReward == this.xpReward &&
          other.goldReward == this.goldReward &&
          other.assignedDate == this.assignedDate &&
          other.completed == this.completed &&
          other.progress == this.progress &&
          other.progressTarget == this.progressTarget);
}

class ClassQuestsTableCompanion extends UpdateCompanion<ClassQuestsTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> classType;
  final Value<String> questKey;
  final Value<String> title;
  final Value<String> description;
  final Value<String> checkType;
  final Value<String> checkParamsJson;
  final Value<int> xpReward;
  final Value<int> goldReward;
  final Value<String> assignedDate;
  final Value<bool> completed;
  final Value<int> progress;
  final Value<int> progressTarget;
  const ClassQuestsTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.classType = const Value.absent(),
    this.questKey = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.checkType = const Value.absent(),
    this.checkParamsJson = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.goldReward = const Value.absent(),
    this.assignedDate = const Value.absent(),
    this.completed = const Value.absent(),
    this.progress = const Value.absent(),
    this.progressTarget = const Value.absent(),
  });
  ClassQuestsTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required String classType,
    required String questKey,
    required String title,
    required String description,
    required String checkType,
    required String checkParamsJson,
    this.xpReward = const Value.absent(),
    this.goldReward = const Value.absent(),
    required String assignedDate,
    this.completed = const Value.absent(),
    this.progress = const Value.absent(),
    this.progressTarget = const Value.absent(),
  })  : playerId = Value(playerId),
        classType = Value(classType),
        questKey = Value(questKey),
        title = Value(title),
        description = Value(description),
        checkType = Value(checkType),
        checkParamsJson = Value(checkParamsJson),
        assignedDate = Value(assignedDate);
  static Insertable<ClassQuestsTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? classType,
    Expression<String>? questKey,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? checkType,
    Expression<String>? checkParamsJson,
    Expression<int>? xpReward,
    Expression<int>? goldReward,
    Expression<String>? assignedDate,
    Expression<bool>? completed,
    Expression<int>? progress,
    Expression<int>? progressTarget,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (classType != null) 'class_type': classType,
      if (questKey != null) 'quest_key': questKey,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (checkType != null) 'check_type': checkType,
      if (checkParamsJson != null) 'check_params_json': checkParamsJson,
      if (xpReward != null) 'xp_reward': xpReward,
      if (goldReward != null) 'gold_reward': goldReward,
      if (assignedDate != null) 'assigned_date': assignedDate,
      if (completed != null) 'completed': completed,
      if (progress != null) 'progress': progress,
      if (progressTarget != null) 'progress_target': progressTarget,
    });
  }

  ClassQuestsTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<String>? classType,
      Value<String>? questKey,
      Value<String>? title,
      Value<String>? description,
      Value<String>? checkType,
      Value<String>? checkParamsJson,
      Value<int>? xpReward,
      Value<int>? goldReward,
      Value<String>? assignedDate,
      Value<bool>? completed,
      Value<int>? progress,
      Value<int>? progressTarget}) {
    return ClassQuestsTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      classType: classType ?? this.classType,
      questKey: questKey ?? this.questKey,
      title: title ?? this.title,
      description: description ?? this.description,
      checkType: checkType ?? this.checkType,
      checkParamsJson: checkParamsJson ?? this.checkParamsJson,
      xpReward: xpReward ?? this.xpReward,
      goldReward: goldReward ?? this.goldReward,
      assignedDate: assignedDate ?? this.assignedDate,
      completed: completed ?? this.completed,
      progress: progress ?? this.progress,
      progressTarget: progressTarget ?? this.progressTarget,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (classType.present) {
      map['class_type'] = Variable<String>(classType.value);
    }
    if (questKey.present) {
      map['quest_key'] = Variable<String>(questKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (checkType.present) {
      map['check_type'] = Variable<String>(checkType.value);
    }
    if (checkParamsJson.present) {
      map['check_params_json'] = Variable<String>(checkParamsJson.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    if (goldReward.present) {
      map['gold_reward'] = Variable<int>(goldReward.value);
    }
    if (assignedDate.present) {
      map['assigned_date'] = Variable<String>(assignedDate.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (progressTarget.present) {
      map['progress_target'] = Variable<int>(progressTarget.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassQuestsTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('classType: $classType, ')
          ..write('questKey: $questKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('checkType: $checkType, ')
          ..write('checkParamsJson: $checkParamsJson, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('assignedDate: $assignedDate, ')
          ..write('completed: $completed, ')
          ..write('progress: $progress, ')
          ..write('progressTarget: $progressTarget')
          ..write(')'))
        .toString();
  }
}

class $FactionQuestsTableTable extends FactionQuestsTable
    with TableInfo<$FactionQuestsTableTable, FactionQuestsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FactionQuestsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _factionIdMeta =
      const VerificationMeta('factionId');
  @override
  late final GeneratedColumn<String> factionId = GeneratedColumn<String>(
      'faction_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questKeyMeta =
      const VerificationMeta('questKey');
  @override
  late final GeneratedColumn<String> questKey = GeneratedColumn<String>(
      'quest_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checkTypeMeta =
      const VerificationMeta('checkType');
  @override
  late final GeneratedColumn<String> checkType = GeneratedColumn<String>(
      'check_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checkParamsJsonMeta =
      const VerificationMeta('checkParamsJson');
  @override
  late final GeneratedColumn<String> checkParamsJson = GeneratedColumn<String>(
      'check_params_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _xpRewardMeta =
      const VerificationMeta('xpReward');
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
      'xp_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _goldRewardMeta =
      const VerificationMeta('goldReward');
  @override
  late final GeneratedColumn<int> goldReward = GeneratedColumn<int>(
      'gold_reward', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _factionItemChanceMeta =
      const VerificationMeta('factionItemChance');
  @override
  late final GeneratedColumn<double> factionItemChance =
      GeneratedColumn<double>('faction_item_chance', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.05));
  static const VerificationMeta _weekStartMeta =
      const VerificationMeta('weekStart');
  @override
  late final GeneratedColumn<String> weekStart = GeneratedColumn<String>(
      'week_start', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _progressTargetMeta =
      const VerificationMeta('progressTarget');
  @override
  late final GeneratedColumn<int> progressTarget = GeneratedColumn<int>(
      'progress_target', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _lastQuestKeyMeta =
      const VerificationMeta('lastQuestKey');
  @override
  late final GeneratedColumn<String> lastQuestKey = GeneratedColumn<String>(
      'last_quest_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playerId,
        factionId,
        questKey,
        title,
        description,
        checkType,
        checkParamsJson,
        xpReward,
        goldReward,
        factionItemChance,
        weekStart,
        completed,
        progress,
        progressTarget,
        lastQuestKey
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_faction_quests';
  @override
  VerificationContext validateIntegrity(
      Insertable<FactionQuestsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('faction_id')) {
      context.handle(_factionIdMeta,
          factionId.isAcceptableOrUnknown(data['faction_id']!, _factionIdMeta));
    } else if (isInserting) {
      context.missing(_factionIdMeta);
    }
    if (data.containsKey('quest_key')) {
      context.handle(_questKeyMeta,
          questKey.isAcceptableOrUnknown(data['quest_key']!, _questKeyMeta));
    } else if (isInserting) {
      context.missing(_questKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('check_type')) {
      context.handle(_checkTypeMeta,
          checkType.isAcceptableOrUnknown(data['check_type']!, _checkTypeMeta));
    } else if (isInserting) {
      context.missing(_checkTypeMeta);
    }
    if (data.containsKey('check_params_json')) {
      context.handle(
          _checkParamsJsonMeta,
          checkParamsJson.isAcceptableOrUnknown(
              data['check_params_json']!, _checkParamsJsonMeta));
    } else if (isInserting) {
      context.missing(_checkParamsJsonMeta);
    }
    if (data.containsKey('xp_reward')) {
      context.handle(_xpRewardMeta,
          xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta));
    }
    if (data.containsKey('gold_reward')) {
      context.handle(
          _goldRewardMeta,
          goldReward.isAcceptableOrUnknown(
              data['gold_reward']!, _goldRewardMeta));
    }
    if (data.containsKey('faction_item_chance')) {
      context.handle(
          _factionItemChanceMeta,
          factionItemChance.isAcceptableOrUnknown(
              data['faction_item_chance']!, _factionItemChanceMeta));
    }
    if (data.containsKey('week_start')) {
      context.handle(_weekStartMeta,
          weekStart.isAcceptableOrUnknown(data['week_start']!, _weekStartMeta));
    } else if (isInserting) {
      context.missing(_weekStartMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('progress_target')) {
      context.handle(
          _progressTargetMeta,
          progressTarget.isAcceptableOrUnknown(
              data['progress_target']!, _progressTargetMeta));
    }
    if (data.containsKey('last_quest_key')) {
      context.handle(
          _lastQuestKeyMeta,
          lastQuestKey.isAcceptableOrUnknown(
              data['last_quest_key']!, _lastQuestKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FactionQuestsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FactionQuestsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      factionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}faction_id'])!,
      questKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quest_key'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      checkType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_type'])!,
      checkParamsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}check_params_json'])!,
      xpReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_reward'])!,
      goldReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gold_reward'])!,
      factionItemChance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}faction_item_chance'])!,
      weekStart: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}week_start'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      progressTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress_target'])!,
      lastQuestKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_quest_key'])!,
    );
  }

  @override
  $FactionQuestsTableTable createAlias(String alias) {
    return $FactionQuestsTableTable(attachedDatabase, alias);
  }
}

class FactionQuestsTableData extends DataClass
    implements Insertable<FactionQuestsTableData> {
  final int id;
  final int playerId;
  final String factionId;
  final String questKey;
  final String title;
  final String description;
  final String checkType;
  final String checkParamsJson;
  final int xpReward;
  final int goldReward;
  final double factionItemChance;
  final String weekStart;
  final bool completed;
  final int progress;
  final int progressTarget;
  final String lastQuestKey;
  const FactionQuestsTableData(
      {required this.id,
      required this.playerId,
      required this.factionId,
      required this.questKey,
      required this.title,
      required this.description,
      required this.checkType,
      required this.checkParamsJson,
      required this.xpReward,
      required this.goldReward,
      required this.factionItemChance,
      required this.weekStart,
      required this.completed,
      required this.progress,
      required this.progressTarget,
      required this.lastQuestKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['faction_id'] = Variable<String>(factionId);
    map['quest_key'] = Variable<String>(questKey);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['check_type'] = Variable<String>(checkType);
    map['check_params_json'] = Variable<String>(checkParamsJson);
    map['xp_reward'] = Variable<int>(xpReward);
    map['gold_reward'] = Variable<int>(goldReward);
    map['faction_item_chance'] = Variable<double>(factionItemChance);
    map['week_start'] = Variable<String>(weekStart);
    map['completed'] = Variable<bool>(completed);
    map['progress'] = Variable<int>(progress);
    map['progress_target'] = Variable<int>(progressTarget);
    map['last_quest_key'] = Variable<String>(lastQuestKey);
    return map;
  }

  FactionQuestsTableCompanion toCompanion(bool nullToAbsent) {
    return FactionQuestsTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      factionId: Value(factionId),
      questKey: Value(questKey),
      title: Value(title),
      description: Value(description),
      checkType: Value(checkType),
      checkParamsJson: Value(checkParamsJson),
      xpReward: Value(xpReward),
      goldReward: Value(goldReward),
      factionItemChance: Value(factionItemChance),
      weekStart: Value(weekStart),
      completed: Value(completed),
      progress: Value(progress),
      progressTarget: Value(progressTarget),
      lastQuestKey: Value(lastQuestKey),
    );
  }

  factory FactionQuestsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FactionQuestsTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      factionId: serializer.fromJson<String>(json['factionId']),
      questKey: serializer.fromJson<String>(json['questKey']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      checkType: serializer.fromJson<String>(json['checkType']),
      checkParamsJson: serializer.fromJson<String>(json['checkParamsJson']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
      goldReward: serializer.fromJson<int>(json['goldReward']),
      factionItemChance: serializer.fromJson<double>(json['factionItemChance']),
      weekStart: serializer.fromJson<String>(json['weekStart']),
      completed: serializer.fromJson<bool>(json['completed']),
      progress: serializer.fromJson<int>(json['progress']),
      progressTarget: serializer.fromJson<int>(json['progressTarget']),
      lastQuestKey: serializer.fromJson<String>(json['lastQuestKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'factionId': serializer.toJson<String>(factionId),
      'questKey': serializer.toJson<String>(questKey),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'checkType': serializer.toJson<String>(checkType),
      'checkParamsJson': serializer.toJson<String>(checkParamsJson),
      'xpReward': serializer.toJson<int>(xpReward),
      'goldReward': serializer.toJson<int>(goldReward),
      'factionItemChance': serializer.toJson<double>(factionItemChance),
      'weekStart': serializer.toJson<String>(weekStart),
      'completed': serializer.toJson<bool>(completed),
      'progress': serializer.toJson<int>(progress),
      'progressTarget': serializer.toJson<int>(progressTarget),
      'lastQuestKey': serializer.toJson<String>(lastQuestKey),
    };
  }

  FactionQuestsTableData copyWith(
          {int? id,
          int? playerId,
          String? factionId,
          String? questKey,
          String? title,
          String? description,
          String? checkType,
          String? checkParamsJson,
          int? xpReward,
          int? goldReward,
          double? factionItemChance,
          String? weekStart,
          bool? completed,
          int? progress,
          int? progressTarget,
          String? lastQuestKey}) =>
      FactionQuestsTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        factionId: factionId ?? this.factionId,
        questKey: questKey ?? this.questKey,
        title: title ?? this.title,
        description: description ?? this.description,
        checkType: checkType ?? this.checkType,
        checkParamsJson: checkParamsJson ?? this.checkParamsJson,
        xpReward: xpReward ?? this.xpReward,
        goldReward: goldReward ?? this.goldReward,
        factionItemChance: factionItemChance ?? this.factionItemChance,
        weekStart: weekStart ?? this.weekStart,
        completed: completed ?? this.completed,
        progress: progress ?? this.progress,
        progressTarget: progressTarget ?? this.progressTarget,
        lastQuestKey: lastQuestKey ?? this.lastQuestKey,
      );
  FactionQuestsTableData copyWithCompanion(FactionQuestsTableCompanion data) {
    return FactionQuestsTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      factionId: data.factionId.present ? data.factionId.value : this.factionId,
      questKey: data.questKey.present ? data.questKey.value : this.questKey,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      checkType: data.checkType.present ? data.checkType.value : this.checkType,
      checkParamsJson: data.checkParamsJson.present
          ? data.checkParamsJson.value
          : this.checkParamsJson,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
      goldReward:
          data.goldReward.present ? data.goldReward.value : this.goldReward,
      factionItemChance: data.factionItemChance.present
          ? data.factionItemChance.value
          : this.factionItemChance,
      weekStart: data.weekStart.present ? data.weekStart.value : this.weekStart,
      completed: data.completed.present ? data.completed.value : this.completed,
      progress: data.progress.present ? data.progress.value : this.progress,
      progressTarget: data.progressTarget.present
          ? data.progressTarget.value
          : this.progressTarget,
      lastQuestKey: data.lastQuestKey.present
          ? data.lastQuestKey.value
          : this.lastQuestKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FactionQuestsTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('factionId: $factionId, ')
          ..write('questKey: $questKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('checkType: $checkType, ')
          ..write('checkParamsJson: $checkParamsJson, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('factionItemChance: $factionItemChance, ')
          ..write('weekStart: $weekStart, ')
          ..write('completed: $completed, ')
          ..write('progress: $progress, ')
          ..write('progressTarget: $progressTarget, ')
          ..write('lastQuestKey: $lastQuestKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      playerId,
      factionId,
      questKey,
      title,
      description,
      checkType,
      checkParamsJson,
      xpReward,
      goldReward,
      factionItemChance,
      weekStart,
      completed,
      progress,
      progressTarget,
      lastQuestKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FactionQuestsTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.factionId == this.factionId &&
          other.questKey == this.questKey &&
          other.title == this.title &&
          other.description == this.description &&
          other.checkType == this.checkType &&
          other.checkParamsJson == this.checkParamsJson &&
          other.xpReward == this.xpReward &&
          other.goldReward == this.goldReward &&
          other.factionItemChance == this.factionItemChance &&
          other.weekStart == this.weekStart &&
          other.completed == this.completed &&
          other.progress == this.progress &&
          other.progressTarget == this.progressTarget &&
          other.lastQuestKey == this.lastQuestKey);
}

class FactionQuestsTableCompanion
    extends UpdateCompanion<FactionQuestsTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> factionId;
  final Value<String> questKey;
  final Value<String> title;
  final Value<String> description;
  final Value<String> checkType;
  final Value<String> checkParamsJson;
  final Value<int> xpReward;
  final Value<int> goldReward;
  final Value<double> factionItemChance;
  final Value<String> weekStart;
  final Value<bool> completed;
  final Value<int> progress;
  final Value<int> progressTarget;
  final Value<String> lastQuestKey;
  const FactionQuestsTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.factionId = const Value.absent(),
    this.questKey = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.checkType = const Value.absent(),
    this.checkParamsJson = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.goldReward = const Value.absent(),
    this.factionItemChance = const Value.absent(),
    this.weekStart = const Value.absent(),
    this.completed = const Value.absent(),
    this.progress = const Value.absent(),
    this.progressTarget = const Value.absent(),
    this.lastQuestKey = const Value.absent(),
  });
  FactionQuestsTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required String factionId,
    required String questKey,
    required String title,
    required String description,
    required String checkType,
    required String checkParamsJson,
    this.xpReward = const Value.absent(),
    this.goldReward = const Value.absent(),
    this.factionItemChance = const Value.absent(),
    required String weekStart,
    this.completed = const Value.absent(),
    this.progress = const Value.absent(),
    this.progressTarget = const Value.absent(),
    this.lastQuestKey = const Value.absent(),
  })  : playerId = Value(playerId),
        factionId = Value(factionId),
        questKey = Value(questKey),
        title = Value(title),
        description = Value(description),
        checkType = Value(checkType),
        checkParamsJson = Value(checkParamsJson),
        weekStart = Value(weekStart);
  static Insertable<FactionQuestsTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? factionId,
    Expression<String>? questKey,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? checkType,
    Expression<String>? checkParamsJson,
    Expression<int>? xpReward,
    Expression<int>? goldReward,
    Expression<double>? factionItemChance,
    Expression<String>? weekStart,
    Expression<bool>? completed,
    Expression<int>? progress,
    Expression<int>? progressTarget,
    Expression<String>? lastQuestKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (factionId != null) 'faction_id': factionId,
      if (questKey != null) 'quest_key': questKey,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (checkType != null) 'check_type': checkType,
      if (checkParamsJson != null) 'check_params_json': checkParamsJson,
      if (xpReward != null) 'xp_reward': xpReward,
      if (goldReward != null) 'gold_reward': goldReward,
      if (factionItemChance != null) 'faction_item_chance': factionItemChance,
      if (weekStart != null) 'week_start': weekStart,
      if (completed != null) 'completed': completed,
      if (progress != null) 'progress': progress,
      if (progressTarget != null) 'progress_target': progressTarget,
      if (lastQuestKey != null) 'last_quest_key': lastQuestKey,
    });
  }

  FactionQuestsTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<String>? factionId,
      Value<String>? questKey,
      Value<String>? title,
      Value<String>? description,
      Value<String>? checkType,
      Value<String>? checkParamsJson,
      Value<int>? xpReward,
      Value<int>? goldReward,
      Value<double>? factionItemChance,
      Value<String>? weekStart,
      Value<bool>? completed,
      Value<int>? progress,
      Value<int>? progressTarget,
      Value<String>? lastQuestKey}) {
    return FactionQuestsTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      factionId: factionId ?? this.factionId,
      questKey: questKey ?? this.questKey,
      title: title ?? this.title,
      description: description ?? this.description,
      checkType: checkType ?? this.checkType,
      checkParamsJson: checkParamsJson ?? this.checkParamsJson,
      xpReward: xpReward ?? this.xpReward,
      goldReward: goldReward ?? this.goldReward,
      factionItemChance: factionItemChance ?? this.factionItemChance,
      weekStart: weekStart ?? this.weekStart,
      completed: completed ?? this.completed,
      progress: progress ?? this.progress,
      progressTarget: progressTarget ?? this.progressTarget,
      lastQuestKey: lastQuestKey ?? this.lastQuestKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (factionId.present) {
      map['faction_id'] = Variable<String>(factionId.value);
    }
    if (questKey.present) {
      map['quest_key'] = Variable<String>(questKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (checkType.present) {
      map['check_type'] = Variable<String>(checkType.value);
    }
    if (checkParamsJson.present) {
      map['check_params_json'] = Variable<String>(checkParamsJson.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    if (goldReward.present) {
      map['gold_reward'] = Variable<int>(goldReward.value);
    }
    if (factionItemChance.present) {
      map['faction_item_chance'] = Variable<double>(factionItemChance.value);
    }
    if (weekStart.present) {
      map['week_start'] = Variable<String>(weekStart.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (progressTarget.present) {
      map['progress_target'] = Variable<int>(progressTarget.value);
    }
    if (lastQuestKey.present) {
      map['last_quest_key'] = Variable<String>(lastQuestKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FactionQuestsTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('factionId: $factionId, ')
          ..write('questKey: $questKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('checkType: $checkType, ')
          ..write('checkParamsJson: $checkParamsJson, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('factionItemChance: $factionItemChance, ')
          ..write('weekStart: $weekStart, ')
          ..write('completed: $completed, ')
          ..write('progress: $progress, ')
          ..write('progressTarget: $progressTarget, ')
          ..write('lastQuestKey: $lastQuestKey')
          ..write(')'))
        .toString();
  }
}

class $GuildAscensionTableTable extends GuildAscensionTable
    with TableInfo<$GuildAscensionTableTable, GuildAscensionTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GuildAscensionTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _rankFromMeta =
      const VerificationMeta('rankFrom');
  @override
  late final GeneratedColumn<String> rankFrom = GeneratedColumn<String>(
      'rank_from', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rankToMeta = const VerificationMeta('rankTo');
  @override
  late final GeneratedColumn<String> rankTo = GeneratedColumn<String>(
      'rank_to', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
      'step', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _questKeyMeta =
      const VerificationMeta('questKey');
  @override
  late final GeneratedColumn<String> questKey = GeneratedColumn<String>(
      'quest_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checkTypeMeta =
      const VerificationMeta('checkType');
  @override
  late final GeneratedColumn<String> checkType = GeneratedColumn<String>(
      'check_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checkParamsJsonMeta =
      const VerificationMeta('checkParamsJson');
  @override
  late final GeneratedColumn<String> checkParamsJson = GeneratedColumn<String>(
      'check_params_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unlockLevelMeta =
      const VerificationMeta('unlockLevel');
  @override
  late final GeneratedColumn<int> unlockLevel = GeneratedColumn<int>(
      'unlock_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _xpRewardMeta =
      const VerificationMeta('xpReward');
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
      'xp_reward', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _goldRewardMeta =
      const VerificationMeta('goldReward');
  @override
  late final GeneratedColumn<int> goldReward = GeneratedColumn<int>(
      'gold_reward', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _progressTargetMeta =
      const VerificationMeta('progressTarget');
  @override
  late final GeneratedColumn<int> progressTarget = GeneratedColumn<int>(
      'progress_target', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playerId,
        rankFrom,
        rankTo,
        step,
        questKey,
        title,
        description,
        checkType,
        checkParamsJson,
        unlockLevel,
        xpReward,
        goldReward,
        completed,
        progress,
        progressTarget
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'guild_ascension_progress';
  @override
  VerificationContext validateIntegrity(
      Insertable<GuildAscensionTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('rank_from')) {
      context.handle(_rankFromMeta,
          rankFrom.isAcceptableOrUnknown(data['rank_from']!, _rankFromMeta));
    } else if (isInserting) {
      context.missing(_rankFromMeta);
    }
    if (data.containsKey('rank_to')) {
      context.handle(_rankToMeta,
          rankTo.isAcceptableOrUnknown(data['rank_to']!, _rankToMeta));
    } else if (isInserting) {
      context.missing(_rankToMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
          _stepMeta, step.isAcceptableOrUnknown(data['step']!, _stepMeta));
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('quest_key')) {
      context.handle(_questKeyMeta,
          questKey.isAcceptableOrUnknown(data['quest_key']!, _questKeyMeta));
    } else if (isInserting) {
      context.missing(_questKeyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('check_type')) {
      context.handle(_checkTypeMeta,
          checkType.isAcceptableOrUnknown(data['check_type']!, _checkTypeMeta));
    } else if (isInserting) {
      context.missing(_checkTypeMeta);
    }
    if (data.containsKey('check_params_json')) {
      context.handle(
          _checkParamsJsonMeta,
          checkParamsJson.isAcceptableOrUnknown(
              data['check_params_json']!, _checkParamsJsonMeta));
    } else if (isInserting) {
      context.missing(_checkParamsJsonMeta);
    }
    if (data.containsKey('unlock_level')) {
      context.handle(
          _unlockLevelMeta,
          unlockLevel.isAcceptableOrUnknown(
              data['unlock_level']!, _unlockLevelMeta));
    } else if (isInserting) {
      context.missing(_unlockLevelMeta);
    }
    if (data.containsKey('xp_reward')) {
      context.handle(_xpRewardMeta,
          xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta));
    } else if (isInserting) {
      context.missing(_xpRewardMeta);
    }
    if (data.containsKey('gold_reward')) {
      context.handle(
          _goldRewardMeta,
          goldReward.isAcceptableOrUnknown(
              data['gold_reward']!, _goldRewardMeta));
    } else if (isInserting) {
      context.missing(_goldRewardMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('progress_target')) {
      context.handle(
          _progressTargetMeta,
          progressTarget.isAcceptableOrUnknown(
              data['progress_target']!, _progressTargetMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GuildAscensionTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GuildAscensionTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      rankFrom: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rank_from'])!,
      rankTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rank_to'])!,
      step: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}step'])!,
      questKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quest_key'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      checkType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}check_type'])!,
      checkParamsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}check_params_json'])!,
      unlockLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unlock_level'])!,
      xpReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_reward'])!,
      goldReward: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gold_reward'])!,
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      progressTarget: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress_target'])!,
    );
  }

  @override
  $GuildAscensionTableTable createAlias(String alias) {
    return $GuildAscensionTableTable(attachedDatabase, alias);
  }
}

class GuildAscensionTableData extends DataClass
    implements Insertable<GuildAscensionTableData> {
  final int id;
  final int playerId;
  final String rankFrom;
  final String rankTo;
  final int step;
  final String questKey;
  final String title;
  final String description;
  final String checkType;
  final String checkParamsJson;
  final int unlockLevel;
  final int xpReward;
  final int goldReward;
  final bool completed;
  final int progress;
  final int progressTarget;
  const GuildAscensionTableData(
      {required this.id,
      required this.playerId,
      required this.rankFrom,
      required this.rankTo,
      required this.step,
      required this.questKey,
      required this.title,
      required this.description,
      required this.checkType,
      required this.checkParamsJson,
      required this.unlockLevel,
      required this.xpReward,
      required this.goldReward,
      required this.completed,
      required this.progress,
      required this.progressTarget});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['rank_from'] = Variable<String>(rankFrom);
    map['rank_to'] = Variable<String>(rankTo);
    map['step'] = Variable<int>(step);
    map['quest_key'] = Variable<String>(questKey);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['check_type'] = Variable<String>(checkType);
    map['check_params_json'] = Variable<String>(checkParamsJson);
    map['unlock_level'] = Variable<int>(unlockLevel);
    map['xp_reward'] = Variable<int>(xpReward);
    map['gold_reward'] = Variable<int>(goldReward);
    map['completed'] = Variable<bool>(completed);
    map['progress'] = Variable<int>(progress);
    map['progress_target'] = Variable<int>(progressTarget);
    return map;
  }

  GuildAscensionTableCompanion toCompanion(bool nullToAbsent) {
    return GuildAscensionTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      rankFrom: Value(rankFrom),
      rankTo: Value(rankTo),
      step: Value(step),
      questKey: Value(questKey),
      title: Value(title),
      description: Value(description),
      checkType: Value(checkType),
      checkParamsJson: Value(checkParamsJson),
      unlockLevel: Value(unlockLevel),
      xpReward: Value(xpReward),
      goldReward: Value(goldReward),
      completed: Value(completed),
      progress: Value(progress),
      progressTarget: Value(progressTarget),
    );
  }

  factory GuildAscensionTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GuildAscensionTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      rankFrom: serializer.fromJson<String>(json['rankFrom']),
      rankTo: serializer.fromJson<String>(json['rankTo']),
      step: serializer.fromJson<int>(json['step']),
      questKey: serializer.fromJson<String>(json['questKey']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      checkType: serializer.fromJson<String>(json['checkType']),
      checkParamsJson: serializer.fromJson<String>(json['checkParamsJson']),
      unlockLevel: serializer.fromJson<int>(json['unlockLevel']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
      goldReward: serializer.fromJson<int>(json['goldReward']),
      completed: serializer.fromJson<bool>(json['completed']),
      progress: serializer.fromJson<int>(json['progress']),
      progressTarget: serializer.fromJson<int>(json['progressTarget']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'rankFrom': serializer.toJson<String>(rankFrom),
      'rankTo': serializer.toJson<String>(rankTo),
      'step': serializer.toJson<int>(step),
      'questKey': serializer.toJson<String>(questKey),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'checkType': serializer.toJson<String>(checkType),
      'checkParamsJson': serializer.toJson<String>(checkParamsJson),
      'unlockLevel': serializer.toJson<int>(unlockLevel),
      'xpReward': serializer.toJson<int>(xpReward),
      'goldReward': serializer.toJson<int>(goldReward),
      'completed': serializer.toJson<bool>(completed),
      'progress': serializer.toJson<int>(progress),
      'progressTarget': serializer.toJson<int>(progressTarget),
    };
  }

  GuildAscensionTableData copyWith(
          {int? id,
          int? playerId,
          String? rankFrom,
          String? rankTo,
          int? step,
          String? questKey,
          String? title,
          String? description,
          String? checkType,
          String? checkParamsJson,
          int? unlockLevel,
          int? xpReward,
          int? goldReward,
          bool? completed,
          int? progress,
          int? progressTarget}) =>
      GuildAscensionTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        rankFrom: rankFrom ?? this.rankFrom,
        rankTo: rankTo ?? this.rankTo,
        step: step ?? this.step,
        questKey: questKey ?? this.questKey,
        title: title ?? this.title,
        description: description ?? this.description,
        checkType: checkType ?? this.checkType,
        checkParamsJson: checkParamsJson ?? this.checkParamsJson,
        unlockLevel: unlockLevel ?? this.unlockLevel,
        xpReward: xpReward ?? this.xpReward,
        goldReward: goldReward ?? this.goldReward,
        completed: completed ?? this.completed,
        progress: progress ?? this.progress,
        progressTarget: progressTarget ?? this.progressTarget,
      );
  GuildAscensionTableData copyWithCompanion(GuildAscensionTableCompanion data) {
    return GuildAscensionTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      rankFrom: data.rankFrom.present ? data.rankFrom.value : this.rankFrom,
      rankTo: data.rankTo.present ? data.rankTo.value : this.rankTo,
      step: data.step.present ? data.step.value : this.step,
      questKey: data.questKey.present ? data.questKey.value : this.questKey,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      checkType: data.checkType.present ? data.checkType.value : this.checkType,
      checkParamsJson: data.checkParamsJson.present
          ? data.checkParamsJson.value
          : this.checkParamsJson,
      unlockLevel:
          data.unlockLevel.present ? data.unlockLevel.value : this.unlockLevel,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
      goldReward:
          data.goldReward.present ? data.goldReward.value : this.goldReward,
      completed: data.completed.present ? data.completed.value : this.completed,
      progress: data.progress.present ? data.progress.value : this.progress,
      progressTarget: data.progressTarget.present
          ? data.progressTarget.value
          : this.progressTarget,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GuildAscensionTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('rankFrom: $rankFrom, ')
          ..write('rankTo: $rankTo, ')
          ..write('step: $step, ')
          ..write('questKey: $questKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('checkType: $checkType, ')
          ..write('checkParamsJson: $checkParamsJson, ')
          ..write('unlockLevel: $unlockLevel, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('completed: $completed, ')
          ..write('progress: $progress, ')
          ..write('progressTarget: $progressTarget')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      playerId,
      rankFrom,
      rankTo,
      step,
      questKey,
      title,
      description,
      checkType,
      checkParamsJson,
      unlockLevel,
      xpReward,
      goldReward,
      completed,
      progress,
      progressTarget);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GuildAscensionTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.rankFrom == this.rankFrom &&
          other.rankTo == this.rankTo &&
          other.step == this.step &&
          other.questKey == this.questKey &&
          other.title == this.title &&
          other.description == this.description &&
          other.checkType == this.checkType &&
          other.checkParamsJson == this.checkParamsJson &&
          other.unlockLevel == this.unlockLevel &&
          other.xpReward == this.xpReward &&
          other.goldReward == this.goldReward &&
          other.completed == this.completed &&
          other.progress == this.progress &&
          other.progressTarget == this.progressTarget);
}

class GuildAscensionTableCompanion
    extends UpdateCompanion<GuildAscensionTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> rankFrom;
  final Value<String> rankTo;
  final Value<int> step;
  final Value<String> questKey;
  final Value<String> title;
  final Value<String> description;
  final Value<String> checkType;
  final Value<String> checkParamsJson;
  final Value<int> unlockLevel;
  final Value<int> xpReward;
  final Value<int> goldReward;
  final Value<bool> completed;
  final Value<int> progress;
  final Value<int> progressTarget;
  const GuildAscensionTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.rankFrom = const Value.absent(),
    this.rankTo = const Value.absent(),
    this.step = const Value.absent(),
    this.questKey = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.checkType = const Value.absent(),
    this.checkParamsJson = const Value.absent(),
    this.unlockLevel = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.goldReward = const Value.absent(),
    this.completed = const Value.absent(),
    this.progress = const Value.absent(),
    this.progressTarget = const Value.absent(),
  });
  GuildAscensionTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required String rankFrom,
    required String rankTo,
    required int step,
    required String questKey,
    required String title,
    required String description,
    required String checkType,
    required String checkParamsJson,
    required int unlockLevel,
    required int xpReward,
    required int goldReward,
    this.completed = const Value.absent(),
    this.progress = const Value.absent(),
    this.progressTarget = const Value.absent(),
  })  : playerId = Value(playerId),
        rankFrom = Value(rankFrom),
        rankTo = Value(rankTo),
        step = Value(step),
        questKey = Value(questKey),
        title = Value(title),
        description = Value(description),
        checkType = Value(checkType),
        checkParamsJson = Value(checkParamsJson),
        unlockLevel = Value(unlockLevel),
        xpReward = Value(xpReward),
        goldReward = Value(goldReward);
  static Insertable<GuildAscensionTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? rankFrom,
    Expression<String>? rankTo,
    Expression<int>? step,
    Expression<String>? questKey,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? checkType,
    Expression<String>? checkParamsJson,
    Expression<int>? unlockLevel,
    Expression<int>? xpReward,
    Expression<int>? goldReward,
    Expression<bool>? completed,
    Expression<int>? progress,
    Expression<int>? progressTarget,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (rankFrom != null) 'rank_from': rankFrom,
      if (rankTo != null) 'rank_to': rankTo,
      if (step != null) 'step': step,
      if (questKey != null) 'quest_key': questKey,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (checkType != null) 'check_type': checkType,
      if (checkParamsJson != null) 'check_params_json': checkParamsJson,
      if (unlockLevel != null) 'unlock_level': unlockLevel,
      if (xpReward != null) 'xp_reward': xpReward,
      if (goldReward != null) 'gold_reward': goldReward,
      if (completed != null) 'completed': completed,
      if (progress != null) 'progress': progress,
      if (progressTarget != null) 'progress_target': progressTarget,
    });
  }

  GuildAscensionTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<String>? rankFrom,
      Value<String>? rankTo,
      Value<int>? step,
      Value<String>? questKey,
      Value<String>? title,
      Value<String>? description,
      Value<String>? checkType,
      Value<String>? checkParamsJson,
      Value<int>? unlockLevel,
      Value<int>? xpReward,
      Value<int>? goldReward,
      Value<bool>? completed,
      Value<int>? progress,
      Value<int>? progressTarget}) {
    return GuildAscensionTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      rankFrom: rankFrom ?? this.rankFrom,
      rankTo: rankTo ?? this.rankTo,
      step: step ?? this.step,
      questKey: questKey ?? this.questKey,
      title: title ?? this.title,
      description: description ?? this.description,
      checkType: checkType ?? this.checkType,
      checkParamsJson: checkParamsJson ?? this.checkParamsJson,
      unlockLevel: unlockLevel ?? this.unlockLevel,
      xpReward: xpReward ?? this.xpReward,
      goldReward: goldReward ?? this.goldReward,
      completed: completed ?? this.completed,
      progress: progress ?? this.progress,
      progressTarget: progressTarget ?? this.progressTarget,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (rankFrom.present) {
      map['rank_from'] = Variable<String>(rankFrom.value);
    }
    if (rankTo.present) {
      map['rank_to'] = Variable<String>(rankTo.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (questKey.present) {
      map['quest_key'] = Variable<String>(questKey.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (checkType.present) {
      map['check_type'] = Variable<String>(checkType.value);
    }
    if (checkParamsJson.present) {
      map['check_params_json'] = Variable<String>(checkParamsJson.value);
    }
    if (unlockLevel.present) {
      map['unlock_level'] = Variable<int>(unlockLevel.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    if (goldReward.present) {
      map['gold_reward'] = Variable<int>(goldReward.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (progressTarget.present) {
      map['progress_target'] = Variable<int>(progressTarget.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GuildAscensionTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('rankFrom: $rankFrom, ')
          ..write('rankTo: $rankTo, ')
          ..write('step: $step, ')
          ..write('questKey: $questKey, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('checkType: $checkType, ')
          ..write('checkParamsJson: $checkParamsJson, ')
          ..write('unlockLevel: $unlockLevel, ')
          ..write('xpReward: $xpReward, ')
          ..write('goldReward: $goldReward, ')
          ..write('completed: $completed, ')
          ..write('progress: $progress, ')
          ..write('progressTarget: $progressTarget')
          ..write(')'))
        .toString();
  }
}

class $VitalismUniqueCatalogTableTable extends VitalismUniqueCatalogTable
    with
        TableInfo<$VitalismUniqueCatalogTableTable,
            VitalismUniqueCatalogTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VitalismUniqueCatalogTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _carrierNameMeta =
      const VerificationMeta('carrierName');
  @override
  late final GeneratedColumn<String> carrierName = GeneratedColumn<String>(
      'carrier_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
      'tier', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _themeDescriptionMeta =
      const VerificationMeta('themeDescription');
  @override
  late final GeneratedColumn<String> themeDescription = GeneratedColumn<String>(
      'theme_description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, carrierName, tier, themeDescription];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vitalism_unique_catalog';
  @override
  VerificationContext validateIntegrity(
      Insertable<VitalismUniqueCatalogTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('carrier_name')) {
      context.handle(
          _carrierNameMeta,
          carrierName.isAcceptableOrUnknown(
              data['carrier_name']!, _carrierNameMeta));
    } else if (isInserting) {
      context.missing(_carrierNameMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
          _tierMeta, tier.isAcceptableOrUnknown(data['tier']!, _tierMeta));
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('theme_description')) {
      context.handle(
          _themeDescriptionMeta,
          themeDescription.isAcceptableOrUnknown(
              data['theme_description']!, _themeDescriptionMeta));
    } else if (isInserting) {
      context.missing(_themeDescriptionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VitalismUniqueCatalogTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VitalismUniqueCatalogTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      carrierName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}carrier_name'])!,
      tier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tier'])!,
      themeDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}theme_description'])!,
    );
  }

  @override
  $VitalismUniqueCatalogTableTable createAlias(String alias) {
    return $VitalismUniqueCatalogTableTable(attachedDatabase, alias);
  }
}

class VitalismUniqueCatalogTableData extends DataClass
    implements Insertable<VitalismUniqueCatalogTableData> {
  final String id;
  final String name;
  final String carrierName;
  final String tier;
  final String themeDescription;
  const VitalismUniqueCatalogTableData(
      {required this.id,
      required this.name,
      required this.carrierName,
      required this.tier,
      required this.themeDescription});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['carrier_name'] = Variable<String>(carrierName);
    map['tier'] = Variable<String>(tier);
    map['theme_description'] = Variable<String>(themeDescription);
    return map;
  }

  VitalismUniqueCatalogTableCompanion toCompanion(bool nullToAbsent) {
    return VitalismUniqueCatalogTableCompanion(
      id: Value(id),
      name: Value(name),
      carrierName: Value(carrierName),
      tier: Value(tier),
      themeDescription: Value(themeDescription),
    );
  }

  factory VitalismUniqueCatalogTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VitalismUniqueCatalogTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      carrierName: serializer.fromJson<String>(json['carrierName']),
      tier: serializer.fromJson<String>(json['tier']),
      themeDescription: serializer.fromJson<String>(json['themeDescription']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'carrierName': serializer.toJson<String>(carrierName),
      'tier': serializer.toJson<String>(tier),
      'themeDescription': serializer.toJson<String>(themeDescription),
    };
  }

  VitalismUniqueCatalogTableData copyWith(
          {String? id,
          String? name,
          String? carrierName,
          String? tier,
          String? themeDescription}) =>
      VitalismUniqueCatalogTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        carrierName: carrierName ?? this.carrierName,
        tier: tier ?? this.tier,
        themeDescription: themeDescription ?? this.themeDescription,
      );
  VitalismUniqueCatalogTableData copyWithCompanion(
      VitalismUniqueCatalogTableCompanion data) {
    return VitalismUniqueCatalogTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      carrierName:
          data.carrierName.present ? data.carrierName.value : this.carrierName,
      tier: data.tier.present ? data.tier.value : this.tier,
      themeDescription: data.themeDescription.present
          ? data.themeDescription.value
          : this.themeDescription,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VitalismUniqueCatalogTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('carrierName: $carrierName, ')
          ..write('tier: $tier, ')
          ..write('themeDescription: $themeDescription')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, carrierName, tier, themeDescription);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VitalismUniqueCatalogTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.carrierName == this.carrierName &&
          other.tier == this.tier &&
          other.themeDescription == this.themeDescription);
}

class VitalismUniqueCatalogTableCompanion
    extends UpdateCompanion<VitalismUniqueCatalogTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> carrierName;
  final Value<String> tier;
  final Value<String> themeDescription;
  final Value<int> rowid;
  const VitalismUniqueCatalogTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.carrierName = const Value.absent(),
    this.tier = const Value.absent(),
    this.themeDescription = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VitalismUniqueCatalogTableCompanion.insert({
    required String id,
    required String name,
    required String carrierName,
    required String tier,
    required String themeDescription,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        carrierName = Value(carrierName),
        tier = Value(tier),
        themeDescription = Value(themeDescription);
  static Insertable<VitalismUniqueCatalogTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? carrierName,
    Expression<String>? tier,
    Expression<String>? themeDescription,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (carrierName != null) 'carrier_name': carrierName,
      if (tier != null) 'tier': tier,
      if (themeDescription != null) 'theme_description': themeDescription,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VitalismUniqueCatalogTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? carrierName,
      Value<String>? tier,
      Value<String>? themeDescription,
      Value<int>? rowid}) {
    return VitalismUniqueCatalogTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      carrierName: carrierName ?? this.carrierName,
      tier: tier ?? this.tier,
      themeDescription: themeDescription ?? this.themeDescription,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (carrierName.present) {
      map['carrier_name'] = Variable<String>(carrierName.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (themeDescription.present) {
      map['theme_description'] = Variable<String>(themeDescription.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VitalismUniqueCatalogTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('carrierName: $carrierName, ')
          ..write('tier: $tier, ')
          ..write('themeDescription: $themeDescription, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayerVitalismAffinitiesTableTable extends PlayerVitalismAffinitiesTable
    with
        TableInfo<$PlayerVitalismAffinitiesTableTable,
            PlayerVitalismAffinitiesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerVitalismAffinitiesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _vitalismIdMeta =
      const VerificationMeta('vitalismId');
  @override
  late final GeneratedColumn<String> vitalismId = GeneratedColumn<String>(
      'vitalism_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _acquiredAtMeta =
      const VerificationMeta('acquiredAt');
  @override
  late final GeneratedColumn<int> acquiredAt = GeneratedColumn<int>(
      'acquired_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _acquiredViaMeta =
      const VerificationMeta('acquiredVia');
  @override
  late final GeneratedColumn<String> acquiredVia = GeneratedColumn<String>(
      'acquired_via', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [playerId, vitalismId, acquiredAt, acquiredVia];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_vitalism_affinities';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlayerVitalismAffinitiesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('vitalism_id')) {
      context.handle(
          _vitalismIdMeta,
          vitalismId.isAcceptableOrUnknown(
              data['vitalism_id']!, _vitalismIdMeta));
    } else if (isInserting) {
      context.missing(_vitalismIdMeta);
    }
    if (data.containsKey('acquired_at')) {
      context.handle(
          _acquiredAtMeta,
          acquiredAt.isAcceptableOrUnknown(
              data['acquired_at']!, _acquiredAtMeta));
    } else if (isInserting) {
      context.missing(_acquiredAtMeta);
    }
    if (data.containsKey('acquired_via')) {
      context.handle(
          _acquiredViaMeta,
          acquiredVia.isAcceptableOrUnknown(
              data['acquired_via']!, _acquiredViaMeta));
    } else if (isInserting) {
      context.missing(_acquiredViaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, vitalismId};
  @override
  PlayerVitalismAffinitiesTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerVitalismAffinitiesTableData(
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      vitalismId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vitalism_id'])!,
      acquiredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}acquired_at'])!,
      acquiredVia: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}acquired_via'])!,
    );
  }

  @override
  $PlayerVitalismAffinitiesTableTable createAlias(String alias) {
    return $PlayerVitalismAffinitiesTableTable(attachedDatabase, alias);
  }
}

class PlayerVitalismAffinitiesTableData extends DataClass
    implements Insertable<PlayerVitalismAffinitiesTableData> {
  final int playerId;
  final String vitalismId;
  final int acquiredAt;
  final String acquiredVia;
  const PlayerVitalismAffinitiesTableData(
      {required this.playerId,
      required this.vitalismId,
      required this.acquiredAt,
      required this.acquiredVia});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['vitalism_id'] = Variable<String>(vitalismId);
    map['acquired_at'] = Variable<int>(acquiredAt);
    map['acquired_via'] = Variable<String>(acquiredVia);
    return map;
  }

  PlayerVitalismAffinitiesTableCompanion toCompanion(bool nullToAbsent) {
    return PlayerVitalismAffinitiesTableCompanion(
      playerId: Value(playerId),
      vitalismId: Value(vitalismId),
      acquiredAt: Value(acquiredAt),
      acquiredVia: Value(acquiredVia),
    );
  }

  factory PlayerVitalismAffinitiesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerVitalismAffinitiesTableData(
      playerId: serializer.fromJson<int>(json['playerId']),
      vitalismId: serializer.fromJson<String>(json['vitalismId']),
      acquiredAt: serializer.fromJson<int>(json['acquiredAt']),
      acquiredVia: serializer.fromJson<String>(json['acquiredVia']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'vitalismId': serializer.toJson<String>(vitalismId),
      'acquiredAt': serializer.toJson<int>(acquiredAt),
      'acquiredVia': serializer.toJson<String>(acquiredVia),
    };
  }

  PlayerVitalismAffinitiesTableData copyWith(
          {int? playerId,
          String? vitalismId,
          int? acquiredAt,
          String? acquiredVia}) =>
      PlayerVitalismAffinitiesTableData(
        playerId: playerId ?? this.playerId,
        vitalismId: vitalismId ?? this.vitalismId,
        acquiredAt: acquiredAt ?? this.acquiredAt,
        acquiredVia: acquiredVia ?? this.acquiredVia,
      );
  PlayerVitalismAffinitiesTableData copyWithCompanion(
      PlayerVitalismAffinitiesTableCompanion data) {
    return PlayerVitalismAffinitiesTableData(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      vitalismId:
          data.vitalismId.present ? data.vitalismId.value : this.vitalismId,
      acquiredAt:
          data.acquiredAt.present ? data.acquiredAt.value : this.acquiredAt,
      acquiredVia:
          data.acquiredVia.present ? data.acquiredVia.value : this.acquiredVia,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerVitalismAffinitiesTableData(')
          ..write('playerId: $playerId, ')
          ..write('vitalismId: $vitalismId, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('acquiredVia: $acquiredVia')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(playerId, vitalismId, acquiredAt, acquiredVia);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerVitalismAffinitiesTableData &&
          other.playerId == this.playerId &&
          other.vitalismId == this.vitalismId &&
          other.acquiredAt == this.acquiredAt &&
          other.acquiredVia == this.acquiredVia);
}

class PlayerVitalismAffinitiesTableCompanion
    extends UpdateCompanion<PlayerVitalismAffinitiesTableData> {
  final Value<int> playerId;
  final Value<String> vitalismId;
  final Value<int> acquiredAt;
  final Value<String> acquiredVia;
  final Value<int> rowid;
  const PlayerVitalismAffinitiesTableCompanion({
    this.playerId = const Value.absent(),
    this.vitalismId = const Value.absent(),
    this.acquiredAt = const Value.absent(),
    this.acquiredVia = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerVitalismAffinitiesTableCompanion.insert({
    required int playerId,
    required String vitalismId,
    required int acquiredAt,
    required String acquiredVia,
    this.rowid = const Value.absent(),
  })  : playerId = Value(playerId),
        vitalismId = Value(vitalismId),
        acquiredAt = Value(acquiredAt),
        acquiredVia = Value(acquiredVia);
  static Insertable<PlayerVitalismAffinitiesTableData> custom({
    Expression<int>? playerId,
    Expression<String>? vitalismId,
    Expression<int>? acquiredAt,
    Expression<String>? acquiredVia,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (vitalismId != null) 'vitalism_id': vitalismId,
      if (acquiredAt != null) 'acquired_at': acquiredAt,
      if (acquiredVia != null) 'acquired_via': acquiredVia,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerVitalismAffinitiesTableCompanion copyWith(
      {Value<int>? playerId,
      Value<String>? vitalismId,
      Value<int>? acquiredAt,
      Value<String>? acquiredVia,
      Value<int>? rowid}) {
    return PlayerVitalismAffinitiesTableCompanion(
      playerId: playerId ?? this.playerId,
      vitalismId: vitalismId ?? this.vitalismId,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      acquiredVia: acquiredVia ?? this.acquiredVia,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (vitalismId.present) {
      map['vitalism_id'] = Variable<String>(vitalismId.value);
    }
    if (acquiredAt.present) {
      map['acquired_at'] = Variable<int>(acquiredAt.value);
    }
    if (acquiredVia.present) {
      map['acquired_via'] = Variable<String>(acquiredVia.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerVitalismAffinitiesTableCompanion(')
          ..write('playerId: $playerId, ')
          ..write('vitalismId: $vitalismId, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('acquiredVia: $acquiredVia, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayerVitalismTreesTableTable extends PlayerVitalismTreesTable
    with
        TableInfo<$PlayerVitalismTreesTableTable,
            PlayerVitalismTreesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerVitalismTreesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _vitalismIdMeta =
      const VerificationMeta('vitalismId');
  @override
  late final GeneratedColumn<String> vitalismId = GeneratedColumn<String>(
      'vitalism_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
      'node_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unlockedMeta =
      const VerificationMeta('unlocked');
  @override
  late final GeneratedColumn<bool> unlocked = GeneratedColumn<bool>(
      'unlocked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("unlocked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _unlockedAtMeta =
      const VerificationMeta('unlockedAt');
  @override
  late final GeneratedColumn<int> unlockedAt = GeneratedColumn<int>(
      'unlocked_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [playerId, vitalismId, nodeId, unlocked, unlockedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_vitalism_trees';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlayerVitalismTreesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('vitalism_id')) {
      context.handle(
          _vitalismIdMeta,
          vitalismId.isAcceptableOrUnknown(
              data['vitalism_id']!, _vitalismIdMeta));
    } else if (isInserting) {
      context.missing(_vitalismIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(_nodeIdMeta,
          nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta));
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('unlocked')) {
      context.handle(_unlockedMeta,
          unlocked.isAcceptableOrUnknown(data['unlocked']!, _unlockedMeta));
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
          _unlockedAtMeta,
          unlockedAt.isAcceptableOrUnknown(
              data['unlocked_at']!, _unlockedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, vitalismId, nodeId};
  @override
  PlayerVitalismTreesTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerVitalismTreesTableData(
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      vitalismId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vitalism_id'])!,
      nodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}node_id'])!,
      unlocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}unlocked'])!,
      unlockedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unlocked_at']),
    );
  }

  @override
  $PlayerVitalismTreesTableTable createAlias(String alias) {
    return $PlayerVitalismTreesTableTable(attachedDatabase, alias);
  }
}

class PlayerVitalismTreesTableData extends DataClass
    implements Insertable<PlayerVitalismTreesTableData> {
  final int playerId;
  final String vitalismId;
  final String nodeId;
  final bool unlocked;
  final int? unlockedAt;
  const PlayerVitalismTreesTableData(
      {required this.playerId,
      required this.vitalismId,
      required this.nodeId,
      required this.unlocked,
      this.unlockedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['vitalism_id'] = Variable<String>(vitalismId);
    map['node_id'] = Variable<String>(nodeId);
    map['unlocked'] = Variable<bool>(unlocked);
    if (!nullToAbsent || unlockedAt != null) {
      map['unlocked_at'] = Variable<int>(unlockedAt);
    }
    return map;
  }

  PlayerVitalismTreesTableCompanion toCompanion(bool nullToAbsent) {
    return PlayerVitalismTreesTableCompanion(
      playerId: Value(playerId),
      vitalismId: Value(vitalismId),
      nodeId: Value(nodeId),
      unlocked: Value(unlocked),
      unlockedAt: unlockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockedAt),
    );
  }

  factory PlayerVitalismTreesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerVitalismTreesTableData(
      playerId: serializer.fromJson<int>(json['playerId']),
      vitalismId: serializer.fromJson<String>(json['vitalismId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      unlocked: serializer.fromJson<bool>(json['unlocked']),
      unlockedAt: serializer.fromJson<int?>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'vitalismId': serializer.toJson<String>(vitalismId),
      'nodeId': serializer.toJson<String>(nodeId),
      'unlocked': serializer.toJson<bool>(unlocked),
      'unlockedAt': serializer.toJson<int?>(unlockedAt),
    };
  }

  PlayerVitalismTreesTableData copyWith(
          {int? playerId,
          String? vitalismId,
          String? nodeId,
          bool? unlocked,
          Value<int?> unlockedAt = const Value.absent()}) =>
      PlayerVitalismTreesTableData(
        playerId: playerId ?? this.playerId,
        vitalismId: vitalismId ?? this.vitalismId,
        nodeId: nodeId ?? this.nodeId,
        unlocked: unlocked ?? this.unlocked,
        unlockedAt: unlockedAt.present ? unlockedAt.value : this.unlockedAt,
      );
  PlayerVitalismTreesTableData copyWithCompanion(
      PlayerVitalismTreesTableCompanion data) {
    return PlayerVitalismTreesTableData(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      vitalismId:
          data.vitalismId.present ? data.vitalismId.value : this.vitalismId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      unlocked: data.unlocked.present ? data.unlocked.value : this.unlocked,
      unlockedAt:
          data.unlockedAt.present ? data.unlockedAt.value : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerVitalismTreesTableData(')
          ..write('playerId: $playerId, ')
          ..write('vitalismId: $vitalismId, ')
          ..write('nodeId: $nodeId, ')
          ..write('unlocked: $unlocked, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(playerId, vitalismId, nodeId, unlocked, unlockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerVitalismTreesTableData &&
          other.playerId == this.playerId &&
          other.vitalismId == this.vitalismId &&
          other.nodeId == this.nodeId &&
          other.unlocked == this.unlocked &&
          other.unlockedAt == this.unlockedAt);
}

class PlayerVitalismTreesTableCompanion
    extends UpdateCompanion<PlayerVitalismTreesTableData> {
  final Value<int> playerId;
  final Value<String> vitalismId;
  final Value<String> nodeId;
  final Value<bool> unlocked;
  final Value<int?> unlockedAt;
  final Value<int> rowid;
  const PlayerVitalismTreesTableCompanion({
    this.playerId = const Value.absent(),
    this.vitalismId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.unlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerVitalismTreesTableCompanion.insert({
    required int playerId,
    required String vitalismId,
    required String nodeId,
    this.unlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : playerId = Value(playerId),
        vitalismId = Value(vitalismId),
        nodeId = Value(nodeId);
  static Insertable<PlayerVitalismTreesTableData> custom({
    Expression<int>? playerId,
    Expression<String>? vitalismId,
    Expression<String>? nodeId,
    Expression<bool>? unlocked,
    Expression<int>? unlockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (vitalismId != null) 'vitalism_id': vitalismId,
      if (nodeId != null) 'node_id': nodeId,
      if (unlocked != null) 'unlocked': unlocked,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerVitalismTreesTableCompanion copyWith(
      {Value<int>? playerId,
      Value<String>? vitalismId,
      Value<String>? nodeId,
      Value<bool>? unlocked,
      Value<int?>? unlockedAt,
      Value<int>? rowid}) {
    return PlayerVitalismTreesTableCompanion(
      playerId: playerId ?? this.playerId,
      vitalismId: vitalismId ?? this.vitalismId,
      nodeId: nodeId ?? this.nodeId,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (vitalismId.present) {
      map['vitalism_id'] = Variable<String>(vitalismId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (unlocked.present) {
      map['unlocked'] = Variable<bool>(unlocked.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<int>(unlockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerVitalismTreesTableCompanion(')
          ..write('playerId: $playerId, ')
          ..write('vitalismId: $vitalismId, ')
          ..write('nodeId: $nodeId, ')
          ..write('unlocked: $unlocked, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LifeVitalismPointsTableTable extends LifeVitalismPointsTable
    with TableInfo<$LifeVitalismPointsTableTable, LifeVitalismPointsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LifeVitalismPointsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalPointsMeta =
      const VerificationMeta('totalPoints');
  @override
  late final GeneratedColumn<int> totalPoints = GeneratedColumn<int>(
      'total_points', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sourceLogMeta =
      const VerificationMeta('sourceLog');
  @override
  late final GeneratedColumn<String> sourceLog = GeneratedColumn<String>(
      'source_log', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [playerId, totalPoints, sourceLog];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'life_vitalism_points';
  @override
  VerificationContext validateIntegrity(
      Insertable<LifeVitalismPointsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    }
    if (data.containsKey('total_points')) {
      context.handle(
          _totalPointsMeta,
          totalPoints.isAcceptableOrUnknown(
              data['total_points']!, _totalPointsMeta));
    }
    if (data.containsKey('source_log')) {
      context.handle(_sourceLogMeta,
          sourceLog.isAcceptableOrUnknown(data['source_log']!, _sourceLogMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId};
  @override
  LifeVitalismPointsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LifeVitalismPointsTableData(
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      totalPoints: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_points'])!,
      sourceLog: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_log'])!,
    );
  }

  @override
  $LifeVitalismPointsTableTable createAlias(String alias) {
    return $LifeVitalismPointsTableTable(attachedDatabase, alias);
  }
}

class LifeVitalismPointsTableData extends DataClass
    implements Insertable<LifeVitalismPointsTableData> {
  final int playerId;
  final int totalPoints;
  final String sourceLog;
  const LifeVitalismPointsTableData(
      {required this.playerId,
      required this.totalPoints,
      required this.sourceLog});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['total_points'] = Variable<int>(totalPoints);
    map['source_log'] = Variable<String>(sourceLog);
    return map;
  }

  LifeVitalismPointsTableCompanion toCompanion(bool nullToAbsent) {
    return LifeVitalismPointsTableCompanion(
      playerId: Value(playerId),
      totalPoints: Value(totalPoints),
      sourceLog: Value(sourceLog),
    );
  }

  factory LifeVitalismPointsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LifeVitalismPointsTableData(
      playerId: serializer.fromJson<int>(json['playerId']),
      totalPoints: serializer.fromJson<int>(json['totalPoints']),
      sourceLog: serializer.fromJson<String>(json['sourceLog']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'totalPoints': serializer.toJson<int>(totalPoints),
      'sourceLog': serializer.toJson<String>(sourceLog),
    };
  }

  LifeVitalismPointsTableData copyWith(
          {int? playerId, int? totalPoints, String? sourceLog}) =>
      LifeVitalismPointsTableData(
        playerId: playerId ?? this.playerId,
        totalPoints: totalPoints ?? this.totalPoints,
        sourceLog: sourceLog ?? this.sourceLog,
      );
  LifeVitalismPointsTableData copyWithCompanion(
      LifeVitalismPointsTableCompanion data) {
    return LifeVitalismPointsTableData(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      totalPoints:
          data.totalPoints.present ? data.totalPoints.value : this.totalPoints,
      sourceLog: data.sourceLog.present ? data.sourceLog.value : this.sourceLog,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LifeVitalismPointsTableData(')
          ..write('playerId: $playerId, ')
          ..write('totalPoints: $totalPoints, ')
          ..write('sourceLog: $sourceLog')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playerId, totalPoints, sourceLog);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LifeVitalismPointsTableData &&
          other.playerId == this.playerId &&
          other.totalPoints == this.totalPoints &&
          other.sourceLog == this.sourceLog);
}

class LifeVitalismPointsTableCompanion
    extends UpdateCompanion<LifeVitalismPointsTableData> {
  final Value<int> playerId;
  final Value<int> totalPoints;
  final Value<String> sourceLog;
  const LifeVitalismPointsTableCompanion({
    this.playerId = const Value.absent(),
    this.totalPoints = const Value.absent(),
    this.sourceLog = const Value.absent(),
  });
  LifeVitalismPointsTableCompanion.insert({
    this.playerId = const Value.absent(),
    this.totalPoints = const Value.absent(),
    this.sourceLog = const Value.absent(),
  });
  static Insertable<LifeVitalismPointsTableData> custom({
    Expression<int>? playerId,
    Expression<int>? totalPoints,
    Expression<String>? sourceLog,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (totalPoints != null) 'total_points': totalPoints,
      if (sourceLog != null) 'source_log': sourceLog,
    });
  }

  LifeVitalismPointsTableCompanion copyWith(
      {Value<int>? playerId,
      Value<int>? totalPoints,
      Value<String>? sourceLog}) {
    return LifeVitalismPointsTableCompanion(
      playerId: playerId ?? this.playerId,
      totalPoints: totalPoints ?? this.totalPoints,
      sourceLog: sourceLog ?? this.sourceLog,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (totalPoints.present) {
      map['total_points'] = Variable<int>(totalPoints.value);
    }
    if (sourceLog.present) {
      map['source_log'] = Variable<String>(sourceLog.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LifeVitalismPointsTableCompanion(')
          ..write('playerId: $playerId, ')
          ..write('totalPoints: $totalPoints, ')
          ..write('sourceLog: $sourceLog')
          ..write(')'))
        .toString();
  }
}

class $ItemsCatalogTableTable extends ItemsCatalogTable
    with TableInfo<$ItemsCatalogTableTable, ItemsCatalogTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsCatalogTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subtypeMeta =
      const VerificationMeta('subtype');
  @override
  late final GeneratedColumn<String> subtype = GeneratedColumn<String>(
      'subtype', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<String> rank = GeneratedColumn<String>(
      'rank', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _requiredRankMeta =
      const VerificationMeta('requiredRank');
  @override
  late final GeneratedColumn<String> requiredRank = GeneratedColumn<String>(
      'required_rank', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<String> rarity = GeneratedColumn<String>(
      'rarity', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('common'));
  static const VerificationMeta _isSecretMeta =
      const VerificationMeta('isSecret');
  @override
  late final GeneratedColumn<bool> isSecret = GeneratedColumn<bool>(
      'is_secret', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_secret" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isUniqueMeta =
      const VerificationMeta('isUnique');
  @override
  late final GeneratedColumn<bool> isUnique = GeneratedColumn<bool>(
      'is_unique', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_unique" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDarkItemMeta =
      const VerificationMeta('isDarkItem');
  @override
  late final GeneratedColumn<bool> isDarkItem = GeneratedColumn<bool>(
      'is_dark_item', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_dark_item" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isEvolvingMeta =
      const VerificationMeta('isEvolving');
  @override
  late final GeneratedColumn<bool> isEvolving = GeneratedColumn<bool>(
      'is_evolving', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_evolving" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _requiredLevelMeta =
      const VerificationMeta('requiredLevel');
  @override
  late final GeneratedColumn<int> requiredLevel = GeneratedColumn<int>(
      'required_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _allowedClassesMeta =
      const VerificationMeta('allowedClasses');
  @override
  late final GeneratedColumn<String> allowedClasses = GeneratedColumn<String>(
      'allowed_classes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _allowedFactionsMeta =
      const VerificationMeta('allowedFactions');
  @override
  late final GeneratedColumn<String> allowedFactions = GeneratedColumn<String>(
      'allowed_factions', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _statsMeta = const VerificationMeta('stats');
  @override
  late final GeneratedColumn<String> stats = GeneratedColumn<String>(
      'stats', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _effectsMeta =
      const VerificationMeta('effects');
  @override
  late final GeneratedColumn<String> effects = GeneratedColumn<String>(
      'effects', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _sourcesMeta =
      const VerificationMeta('sources');
  @override
  late final GeneratedColumn<String> sources = GeneratedColumn<String>(
      'sources', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _shopPriceCoinsMeta =
      const VerificationMeta('shopPriceCoins');
  @override
  late final GeneratedColumn<int> shopPriceCoins = GeneratedColumn<int>(
      'shop_price_coins', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _shopPriceGemsMeta =
      const VerificationMeta('shopPriceGems');
  @override
  late final GeneratedColumn<int> shopPriceGems = GeneratedColumn<int>(
      'shop_price_gems', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _stackMaxMeta =
      const VerificationMeta('stackMax');
  @override
  late final GeneratedColumn<int> stackMax = GeneratedColumn<int>(
      'stack_max', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _durabilityMaxMeta =
      const VerificationMeta('durabilityMax');
  @override
  late final GeneratedColumn<int> durabilityMax = GeneratedColumn<int>(
      'durability_max', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durabilityBreaksToMeta =
      const VerificationMeta('durabilityBreaksTo');
  @override
  late final GeneratedColumn<String> durabilityBreaksTo =
      GeneratedColumn<String>('durability_breaks_to', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isStackableMeta =
      const VerificationMeta('isStackable');
  @override
  late final GeneratedColumn<bool> isStackable = GeneratedColumn<bool>(
      'is_stackable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_stackable" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isConsumableMeta =
      const VerificationMeta('isConsumable');
  @override
  late final GeneratedColumn<bool> isConsumable = GeneratedColumn<bool>(
      'is_consumable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_consumable" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isEquippableMeta =
      const VerificationMeta('isEquippable');
  @override
  late final GeneratedColumn<bool> isEquippable = GeneratedColumn<bool>(
      'is_equippable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_equippable" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isTradableMeta =
      const VerificationMeta('isTradable');
  @override
  late final GeneratedColumn<bool> isTradable = GeneratedColumn<bool>(
      'is_tradable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_tradable" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isSellableMeta =
      const VerificationMeta('isSellable');
  @override
  late final GeneratedColumn<bool> isSellable = GeneratedColumn<bool>(
      'is_sellable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_sellable" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _bindOnPickupMeta =
      const VerificationMeta('bindOnPickup');
  @override
  late final GeneratedColumn<bool> bindOnPickup = GeneratedColumn<bool>(
      'bind_on_pickup', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("bind_on_pickup" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _craftRecipeIdMeta =
      const VerificationMeta('craftRecipeId');
  @override
  late final GeneratedColumn<String> craftRecipeId = GeneratedColumn<String>(
      'craft_recipe_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _forgeRecipeIdMeta =
      const VerificationMeta('forgeRecipeId');
  @override
  late final GeneratedColumn<String> forgeRecipeId = GeneratedColumn<String>(
      'forge_recipe_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _enchantAllowedMeta =
      const VerificationMeta('enchantAllowed');
  @override
  late final GeneratedColumn<bool> enchantAllowed = GeneratedColumn<bool>(
      'enchant_allowed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enchant_allowed" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _sombrioContentIdMeta =
      const VerificationMeta('sombrioContentId');
  @override
  late final GeneratedColumn<String> sombrioContentId = GeneratedColumn<String>(
      'sombrio_content_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _evolutionStagesMeta =
      const VerificationMeta('evolutionStages');
  @override
  late final GeneratedColumn<String> evolutionStages = GeneratedColumn<String>(
      'evolution_stages', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
      'image', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        key,
        name,
        description,
        type,
        subtype,
        slot,
        rank,
        requiredRank,
        rarity,
        isSecret,
        isUnique,
        isDarkItem,
        isEvolving,
        requiredLevel,
        allowedClasses,
        allowedFactions,
        stats,
        effects,
        sources,
        shopPriceCoins,
        shopPriceGems,
        stackMax,
        durabilityMax,
        durabilityBreaksTo,
        isStackable,
        isConsumable,
        isEquippable,
        isTradable,
        isSellable,
        bindOnPickup,
        craftRecipeId,
        forgeRecipeId,
        enchantAllowed,
        sombrioContentId,
        evolutionStages,
        image,
        icon
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items_catalog';
  @override
  VerificationContext validateIntegrity(
      Insertable<ItemsCatalogTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('subtype')) {
      context.handle(_subtypeMeta,
          subtype.isAcceptableOrUnknown(data['subtype']!, _subtypeMeta));
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    }
    if (data.containsKey('rank')) {
      context.handle(
          _rankMeta, rank.isAcceptableOrUnknown(data['rank']!, _rankMeta));
    }
    if (data.containsKey('required_rank')) {
      context.handle(
          _requiredRankMeta,
          requiredRank.isAcceptableOrUnknown(
              data['required_rank']!, _requiredRankMeta));
    }
    if (data.containsKey('rarity')) {
      context.handle(_rarityMeta,
          rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta));
    }
    if (data.containsKey('is_secret')) {
      context.handle(_isSecretMeta,
          isSecret.isAcceptableOrUnknown(data['is_secret']!, _isSecretMeta));
    }
    if (data.containsKey('is_unique')) {
      context.handle(_isUniqueMeta,
          isUnique.isAcceptableOrUnknown(data['is_unique']!, _isUniqueMeta));
    }
    if (data.containsKey('is_dark_item')) {
      context.handle(
          _isDarkItemMeta,
          isDarkItem.isAcceptableOrUnknown(
              data['is_dark_item']!, _isDarkItemMeta));
    }
    if (data.containsKey('is_evolving')) {
      context.handle(
          _isEvolvingMeta,
          isEvolving.isAcceptableOrUnknown(
              data['is_evolving']!, _isEvolvingMeta));
    }
    if (data.containsKey('required_level')) {
      context.handle(
          _requiredLevelMeta,
          requiredLevel.isAcceptableOrUnknown(
              data['required_level']!, _requiredLevelMeta));
    }
    if (data.containsKey('allowed_classes')) {
      context.handle(
          _allowedClassesMeta,
          allowedClasses.isAcceptableOrUnknown(
              data['allowed_classes']!, _allowedClassesMeta));
    }
    if (data.containsKey('allowed_factions')) {
      context.handle(
          _allowedFactionsMeta,
          allowedFactions.isAcceptableOrUnknown(
              data['allowed_factions']!, _allowedFactionsMeta));
    }
    if (data.containsKey('stats')) {
      context.handle(
          _statsMeta, stats.isAcceptableOrUnknown(data['stats']!, _statsMeta));
    }
    if (data.containsKey('effects')) {
      context.handle(_effectsMeta,
          effects.isAcceptableOrUnknown(data['effects']!, _effectsMeta));
    }
    if (data.containsKey('sources')) {
      context.handle(_sourcesMeta,
          sources.isAcceptableOrUnknown(data['sources']!, _sourcesMeta));
    }
    if (data.containsKey('shop_price_coins')) {
      context.handle(
          _shopPriceCoinsMeta,
          shopPriceCoins.isAcceptableOrUnknown(
              data['shop_price_coins']!, _shopPriceCoinsMeta));
    }
    if (data.containsKey('shop_price_gems')) {
      context.handle(
          _shopPriceGemsMeta,
          shopPriceGems.isAcceptableOrUnknown(
              data['shop_price_gems']!, _shopPriceGemsMeta));
    }
    if (data.containsKey('stack_max')) {
      context.handle(_stackMaxMeta,
          stackMax.isAcceptableOrUnknown(data['stack_max']!, _stackMaxMeta));
    }
    if (data.containsKey('durability_max')) {
      context.handle(
          _durabilityMaxMeta,
          durabilityMax.isAcceptableOrUnknown(
              data['durability_max']!, _durabilityMaxMeta));
    }
    if (data.containsKey('durability_breaks_to')) {
      context.handle(
          _durabilityBreaksToMeta,
          durabilityBreaksTo.isAcceptableOrUnknown(
              data['durability_breaks_to']!, _durabilityBreaksToMeta));
    }
    if (data.containsKey('is_stackable')) {
      context.handle(
          _isStackableMeta,
          isStackable.isAcceptableOrUnknown(
              data['is_stackable']!, _isStackableMeta));
    }
    if (data.containsKey('is_consumable')) {
      context.handle(
          _isConsumableMeta,
          isConsumable.isAcceptableOrUnknown(
              data['is_consumable']!, _isConsumableMeta));
    }
    if (data.containsKey('is_equippable')) {
      context.handle(
          _isEquippableMeta,
          isEquippable.isAcceptableOrUnknown(
              data['is_equippable']!, _isEquippableMeta));
    }
    if (data.containsKey('is_tradable')) {
      context.handle(
          _isTradableMeta,
          isTradable.isAcceptableOrUnknown(
              data['is_tradable']!, _isTradableMeta));
    }
    if (data.containsKey('is_sellable')) {
      context.handle(
          _isSellableMeta,
          isSellable.isAcceptableOrUnknown(
              data['is_sellable']!, _isSellableMeta));
    }
    if (data.containsKey('bind_on_pickup')) {
      context.handle(
          _bindOnPickupMeta,
          bindOnPickup.isAcceptableOrUnknown(
              data['bind_on_pickup']!, _bindOnPickupMeta));
    }
    if (data.containsKey('craft_recipe_id')) {
      context.handle(
          _craftRecipeIdMeta,
          craftRecipeId.isAcceptableOrUnknown(
              data['craft_recipe_id']!, _craftRecipeIdMeta));
    }
    if (data.containsKey('forge_recipe_id')) {
      context.handle(
          _forgeRecipeIdMeta,
          forgeRecipeId.isAcceptableOrUnknown(
              data['forge_recipe_id']!, _forgeRecipeIdMeta));
    }
    if (data.containsKey('enchant_allowed')) {
      context.handle(
          _enchantAllowedMeta,
          enchantAllowed.isAcceptableOrUnknown(
              data['enchant_allowed']!, _enchantAllowedMeta));
    }
    if (data.containsKey('sombrio_content_id')) {
      context.handle(
          _sombrioContentIdMeta,
          sombrioContentId.isAcceptableOrUnknown(
              data['sombrio_content_id']!, _sombrioContentIdMeta));
    }
    if (data.containsKey('evolution_stages')) {
      context.handle(
          _evolutionStagesMeta,
          evolutionStages.isAcceptableOrUnknown(
              data['evolution_stages']!, _evolutionStagesMeta));
    }
    if (data.containsKey('image')) {
      context.handle(
          _imageMeta, image.isAcceptableOrUnknown(data['image']!, _imageMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ItemsCatalogTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemsCatalogTableData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      subtype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtype']),
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot']),
      rank: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rank']),
      requiredRank: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}required_rank']),
      rarity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rarity'])!,
      isSecret: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_secret'])!,
      isUnique: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_unique'])!,
      isDarkItem: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_dark_item'])!,
      isEvolving: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_evolving'])!,
      requiredLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}required_level'])!,
      allowedClasses: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}allowed_classes'])!,
      allowedFactions: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}allowed_factions'])!,
      stats: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stats'])!,
      effects: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effects'])!,
      sources: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sources'])!,
      shopPriceCoins: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shop_price_coins']),
      shopPriceGems: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}shop_price_gems']),
      stackMax: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stack_max'])!,
      durabilityMax: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}durability_max']),
      durabilityBreaksTo: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}durability_breaks_to']),
      isStackable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_stackable'])!,
      isConsumable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_consumable'])!,
      isEquippable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_equippable'])!,
      isTradable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_tradable'])!,
      isSellable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_sellable'])!,
      bindOnPickup: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}bind_on_pickup'])!,
      craftRecipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}craft_recipe_id']),
      forgeRecipeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}forge_recipe_id']),
      enchantAllowed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enchant_allowed'])!,
      sombrioContentId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sombrio_content_id']),
      evolutionStages: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}evolution_stages']),
      image: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
    );
  }

  @override
  $ItemsCatalogTableTable createAlias(String alias) {
    return $ItemsCatalogTableTable(attachedDatabase, alias);
  }
}

class ItemsCatalogTableData extends DataClass
    implements Insertable<ItemsCatalogTableData> {
  final String key;
  final String name;
  final String description;
  final String type;
  final String? subtype;
  final String? slot;
  final String? rank;
  final String? requiredRank;
  final String rarity;
  final bool isSecret;
  final bool isUnique;
  final bool isDarkItem;
  final bool isEvolving;
  final int requiredLevel;
  final String allowedClasses;
  final String allowedFactions;
  final String stats;
  final String effects;
  final String sources;
  final int? shopPriceCoins;
  final int? shopPriceGems;
  final int stackMax;
  final int? durabilityMax;
  final String? durabilityBreaksTo;
  final bool isStackable;
  final bool isConsumable;
  final bool isEquippable;
  final bool isTradable;
  final bool isSellable;
  final bool bindOnPickup;
  final String? craftRecipeId;
  final String? forgeRecipeId;
  final bool enchantAllowed;
  final String? sombrioContentId;
  final String? evolutionStages;
  final String image;
  final String? icon;
  const ItemsCatalogTableData(
      {required this.key,
      required this.name,
      required this.description,
      required this.type,
      this.subtype,
      this.slot,
      this.rank,
      this.requiredRank,
      required this.rarity,
      required this.isSecret,
      required this.isUnique,
      required this.isDarkItem,
      required this.isEvolving,
      required this.requiredLevel,
      required this.allowedClasses,
      required this.allowedFactions,
      required this.stats,
      required this.effects,
      required this.sources,
      this.shopPriceCoins,
      this.shopPriceGems,
      required this.stackMax,
      this.durabilityMax,
      this.durabilityBreaksTo,
      required this.isStackable,
      required this.isConsumable,
      required this.isEquippable,
      required this.isTradable,
      required this.isSellable,
      required this.bindOnPickup,
      this.craftRecipeId,
      this.forgeRecipeId,
      required this.enchantAllowed,
      this.sombrioContentId,
      this.evolutionStages,
      required this.image,
      this.icon});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || subtype != null) {
      map['subtype'] = Variable<String>(subtype);
    }
    if (!nullToAbsent || slot != null) {
      map['slot'] = Variable<String>(slot);
    }
    if (!nullToAbsent || rank != null) {
      map['rank'] = Variable<String>(rank);
    }
    if (!nullToAbsent || requiredRank != null) {
      map['required_rank'] = Variable<String>(requiredRank);
    }
    map['rarity'] = Variable<String>(rarity);
    map['is_secret'] = Variable<bool>(isSecret);
    map['is_unique'] = Variable<bool>(isUnique);
    map['is_dark_item'] = Variable<bool>(isDarkItem);
    map['is_evolving'] = Variable<bool>(isEvolving);
    map['required_level'] = Variable<int>(requiredLevel);
    map['allowed_classes'] = Variable<String>(allowedClasses);
    map['allowed_factions'] = Variable<String>(allowedFactions);
    map['stats'] = Variable<String>(stats);
    map['effects'] = Variable<String>(effects);
    map['sources'] = Variable<String>(sources);
    if (!nullToAbsent || shopPriceCoins != null) {
      map['shop_price_coins'] = Variable<int>(shopPriceCoins);
    }
    if (!nullToAbsent || shopPriceGems != null) {
      map['shop_price_gems'] = Variable<int>(shopPriceGems);
    }
    map['stack_max'] = Variable<int>(stackMax);
    if (!nullToAbsent || durabilityMax != null) {
      map['durability_max'] = Variable<int>(durabilityMax);
    }
    if (!nullToAbsent || durabilityBreaksTo != null) {
      map['durability_breaks_to'] = Variable<String>(durabilityBreaksTo);
    }
    map['is_stackable'] = Variable<bool>(isStackable);
    map['is_consumable'] = Variable<bool>(isConsumable);
    map['is_equippable'] = Variable<bool>(isEquippable);
    map['is_tradable'] = Variable<bool>(isTradable);
    map['is_sellable'] = Variable<bool>(isSellable);
    map['bind_on_pickup'] = Variable<bool>(bindOnPickup);
    if (!nullToAbsent || craftRecipeId != null) {
      map['craft_recipe_id'] = Variable<String>(craftRecipeId);
    }
    if (!nullToAbsent || forgeRecipeId != null) {
      map['forge_recipe_id'] = Variable<String>(forgeRecipeId);
    }
    map['enchant_allowed'] = Variable<bool>(enchantAllowed);
    if (!nullToAbsent || sombrioContentId != null) {
      map['sombrio_content_id'] = Variable<String>(sombrioContentId);
    }
    if (!nullToAbsent || evolutionStages != null) {
      map['evolution_stages'] = Variable<String>(evolutionStages);
    }
    map['image'] = Variable<String>(image);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    return map;
  }

  ItemsCatalogTableCompanion toCompanion(bool nullToAbsent) {
    return ItemsCatalogTableCompanion(
      key: Value(key),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      subtype: subtype == null && nullToAbsent
          ? const Value.absent()
          : Value(subtype),
      slot: slot == null && nullToAbsent ? const Value.absent() : Value(slot),
      rank: rank == null && nullToAbsent ? const Value.absent() : Value(rank),
      requiredRank: requiredRank == null && nullToAbsent
          ? const Value.absent()
          : Value(requiredRank),
      rarity: Value(rarity),
      isSecret: Value(isSecret),
      isUnique: Value(isUnique),
      isDarkItem: Value(isDarkItem),
      isEvolving: Value(isEvolving),
      requiredLevel: Value(requiredLevel),
      allowedClasses: Value(allowedClasses),
      allowedFactions: Value(allowedFactions),
      stats: Value(stats),
      effects: Value(effects),
      sources: Value(sources),
      shopPriceCoins: shopPriceCoins == null && nullToAbsent
          ? const Value.absent()
          : Value(shopPriceCoins),
      shopPriceGems: shopPriceGems == null && nullToAbsent
          ? const Value.absent()
          : Value(shopPriceGems),
      stackMax: Value(stackMax),
      durabilityMax: durabilityMax == null && nullToAbsent
          ? const Value.absent()
          : Value(durabilityMax),
      durabilityBreaksTo: durabilityBreaksTo == null && nullToAbsent
          ? const Value.absent()
          : Value(durabilityBreaksTo),
      isStackable: Value(isStackable),
      isConsumable: Value(isConsumable),
      isEquippable: Value(isEquippable),
      isTradable: Value(isTradable),
      isSellable: Value(isSellable),
      bindOnPickup: Value(bindOnPickup),
      craftRecipeId: craftRecipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(craftRecipeId),
      forgeRecipeId: forgeRecipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(forgeRecipeId),
      enchantAllowed: Value(enchantAllowed),
      sombrioContentId: sombrioContentId == null && nullToAbsent
          ? const Value.absent()
          : Value(sombrioContentId),
      evolutionStages: evolutionStages == null && nullToAbsent
          ? const Value.absent()
          : Value(evolutionStages),
      image: Value(image),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
    );
  }

  factory ItemsCatalogTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemsCatalogTableData(
      key: serializer.fromJson<String>(json['key']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      subtype: serializer.fromJson<String?>(json['subtype']),
      slot: serializer.fromJson<String?>(json['slot']),
      rank: serializer.fromJson<String?>(json['rank']),
      requiredRank: serializer.fromJson<String?>(json['requiredRank']),
      rarity: serializer.fromJson<String>(json['rarity']),
      isSecret: serializer.fromJson<bool>(json['isSecret']),
      isUnique: serializer.fromJson<bool>(json['isUnique']),
      isDarkItem: serializer.fromJson<bool>(json['isDarkItem']),
      isEvolving: serializer.fromJson<bool>(json['isEvolving']),
      requiredLevel: serializer.fromJson<int>(json['requiredLevel']),
      allowedClasses: serializer.fromJson<String>(json['allowedClasses']),
      allowedFactions: serializer.fromJson<String>(json['allowedFactions']),
      stats: serializer.fromJson<String>(json['stats']),
      effects: serializer.fromJson<String>(json['effects']),
      sources: serializer.fromJson<String>(json['sources']),
      shopPriceCoins: serializer.fromJson<int?>(json['shopPriceCoins']),
      shopPriceGems: serializer.fromJson<int?>(json['shopPriceGems']),
      stackMax: serializer.fromJson<int>(json['stackMax']),
      durabilityMax: serializer.fromJson<int?>(json['durabilityMax']),
      durabilityBreaksTo:
          serializer.fromJson<String?>(json['durabilityBreaksTo']),
      isStackable: serializer.fromJson<bool>(json['isStackable']),
      isConsumable: serializer.fromJson<bool>(json['isConsumable']),
      isEquippable: serializer.fromJson<bool>(json['isEquippable']),
      isTradable: serializer.fromJson<bool>(json['isTradable']),
      isSellable: serializer.fromJson<bool>(json['isSellable']),
      bindOnPickup: serializer.fromJson<bool>(json['bindOnPickup']),
      craftRecipeId: serializer.fromJson<String?>(json['craftRecipeId']),
      forgeRecipeId: serializer.fromJson<String?>(json['forgeRecipeId']),
      enchantAllowed: serializer.fromJson<bool>(json['enchantAllowed']),
      sombrioContentId: serializer.fromJson<String?>(json['sombrioContentId']),
      evolutionStages: serializer.fromJson<String?>(json['evolutionStages']),
      image: serializer.fromJson<String>(json['image']),
      icon: serializer.fromJson<String?>(json['icon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'subtype': serializer.toJson<String?>(subtype),
      'slot': serializer.toJson<String?>(slot),
      'rank': serializer.toJson<String?>(rank),
      'requiredRank': serializer.toJson<String?>(requiredRank),
      'rarity': serializer.toJson<String>(rarity),
      'isSecret': serializer.toJson<bool>(isSecret),
      'isUnique': serializer.toJson<bool>(isUnique),
      'isDarkItem': serializer.toJson<bool>(isDarkItem),
      'isEvolving': serializer.toJson<bool>(isEvolving),
      'requiredLevel': serializer.toJson<int>(requiredLevel),
      'allowedClasses': serializer.toJson<String>(allowedClasses),
      'allowedFactions': serializer.toJson<String>(allowedFactions),
      'stats': serializer.toJson<String>(stats),
      'effects': serializer.toJson<String>(effects),
      'sources': serializer.toJson<String>(sources),
      'shopPriceCoins': serializer.toJson<int?>(shopPriceCoins),
      'shopPriceGems': serializer.toJson<int?>(shopPriceGems),
      'stackMax': serializer.toJson<int>(stackMax),
      'durabilityMax': serializer.toJson<int?>(durabilityMax),
      'durabilityBreaksTo': serializer.toJson<String?>(durabilityBreaksTo),
      'isStackable': serializer.toJson<bool>(isStackable),
      'isConsumable': serializer.toJson<bool>(isConsumable),
      'isEquippable': serializer.toJson<bool>(isEquippable),
      'isTradable': serializer.toJson<bool>(isTradable),
      'isSellable': serializer.toJson<bool>(isSellable),
      'bindOnPickup': serializer.toJson<bool>(bindOnPickup),
      'craftRecipeId': serializer.toJson<String?>(craftRecipeId),
      'forgeRecipeId': serializer.toJson<String?>(forgeRecipeId),
      'enchantAllowed': serializer.toJson<bool>(enchantAllowed),
      'sombrioContentId': serializer.toJson<String?>(sombrioContentId),
      'evolutionStages': serializer.toJson<String?>(evolutionStages),
      'image': serializer.toJson<String>(image),
      'icon': serializer.toJson<String?>(icon),
    };
  }

  ItemsCatalogTableData copyWith(
          {String? key,
          String? name,
          String? description,
          String? type,
          Value<String?> subtype = const Value.absent(),
          Value<String?> slot = const Value.absent(),
          Value<String?> rank = const Value.absent(),
          Value<String?> requiredRank = const Value.absent(),
          String? rarity,
          bool? isSecret,
          bool? isUnique,
          bool? isDarkItem,
          bool? isEvolving,
          int? requiredLevel,
          String? allowedClasses,
          String? allowedFactions,
          String? stats,
          String? effects,
          String? sources,
          Value<int?> shopPriceCoins = const Value.absent(),
          Value<int?> shopPriceGems = const Value.absent(),
          int? stackMax,
          Value<int?> durabilityMax = const Value.absent(),
          Value<String?> durabilityBreaksTo = const Value.absent(),
          bool? isStackable,
          bool? isConsumable,
          bool? isEquippable,
          bool? isTradable,
          bool? isSellable,
          bool? bindOnPickup,
          Value<String?> craftRecipeId = const Value.absent(),
          Value<String?> forgeRecipeId = const Value.absent(),
          bool? enchantAllowed,
          Value<String?> sombrioContentId = const Value.absent(),
          Value<String?> evolutionStages = const Value.absent(),
          String? image,
          Value<String?> icon = const Value.absent()}) =>
      ItemsCatalogTableData(
        key: key ?? this.key,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        subtype: subtype.present ? subtype.value : this.subtype,
        slot: slot.present ? slot.value : this.slot,
        rank: rank.present ? rank.value : this.rank,
        requiredRank:
            requiredRank.present ? requiredRank.value : this.requiredRank,
        rarity: rarity ?? this.rarity,
        isSecret: isSecret ?? this.isSecret,
        isUnique: isUnique ?? this.isUnique,
        isDarkItem: isDarkItem ?? this.isDarkItem,
        isEvolving: isEvolving ?? this.isEvolving,
        requiredLevel: requiredLevel ?? this.requiredLevel,
        allowedClasses: allowedClasses ?? this.allowedClasses,
        allowedFactions: allowedFactions ?? this.allowedFactions,
        stats: stats ?? this.stats,
        effects: effects ?? this.effects,
        sources: sources ?? this.sources,
        shopPriceCoins:
            shopPriceCoins.present ? shopPriceCoins.value : this.shopPriceCoins,
        shopPriceGems:
            shopPriceGems.present ? shopPriceGems.value : this.shopPriceGems,
        stackMax: stackMax ?? this.stackMax,
        durabilityMax:
            durabilityMax.present ? durabilityMax.value : this.durabilityMax,
        durabilityBreaksTo: durabilityBreaksTo.present
            ? durabilityBreaksTo.value
            : this.durabilityBreaksTo,
        isStackable: isStackable ?? this.isStackable,
        isConsumable: isConsumable ?? this.isConsumable,
        isEquippable: isEquippable ?? this.isEquippable,
        isTradable: isTradable ?? this.isTradable,
        isSellable: isSellable ?? this.isSellable,
        bindOnPickup: bindOnPickup ?? this.bindOnPickup,
        craftRecipeId:
            craftRecipeId.present ? craftRecipeId.value : this.craftRecipeId,
        forgeRecipeId:
            forgeRecipeId.present ? forgeRecipeId.value : this.forgeRecipeId,
        enchantAllowed: enchantAllowed ?? this.enchantAllowed,
        sombrioContentId: sombrioContentId.present
            ? sombrioContentId.value
            : this.sombrioContentId,
        evolutionStages: evolutionStages.present
            ? evolutionStages.value
            : this.evolutionStages,
        image: image ?? this.image,
        icon: icon.present ? icon.value : this.icon,
      );
  ItemsCatalogTableData copyWithCompanion(ItemsCatalogTableCompanion data) {
    return ItemsCatalogTableData(
      key: data.key.present ? data.key.value : this.key,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      type: data.type.present ? data.type.value : this.type,
      subtype: data.subtype.present ? data.subtype.value : this.subtype,
      slot: data.slot.present ? data.slot.value : this.slot,
      rank: data.rank.present ? data.rank.value : this.rank,
      requiredRank: data.requiredRank.present
          ? data.requiredRank.value
          : this.requiredRank,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      isSecret: data.isSecret.present ? data.isSecret.value : this.isSecret,
      isUnique: data.isUnique.present ? data.isUnique.value : this.isUnique,
      isDarkItem:
          data.isDarkItem.present ? data.isDarkItem.value : this.isDarkItem,
      isEvolving:
          data.isEvolving.present ? data.isEvolving.value : this.isEvolving,
      requiredLevel: data.requiredLevel.present
          ? data.requiredLevel.value
          : this.requiredLevel,
      allowedClasses: data.allowedClasses.present
          ? data.allowedClasses.value
          : this.allowedClasses,
      allowedFactions: data.allowedFactions.present
          ? data.allowedFactions.value
          : this.allowedFactions,
      stats: data.stats.present ? data.stats.value : this.stats,
      effects: data.effects.present ? data.effects.value : this.effects,
      sources: data.sources.present ? data.sources.value : this.sources,
      shopPriceCoins: data.shopPriceCoins.present
          ? data.shopPriceCoins.value
          : this.shopPriceCoins,
      shopPriceGems: data.shopPriceGems.present
          ? data.shopPriceGems.value
          : this.shopPriceGems,
      stackMax: data.stackMax.present ? data.stackMax.value : this.stackMax,
      durabilityMax: data.durabilityMax.present
          ? data.durabilityMax.value
          : this.durabilityMax,
      durabilityBreaksTo: data.durabilityBreaksTo.present
          ? data.durabilityBreaksTo.value
          : this.durabilityBreaksTo,
      isStackable:
          data.isStackable.present ? data.isStackable.value : this.isStackable,
      isConsumable: data.isConsumable.present
          ? data.isConsumable.value
          : this.isConsumable,
      isEquippable: data.isEquippable.present
          ? data.isEquippable.value
          : this.isEquippable,
      isTradable:
          data.isTradable.present ? data.isTradable.value : this.isTradable,
      isSellable:
          data.isSellable.present ? data.isSellable.value : this.isSellable,
      bindOnPickup: data.bindOnPickup.present
          ? data.bindOnPickup.value
          : this.bindOnPickup,
      craftRecipeId: data.craftRecipeId.present
          ? data.craftRecipeId.value
          : this.craftRecipeId,
      forgeRecipeId: data.forgeRecipeId.present
          ? data.forgeRecipeId.value
          : this.forgeRecipeId,
      enchantAllowed: data.enchantAllowed.present
          ? data.enchantAllowed.value
          : this.enchantAllowed,
      sombrioContentId: data.sombrioContentId.present
          ? data.sombrioContentId.value
          : this.sombrioContentId,
      evolutionStages: data.evolutionStages.present
          ? data.evolutionStages.value
          : this.evolutionStages,
      image: data.image.present ? data.image.value : this.image,
      icon: data.icon.present ? data.icon.value : this.icon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCatalogTableData(')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('slot: $slot, ')
          ..write('rank: $rank, ')
          ..write('requiredRank: $requiredRank, ')
          ..write('rarity: $rarity, ')
          ..write('isSecret: $isSecret, ')
          ..write('isUnique: $isUnique, ')
          ..write('isDarkItem: $isDarkItem, ')
          ..write('isEvolving: $isEvolving, ')
          ..write('requiredLevel: $requiredLevel, ')
          ..write('allowedClasses: $allowedClasses, ')
          ..write('allowedFactions: $allowedFactions, ')
          ..write('stats: $stats, ')
          ..write('effects: $effects, ')
          ..write('sources: $sources, ')
          ..write('shopPriceCoins: $shopPriceCoins, ')
          ..write('shopPriceGems: $shopPriceGems, ')
          ..write('stackMax: $stackMax, ')
          ..write('durabilityMax: $durabilityMax, ')
          ..write('durabilityBreaksTo: $durabilityBreaksTo, ')
          ..write('isStackable: $isStackable, ')
          ..write('isConsumable: $isConsumable, ')
          ..write('isEquippable: $isEquippable, ')
          ..write('isTradable: $isTradable, ')
          ..write('isSellable: $isSellable, ')
          ..write('bindOnPickup: $bindOnPickup, ')
          ..write('craftRecipeId: $craftRecipeId, ')
          ..write('forgeRecipeId: $forgeRecipeId, ')
          ..write('enchantAllowed: $enchantAllowed, ')
          ..write('sombrioContentId: $sombrioContentId, ')
          ..write('evolutionStages: $evolutionStages, ')
          ..write('image: $image, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        key,
        name,
        description,
        type,
        subtype,
        slot,
        rank,
        requiredRank,
        rarity,
        isSecret,
        isUnique,
        isDarkItem,
        isEvolving,
        requiredLevel,
        allowedClasses,
        allowedFactions,
        stats,
        effects,
        sources,
        shopPriceCoins,
        shopPriceGems,
        stackMax,
        durabilityMax,
        durabilityBreaksTo,
        isStackable,
        isConsumable,
        isEquippable,
        isTradable,
        isSellable,
        bindOnPickup,
        craftRecipeId,
        forgeRecipeId,
        enchantAllowed,
        sombrioContentId,
        evolutionStages,
        image,
        icon
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemsCatalogTableData &&
          other.key == this.key &&
          other.name == this.name &&
          other.description == this.description &&
          other.type == this.type &&
          other.subtype == this.subtype &&
          other.slot == this.slot &&
          other.rank == this.rank &&
          other.requiredRank == this.requiredRank &&
          other.rarity == this.rarity &&
          other.isSecret == this.isSecret &&
          other.isUnique == this.isUnique &&
          other.isDarkItem == this.isDarkItem &&
          other.isEvolving == this.isEvolving &&
          other.requiredLevel == this.requiredLevel &&
          other.allowedClasses == this.allowedClasses &&
          other.allowedFactions == this.allowedFactions &&
          other.stats == this.stats &&
          other.effects == this.effects &&
          other.sources == this.sources &&
          other.shopPriceCoins == this.shopPriceCoins &&
          other.shopPriceGems == this.shopPriceGems &&
          other.stackMax == this.stackMax &&
          other.durabilityMax == this.durabilityMax &&
          other.durabilityBreaksTo == this.durabilityBreaksTo &&
          other.isStackable == this.isStackable &&
          other.isConsumable == this.isConsumable &&
          other.isEquippable == this.isEquippable &&
          other.isTradable == this.isTradable &&
          other.isSellable == this.isSellable &&
          other.bindOnPickup == this.bindOnPickup &&
          other.craftRecipeId == this.craftRecipeId &&
          other.forgeRecipeId == this.forgeRecipeId &&
          other.enchantAllowed == this.enchantAllowed &&
          other.sombrioContentId == this.sombrioContentId &&
          other.evolutionStages == this.evolutionStages &&
          other.image == this.image &&
          other.icon == this.icon);
}

class ItemsCatalogTableCompanion
    extends UpdateCompanion<ItemsCatalogTableData> {
  final Value<String> key;
  final Value<String> name;
  final Value<String> description;
  final Value<String> type;
  final Value<String?> subtype;
  final Value<String?> slot;
  final Value<String?> rank;
  final Value<String?> requiredRank;
  final Value<String> rarity;
  final Value<bool> isSecret;
  final Value<bool> isUnique;
  final Value<bool> isDarkItem;
  final Value<bool> isEvolving;
  final Value<int> requiredLevel;
  final Value<String> allowedClasses;
  final Value<String> allowedFactions;
  final Value<String> stats;
  final Value<String> effects;
  final Value<String> sources;
  final Value<int?> shopPriceCoins;
  final Value<int?> shopPriceGems;
  final Value<int> stackMax;
  final Value<int?> durabilityMax;
  final Value<String?> durabilityBreaksTo;
  final Value<bool> isStackable;
  final Value<bool> isConsumable;
  final Value<bool> isEquippable;
  final Value<bool> isTradable;
  final Value<bool> isSellable;
  final Value<bool> bindOnPickup;
  final Value<String?> craftRecipeId;
  final Value<String?> forgeRecipeId;
  final Value<bool> enchantAllowed;
  final Value<String?> sombrioContentId;
  final Value<String?> evolutionStages;
  final Value<String> image;
  final Value<String?> icon;
  final Value<int> rowid;
  const ItemsCatalogTableCompanion({
    this.key = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.subtype = const Value.absent(),
    this.slot = const Value.absent(),
    this.rank = const Value.absent(),
    this.requiredRank = const Value.absent(),
    this.rarity = const Value.absent(),
    this.isSecret = const Value.absent(),
    this.isUnique = const Value.absent(),
    this.isDarkItem = const Value.absent(),
    this.isEvolving = const Value.absent(),
    this.requiredLevel = const Value.absent(),
    this.allowedClasses = const Value.absent(),
    this.allowedFactions = const Value.absent(),
    this.stats = const Value.absent(),
    this.effects = const Value.absent(),
    this.sources = const Value.absent(),
    this.shopPriceCoins = const Value.absent(),
    this.shopPriceGems = const Value.absent(),
    this.stackMax = const Value.absent(),
    this.durabilityMax = const Value.absent(),
    this.durabilityBreaksTo = const Value.absent(),
    this.isStackable = const Value.absent(),
    this.isConsumable = const Value.absent(),
    this.isEquippable = const Value.absent(),
    this.isTradable = const Value.absent(),
    this.isSellable = const Value.absent(),
    this.bindOnPickup = const Value.absent(),
    this.craftRecipeId = const Value.absent(),
    this.forgeRecipeId = const Value.absent(),
    this.enchantAllowed = const Value.absent(),
    this.sombrioContentId = const Value.absent(),
    this.evolutionStages = const Value.absent(),
    this.image = const Value.absent(),
    this.icon = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCatalogTableCompanion.insert({
    required String key,
    required String name,
    this.description = const Value.absent(),
    required String type,
    this.subtype = const Value.absent(),
    this.slot = const Value.absent(),
    this.rank = const Value.absent(),
    this.requiredRank = const Value.absent(),
    this.rarity = const Value.absent(),
    this.isSecret = const Value.absent(),
    this.isUnique = const Value.absent(),
    this.isDarkItem = const Value.absent(),
    this.isEvolving = const Value.absent(),
    this.requiredLevel = const Value.absent(),
    this.allowedClasses = const Value.absent(),
    this.allowedFactions = const Value.absent(),
    this.stats = const Value.absent(),
    this.effects = const Value.absent(),
    this.sources = const Value.absent(),
    this.shopPriceCoins = const Value.absent(),
    this.shopPriceGems = const Value.absent(),
    this.stackMax = const Value.absent(),
    this.durabilityMax = const Value.absent(),
    this.durabilityBreaksTo = const Value.absent(),
    this.isStackable = const Value.absent(),
    this.isConsumable = const Value.absent(),
    this.isEquippable = const Value.absent(),
    this.isTradable = const Value.absent(),
    this.isSellable = const Value.absent(),
    this.bindOnPickup = const Value.absent(),
    this.craftRecipeId = const Value.absent(),
    this.forgeRecipeId = const Value.absent(),
    this.enchantAllowed = const Value.absent(),
    this.sombrioContentId = const Value.absent(),
    this.evolutionStages = const Value.absent(),
    this.image = const Value.absent(),
    this.icon = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        name = Value(name),
        type = Value(type);
  static Insertable<ItemsCatalogTableData> custom({
    Expression<String>? key,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? subtype,
    Expression<String>? slot,
    Expression<String>? rank,
    Expression<String>? requiredRank,
    Expression<String>? rarity,
    Expression<bool>? isSecret,
    Expression<bool>? isUnique,
    Expression<bool>? isDarkItem,
    Expression<bool>? isEvolving,
    Expression<int>? requiredLevel,
    Expression<String>? allowedClasses,
    Expression<String>? allowedFactions,
    Expression<String>? stats,
    Expression<String>? effects,
    Expression<String>? sources,
    Expression<int>? shopPriceCoins,
    Expression<int>? shopPriceGems,
    Expression<int>? stackMax,
    Expression<int>? durabilityMax,
    Expression<String>? durabilityBreaksTo,
    Expression<bool>? isStackable,
    Expression<bool>? isConsumable,
    Expression<bool>? isEquippable,
    Expression<bool>? isTradable,
    Expression<bool>? isSellable,
    Expression<bool>? bindOnPickup,
    Expression<String>? craftRecipeId,
    Expression<String>? forgeRecipeId,
    Expression<bool>? enchantAllowed,
    Expression<String>? sombrioContentId,
    Expression<String>? evolutionStages,
    Expression<String>? image,
    Expression<String>? icon,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (subtype != null) 'subtype': subtype,
      if (slot != null) 'slot': slot,
      if (rank != null) 'rank': rank,
      if (requiredRank != null) 'required_rank': requiredRank,
      if (rarity != null) 'rarity': rarity,
      if (isSecret != null) 'is_secret': isSecret,
      if (isUnique != null) 'is_unique': isUnique,
      if (isDarkItem != null) 'is_dark_item': isDarkItem,
      if (isEvolving != null) 'is_evolving': isEvolving,
      if (requiredLevel != null) 'required_level': requiredLevel,
      if (allowedClasses != null) 'allowed_classes': allowedClasses,
      if (allowedFactions != null) 'allowed_factions': allowedFactions,
      if (stats != null) 'stats': stats,
      if (effects != null) 'effects': effects,
      if (sources != null) 'sources': sources,
      if (shopPriceCoins != null) 'shop_price_coins': shopPriceCoins,
      if (shopPriceGems != null) 'shop_price_gems': shopPriceGems,
      if (stackMax != null) 'stack_max': stackMax,
      if (durabilityMax != null) 'durability_max': durabilityMax,
      if (durabilityBreaksTo != null)
        'durability_breaks_to': durabilityBreaksTo,
      if (isStackable != null) 'is_stackable': isStackable,
      if (isConsumable != null) 'is_consumable': isConsumable,
      if (isEquippable != null) 'is_equippable': isEquippable,
      if (isTradable != null) 'is_tradable': isTradable,
      if (isSellable != null) 'is_sellable': isSellable,
      if (bindOnPickup != null) 'bind_on_pickup': bindOnPickup,
      if (craftRecipeId != null) 'craft_recipe_id': craftRecipeId,
      if (forgeRecipeId != null) 'forge_recipe_id': forgeRecipeId,
      if (enchantAllowed != null) 'enchant_allowed': enchantAllowed,
      if (sombrioContentId != null) 'sombrio_content_id': sombrioContentId,
      if (evolutionStages != null) 'evolution_stages': evolutionStages,
      if (image != null) 'image': image,
      if (icon != null) 'icon': icon,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCatalogTableCompanion copyWith(
      {Value<String>? key,
      Value<String>? name,
      Value<String>? description,
      Value<String>? type,
      Value<String?>? subtype,
      Value<String?>? slot,
      Value<String?>? rank,
      Value<String?>? requiredRank,
      Value<String>? rarity,
      Value<bool>? isSecret,
      Value<bool>? isUnique,
      Value<bool>? isDarkItem,
      Value<bool>? isEvolving,
      Value<int>? requiredLevel,
      Value<String>? allowedClasses,
      Value<String>? allowedFactions,
      Value<String>? stats,
      Value<String>? effects,
      Value<String>? sources,
      Value<int?>? shopPriceCoins,
      Value<int?>? shopPriceGems,
      Value<int>? stackMax,
      Value<int?>? durabilityMax,
      Value<String?>? durabilityBreaksTo,
      Value<bool>? isStackable,
      Value<bool>? isConsumable,
      Value<bool>? isEquippable,
      Value<bool>? isTradable,
      Value<bool>? isSellable,
      Value<bool>? bindOnPickup,
      Value<String?>? craftRecipeId,
      Value<String?>? forgeRecipeId,
      Value<bool>? enchantAllowed,
      Value<String?>? sombrioContentId,
      Value<String?>? evolutionStages,
      Value<String>? image,
      Value<String?>? icon,
      Value<int>? rowid}) {
    return ItemsCatalogTableCompanion(
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      slot: slot ?? this.slot,
      rank: rank ?? this.rank,
      requiredRank: requiredRank ?? this.requiredRank,
      rarity: rarity ?? this.rarity,
      isSecret: isSecret ?? this.isSecret,
      isUnique: isUnique ?? this.isUnique,
      isDarkItem: isDarkItem ?? this.isDarkItem,
      isEvolving: isEvolving ?? this.isEvolving,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      allowedClasses: allowedClasses ?? this.allowedClasses,
      allowedFactions: allowedFactions ?? this.allowedFactions,
      stats: stats ?? this.stats,
      effects: effects ?? this.effects,
      sources: sources ?? this.sources,
      shopPriceCoins: shopPriceCoins ?? this.shopPriceCoins,
      shopPriceGems: shopPriceGems ?? this.shopPriceGems,
      stackMax: stackMax ?? this.stackMax,
      durabilityMax: durabilityMax ?? this.durabilityMax,
      durabilityBreaksTo: durabilityBreaksTo ?? this.durabilityBreaksTo,
      isStackable: isStackable ?? this.isStackable,
      isConsumable: isConsumable ?? this.isConsumable,
      isEquippable: isEquippable ?? this.isEquippable,
      isTradable: isTradable ?? this.isTradable,
      isSellable: isSellable ?? this.isSellable,
      bindOnPickup: bindOnPickup ?? this.bindOnPickup,
      craftRecipeId: craftRecipeId ?? this.craftRecipeId,
      forgeRecipeId: forgeRecipeId ?? this.forgeRecipeId,
      enchantAllowed: enchantAllowed ?? this.enchantAllowed,
      sombrioContentId: sombrioContentId ?? this.sombrioContentId,
      evolutionStages: evolutionStages ?? this.evolutionStages,
      image: image ?? this.image,
      icon: icon ?? this.icon,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subtype.present) {
      map['subtype'] = Variable<String>(subtype.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (rank.present) {
      map['rank'] = Variable<String>(rank.value);
    }
    if (requiredRank.present) {
      map['required_rank'] = Variable<String>(requiredRank.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<String>(rarity.value);
    }
    if (isSecret.present) {
      map['is_secret'] = Variable<bool>(isSecret.value);
    }
    if (isUnique.present) {
      map['is_unique'] = Variable<bool>(isUnique.value);
    }
    if (isDarkItem.present) {
      map['is_dark_item'] = Variable<bool>(isDarkItem.value);
    }
    if (isEvolving.present) {
      map['is_evolving'] = Variable<bool>(isEvolving.value);
    }
    if (requiredLevel.present) {
      map['required_level'] = Variable<int>(requiredLevel.value);
    }
    if (allowedClasses.present) {
      map['allowed_classes'] = Variable<String>(allowedClasses.value);
    }
    if (allowedFactions.present) {
      map['allowed_factions'] = Variable<String>(allowedFactions.value);
    }
    if (stats.present) {
      map['stats'] = Variable<String>(stats.value);
    }
    if (effects.present) {
      map['effects'] = Variable<String>(effects.value);
    }
    if (sources.present) {
      map['sources'] = Variable<String>(sources.value);
    }
    if (shopPriceCoins.present) {
      map['shop_price_coins'] = Variable<int>(shopPriceCoins.value);
    }
    if (shopPriceGems.present) {
      map['shop_price_gems'] = Variable<int>(shopPriceGems.value);
    }
    if (stackMax.present) {
      map['stack_max'] = Variable<int>(stackMax.value);
    }
    if (durabilityMax.present) {
      map['durability_max'] = Variable<int>(durabilityMax.value);
    }
    if (durabilityBreaksTo.present) {
      map['durability_breaks_to'] = Variable<String>(durabilityBreaksTo.value);
    }
    if (isStackable.present) {
      map['is_stackable'] = Variable<bool>(isStackable.value);
    }
    if (isConsumable.present) {
      map['is_consumable'] = Variable<bool>(isConsumable.value);
    }
    if (isEquippable.present) {
      map['is_equippable'] = Variable<bool>(isEquippable.value);
    }
    if (isTradable.present) {
      map['is_tradable'] = Variable<bool>(isTradable.value);
    }
    if (isSellable.present) {
      map['is_sellable'] = Variable<bool>(isSellable.value);
    }
    if (bindOnPickup.present) {
      map['bind_on_pickup'] = Variable<bool>(bindOnPickup.value);
    }
    if (craftRecipeId.present) {
      map['craft_recipe_id'] = Variable<String>(craftRecipeId.value);
    }
    if (forgeRecipeId.present) {
      map['forge_recipe_id'] = Variable<String>(forgeRecipeId.value);
    }
    if (enchantAllowed.present) {
      map['enchant_allowed'] = Variable<bool>(enchantAllowed.value);
    }
    if (sombrioContentId.present) {
      map['sombrio_content_id'] = Variable<String>(sombrioContentId.value);
    }
    if (evolutionStages.present) {
      map['evolution_stages'] = Variable<String>(evolutionStages.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCatalogTableCompanion(')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('subtype: $subtype, ')
          ..write('slot: $slot, ')
          ..write('rank: $rank, ')
          ..write('requiredRank: $requiredRank, ')
          ..write('rarity: $rarity, ')
          ..write('isSecret: $isSecret, ')
          ..write('isUnique: $isUnique, ')
          ..write('isDarkItem: $isDarkItem, ')
          ..write('isEvolving: $isEvolving, ')
          ..write('requiredLevel: $requiredLevel, ')
          ..write('allowedClasses: $allowedClasses, ')
          ..write('allowedFactions: $allowedFactions, ')
          ..write('stats: $stats, ')
          ..write('effects: $effects, ')
          ..write('sources: $sources, ')
          ..write('shopPriceCoins: $shopPriceCoins, ')
          ..write('shopPriceGems: $shopPriceGems, ')
          ..write('stackMax: $stackMax, ')
          ..write('durabilityMax: $durabilityMax, ')
          ..write('durabilityBreaksTo: $durabilityBreaksTo, ')
          ..write('isStackable: $isStackable, ')
          ..write('isConsumable: $isConsumable, ')
          ..write('isEquippable: $isEquippable, ')
          ..write('isTradable: $isTradable, ')
          ..write('isSellable: $isSellable, ')
          ..write('bindOnPickup: $bindOnPickup, ')
          ..write('craftRecipeId: $craftRecipeId, ')
          ..write('forgeRecipeId: $forgeRecipeId, ')
          ..write('enchantAllowed: $enchantAllowed, ')
          ..write('sombrioContentId: $sombrioContentId, ')
          ..write('evolutionStages: $evolutionStages, ')
          ..write('image: $image, ')
          ..write('icon: $icon, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayerInventoryTableTable extends PlayerInventoryTable
    with TableInfo<$PlayerInventoryTableTable, PlayerInventoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerInventoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _itemKeyMeta =
      const VerificationMeta('itemKey');
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
      'item_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _durabilityCurrentMeta =
      const VerificationMeta('durabilityCurrent');
  @override
  late final GeneratedColumn<int> durabilityCurrent = GeneratedColumn<int>(
      'durability_current', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _acquiredAtMeta =
      const VerificationMeta('acquiredAt');
  @override
  late final GeneratedColumn<int> acquiredAt = GeneratedColumn<int>(
      'acquired_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _acquiredViaMeta =
      const VerificationMeta('acquiredVia');
  @override
  late final GeneratedColumn<String> acquiredVia = GeneratedColumn<String>(
      'acquired_via', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _evolutionStageMeta =
      const VerificationMeta('evolutionStage');
  @override
  late final GeneratedColumn<String> evolutionStage = GeneratedColumn<String>(
      'evolution_stage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isEquippedMeta =
      const VerificationMeta('isEquipped');
  @override
  late final GeneratedColumn<bool> isEquipped = GeneratedColumn<bool>(
      'is_equipped', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_equipped" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _appliedRuneKeyMeta =
      const VerificationMeta('appliedRuneKey');
  @override
  late final GeneratedColumn<String> appliedRuneKey = GeneratedColumn<String>(
      'applied_rune_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _appliedSapKeyMeta =
      const VerificationMeta('appliedSapKey');
  @override
  late final GeneratedColumn<String> appliedSapKey = GeneratedColumn<String>(
      'applied_sap_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sapChargesRemainingMeta =
      const VerificationMeta('sapChargesRemaining');
  @override
  late final GeneratedColumn<int> sapChargesRemaining = GeneratedColumn<int>(
      'sap_charges_remaining', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        playerId,
        itemKey,
        quantity,
        durabilityCurrent,
        acquiredAt,
        acquiredVia,
        evolutionStage,
        isEquipped,
        appliedRuneKey,
        appliedSapKey,
        sapChargesRemaining
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_inventory';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlayerInventoryTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('item_key')) {
      context.handle(_itemKeyMeta,
          itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta));
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('durability_current')) {
      context.handle(
          _durabilityCurrentMeta,
          durabilityCurrent.isAcceptableOrUnknown(
              data['durability_current']!, _durabilityCurrentMeta));
    }
    if (data.containsKey('acquired_at')) {
      context.handle(
          _acquiredAtMeta,
          acquiredAt.isAcceptableOrUnknown(
              data['acquired_at']!, _acquiredAtMeta));
    } else if (isInserting) {
      context.missing(_acquiredAtMeta);
    }
    if (data.containsKey('acquired_via')) {
      context.handle(
          _acquiredViaMeta,
          acquiredVia.isAcceptableOrUnknown(
              data['acquired_via']!, _acquiredViaMeta));
    } else if (isInserting) {
      context.missing(_acquiredViaMeta);
    }
    if (data.containsKey('evolution_stage')) {
      context.handle(
          _evolutionStageMeta,
          evolutionStage.isAcceptableOrUnknown(
              data['evolution_stage']!, _evolutionStageMeta));
    }
    if (data.containsKey('is_equipped')) {
      context.handle(
          _isEquippedMeta,
          isEquipped.isAcceptableOrUnknown(
              data['is_equipped']!, _isEquippedMeta));
    }
    if (data.containsKey('applied_rune_key')) {
      context.handle(
          _appliedRuneKeyMeta,
          appliedRuneKey.isAcceptableOrUnknown(
              data['applied_rune_key']!, _appliedRuneKeyMeta));
    }
    if (data.containsKey('applied_sap_key')) {
      context.handle(
          _appliedSapKeyMeta,
          appliedSapKey.isAcceptableOrUnknown(
              data['applied_sap_key']!, _appliedSapKeyMeta));
    }
    if (data.containsKey('sap_charges_remaining')) {
      context.handle(
          _sapChargesRemainingMeta,
          sapChargesRemaining.isAcceptableOrUnknown(
              data['sap_charges_remaining']!, _sapChargesRemainingMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerInventoryTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerInventoryTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      itemKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_key'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      durabilityCurrent: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}durability_current']),
      acquiredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}acquired_at'])!,
      acquiredVia: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}acquired_via'])!,
      evolutionStage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evolution_stage']),
      isEquipped: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_equipped'])!,
      appliedRuneKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}applied_rune_key']),
      appliedSapKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}applied_sap_key']),
      sapChargesRemaining: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}sap_charges_remaining']),
    );
  }

  @override
  $PlayerInventoryTableTable createAlias(String alias) {
    return $PlayerInventoryTableTable(attachedDatabase, alias);
  }
}

class PlayerInventoryTableData extends DataClass
    implements Insertable<PlayerInventoryTableData> {
  final int id;
  final int playerId;
  final String itemKey;
  final int quantity;
  final int? durabilityCurrent;
  final int acquiredAt;
  final String acquiredVia;
  final String? evolutionStage;
  final bool isEquipped;
  final String? appliedRuneKey;
  final String? appliedSapKey;
  final int? sapChargesRemaining;
  const PlayerInventoryTableData(
      {required this.id,
      required this.playerId,
      required this.itemKey,
      required this.quantity,
      this.durabilityCurrent,
      required this.acquiredAt,
      required this.acquiredVia,
      this.evolutionStage,
      required this.isEquipped,
      this.appliedRuneKey,
      this.appliedSapKey,
      this.sapChargesRemaining});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<int>(playerId);
    map['item_key'] = Variable<String>(itemKey);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || durabilityCurrent != null) {
      map['durability_current'] = Variable<int>(durabilityCurrent);
    }
    map['acquired_at'] = Variable<int>(acquiredAt);
    map['acquired_via'] = Variable<String>(acquiredVia);
    if (!nullToAbsent || evolutionStage != null) {
      map['evolution_stage'] = Variable<String>(evolutionStage);
    }
    map['is_equipped'] = Variable<bool>(isEquipped);
    if (!nullToAbsent || appliedRuneKey != null) {
      map['applied_rune_key'] = Variable<String>(appliedRuneKey);
    }
    if (!nullToAbsent || appliedSapKey != null) {
      map['applied_sap_key'] = Variable<String>(appliedSapKey);
    }
    if (!nullToAbsent || sapChargesRemaining != null) {
      map['sap_charges_remaining'] = Variable<int>(sapChargesRemaining);
    }
    return map;
  }

  PlayerInventoryTableCompanion toCompanion(bool nullToAbsent) {
    return PlayerInventoryTableCompanion(
      id: Value(id),
      playerId: Value(playerId),
      itemKey: Value(itemKey),
      quantity: Value(quantity),
      durabilityCurrent: durabilityCurrent == null && nullToAbsent
          ? const Value.absent()
          : Value(durabilityCurrent),
      acquiredAt: Value(acquiredAt),
      acquiredVia: Value(acquiredVia),
      evolutionStage: evolutionStage == null && nullToAbsent
          ? const Value.absent()
          : Value(evolutionStage),
      isEquipped: Value(isEquipped),
      appliedRuneKey: appliedRuneKey == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedRuneKey),
      appliedSapKey: appliedSapKey == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedSapKey),
      sapChargesRemaining: sapChargesRemaining == null && nullToAbsent
          ? const Value.absent()
          : Value(sapChargesRemaining),
    );
  }

  factory PlayerInventoryTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerInventoryTableData(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<int>(json['playerId']),
      itemKey: serializer.fromJson<String>(json['itemKey']),
      quantity: serializer.fromJson<int>(json['quantity']),
      durabilityCurrent: serializer.fromJson<int?>(json['durabilityCurrent']),
      acquiredAt: serializer.fromJson<int>(json['acquiredAt']),
      acquiredVia: serializer.fromJson<String>(json['acquiredVia']),
      evolutionStage: serializer.fromJson<String?>(json['evolutionStage']),
      isEquipped: serializer.fromJson<bool>(json['isEquipped']),
      appliedRuneKey: serializer.fromJson<String?>(json['appliedRuneKey']),
      appliedSapKey: serializer.fromJson<String?>(json['appliedSapKey']),
      sapChargesRemaining:
          serializer.fromJson<int?>(json['sapChargesRemaining']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<int>(playerId),
      'itemKey': serializer.toJson<String>(itemKey),
      'quantity': serializer.toJson<int>(quantity),
      'durabilityCurrent': serializer.toJson<int?>(durabilityCurrent),
      'acquiredAt': serializer.toJson<int>(acquiredAt),
      'acquiredVia': serializer.toJson<String>(acquiredVia),
      'evolutionStage': serializer.toJson<String?>(evolutionStage),
      'isEquipped': serializer.toJson<bool>(isEquipped),
      'appliedRuneKey': serializer.toJson<String?>(appliedRuneKey),
      'appliedSapKey': serializer.toJson<String?>(appliedSapKey),
      'sapChargesRemaining': serializer.toJson<int?>(sapChargesRemaining),
    };
  }

  PlayerInventoryTableData copyWith(
          {int? id,
          int? playerId,
          String? itemKey,
          int? quantity,
          Value<int?> durabilityCurrent = const Value.absent(),
          int? acquiredAt,
          String? acquiredVia,
          Value<String?> evolutionStage = const Value.absent(),
          bool? isEquipped,
          Value<String?> appliedRuneKey = const Value.absent(),
          Value<String?> appliedSapKey = const Value.absent(),
          Value<int?> sapChargesRemaining = const Value.absent()}) =>
      PlayerInventoryTableData(
        id: id ?? this.id,
        playerId: playerId ?? this.playerId,
        itemKey: itemKey ?? this.itemKey,
        quantity: quantity ?? this.quantity,
        durabilityCurrent: durabilityCurrent.present
            ? durabilityCurrent.value
            : this.durabilityCurrent,
        acquiredAt: acquiredAt ?? this.acquiredAt,
        acquiredVia: acquiredVia ?? this.acquiredVia,
        evolutionStage:
            evolutionStage.present ? evolutionStage.value : this.evolutionStage,
        isEquipped: isEquipped ?? this.isEquipped,
        appliedRuneKey:
            appliedRuneKey.present ? appliedRuneKey.value : this.appliedRuneKey,
        appliedSapKey:
            appliedSapKey.present ? appliedSapKey.value : this.appliedSapKey,
        sapChargesRemaining: sapChargesRemaining.present
            ? sapChargesRemaining.value
            : this.sapChargesRemaining,
      );
  PlayerInventoryTableData copyWithCompanion(
      PlayerInventoryTableCompanion data) {
    return PlayerInventoryTableData(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      durabilityCurrent: data.durabilityCurrent.present
          ? data.durabilityCurrent.value
          : this.durabilityCurrent,
      acquiredAt:
          data.acquiredAt.present ? data.acquiredAt.value : this.acquiredAt,
      acquiredVia:
          data.acquiredVia.present ? data.acquiredVia.value : this.acquiredVia,
      evolutionStage: data.evolutionStage.present
          ? data.evolutionStage.value
          : this.evolutionStage,
      isEquipped:
          data.isEquipped.present ? data.isEquipped.value : this.isEquipped,
      appliedRuneKey: data.appliedRuneKey.present
          ? data.appliedRuneKey.value
          : this.appliedRuneKey,
      appliedSapKey: data.appliedSapKey.present
          ? data.appliedSapKey.value
          : this.appliedSapKey,
      sapChargesRemaining: data.sapChargesRemaining.present
          ? data.sapChargesRemaining.value
          : this.sapChargesRemaining,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerInventoryTableData(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('itemKey: $itemKey, ')
          ..write('quantity: $quantity, ')
          ..write('durabilityCurrent: $durabilityCurrent, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('acquiredVia: $acquiredVia, ')
          ..write('evolutionStage: $evolutionStage, ')
          ..write('isEquipped: $isEquipped, ')
          ..write('appliedRuneKey: $appliedRuneKey, ')
          ..write('appliedSapKey: $appliedSapKey, ')
          ..write('sapChargesRemaining: $sapChargesRemaining')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      playerId,
      itemKey,
      quantity,
      durabilityCurrent,
      acquiredAt,
      acquiredVia,
      evolutionStage,
      isEquipped,
      appliedRuneKey,
      appliedSapKey,
      sapChargesRemaining);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerInventoryTableData &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.itemKey == this.itemKey &&
          other.quantity == this.quantity &&
          other.durabilityCurrent == this.durabilityCurrent &&
          other.acquiredAt == this.acquiredAt &&
          other.acquiredVia == this.acquiredVia &&
          other.evolutionStage == this.evolutionStage &&
          other.isEquipped == this.isEquipped &&
          other.appliedRuneKey == this.appliedRuneKey &&
          other.appliedSapKey == this.appliedSapKey &&
          other.sapChargesRemaining == this.sapChargesRemaining);
}

class PlayerInventoryTableCompanion
    extends UpdateCompanion<PlayerInventoryTableData> {
  final Value<int> id;
  final Value<int> playerId;
  final Value<String> itemKey;
  final Value<int> quantity;
  final Value<int?> durabilityCurrent;
  final Value<int> acquiredAt;
  final Value<String> acquiredVia;
  final Value<String?> evolutionStage;
  final Value<bool> isEquipped;
  final Value<String?> appliedRuneKey;
  final Value<String?> appliedSapKey;
  final Value<int?> sapChargesRemaining;
  const PlayerInventoryTableCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.itemKey = const Value.absent(),
    this.quantity = const Value.absent(),
    this.durabilityCurrent = const Value.absent(),
    this.acquiredAt = const Value.absent(),
    this.acquiredVia = const Value.absent(),
    this.evolutionStage = const Value.absent(),
    this.isEquipped = const Value.absent(),
    this.appliedRuneKey = const Value.absent(),
    this.appliedSapKey = const Value.absent(),
    this.sapChargesRemaining = const Value.absent(),
  });
  PlayerInventoryTableCompanion.insert({
    this.id = const Value.absent(),
    required int playerId,
    required String itemKey,
    this.quantity = const Value.absent(),
    this.durabilityCurrent = const Value.absent(),
    required int acquiredAt,
    required String acquiredVia,
    this.evolutionStage = const Value.absent(),
    this.isEquipped = const Value.absent(),
    this.appliedRuneKey = const Value.absent(),
    this.appliedSapKey = const Value.absent(),
    this.sapChargesRemaining = const Value.absent(),
  })  : playerId = Value(playerId),
        itemKey = Value(itemKey),
        acquiredAt = Value(acquiredAt),
        acquiredVia = Value(acquiredVia);
  static Insertable<PlayerInventoryTableData> custom({
    Expression<int>? id,
    Expression<int>? playerId,
    Expression<String>? itemKey,
    Expression<int>? quantity,
    Expression<int>? durabilityCurrent,
    Expression<int>? acquiredAt,
    Expression<String>? acquiredVia,
    Expression<String>? evolutionStage,
    Expression<bool>? isEquipped,
    Expression<String>? appliedRuneKey,
    Expression<String>? appliedSapKey,
    Expression<int>? sapChargesRemaining,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (itemKey != null) 'item_key': itemKey,
      if (quantity != null) 'quantity': quantity,
      if (durabilityCurrent != null) 'durability_current': durabilityCurrent,
      if (acquiredAt != null) 'acquired_at': acquiredAt,
      if (acquiredVia != null) 'acquired_via': acquiredVia,
      if (evolutionStage != null) 'evolution_stage': evolutionStage,
      if (isEquipped != null) 'is_equipped': isEquipped,
      if (appliedRuneKey != null) 'applied_rune_key': appliedRuneKey,
      if (appliedSapKey != null) 'applied_sap_key': appliedSapKey,
      if (sapChargesRemaining != null)
        'sap_charges_remaining': sapChargesRemaining,
    });
  }

  PlayerInventoryTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? playerId,
      Value<String>? itemKey,
      Value<int>? quantity,
      Value<int?>? durabilityCurrent,
      Value<int>? acquiredAt,
      Value<String>? acquiredVia,
      Value<String?>? evolutionStage,
      Value<bool>? isEquipped,
      Value<String?>? appliedRuneKey,
      Value<String?>? appliedSapKey,
      Value<int?>? sapChargesRemaining}) {
    return PlayerInventoryTableCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      itemKey: itemKey ?? this.itemKey,
      quantity: quantity ?? this.quantity,
      durabilityCurrent: durabilityCurrent ?? this.durabilityCurrent,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      acquiredVia: acquiredVia ?? this.acquiredVia,
      evolutionStage: evolutionStage ?? this.evolutionStage,
      isEquipped: isEquipped ?? this.isEquipped,
      appliedRuneKey: appliedRuneKey ?? this.appliedRuneKey,
      appliedSapKey: appliedSapKey ?? this.appliedSapKey,
      sapChargesRemaining: sapChargesRemaining ?? this.sapChargesRemaining,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (durabilityCurrent.present) {
      map['durability_current'] = Variable<int>(durabilityCurrent.value);
    }
    if (acquiredAt.present) {
      map['acquired_at'] = Variable<int>(acquiredAt.value);
    }
    if (acquiredVia.present) {
      map['acquired_via'] = Variable<String>(acquiredVia.value);
    }
    if (evolutionStage.present) {
      map['evolution_stage'] = Variable<String>(evolutionStage.value);
    }
    if (isEquipped.present) {
      map['is_equipped'] = Variable<bool>(isEquipped.value);
    }
    if (appliedRuneKey.present) {
      map['applied_rune_key'] = Variable<String>(appliedRuneKey.value);
    }
    if (appliedSapKey.present) {
      map['applied_sap_key'] = Variable<String>(appliedSapKey.value);
    }
    if (sapChargesRemaining.present) {
      map['sap_charges_remaining'] = Variable<int>(sapChargesRemaining.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerInventoryTableCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('itemKey: $itemKey, ')
          ..write('quantity: $quantity, ')
          ..write('durabilityCurrent: $durabilityCurrent, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('acquiredVia: $acquiredVia, ')
          ..write('evolutionStage: $evolutionStage, ')
          ..write('isEquipped: $isEquipped, ')
          ..write('appliedRuneKey: $appliedRuneKey, ')
          ..write('appliedSapKey: $appliedSapKey, ')
          ..write('sapChargesRemaining: $sapChargesRemaining')
          ..write(')'))
        .toString();
  }
}

class $PlayerEquipmentTableTable extends PlayerEquipmentTable
    with TableInfo<$PlayerEquipmentTableTable, PlayerEquipmentTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerEquipmentTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inventoryIdMeta =
      const VerificationMeta('inventoryId');
  @override
  late final GeneratedColumn<int> inventoryId = GeneratedColumn<int>(
      'inventory_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [playerId, slot, inventoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_equipment';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlayerEquipmentTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('inventory_id')) {
      context.handle(
          _inventoryIdMeta,
          inventoryId.isAcceptableOrUnknown(
              data['inventory_id']!, _inventoryIdMeta));
    } else if (isInserting) {
      context.missing(_inventoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, slot};
  @override
  PlayerEquipmentTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerEquipmentTableData(
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot'])!,
      inventoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}inventory_id'])!,
    );
  }

  @override
  $PlayerEquipmentTableTable createAlias(String alias) {
    return $PlayerEquipmentTableTable(attachedDatabase, alias);
  }
}

class PlayerEquipmentTableData extends DataClass
    implements Insertable<PlayerEquipmentTableData> {
  final int playerId;
  final String slot;
  final int inventoryId;
  const PlayerEquipmentTableData(
      {required this.playerId, required this.slot, required this.inventoryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['slot'] = Variable<String>(slot);
    map['inventory_id'] = Variable<int>(inventoryId);
    return map;
  }

  PlayerEquipmentTableCompanion toCompanion(bool nullToAbsent) {
    return PlayerEquipmentTableCompanion(
      playerId: Value(playerId),
      slot: Value(slot),
      inventoryId: Value(inventoryId),
    );
  }

  factory PlayerEquipmentTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerEquipmentTableData(
      playerId: serializer.fromJson<int>(json['playerId']),
      slot: serializer.fromJson<String>(json['slot']),
      inventoryId: serializer.fromJson<int>(json['inventoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'slot': serializer.toJson<String>(slot),
      'inventoryId': serializer.toJson<int>(inventoryId),
    };
  }

  PlayerEquipmentTableData copyWith(
          {int? playerId, String? slot, int? inventoryId}) =>
      PlayerEquipmentTableData(
        playerId: playerId ?? this.playerId,
        slot: slot ?? this.slot,
        inventoryId: inventoryId ?? this.inventoryId,
      );
  PlayerEquipmentTableData copyWithCompanion(
      PlayerEquipmentTableCompanion data) {
    return PlayerEquipmentTableData(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      slot: data.slot.present ? data.slot.value : this.slot,
      inventoryId:
          data.inventoryId.present ? data.inventoryId.value : this.inventoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerEquipmentTableData(')
          ..write('playerId: $playerId, ')
          ..write('slot: $slot, ')
          ..write('inventoryId: $inventoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playerId, slot, inventoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerEquipmentTableData &&
          other.playerId == this.playerId &&
          other.slot == this.slot &&
          other.inventoryId == this.inventoryId);
}

class PlayerEquipmentTableCompanion
    extends UpdateCompanion<PlayerEquipmentTableData> {
  final Value<int> playerId;
  final Value<String> slot;
  final Value<int> inventoryId;
  final Value<int> rowid;
  const PlayerEquipmentTableCompanion({
    this.playerId = const Value.absent(),
    this.slot = const Value.absent(),
    this.inventoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerEquipmentTableCompanion.insert({
    required int playerId,
    required String slot,
    required int inventoryId,
    this.rowid = const Value.absent(),
  })  : playerId = Value(playerId),
        slot = Value(slot),
        inventoryId = Value(inventoryId);
  static Insertable<PlayerEquipmentTableData> custom({
    Expression<int>? playerId,
    Expression<String>? slot,
    Expression<int>? inventoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (slot != null) 'slot': slot,
      if (inventoryId != null) 'inventory_id': inventoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerEquipmentTableCompanion copyWith(
      {Value<int>? playerId,
      Value<String>? slot,
      Value<int>? inventoryId,
      Value<int>? rowid}) {
    return PlayerEquipmentTableCompanion(
      playerId: playerId ?? this.playerId,
      slot: slot ?? this.slot,
      inventoryId: inventoryId ?? this.inventoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (inventoryId.present) {
      map['inventory_id'] = Variable<int>(inventoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerEquipmentTableCompanion(')
          ..write('playerId: $playerId, ')
          ..write('slot: $slot, ')
          ..write('inventoryId: $inventoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesCatalogTableTable extends RecipesCatalogTable
    with TableInfo<$RecipesCatalogTableTable, RecipesCatalogTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesCatalogTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requiredRankMeta =
      const VerificationMeta('requiredRank');
  @override
  late final GeneratedColumn<String> requiredRank = GeneratedColumn<String>(
      'required_rank', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _requiredLevelMeta =
      const VerificationMeta('requiredLevel');
  @override
  late final GeneratedColumn<int> requiredLevel = GeneratedColumn<int>(
      'required_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _requiredStationMeta =
      const VerificationMeta('requiredStation');
  @override
  late final GeneratedColumn<String> requiredStation = GeneratedColumn<String>(
      'required_station', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('workshop'));
  static const VerificationMeta _resultItemKeyMeta =
      const VerificationMeta('resultItemKey');
  @override
  late final GeneratedColumn<String> resultItemKey = GeneratedColumn<String>(
      'result_item_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resultQuantityMeta =
      const VerificationMeta('resultQuantity');
  @override
  late final GeneratedColumn<int> resultQuantity = GeneratedColumn<int>(
      'result_quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _materialsMeta =
      const VerificationMeta('materials');
  @override
  late final GeneratedColumn<String> materials = GeneratedColumn<String>(
      'materials', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _costCoinsMeta =
      const VerificationMeta('costCoins');
  @override
  late final GeneratedColumn<int> costCoins = GeneratedColumn<int>(
      'cost_coins', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _durationSecMeta =
      const VerificationMeta('durationSec');
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
      'duration_sec', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _unlockSourcesMeta =
      const VerificationMeta('unlockSources');
  @override
  late final GeneratedColumn<String> unlockSources = GeneratedColumn<String>(
      'unlock_sources', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        key,
        name,
        description,
        type,
        requiredRank,
        requiredLevel,
        requiredStation,
        resultItemKey,
        resultQuantity,
        materials,
        costCoins,
        durationSec,
        unlockSources,
        icon
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes_catalog';
  @override
  VerificationContext validateIntegrity(
      Insertable<RecipesCatalogTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('required_rank')) {
      context.handle(
          _requiredRankMeta,
          requiredRank.isAcceptableOrUnknown(
              data['required_rank']!, _requiredRankMeta));
    }
    if (data.containsKey('required_level')) {
      context.handle(
          _requiredLevelMeta,
          requiredLevel.isAcceptableOrUnknown(
              data['required_level']!, _requiredLevelMeta));
    }
    if (data.containsKey('required_station')) {
      context.handle(
          _requiredStationMeta,
          requiredStation.isAcceptableOrUnknown(
              data['required_station']!, _requiredStationMeta));
    }
    if (data.containsKey('result_item_key')) {
      context.handle(
          _resultItemKeyMeta,
          resultItemKey.isAcceptableOrUnknown(
              data['result_item_key']!, _resultItemKeyMeta));
    } else if (isInserting) {
      context.missing(_resultItemKeyMeta);
    }
    if (data.containsKey('result_quantity')) {
      context.handle(
          _resultQuantityMeta,
          resultQuantity.isAcceptableOrUnknown(
              data['result_quantity']!, _resultQuantityMeta));
    }
    if (data.containsKey('materials')) {
      context.handle(_materialsMeta,
          materials.isAcceptableOrUnknown(data['materials']!, _materialsMeta));
    } else if (isInserting) {
      context.missing(_materialsMeta);
    }
    if (data.containsKey('cost_coins')) {
      context.handle(_costCoinsMeta,
          costCoins.isAcceptableOrUnknown(data['cost_coins']!, _costCoinsMeta));
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
          _durationSecMeta,
          durationSec.isAcceptableOrUnknown(
              data['duration_sec']!, _durationSecMeta));
    }
    if (data.containsKey('unlock_sources')) {
      context.handle(
          _unlockSourcesMeta,
          unlockSources.isAcceptableOrUnknown(
              data['unlock_sources']!, _unlockSourcesMeta));
    } else if (isInserting) {
      context.missing(_unlockSourcesMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  RecipesCatalogTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipesCatalogTableData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      requiredRank: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}required_rank']),
      requiredLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}required_level'])!,
      requiredStation: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}required_station'])!,
      resultItemKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}result_item_key'])!,
      resultQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}result_quantity'])!,
      materials: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}materials'])!,
      costCoins: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cost_coins'])!,
      durationSec: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_sec'])!,
      unlockSources: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unlock_sources'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
    );
  }

  @override
  $RecipesCatalogTableTable createAlias(String alias) {
    return $RecipesCatalogTableTable(attachedDatabase, alias);
  }
}

class RecipesCatalogTableData extends DataClass
    implements Insertable<RecipesCatalogTableData> {
  final String key;
  final String name;
  final String description;
  final String type;
  final String? requiredRank;
  final int requiredLevel;
  final String requiredStation;
  final String resultItemKey;
  final int resultQuantity;
  final String materials;
  final int costCoins;
  final int durationSec;
  final String unlockSources;
  final String? icon;
  const RecipesCatalogTableData(
      {required this.key,
      required this.name,
      required this.description,
      required this.type,
      this.requiredRank,
      required this.requiredLevel,
      required this.requiredStation,
      required this.resultItemKey,
      required this.resultQuantity,
      required this.materials,
      required this.costCoins,
      required this.durationSec,
      required this.unlockSources,
      this.icon});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || requiredRank != null) {
      map['required_rank'] = Variable<String>(requiredRank);
    }
    map['required_level'] = Variable<int>(requiredLevel);
    map['required_station'] = Variable<String>(requiredStation);
    map['result_item_key'] = Variable<String>(resultItemKey);
    map['result_quantity'] = Variable<int>(resultQuantity);
    map['materials'] = Variable<String>(materials);
    map['cost_coins'] = Variable<int>(costCoins);
    map['duration_sec'] = Variable<int>(durationSec);
    map['unlock_sources'] = Variable<String>(unlockSources);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    return map;
  }

  RecipesCatalogTableCompanion toCompanion(bool nullToAbsent) {
    return RecipesCatalogTableCompanion(
      key: Value(key),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      requiredRank: requiredRank == null && nullToAbsent
          ? const Value.absent()
          : Value(requiredRank),
      requiredLevel: Value(requiredLevel),
      requiredStation: Value(requiredStation),
      resultItemKey: Value(resultItemKey),
      resultQuantity: Value(resultQuantity),
      materials: Value(materials),
      costCoins: Value(costCoins),
      durationSec: Value(durationSec),
      unlockSources: Value(unlockSources),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
    );
  }

  factory RecipesCatalogTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipesCatalogTableData(
      key: serializer.fromJson<String>(json['key']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      requiredRank: serializer.fromJson<String?>(json['requiredRank']),
      requiredLevel: serializer.fromJson<int>(json['requiredLevel']),
      requiredStation: serializer.fromJson<String>(json['requiredStation']),
      resultItemKey: serializer.fromJson<String>(json['resultItemKey']),
      resultQuantity: serializer.fromJson<int>(json['resultQuantity']),
      materials: serializer.fromJson<String>(json['materials']),
      costCoins: serializer.fromJson<int>(json['costCoins']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      unlockSources: serializer.fromJson<String>(json['unlockSources']),
      icon: serializer.fromJson<String?>(json['icon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<String>(type),
      'requiredRank': serializer.toJson<String?>(requiredRank),
      'requiredLevel': serializer.toJson<int>(requiredLevel),
      'requiredStation': serializer.toJson<String>(requiredStation),
      'resultItemKey': serializer.toJson<String>(resultItemKey),
      'resultQuantity': serializer.toJson<int>(resultQuantity),
      'materials': serializer.toJson<String>(materials),
      'costCoins': serializer.toJson<int>(costCoins),
      'durationSec': serializer.toJson<int>(durationSec),
      'unlockSources': serializer.toJson<String>(unlockSources),
      'icon': serializer.toJson<String?>(icon),
    };
  }

  RecipesCatalogTableData copyWith(
          {String? key,
          String? name,
          String? description,
          String? type,
          Value<String?> requiredRank = const Value.absent(),
          int? requiredLevel,
          String? requiredStation,
          String? resultItemKey,
          int? resultQuantity,
          String? materials,
          int? costCoins,
          int? durationSec,
          String? unlockSources,
          Value<String?> icon = const Value.absent()}) =>
      RecipesCatalogTableData(
        key: key ?? this.key,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        requiredRank:
            requiredRank.present ? requiredRank.value : this.requiredRank,
        requiredLevel: requiredLevel ?? this.requiredLevel,
        requiredStation: requiredStation ?? this.requiredStation,
        resultItemKey: resultItemKey ?? this.resultItemKey,
        resultQuantity: resultQuantity ?? this.resultQuantity,
        materials: materials ?? this.materials,
        costCoins: costCoins ?? this.costCoins,
        durationSec: durationSec ?? this.durationSec,
        unlockSources: unlockSources ?? this.unlockSources,
        icon: icon.present ? icon.value : this.icon,
      );
  RecipesCatalogTableData copyWithCompanion(RecipesCatalogTableCompanion data) {
    return RecipesCatalogTableData(
      key: data.key.present ? data.key.value : this.key,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      type: data.type.present ? data.type.value : this.type,
      requiredRank: data.requiredRank.present
          ? data.requiredRank.value
          : this.requiredRank,
      requiredLevel: data.requiredLevel.present
          ? data.requiredLevel.value
          : this.requiredLevel,
      requiredStation: data.requiredStation.present
          ? data.requiredStation.value
          : this.requiredStation,
      resultItemKey: data.resultItemKey.present
          ? data.resultItemKey.value
          : this.resultItemKey,
      resultQuantity: data.resultQuantity.present
          ? data.resultQuantity.value
          : this.resultQuantity,
      materials: data.materials.present ? data.materials.value : this.materials,
      costCoins: data.costCoins.present ? data.costCoins.value : this.costCoins,
      durationSec:
          data.durationSec.present ? data.durationSec.value : this.durationSec,
      unlockSources: data.unlockSources.present
          ? data.unlockSources.value
          : this.unlockSources,
      icon: data.icon.present ? data.icon.value : this.icon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCatalogTableData(')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('requiredRank: $requiredRank, ')
          ..write('requiredLevel: $requiredLevel, ')
          ..write('requiredStation: $requiredStation, ')
          ..write('resultItemKey: $resultItemKey, ')
          ..write('resultQuantity: $resultQuantity, ')
          ..write('materials: $materials, ')
          ..write('costCoins: $costCoins, ')
          ..write('durationSec: $durationSec, ')
          ..write('unlockSources: $unlockSources, ')
          ..write('icon: $icon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      key,
      name,
      description,
      type,
      requiredRank,
      requiredLevel,
      requiredStation,
      resultItemKey,
      resultQuantity,
      materials,
      costCoins,
      durationSec,
      unlockSources,
      icon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipesCatalogTableData &&
          other.key == this.key &&
          other.name == this.name &&
          other.description == this.description &&
          other.type == this.type &&
          other.requiredRank == this.requiredRank &&
          other.requiredLevel == this.requiredLevel &&
          other.requiredStation == this.requiredStation &&
          other.resultItemKey == this.resultItemKey &&
          other.resultQuantity == this.resultQuantity &&
          other.materials == this.materials &&
          other.costCoins == this.costCoins &&
          other.durationSec == this.durationSec &&
          other.unlockSources == this.unlockSources &&
          other.icon == this.icon);
}

class RecipesCatalogTableCompanion
    extends UpdateCompanion<RecipesCatalogTableData> {
  final Value<String> key;
  final Value<String> name;
  final Value<String> description;
  final Value<String> type;
  final Value<String?> requiredRank;
  final Value<int> requiredLevel;
  final Value<String> requiredStation;
  final Value<String> resultItemKey;
  final Value<int> resultQuantity;
  final Value<String> materials;
  final Value<int> costCoins;
  final Value<int> durationSec;
  final Value<String> unlockSources;
  final Value<String?> icon;
  final Value<int> rowid;
  const RecipesCatalogTableCompanion({
    this.key = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.requiredRank = const Value.absent(),
    this.requiredLevel = const Value.absent(),
    this.requiredStation = const Value.absent(),
    this.resultItemKey = const Value.absent(),
    this.resultQuantity = const Value.absent(),
    this.materials = const Value.absent(),
    this.costCoins = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.unlockSources = const Value.absent(),
    this.icon = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCatalogTableCompanion.insert({
    required String key,
    required String name,
    this.description = const Value.absent(),
    required String type,
    this.requiredRank = const Value.absent(),
    this.requiredLevel = const Value.absent(),
    this.requiredStation = const Value.absent(),
    required String resultItemKey,
    this.resultQuantity = const Value.absent(),
    required String materials,
    this.costCoins = const Value.absent(),
    this.durationSec = const Value.absent(),
    required String unlockSources,
    this.icon = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        name = Value(name),
        type = Value(type),
        resultItemKey = Value(resultItemKey),
        materials = Value(materials),
        unlockSources = Value(unlockSources);
  static Insertable<RecipesCatalogTableData> custom({
    Expression<String>? key,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? requiredRank,
    Expression<int>? requiredLevel,
    Expression<String>? requiredStation,
    Expression<String>? resultItemKey,
    Expression<int>? resultQuantity,
    Expression<String>? materials,
    Expression<int>? costCoins,
    Expression<int>? durationSec,
    Expression<String>? unlockSources,
    Expression<String>? icon,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (requiredRank != null) 'required_rank': requiredRank,
      if (requiredLevel != null) 'required_level': requiredLevel,
      if (requiredStation != null) 'required_station': requiredStation,
      if (resultItemKey != null) 'result_item_key': resultItemKey,
      if (resultQuantity != null) 'result_quantity': resultQuantity,
      if (materials != null) 'materials': materials,
      if (costCoins != null) 'cost_coins': costCoins,
      if (durationSec != null) 'duration_sec': durationSec,
      if (unlockSources != null) 'unlock_sources': unlockSources,
      if (icon != null) 'icon': icon,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCatalogTableCompanion copyWith(
      {Value<String>? key,
      Value<String>? name,
      Value<String>? description,
      Value<String>? type,
      Value<String?>? requiredRank,
      Value<int>? requiredLevel,
      Value<String>? requiredStation,
      Value<String>? resultItemKey,
      Value<int>? resultQuantity,
      Value<String>? materials,
      Value<int>? costCoins,
      Value<int>? durationSec,
      Value<String>? unlockSources,
      Value<String?>? icon,
      Value<int>? rowid}) {
    return RecipesCatalogTableCompanion(
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      requiredRank: requiredRank ?? this.requiredRank,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      requiredStation: requiredStation ?? this.requiredStation,
      resultItemKey: resultItemKey ?? this.resultItemKey,
      resultQuantity: resultQuantity ?? this.resultQuantity,
      materials: materials ?? this.materials,
      costCoins: costCoins ?? this.costCoins,
      durationSec: durationSec ?? this.durationSec,
      unlockSources: unlockSources ?? this.unlockSources,
      icon: icon ?? this.icon,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (requiredRank.present) {
      map['required_rank'] = Variable<String>(requiredRank.value);
    }
    if (requiredLevel.present) {
      map['required_level'] = Variable<int>(requiredLevel.value);
    }
    if (requiredStation.present) {
      map['required_station'] = Variable<String>(requiredStation.value);
    }
    if (resultItemKey.present) {
      map['result_item_key'] = Variable<String>(resultItemKey.value);
    }
    if (resultQuantity.present) {
      map['result_quantity'] = Variable<int>(resultQuantity.value);
    }
    if (materials.present) {
      map['materials'] = Variable<String>(materials.value);
    }
    if (costCoins.present) {
      map['cost_coins'] = Variable<int>(costCoins.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (unlockSources.present) {
      map['unlock_sources'] = Variable<String>(unlockSources.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCatalogTableCompanion(')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('requiredRank: $requiredRank, ')
          ..write('requiredLevel: $requiredLevel, ')
          ..write('requiredStation: $requiredStation, ')
          ..write('resultItemKey: $resultItemKey, ')
          ..write('resultQuantity: $resultQuantity, ')
          ..write('materials: $materials, ')
          ..write('costCoins: $costCoins, ')
          ..write('durationSec: $durationSec, ')
          ..write('unlockSources: $unlockSources, ')
          ..write('icon: $icon, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayerRecipesUnlockedTableTable extends PlayerRecipesUnlockedTable
    with
        TableInfo<$PlayerRecipesUnlockedTableTable,
            PlayerRecipesUnlockedTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerRecipesUnlockedTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playerIdMeta =
      const VerificationMeta('playerId');
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
      'player_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _recipeKeyMeta =
      const VerificationMeta('recipeKey');
  @override
  late final GeneratedColumn<String> recipeKey = GeneratedColumn<String>(
      'recipe_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unlockedAtMeta =
      const VerificationMeta('unlockedAt');
  @override
  late final GeneratedColumn<int> unlockedAt = GeneratedColumn<int>(
      'unlocked_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _unlockedViaMeta =
      const VerificationMeta('unlockedVia');
  @override
  late final GeneratedColumn<String> unlockedVia = GeneratedColumn<String>(
      'unlocked_via', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [playerId, recipeKey, unlockedAt, unlockedVia];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_recipes_unlocked';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlayerRecipesUnlockedTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('player_id')) {
      context.handle(_playerIdMeta,
          playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta));
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('recipe_key')) {
      context.handle(_recipeKeyMeta,
          recipeKey.isAcceptableOrUnknown(data['recipe_key']!, _recipeKeyMeta));
    } else if (isInserting) {
      context.missing(_recipeKeyMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
          _unlockedAtMeta,
          unlockedAt.isAcceptableOrUnknown(
              data['unlocked_at']!, _unlockedAtMeta));
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    if (data.containsKey('unlocked_via')) {
      context.handle(
          _unlockedViaMeta,
          unlockedVia.isAcceptableOrUnknown(
              data['unlocked_via']!, _unlockedViaMeta));
    } else if (isInserting) {
      context.missing(_unlockedViaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playerId, recipeKey};
  @override
  PlayerRecipesUnlockedTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerRecipesUnlockedTableData(
      playerId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}player_id'])!,
      recipeKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recipe_key'])!,
      unlockedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unlocked_at'])!,
      unlockedVia: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unlocked_via'])!,
    );
  }

  @override
  $PlayerRecipesUnlockedTableTable createAlias(String alias) {
    return $PlayerRecipesUnlockedTableTable(attachedDatabase, alias);
  }
}

class PlayerRecipesUnlockedTableData extends DataClass
    implements Insertable<PlayerRecipesUnlockedTableData> {
  final int playerId;
  final String recipeKey;
  final int unlockedAt;
  final String unlockedVia;
  const PlayerRecipesUnlockedTableData(
      {required this.playerId,
      required this.recipeKey,
      required this.unlockedAt,
      required this.unlockedVia});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['player_id'] = Variable<int>(playerId);
    map['recipe_key'] = Variable<String>(recipeKey);
    map['unlocked_at'] = Variable<int>(unlockedAt);
    map['unlocked_via'] = Variable<String>(unlockedVia);
    return map;
  }

  PlayerRecipesUnlockedTableCompanion toCompanion(bool nullToAbsent) {
    return PlayerRecipesUnlockedTableCompanion(
      playerId: Value(playerId),
      recipeKey: Value(recipeKey),
      unlockedAt: Value(unlockedAt),
      unlockedVia: Value(unlockedVia),
    );
  }

  factory PlayerRecipesUnlockedTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerRecipesUnlockedTableData(
      playerId: serializer.fromJson<int>(json['playerId']),
      recipeKey: serializer.fromJson<String>(json['recipeKey']),
      unlockedAt: serializer.fromJson<int>(json['unlockedAt']),
      unlockedVia: serializer.fromJson<String>(json['unlockedVia']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playerId': serializer.toJson<int>(playerId),
      'recipeKey': serializer.toJson<String>(recipeKey),
      'unlockedAt': serializer.toJson<int>(unlockedAt),
      'unlockedVia': serializer.toJson<String>(unlockedVia),
    };
  }

  PlayerRecipesUnlockedTableData copyWith(
          {int? playerId,
          String? recipeKey,
          int? unlockedAt,
          String? unlockedVia}) =>
      PlayerRecipesUnlockedTableData(
        playerId: playerId ?? this.playerId,
        recipeKey: recipeKey ?? this.recipeKey,
        unlockedAt: unlockedAt ?? this.unlockedAt,
        unlockedVia: unlockedVia ?? this.unlockedVia,
      );
  PlayerRecipesUnlockedTableData copyWithCompanion(
      PlayerRecipesUnlockedTableCompanion data) {
    return PlayerRecipesUnlockedTableData(
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      recipeKey: data.recipeKey.present ? data.recipeKey.value : this.recipeKey,
      unlockedAt:
          data.unlockedAt.present ? data.unlockedAt.value : this.unlockedAt,
      unlockedVia:
          data.unlockedVia.present ? data.unlockedVia.value : this.unlockedVia,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerRecipesUnlockedTableData(')
          ..write('playerId: $playerId, ')
          ..write('recipeKey: $recipeKey, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('unlockedVia: $unlockedVia')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playerId, recipeKey, unlockedAt, unlockedVia);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerRecipesUnlockedTableData &&
          other.playerId == this.playerId &&
          other.recipeKey == this.recipeKey &&
          other.unlockedAt == this.unlockedAt &&
          other.unlockedVia == this.unlockedVia);
}

class PlayerRecipesUnlockedTableCompanion
    extends UpdateCompanion<PlayerRecipesUnlockedTableData> {
  final Value<int> playerId;
  final Value<String> recipeKey;
  final Value<int> unlockedAt;
  final Value<String> unlockedVia;
  final Value<int> rowid;
  const PlayerRecipesUnlockedTableCompanion({
    this.playerId = const Value.absent(),
    this.recipeKey = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.unlockedVia = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerRecipesUnlockedTableCompanion.insert({
    required int playerId,
    required String recipeKey,
    required int unlockedAt,
    required String unlockedVia,
    this.rowid = const Value.absent(),
  })  : playerId = Value(playerId),
        recipeKey = Value(recipeKey),
        unlockedAt = Value(unlockedAt),
        unlockedVia = Value(unlockedVia);
  static Insertable<PlayerRecipesUnlockedTableData> custom({
    Expression<int>? playerId,
    Expression<String>? recipeKey,
    Expression<int>? unlockedAt,
    Expression<String>? unlockedVia,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playerId != null) 'player_id': playerId,
      if (recipeKey != null) 'recipe_key': recipeKey,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (unlockedVia != null) 'unlocked_via': unlockedVia,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerRecipesUnlockedTableCompanion copyWith(
      {Value<int>? playerId,
      Value<String>? recipeKey,
      Value<int>? unlockedAt,
      Value<String>? unlockedVia,
      Value<int>? rowid}) {
    return PlayerRecipesUnlockedTableCompanion(
      playerId: playerId ?? this.playerId,
      recipeKey: recipeKey ?? this.recipeKey,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      unlockedVia: unlockedVia ?? this.unlockedVia,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (recipeKey.present) {
      map['recipe_key'] = Variable<String>(recipeKey.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<int>(unlockedAt.value);
    }
    if (unlockedVia.present) {
      map['unlocked_via'] = Variable<String>(unlockedVia.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerRecipesUnlockedTableCompanion(')
          ..write('playerId: $playerId, ')
          ..write('recipeKey: $recipeKey, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('unlockedVia: $unlockedVia, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTableTable playersTable = $PlayersTableTable(this);
  late final $HabitsTableTable habitsTable = $HabitsTableTable(this);
  late final $HabitLogsTableTable habitLogsTable = $HabitLogsTableTable(this);
  late final $ItemsTableTable itemsTable = $ItemsTableTable(this);
  late final $InventoryTableTable inventoryTable = $InventoryTableTable(this);
  late final $ShopItemsTableTable shopItemsTable = $ShopItemsTableTable(this);
  late final $AchievementsTableTable achievementsTable =
      $AchievementsTableTable(this);
  late final $PlayerAchievementsTableTable playerAchievementsTable =
      $PlayerAchievementsTableTable(this);
  late final $GuildStatusTableTable guildStatusTable =
      $GuildStatusTableTable(this);
  late final $NpcReputationTableTable npcReputationTable =
      $NpcReputationTableTable(this);
  late final $DiaryEntriesTableTable diaryEntriesTable =
      $DiaryEntriesTableTable(this);
  late final $ClassQuestsTableTable classQuestsTable =
      $ClassQuestsTableTable(this);
  late final $FactionQuestsTableTable factionQuestsTable =
      $FactionQuestsTableTable(this);
  late final $GuildAscensionTableTable guildAscensionTable =
      $GuildAscensionTableTable(this);
  late final $VitalismUniqueCatalogTableTable vitalismUniqueCatalogTable =
      $VitalismUniqueCatalogTableTable(this);
  late final $PlayerVitalismAffinitiesTableTable playerVitalismAffinitiesTable =
      $PlayerVitalismAffinitiesTableTable(this);
  late final $PlayerVitalismTreesTableTable playerVitalismTreesTable =
      $PlayerVitalismTreesTableTable(this);
  late final $LifeVitalismPointsTableTable lifeVitalismPointsTable =
      $LifeVitalismPointsTableTable(this);
  late final $ItemsCatalogTableTable itemsCatalogTable =
      $ItemsCatalogTableTable(this);
  late final $PlayerInventoryTableTable playerInventoryTable =
      $PlayerInventoryTableTable(this);
  late final $PlayerEquipmentTableTable playerEquipmentTable =
      $PlayerEquipmentTableTable(this);
  late final $RecipesCatalogTableTable recipesCatalogTable =
      $RecipesCatalogTableTable(this);
  late final $PlayerRecipesUnlockedTableTable playerRecipesUnlockedTable =
      $PlayerRecipesUnlockedTableTable(this);
  late final PlayerDao playerDao = PlayerDao(this as AppDatabase);
  late final HabitDao habitDao = HabitDao(this as AppDatabase);
  late final AchievementDao achievementDao =
      AchievementDao(this as AppDatabase);
  late final GuildDao guildDao = GuildDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        playersTable,
        habitsTable,
        habitLogsTable,
        itemsTable,
        inventoryTable,
        shopItemsTable,
        achievementsTable,
        playerAchievementsTable,
        guildStatusTable,
        npcReputationTable,
        diaryEntriesTable,
        classQuestsTable,
        factionQuestsTable,
        guildAscensionTable,
        vitalismUniqueCatalogTable,
        playerVitalismAffinitiesTable,
        playerVitalismTreesTable,
        lifeVitalismPointsTable,
        itemsCatalogTable,
        playerInventoryTable,
        playerEquipmentTable,
        recipesCatalogTable,
        playerRecipesUnlockedTable
      ];
}

typedef $$PlayersTableTableCreateCompanionBuilder = PlayersTableCompanion
    Function({
  Value<int> id,
  required String email,
  required String passwordHash,
  Value<String> shadowName,
  Value<int> level,
  Value<int> xp,
  Value<int> xpToNext,
  Value<int> attributePoints,
  Value<int> vitalismLevel,
  Value<int> vitalismXp,
  Value<int> strength,
  Value<int> dexterity,
  Value<int> intelligence,
  Value<int> constitution,
  Value<int> spirit,
  Value<int> charisma,
  Value<int> hp,
  Value<int> maxHp,
  Value<int> mp,
  Value<int> maxMp,
  Value<int> currentVitalism,
  Value<int> gold,
  Value<int> gems,
  Value<int> streakDays,
  Value<int> caelumDay,
  Value<String> shadowState,
  Value<int> shadowCorruption,
  Value<String?> classType,
  Value<String?> factionType,
  Value<String> guildRank,
  Value<int> totalQuestsCompleted,
  Value<String> narrativeMode,
  Value<bool> onboardingDone,
  Value<String> playStyle,
  Value<DateTime> createdAt,
  Value<DateTime> lastLoginAt,
  Value<DateTime?> lastStreakDate,
});
typedef $$PlayersTableTableUpdateCompanionBuilder = PlayersTableCompanion
    Function({
  Value<int> id,
  Value<String> email,
  Value<String> passwordHash,
  Value<String> shadowName,
  Value<int> level,
  Value<int> xp,
  Value<int> xpToNext,
  Value<int> attributePoints,
  Value<int> vitalismLevel,
  Value<int> vitalismXp,
  Value<int> strength,
  Value<int> dexterity,
  Value<int> intelligence,
  Value<int> constitution,
  Value<int> spirit,
  Value<int> charisma,
  Value<int> hp,
  Value<int> maxHp,
  Value<int> mp,
  Value<int> maxMp,
  Value<int> currentVitalism,
  Value<int> gold,
  Value<int> gems,
  Value<int> streakDays,
  Value<int> caelumDay,
  Value<String> shadowState,
  Value<int> shadowCorruption,
  Value<String?> classType,
  Value<String?> factionType,
  Value<String> guildRank,
  Value<int> totalQuestsCompleted,
  Value<String> narrativeMode,
  Value<bool> onboardingDone,
  Value<String> playStyle,
  Value<DateTime> createdAt,
  Value<DateTime> lastLoginAt,
  Value<DateTime?> lastStreakDate,
});

class $$PlayersTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTableTable> {
  $$PlayersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shadowName => $composableBuilder(
      column: $table.shadowName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xp => $composableBuilder(
      column: $table.xp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpToNext => $composableBuilder(
      column: $table.xpToNext, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attributePoints => $composableBuilder(
      column: $table.attributePoints,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get vitalismLevel => $composableBuilder(
      column: $table.vitalismLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get vitalismXp => $composableBuilder(
      column: $table.vitalismXp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get strength => $composableBuilder(
      column: $table.strength, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dexterity => $composableBuilder(
      column: $table.dexterity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intelligence => $composableBuilder(
      column: $table.intelligence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get constitution => $composableBuilder(
      column: $table.constitution, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get spirit => $composableBuilder(
      column: $table.spirit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get charisma => $composableBuilder(
      column: $table.charisma, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hp => $composableBuilder(
      column: $table.hp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxHp => $composableBuilder(
      column: $table.maxHp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mp => $composableBuilder(
      column: $table.mp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxMp => $composableBuilder(
      column: $table.maxMp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentVitalism => $composableBuilder(
      column: $table.currentVitalism,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gold => $composableBuilder(
      column: $table.gold, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gems => $composableBuilder(
      column: $table.gems, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get streakDays => $composableBuilder(
      column: $table.streakDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get caelumDay => $composableBuilder(
      column: $table.caelumDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shadowState => $composableBuilder(
      column: $table.shadowState, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shadowCorruption => $composableBuilder(
      column: $table.shadowCorruption,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get classType => $composableBuilder(
      column: $table.classType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get factionType => $composableBuilder(
      column: $table.factionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get guildRank => $composableBuilder(
      column: $table.guildRank, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalQuestsCompleted => $composableBuilder(
      column: $table.totalQuestsCompleted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get narrativeMode => $composableBuilder(
      column: $table.narrativeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get onboardingDone => $composableBuilder(
      column: $table.onboardingDone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get playStyle => $composableBuilder(
      column: $table.playStyle, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastStreakDate => $composableBuilder(
      column: $table.lastStreakDate,
      builder: (column) => ColumnFilters(column));
}

class $$PlayersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTableTable> {
  $$PlayersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shadowName => $composableBuilder(
      column: $table.shadowName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xp => $composableBuilder(
      column: $table.xp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpToNext => $composableBuilder(
      column: $table.xpToNext, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attributePoints => $composableBuilder(
      column: $table.attributePoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get vitalismLevel => $composableBuilder(
      column: $table.vitalismLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get vitalismXp => $composableBuilder(
      column: $table.vitalismXp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get strength => $composableBuilder(
      column: $table.strength, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dexterity => $composableBuilder(
      column: $table.dexterity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intelligence => $composableBuilder(
      column: $table.intelligence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get constitution => $composableBuilder(
      column: $table.constitution,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spirit => $composableBuilder(
      column: $table.spirit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get charisma => $composableBuilder(
      column: $table.charisma, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hp => $composableBuilder(
      column: $table.hp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxHp => $composableBuilder(
      column: $table.maxHp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mp => $composableBuilder(
      column: $table.mp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxMp => $composableBuilder(
      column: $table.maxMp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentVitalism => $composableBuilder(
      column: $table.currentVitalism,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gold => $composableBuilder(
      column: $table.gold, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gems => $composableBuilder(
      column: $table.gems, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get streakDays => $composableBuilder(
      column: $table.streakDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get caelumDay => $composableBuilder(
      column: $table.caelumDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shadowState => $composableBuilder(
      column: $table.shadowState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shadowCorruption => $composableBuilder(
      column: $table.shadowCorruption,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get classType => $composableBuilder(
      column: $table.classType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get factionType => $composableBuilder(
      column: $table.factionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get guildRank => $composableBuilder(
      column: $table.guildRank, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalQuestsCompleted => $composableBuilder(
      column: $table.totalQuestsCompleted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get narrativeMode => $composableBuilder(
      column: $table.narrativeMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get onboardingDone => $composableBuilder(
      column: $table.onboardingDone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get playStyle => $composableBuilder(
      column: $table.playStyle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastStreakDate => $composableBuilder(
      column: $table.lastStreakDate,
      builder: (column) => ColumnOrderings(column));
}

class $$PlayersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTableTable> {
  $$PlayersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
      column: $table.passwordHash, builder: (column) => column);

  GeneratedColumn<String> get shadowName => $composableBuilder(
      column: $table.shadowName, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<int> get xpToNext =>
      $composableBuilder(column: $table.xpToNext, builder: (column) => column);

  GeneratedColumn<int> get attributePoints => $composableBuilder(
      column: $table.attributePoints, builder: (column) => column);

  GeneratedColumn<int> get vitalismLevel => $composableBuilder(
      column: $table.vitalismLevel, builder: (column) => column);

  GeneratedColumn<int> get vitalismXp => $composableBuilder(
      column: $table.vitalismXp, builder: (column) => column);

  GeneratedColumn<int> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<int> get dexterity =>
      $composableBuilder(column: $table.dexterity, builder: (column) => column);

  GeneratedColumn<int> get intelligence => $composableBuilder(
      column: $table.intelligence, builder: (column) => column);

  GeneratedColumn<int> get constitution => $composableBuilder(
      column: $table.constitution, builder: (column) => column);

  GeneratedColumn<int> get spirit =>
      $composableBuilder(column: $table.spirit, builder: (column) => column);

  GeneratedColumn<int> get charisma =>
      $composableBuilder(column: $table.charisma, builder: (column) => column);

  GeneratedColumn<int> get hp =>
      $composableBuilder(column: $table.hp, builder: (column) => column);

  GeneratedColumn<int> get maxHp =>
      $composableBuilder(column: $table.maxHp, builder: (column) => column);

  GeneratedColumn<int> get mp =>
      $composableBuilder(column: $table.mp, builder: (column) => column);

  GeneratedColumn<int> get maxMp =>
      $composableBuilder(column: $table.maxMp, builder: (column) => column);

  GeneratedColumn<int> get currentVitalism => $composableBuilder(
      column: $table.currentVitalism, builder: (column) => column);

  GeneratedColumn<int> get gold =>
      $composableBuilder(column: $table.gold, builder: (column) => column);

  GeneratedColumn<int> get gems =>
      $composableBuilder(column: $table.gems, builder: (column) => column);

  GeneratedColumn<int> get streakDays => $composableBuilder(
      column: $table.streakDays, builder: (column) => column);

  GeneratedColumn<int> get caelumDay =>
      $composableBuilder(column: $table.caelumDay, builder: (column) => column);

  GeneratedColumn<String> get shadowState => $composableBuilder(
      column: $table.shadowState, builder: (column) => column);

  GeneratedColumn<int> get shadowCorruption => $composableBuilder(
      column: $table.shadowCorruption, builder: (column) => column);

  GeneratedColumn<String> get classType =>
      $composableBuilder(column: $table.classType, builder: (column) => column);

  GeneratedColumn<String> get factionType => $composableBuilder(
      column: $table.factionType, builder: (column) => column);

  GeneratedColumn<String> get guildRank =>
      $composableBuilder(column: $table.guildRank, builder: (column) => column);

  GeneratedColumn<int> get totalQuestsCompleted => $composableBuilder(
      column: $table.totalQuestsCompleted, builder: (column) => column);

  GeneratedColumn<String> get narrativeMode => $composableBuilder(
      column: $table.narrativeMode, builder: (column) => column);

  GeneratedColumn<bool> get onboardingDone => $composableBuilder(
      column: $table.onboardingDone, builder: (column) => column);

  GeneratedColumn<String> get playStyle =>
      $composableBuilder(column: $table.playStyle, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
      column: $table.lastLoginAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastStreakDate => $composableBuilder(
      column: $table.lastStreakDate, builder: (column) => column);
}

class $$PlayersTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayersTableTable,
    PlayersTableData,
    $$PlayersTableTableFilterComposer,
    $$PlayersTableTableOrderingComposer,
    $$PlayersTableTableAnnotationComposer,
    $$PlayersTableTableCreateCompanionBuilder,
    $$PlayersTableTableUpdateCompanionBuilder,
    (
      PlayersTableData,
      BaseReferences<_$AppDatabase, $PlayersTableTable, PlayersTableData>
    ),
    PlayersTableData,
    PrefetchHooks Function()> {
  $$PlayersTableTableTableManager(_$AppDatabase db, $PlayersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> passwordHash = const Value.absent(),
            Value<String> shadowName = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<int> xp = const Value.absent(),
            Value<int> xpToNext = const Value.absent(),
            Value<int> attributePoints = const Value.absent(),
            Value<int> vitalismLevel = const Value.absent(),
            Value<int> vitalismXp = const Value.absent(),
            Value<int> strength = const Value.absent(),
            Value<int> dexterity = const Value.absent(),
            Value<int> intelligence = const Value.absent(),
            Value<int> constitution = const Value.absent(),
            Value<int> spirit = const Value.absent(),
            Value<int> charisma = const Value.absent(),
            Value<int> hp = const Value.absent(),
            Value<int> maxHp = const Value.absent(),
            Value<int> mp = const Value.absent(),
            Value<int> maxMp = const Value.absent(),
            Value<int> currentVitalism = const Value.absent(),
            Value<int> gold = const Value.absent(),
            Value<int> gems = const Value.absent(),
            Value<int> streakDays = const Value.absent(),
            Value<int> caelumDay = const Value.absent(),
            Value<String> shadowState = const Value.absent(),
            Value<int> shadowCorruption = const Value.absent(),
            Value<String?> classType = const Value.absent(),
            Value<String?> factionType = const Value.absent(),
            Value<String> guildRank = const Value.absent(),
            Value<int> totalQuestsCompleted = const Value.absent(),
            Value<String> narrativeMode = const Value.absent(),
            Value<bool> onboardingDone = const Value.absent(),
            Value<String> playStyle = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastLoginAt = const Value.absent(),
            Value<DateTime?> lastStreakDate = const Value.absent(),
          }) =>
              PlayersTableCompanion(
            id: id,
            email: email,
            passwordHash: passwordHash,
            shadowName: shadowName,
            level: level,
            xp: xp,
            xpToNext: xpToNext,
            attributePoints: attributePoints,
            vitalismLevel: vitalismLevel,
            vitalismXp: vitalismXp,
            strength: strength,
            dexterity: dexterity,
            intelligence: intelligence,
            constitution: constitution,
            spirit: spirit,
            charisma: charisma,
            hp: hp,
            maxHp: maxHp,
            mp: mp,
            maxMp: maxMp,
            currentVitalism: currentVitalism,
            gold: gold,
            gems: gems,
            streakDays: streakDays,
            caelumDay: caelumDay,
            shadowState: shadowState,
            shadowCorruption: shadowCorruption,
            classType: classType,
            factionType: factionType,
            guildRank: guildRank,
            totalQuestsCompleted: totalQuestsCompleted,
            narrativeMode: narrativeMode,
            onboardingDone: onboardingDone,
            playStyle: playStyle,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            lastStreakDate: lastStreakDate,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String email,
            required String passwordHash,
            Value<String> shadowName = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<int> xp = const Value.absent(),
            Value<int> xpToNext = const Value.absent(),
            Value<int> attributePoints = const Value.absent(),
            Value<int> vitalismLevel = const Value.absent(),
            Value<int> vitalismXp = const Value.absent(),
            Value<int> strength = const Value.absent(),
            Value<int> dexterity = const Value.absent(),
            Value<int> intelligence = const Value.absent(),
            Value<int> constitution = const Value.absent(),
            Value<int> spirit = const Value.absent(),
            Value<int> charisma = const Value.absent(),
            Value<int> hp = const Value.absent(),
            Value<int> maxHp = const Value.absent(),
            Value<int> mp = const Value.absent(),
            Value<int> maxMp = const Value.absent(),
            Value<int> currentVitalism = const Value.absent(),
            Value<int> gold = const Value.absent(),
            Value<int> gems = const Value.absent(),
            Value<int> streakDays = const Value.absent(),
            Value<int> caelumDay = const Value.absent(),
            Value<String> shadowState = const Value.absent(),
            Value<int> shadowCorruption = const Value.absent(),
            Value<String?> classType = const Value.absent(),
            Value<String?> factionType = const Value.absent(),
            Value<String> guildRank = const Value.absent(),
            Value<int> totalQuestsCompleted = const Value.absent(),
            Value<String> narrativeMode = const Value.absent(),
            Value<bool> onboardingDone = const Value.absent(),
            Value<String> playStyle = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> lastLoginAt = const Value.absent(),
            Value<DateTime?> lastStreakDate = const Value.absent(),
          }) =>
              PlayersTableCompanion.insert(
            id: id,
            email: email,
            passwordHash: passwordHash,
            shadowName: shadowName,
            level: level,
            xp: xp,
            xpToNext: xpToNext,
            attributePoints: attributePoints,
            vitalismLevel: vitalismLevel,
            vitalismXp: vitalismXp,
            strength: strength,
            dexterity: dexterity,
            intelligence: intelligence,
            constitution: constitution,
            spirit: spirit,
            charisma: charisma,
            hp: hp,
            maxHp: maxHp,
            mp: mp,
            maxMp: maxMp,
            currentVitalism: currentVitalism,
            gold: gold,
            gems: gems,
            streakDays: streakDays,
            caelumDay: caelumDay,
            shadowState: shadowState,
            shadowCorruption: shadowCorruption,
            classType: classType,
            factionType: factionType,
            guildRank: guildRank,
            totalQuestsCompleted: totalQuestsCompleted,
            narrativeMode: narrativeMode,
            onboardingDone: onboardingDone,
            playStyle: playStyle,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            lastStreakDate: lastStreakDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayersTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlayersTableTable,
    PlayersTableData,
    $$PlayersTableTableFilterComposer,
    $$PlayersTableTableOrderingComposer,
    $$PlayersTableTableAnnotationComposer,
    $$PlayersTableTableCreateCompanionBuilder,
    $$PlayersTableTableUpdateCompanionBuilder,
    (
      PlayersTableData,
      BaseReferences<_$AppDatabase, $PlayersTableTable, PlayersTableData>
    ),
    PlayersTableData,
    PrefetchHooks Function()>;
typedef $$HabitsTableTableCreateCompanionBuilder = HabitsTableCompanion
    Function({
  Value<int> id,
  required int playerId,
  required String title,
  Value<String> description,
  required String category,
  Value<String> rank,
  Value<bool> isSystemHabit,
  Value<bool> isRepeatable,
  Value<bool> isPaused,
  Value<int> xpReward,
  Value<int> goldReward,
  Value<int> streakCount,
  Value<int> totalCompleted,
  Value<String?> requirements,
  Value<String> questType,
  Value<String> metricUnit,
  Value<String?> autoDescription,
  Value<DateTime> createdAt,
});
typedef $$HabitsTableTableUpdateCompanionBuilder = HabitsTableCompanion
    Function({
  Value<int> id,
  Value<int> playerId,
  Value<String> title,
  Value<String> description,
  Value<String> category,
  Value<String> rank,
  Value<bool> isSystemHabit,
  Value<bool> isRepeatable,
  Value<bool> isPaused,
  Value<int> xpReward,
  Value<int> goldReward,
  Value<int> streakCount,
  Value<int> totalCompleted,
  Value<String?> requirements,
  Value<String> questType,
  Value<String> metricUnit,
  Value<String?> autoDescription,
  Value<DateTime> createdAt,
});

class $$HabitsTableTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTableTable> {
  $$HabitsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rank => $composableBuilder(
      column: $table.rank, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSystemHabit => $composableBuilder(
      column: $table.isSystemHabit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRepeatable => $composableBuilder(
      column: $table.isRepeatable, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPaused => $composableBuilder(
      column: $table.isPaused, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get streakCount => $composableBuilder(
      column: $table.streakCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCompleted => $composableBuilder(
      column: $table.totalCompleted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requirements => $composableBuilder(
      column: $table.requirements, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questType => $composableBuilder(
      column: $table.questType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metricUnit => $composableBuilder(
      column: $table.metricUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get autoDescription => $composableBuilder(
      column: $table.autoDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$HabitsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTableTable> {
  $$HabitsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rank => $composableBuilder(
      column: $table.rank, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSystemHabit => $composableBuilder(
      column: $table.isSystemHabit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRepeatable => $composableBuilder(
      column: $table.isRepeatable,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPaused => $composableBuilder(
      column: $table.isPaused, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get streakCount => $composableBuilder(
      column: $table.streakCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCompleted => $composableBuilder(
      column: $table.totalCompleted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requirements => $composableBuilder(
      column: $table.requirements,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questType => $composableBuilder(
      column: $table.questType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metricUnit => $composableBuilder(
      column: $table.metricUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get autoDescription => $composableBuilder(
      column: $table.autoDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$HabitsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTableTable> {
  $$HabitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<bool> get isSystemHabit => $composableBuilder(
      column: $table.isSystemHabit, builder: (column) => column);

  GeneratedColumn<bool> get isRepeatable => $composableBuilder(
      column: $table.isRepeatable, builder: (column) => column);

  GeneratedColumn<bool> get isPaused =>
      $composableBuilder(column: $table.isPaused, builder: (column) => column);

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);

  GeneratedColumn<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => column);

  GeneratedColumn<int> get streakCount => $composableBuilder(
      column: $table.streakCount, builder: (column) => column);

  GeneratedColumn<int> get totalCompleted => $composableBuilder(
      column: $table.totalCompleted, builder: (column) => column);

  GeneratedColumn<String> get requirements => $composableBuilder(
      column: $table.requirements, builder: (column) => column);

  GeneratedColumn<String> get questType =>
      $composableBuilder(column: $table.questType, builder: (column) => column);

  GeneratedColumn<String> get metricUnit => $composableBuilder(
      column: $table.metricUnit, builder: (column) => column);

  GeneratedColumn<String> get autoDescription => $composableBuilder(
      column: $table.autoDescription, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HabitsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HabitsTableTable,
    HabitsTableData,
    $$HabitsTableTableFilterComposer,
    $$HabitsTableTableOrderingComposer,
    $$HabitsTableTableAnnotationComposer,
    $$HabitsTableTableCreateCompanionBuilder,
    $$HabitsTableTableUpdateCompanionBuilder,
    (
      HabitsTableData,
      BaseReferences<_$AppDatabase, $HabitsTableTable, HabitsTableData>
    ),
    HabitsTableData,
    PrefetchHooks Function()> {
  $$HabitsTableTableTableManager(_$AppDatabase db, $HabitsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> rank = const Value.absent(),
            Value<bool> isSystemHabit = const Value.absent(),
            Value<bool> isRepeatable = const Value.absent(),
            Value<bool> isPaused = const Value.absent(),
            Value<int> xpReward = const Value.absent(),
            Value<int> goldReward = const Value.absent(),
            Value<int> streakCount = const Value.absent(),
            Value<int> totalCompleted = const Value.absent(),
            Value<String?> requirements = const Value.absent(),
            Value<String> questType = const Value.absent(),
            Value<String> metricUnit = const Value.absent(),
            Value<String?> autoDescription = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              HabitsTableCompanion(
            id: id,
            playerId: playerId,
            title: title,
            description: description,
            category: category,
            rank: rank,
            isSystemHabit: isSystemHabit,
            isRepeatable: isRepeatable,
            isPaused: isPaused,
            xpReward: xpReward,
            goldReward: goldReward,
            streakCount: streakCount,
            totalCompleted: totalCompleted,
            requirements: requirements,
            questType: questType,
            metricUnit: metricUnit,
            autoDescription: autoDescription,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            required String title,
            Value<String> description = const Value.absent(),
            required String category,
            Value<String> rank = const Value.absent(),
            Value<bool> isSystemHabit = const Value.absent(),
            Value<bool> isRepeatable = const Value.absent(),
            Value<bool> isPaused = const Value.absent(),
            Value<int> xpReward = const Value.absent(),
            Value<int> goldReward = const Value.absent(),
            Value<int> streakCount = const Value.absent(),
            Value<int> totalCompleted = const Value.absent(),
            Value<String?> requirements = const Value.absent(),
            Value<String> questType = const Value.absent(),
            Value<String> metricUnit = const Value.absent(),
            Value<String?> autoDescription = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              HabitsTableCompanion.insert(
            id: id,
            playerId: playerId,
            title: title,
            description: description,
            category: category,
            rank: rank,
            isSystemHabit: isSystemHabit,
            isRepeatable: isRepeatable,
            isPaused: isPaused,
            xpReward: xpReward,
            goldReward: goldReward,
            streakCount: streakCount,
            totalCompleted: totalCompleted,
            requirements: requirements,
            questType: questType,
            metricUnit: metricUnit,
            autoDescription: autoDescription,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HabitsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HabitsTableTable,
    HabitsTableData,
    $$HabitsTableTableFilterComposer,
    $$HabitsTableTableOrderingComposer,
    $$HabitsTableTableAnnotationComposer,
    $$HabitsTableTableCreateCompanionBuilder,
    $$HabitsTableTableUpdateCompanionBuilder,
    (
      HabitsTableData,
      BaseReferences<_$AppDatabase, $HabitsTableTable, HabitsTableData>
    ),
    HabitsTableData,
    PrefetchHooks Function()>;
typedef $$HabitLogsTableTableCreateCompanionBuilder = HabitLogsTableCompanion
    Function({
  Value<int> id,
  required int habitId,
  required int playerId,
  required String status,
  Value<int> xpGained,
  Value<int> goldGained,
  Value<int> shadowImpact,
  Value<DateTime> logDate,
});
typedef $$HabitLogsTableTableUpdateCompanionBuilder = HabitLogsTableCompanion
    Function({
  Value<int> id,
  Value<int> habitId,
  Value<int> playerId,
  Value<String> status,
  Value<int> xpGained,
  Value<int> goldGained,
  Value<int> shadowImpact,
  Value<DateTime> logDate,
});

class $$HabitLogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $HabitLogsTableTable> {
  $$HabitLogsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get habitId => $composableBuilder(
      column: $table.habitId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpGained => $composableBuilder(
      column: $table.xpGained, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goldGained => $composableBuilder(
      column: $table.goldGained, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shadowImpact => $composableBuilder(
      column: $table.shadowImpact, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get logDate => $composableBuilder(
      column: $table.logDate, builder: (column) => ColumnFilters(column));
}

class $$HabitLogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitLogsTableTable> {
  $$HabitLogsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get habitId => $composableBuilder(
      column: $table.habitId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpGained => $composableBuilder(
      column: $table.xpGained, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goldGained => $composableBuilder(
      column: $table.goldGained, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shadowImpact => $composableBuilder(
      column: $table.shadowImpact,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get logDate => $composableBuilder(
      column: $table.logDate, builder: (column) => ColumnOrderings(column));
}

class $$HabitLogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitLogsTableTable> {
  $$HabitLogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get habitId =>
      $composableBuilder(column: $table.habitId, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get xpGained =>
      $composableBuilder(column: $table.xpGained, builder: (column) => column);

  GeneratedColumn<int> get goldGained => $composableBuilder(
      column: $table.goldGained, builder: (column) => column);

  GeneratedColumn<int> get shadowImpact => $composableBuilder(
      column: $table.shadowImpact, builder: (column) => column);

  GeneratedColumn<DateTime> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);
}

class $$HabitLogsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HabitLogsTableTable,
    HabitLogsTableData,
    $$HabitLogsTableTableFilterComposer,
    $$HabitLogsTableTableOrderingComposer,
    $$HabitLogsTableTableAnnotationComposer,
    $$HabitLogsTableTableCreateCompanionBuilder,
    $$HabitLogsTableTableUpdateCompanionBuilder,
    (
      HabitLogsTableData,
      BaseReferences<_$AppDatabase, $HabitLogsTableTable, HabitLogsTableData>
    ),
    HabitLogsTableData,
    PrefetchHooks Function()> {
  $$HabitLogsTableTableTableManager(
      _$AppDatabase db, $HabitLogsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitLogsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitLogsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitLogsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> habitId = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> xpGained = const Value.absent(),
            Value<int> goldGained = const Value.absent(),
            Value<int> shadowImpact = const Value.absent(),
            Value<DateTime> logDate = const Value.absent(),
          }) =>
              HabitLogsTableCompanion(
            id: id,
            habitId: habitId,
            playerId: playerId,
            status: status,
            xpGained: xpGained,
            goldGained: goldGained,
            shadowImpact: shadowImpact,
            logDate: logDate,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int habitId,
            required int playerId,
            required String status,
            Value<int> xpGained = const Value.absent(),
            Value<int> goldGained = const Value.absent(),
            Value<int> shadowImpact = const Value.absent(),
            Value<DateTime> logDate = const Value.absent(),
          }) =>
              HabitLogsTableCompanion.insert(
            id: id,
            habitId: habitId,
            playerId: playerId,
            status: status,
            xpGained: xpGained,
            goldGained: goldGained,
            shadowImpact: shadowImpact,
            logDate: logDate,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HabitLogsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HabitLogsTableTable,
    HabitLogsTableData,
    $$HabitLogsTableTableFilterComposer,
    $$HabitLogsTableTableOrderingComposer,
    $$HabitLogsTableTableAnnotationComposer,
    $$HabitLogsTableTableCreateCompanionBuilder,
    $$HabitLogsTableTableUpdateCompanionBuilder,
    (
      HabitLogsTableData,
      BaseReferences<_$AppDatabase, $HabitLogsTableTable, HabitLogsTableData>
    ),
    HabitLogsTableData,
    PrefetchHooks Function()>;
typedef $$ItemsTableTableCreateCompanionBuilder = ItemsTableCompanion Function({
  Value<int> id,
  required String name,
  Value<String> description,
  required String type,
  Value<String> rarity,
  Value<String?> slot,
  Value<int> goldValue,
  Value<int> gemValue,
  Value<int> strBonus,
  Value<int> dexBonus,
  Value<int> intBonus,
  Value<int> conBonus,
  Value<int> spiBonus,
  Value<int> hpBonus,
  Value<int> mpBonus,
  Value<bool> isConsumable,
  Value<bool> isStackable,
  Value<String> iconName,
});
typedef $$ItemsTableTableUpdateCompanionBuilder = ItemsTableCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> description,
  Value<String> type,
  Value<String> rarity,
  Value<String?> slot,
  Value<int> goldValue,
  Value<int> gemValue,
  Value<int> strBonus,
  Value<int> dexBonus,
  Value<int> intBonus,
  Value<int> conBonus,
  Value<int> spiBonus,
  Value<int> hpBonus,
  Value<int> mpBonus,
  Value<bool> isConsumable,
  Value<bool> isStackable,
  Value<String> iconName,
});

class $$ItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ItemsTableTable> {
  $$ItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rarity => $composableBuilder(
      column: $table.rarity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goldValue => $composableBuilder(
      column: $table.goldValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gemValue => $composableBuilder(
      column: $table.gemValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get strBonus => $composableBuilder(
      column: $table.strBonus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dexBonus => $composableBuilder(
      column: $table.dexBonus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intBonus => $composableBuilder(
      column: $table.intBonus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get conBonus => $composableBuilder(
      column: $table.conBonus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get spiBonus => $composableBuilder(
      column: $table.spiBonus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hpBonus => $composableBuilder(
      column: $table.hpBonus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mpBonus => $composableBuilder(
      column: $table.mpBonus, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isConsumable => $composableBuilder(
      column: $table.isConsumable, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isStackable => $composableBuilder(
      column: $table.isStackable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnFilters(column));
}

class $$ItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTableTable> {
  $$ItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rarity => $composableBuilder(
      column: $table.rarity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goldValue => $composableBuilder(
      column: $table.goldValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gemValue => $composableBuilder(
      column: $table.gemValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get strBonus => $composableBuilder(
      column: $table.strBonus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dexBonus => $composableBuilder(
      column: $table.dexBonus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intBonus => $composableBuilder(
      column: $table.intBonus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get conBonus => $composableBuilder(
      column: $table.conBonus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spiBonus => $composableBuilder(
      column: $table.spiBonus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hpBonus => $composableBuilder(
      column: $table.hpBonus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mpBonus => $composableBuilder(
      column: $table.mpBonus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isConsumable => $composableBuilder(
      column: $table.isConsumable,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStackable => $composableBuilder(
      column: $table.isStackable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnOrderings(column));
}

class $$ItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTableTable> {
  $$ItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get rarity =>
      $composableBuilder(column: $table.rarity, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get goldValue =>
      $composableBuilder(column: $table.goldValue, builder: (column) => column);

  GeneratedColumn<int> get gemValue =>
      $composableBuilder(column: $table.gemValue, builder: (column) => column);

  GeneratedColumn<int> get strBonus =>
      $composableBuilder(column: $table.strBonus, builder: (column) => column);

  GeneratedColumn<int> get dexBonus =>
      $composableBuilder(column: $table.dexBonus, builder: (column) => column);

  GeneratedColumn<int> get intBonus =>
      $composableBuilder(column: $table.intBonus, builder: (column) => column);

  GeneratedColumn<int> get conBonus =>
      $composableBuilder(column: $table.conBonus, builder: (column) => column);

  GeneratedColumn<int> get spiBonus =>
      $composableBuilder(column: $table.spiBonus, builder: (column) => column);

  GeneratedColumn<int> get hpBonus =>
      $composableBuilder(column: $table.hpBonus, builder: (column) => column);

  GeneratedColumn<int> get mpBonus =>
      $composableBuilder(column: $table.mpBonus, builder: (column) => column);

  GeneratedColumn<bool> get isConsumable => $composableBuilder(
      column: $table.isConsumable, builder: (column) => column);

  GeneratedColumn<bool> get isStackable => $composableBuilder(
      column: $table.isStackable, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);
}

class $$ItemsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemsTableTable,
    ItemsTableData,
    $$ItemsTableTableFilterComposer,
    $$ItemsTableTableOrderingComposer,
    $$ItemsTableTableAnnotationComposer,
    $$ItemsTableTableCreateCompanionBuilder,
    $$ItemsTableTableUpdateCompanionBuilder,
    (
      ItemsTableData,
      BaseReferences<_$AppDatabase, $ItemsTableTable, ItemsTableData>
    ),
    ItemsTableData,
    PrefetchHooks Function()> {
  $$ItemsTableTableTableManager(_$AppDatabase db, $ItemsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> rarity = const Value.absent(),
            Value<String?> slot = const Value.absent(),
            Value<int> goldValue = const Value.absent(),
            Value<int> gemValue = const Value.absent(),
            Value<int> strBonus = const Value.absent(),
            Value<int> dexBonus = const Value.absent(),
            Value<int> intBonus = const Value.absent(),
            Value<int> conBonus = const Value.absent(),
            Value<int> spiBonus = const Value.absent(),
            Value<int> hpBonus = const Value.absent(),
            Value<int> mpBonus = const Value.absent(),
            Value<bool> isConsumable = const Value.absent(),
            Value<bool> isStackable = const Value.absent(),
            Value<String> iconName = const Value.absent(),
          }) =>
              ItemsTableCompanion(
            id: id,
            name: name,
            description: description,
            type: type,
            rarity: rarity,
            slot: slot,
            goldValue: goldValue,
            gemValue: gemValue,
            strBonus: strBonus,
            dexBonus: dexBonus,
            intBonus: intBonus,
            conBonus: conBonus,
            spiBonus: spiBonus,
            hpBonus: hpBonus,
            mpBonus: mpBonus,
            isConsumable: isConsumable,
            isStackable: isStackable,
            iconName: iconName,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> description = const Value.absent(),
            required String type,
            Value<String> rarity = const Value.absent(),
            Value<String?> slot = const Value.absent(),
            Value<int> goldValue = const Value.absent(),
            Value<int> gemValue = const Value.absent(),
            Value<int> strBonus = const Value.absent(),
            Value<int> dexBonus = const Value.absent(),
            Value<int> intBonus = const Value.absent(),
            Value<int> conBonus = const Value.absent(),
            Value<int> spiBonus = const Value.absent(),
            Value<int> hpBonus = const Value.absent(),
            Value<int> mpBonus = const Value.absent(),
            Value<bool> isConsumable = const Value.absent(),
            Value<bool> isStackable = const Value.absent(),
            Value<String> iconName = const Value.absent(),
          }) =>
              ItemsTableCompanion.insert(
            id: id,
            name: name,
            description: description,
            type: type,
            rarity: rarity,
            slot: slot,
            goldValue: goldValue,
            gemValue: gemValue,
            strBonus: strBonus,
            dexBonus: dexBonus,
            intBonus: intBonus,
            conBonus: conBonus,
            spiBonus: spiBonus,
            hpBonus: hpBonus,
            mpBonus: mpBonus,
            isConsumable: isConsumable,
            isStackable: isStackable,
            iconName: iconName,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ItemsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemsTableTable,
    ItemsTableData,
    $$ItemsTableTableFilterComposer,
    $$ItemsTableTableOrderingComposer,
    $$ItemsTableTableAnnotationComposer,
    $$ItemsTableTableCreateCompanionBuilder,
    $$ItemsTableTableUpdateCompanionBuilder,
    (
      ItemsTableData,
      BaseReferences<_$AppDatabase, $ItemsTableTable, ItemsTableData>
    ),
    ItemsTableData,
    PrefetchHooks Function()>;
typedef $$InventoryTableTableCreateCompanionBuilder = InventoryTableCompanion
    Function({
  Value<int> id,
  required int playerId,
  required int itemId,
  Value<int> quantity,
  Value<bool> isEquipped,
  Value<String?> equippedSlot,
  Value<DateTime> acquiredAt,
});
typedef $$InventoryTableTableUpdateCompanionBuilder = InventoryTableCompanion
    Function({
  Value<int> id,
  Value<int> playerId,
  Value<int> itemId,
  Value<int> quantity,
  Value<bool> isEquipped,
  Value<String?> equippedSlot,
  Value<DateTime> acquiredAt,
});

class $$InventoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryTableTable> {
  $$InventoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEquipped => $composableBuilder(
      column: $table.isEquipped, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equippedSlot => $composableBuilder(
      column: $table.equippedSlot, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get acquiredAt => $composableBuilder(
      column: $table.acquiredAt, builder: (column) => ColumnFilters(column));
}

class $$InventoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryTableTable> {
  $$InventoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEquipped => $composableBuilder(
      column: $table.isEquipped, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equippedSlot => $composableBuilder(
      column: $table.equippedSlot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get acquiredAt => $composableBuilder(
      column: $table.acquiredAt, builder: (column) => ColumnOrderings(column));
}

class $$InventoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryTableTable> {
  $$InventoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<bool> get isEquipped => $composableBuilder(
      column: $table.isEquipped, builder: (column) => column);

  GeneratedColumn<String> get equippedSlot => $composableBuilder(
      column: $table.equippedSlot, builder: (column) => column);

  GeneratedColumn<DateTime> get acquiredAt => $composableBuilder(
      column: $table.acquiredAt, builder: (column) => column);
}

class $$InventoryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryTableTable,
    InventoryTableData,
    $$InventoryTableTableFilterComposer,
    $$InventoryTableTableOrderingComposer,
    $$InventoryTableTableAnnotationComposer,
    $$InventoryTableTableCreateCompanionBuilder,
    $$InventoryTableTableUpdateCompanionBuilder,
    (
      InventoryTableData,
      BaseReferences<_$AppDatabase, $InventoryTableTable, InventoryTableData>
    ),
    InventoryTableData,
    PrefetchHooks Function()> {
  $$InventoryTableTableTableManager(
      _$AppDatabase db, $InventoryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<int> itemId = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<bool> isEquipped = const Value.absent(),
            Value<String?> equippedSlot = const Value.absent(),
            Value<DateTime> acquiredAt = const Value.absent(),
          }) =>
              InventoryTableCompanion(
            id: id,
            playerId: playerId,
            itemId: itemId,
            quantity: quantity,
            isEquipped: isEquipped,
            equippedSlot: equippedSlot,
            acquiredAt: acquiredAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            required int itemId,
            Value<int> quantity = const Value.absent(),
            Value<bool> isEquipped = const Value.absent(),
            Value<String?> equippedSlot = const Value.absent(),
            Value<DateTime> acquiredAt = const Value.absent(),
          }) =>
              InventoryTableCompanion.insert(
            id: id,
            playerId: playerId,
            itemId: itemId,
            quantity: quantity,
            isEquipped: isEquipped,
            equippedSlot: equippedSlot,
            acquiredAt: acquiredAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventoryTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryTableTable,
    InventoryTableData,
    $$InventoryTableTableFilterComposer,
    $$InventoryTableTableOrderingComposer,
    $$InventoryTableTableAnnotationComposer,
    $$InventoryTableTableCreateCompanionBuilder,
    $$InventoryTableTableUpdateCompanionBuilder,
    (
      InventoryTableData,
      BaseReferences<_$AppDatabase, $InventoryTableTable, InventoryTableData>
    ),
    InventoryTableData,
    PrefetchHooks Function()>;
typedef $$ShopItemsTableTableCreateCompanionBuilder = ShopItemsTableCompanion
    Function({
  Value<int> id,
  required int itemId,
  Value<String> currency,
  required int price,
  Value<bool> isAvailable,
  Value<int> requiredLevel,
});
typedef $$ShopItemsTableTableUpdateCompanionBuilder = ShopItemsTableCompanion
    Function({
  Value<int> id,
  Value<int> itemId,
  Value<String> currency,
  Value<int> price,
  Value<bool> isAvailable,
  Value<int> requiredLevel,
});

class $$ShopItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ShopItemsTableTable> {
  $$ShopItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAvailable => $composableBuilder(
      column: $table.isAvailable, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requiredLevel => $composableBuilder(
      column: $table.requiredLevel, builder: (column) => ColumnFilters(column));
}

class $$ShopItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ShopItemsTableTable> {
  $$ShopItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
      column: $table.isAvailable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requiredLevel => $composableBuilder(
      column: $table.requiredLevel,
      builder: (column) => ColumnOrderings(column));
}

class $$ShopItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShopItemsTableTable> {
  $$ShopItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
      column: $table.isAvailable, builder: (column) => column);

  GeneratedColumn<int> get requiredLevel => $composableBuilder(
      column: $table.requiredLevel, builder: (column) => column);
}

class $$ShopItemsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShopItemsTableTable,
    ShopItemsTableData,
    $$ShopItemsTableTableFilterComposer,
    $$ShopItemsTableTableOrderingComposer,
    $$ShopItemsTableTableAnnotationComposer,
    $$ShopItemsTableTableCreateCompanionBuilder,
    $$ShopItemsTableTableUpdateCompanionBuilder,
    (
      ShopItemsTableData,
      BaseReferences<_$AppDatabase, $ShopItemsTableTable, ShopItemsTableData>
    ),
    ShopItemsTableData,
    PrefetchHooks Function()> {
  $$ShopItemsTableTableTableManager(
      _$AppDatabase db, $ShopItemsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShopItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShopItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShopItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> itemId = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<int> price = const Value.absent(),
            Value<bool> isAvailable = const Value.absent(),
            Value<int> requiredLevel = const Value.absent(),
          }) =>
              ShopItemsTableCompanion(
            id: id,
            itemId: itemId,
            currency: currency,
            price: price,
            isAvailable: isAvailable,
            requiredLevel: requiredLevel,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int itemId,
            Value<String> currency = const Value.absent(),
            required int price,
            Value<bool> isAvailable = const Value.absent(),
            Value<int> requiredLevel = const Value.absent(),
          }) =>
              ShopItemsTableCompanion.insert(
            id: id,
            itemId: itemId,
            currency: currency,
            price: price,
            isAvailable: isAvailable,
            requiredLevel: requiredLevel,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShopItemsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShopItemsTableTable,
    ShopItemsTableData,
    $$ShopItemsTableTableFilterComposer,
    $$ShopItemsTableTableOrderingComposer,
    $$ShopItemsTableTableAnnotationComposer,
    $$ShopItemsTableTableCreateCompanionBuilder,
    $$ShopItemsTableTableUpdateCompanionBuilder,
    (
      ShopItemsTableData,
      BaseReferences<_$AppDatabase, $ShopItemsTableTable, ShopItemsTableData>
    ),
    ShopItemsTableData,
    PrefetchHooks Function()>;
typedef $$AchievementsTableTableCreateCompanionBuilder
    = AchievementsTableCompanion Function({
  Value<int> id,
  required String key,
  required String title,
  required String description,
  required String category,
  Value<String> iconName,
  Value<int> xpReward,
  Value<int> goldReward,
  Value<int> gemReward,
  Value<bool> isSecret,
  Value<String> rarity,
  Value<String?> titleReward,
  Value<String?> category2,
});
typedef $$AchievementsTableTableUpdateCompanionBuilder
    = AchievementsTableCompanion Function({
  Value<int> id,
  Value<String> key,
  Value<String> title,
  Value<String> description,
  Value<String> category,
  Value<String> iconName,
  Value<int> xpReward,
  Value<int> goldReward,
  Value<int> gemReward,
  Value<bool> isSecret,
  Value<String> rarity,
  Value<String?> titleReward,
  Value<String?> category2,
});

class $$AchievementsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTableTable> {
  $$AchievementsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gemReward => $composableBuilder(
      column: $table.gemReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSecret => $composableBuilder(
      column: $table.isSecret, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rarity => $composableBuilder(
      column: $table.rarity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titleReward => $composableBuilder(
      column: $table.titleReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category2 => $composableBuilder(
      column: $table.category2, builder: (column) => ColumnFilters(column));
}

class $$AchievementsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTableTable> {
  $$AchievementsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconName => $composableBuilder(
      column: $table.iconName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gemReward => $composableBuilder(
      column: $table.gemReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSecret => $composableBuilder(
      column: $table.isSecret, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rarity => $composableBuilder(
      column: $table.rarity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titleReward => $composableBuilder(
      column: $table.titleReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category2 => $composableBuilder(
      column: $table.category2, builder: (column) => ColumnOrderings(column));
}

class $$AchievementsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTableTable> {
  $$AchievementsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);

  GeneratedColumn<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => column);

  GeneratedColumn<int> get gemReward =>
      $composableBuilder(column: $table.gemReward, builder: (column) => column);

  GeneratedColumn<bool> get isSecret =>
      $composableBuilder(column: $table.isSecret, builder: (column) => column);

  GeneratedColumn<String> get rarity =>
      $composableBuilder(column: $table.rarity, builder: (column) => column);

  GeneratedColumn<String> get titleReward => $composableBuilder(
      column: $table.titleReward, builder: (column) => column);

  GeneratedColumn<String> get category2 =>
      $composableBuilder(column: $table.category2, builder: (column) => column);
}

class $$AchievementsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AchievementsTableTable,
    AchievementsTableData,
    $$AchievementsTableTableFilterComposer,
    $$AchievementsTableTableOrderingComposer,
    $$AchievementsTableTableAnnotationComposer,
    $$AchievementsTableTableCreateCompanionBuilder,
    $$AchievementsTableTableUpdateCompanionBuilder,
    (
      AchievementsTableData,
      BaseReferences<_$AppDatabase, $AchievementsTableTable,
          AchievementsTableData>
    ),
    AchievementsTableData,
    PrefetchHooks Function()> {
  $$AchievementsTableTableTableManager(
      _$AppDatabase db, $AchievementsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> iconName = const Value.absent(),
            Value<int> xpReward = const Value.absent(),
            Value<int> goldReward = const Value.absent(),
            Value<int> gemReward = const Value.absent(),
            Value<bool> isSecret = const Value.absent(),
            Value<String> rarity = const Value.absent(),
            Value<String?> titleReward = const Value.absent(),
            Value<String?> category2 = const Value.absent(),
          }) =>
              AchievementsTableCompanion(
            id: id,
            key: key,
            title: title,
            description: description,
            category: category,
            iconName: iconName,
            xpReward: xpReward,
            goldReward: goldReward,
            gemReward: gemReward,
            isSecret: isSecret,
            rarity: rarity,
            titleReward: titleReward,
            category2: category2,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String key,
            required String title,
            required String description,
            required String category,
            Value<String> iconName = const Value.absent(),
            Value<int> xpReward = const Value.absent(),
            Value<int> goldReward = const Value.absent(),
            Value<int> gemReward = const Value.absent(),
            Value<bool> isSecret = const Value.absent(),
            Value<String> rarity = const Value.absent(),
            Value<String?> titleReward = const Value.absent(),
            Value<String?> category2 = const Value.absent(),
          }) =>
              AchievementsTableCompanion.insert(
            id: id,
            key: key,
            title: title,
            description: description,
            category: category,
            iconName: iconName,
            xpReward: xpReward,
            goldReward: goldReward,
            gemReward: gemReward,
            isSecret: isSecret,
            rarity: rarity,
            titleReward: titleReward,
            category2: category2,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AchievementsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AchievementsTableTable,
    AchievementsTableData,
    $$AchievementsTableTableFilterComposer,
    $$AchievementsTableTableOrderingComposer,
    $$AchievementsTableTableAnnotationComposer,
    $$AchievementsTableTableCreateCompanionBuilder,
    $$AchievementsTableTableUpdateCompanionBuilder,
    (
      AchievementsTableData,
      BaseReferences<_$AppDatabase, $AchievementsTableTable,
          AchievementsTableData>
    ),
    AchievementsTableData,
    PrefetchHooks Function()>;
typedef $$PlayerAchievementsTableTableCreateCompanionBuilder
    = PlayerAchievementsTableCompanion Function({
  Value<int> id,
  required int playerId,
  required String achievementKey,
  Value<DateTime> unlockedAt,
  Value<DateTime?> collectedAt,
});
typedef $$PlayerAchievementsTableTableUpdateCompanionBuilder
    = PlayerAchievementsTableCompanion Function({
  Value<int> id,
  Value<int> playerId,
  Value<String> achievementKey,
  Value<DateTime> unlockedAt,
  Value<DateTime?> collectedAt,
});

class $$PlayerAchievementsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerAchievementsTableTable> {
  $$PlayerAchievementsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get achievementKey => $composableBuilder(
      column: $table.achievementKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get collectedAt => $composableBuilder(
      column: $table.collectedAt, builder: (column) => ColumnFilters(column));
}

class $$PlayerAchievementsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerAchievementsTableTable> {
  $$PlayerAchievementsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get achievementKey => $composableBuilder(
      column: $table.achievementKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get collectedAt => $composableBuilder(
      column: $table.collectedAt, builder: (column) => ColumnOrderings(column));
}

class $$PlayerAchievementsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerAchievementsTableTable> {
  $$PlayerAchievementsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get achievementKey => $composableBuilder(
      column: $table.achievementKey, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get collectedAt => $composableBuilder(
      column: $table.collectedAt, builder: (column) => column);
}

class $$PlayerAchievementsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayerAchievementsTableTable,
    PlayerAchievementsTableData,
    $$PlayerAchievementsTableTableFilterComposer,
    $$PlayerAchievementsTableTableOrderingComposer,
    $$PlayerAchievementsTableTableAnnotationComposer,
    $$PlayerAchievementsTableTableCreateCompanionBuilder,
    $$PlayerAchievementsTableTableUpdateCompanionBuilder,
    (
      PlayerAchievementsTableData,
      BaseReferences<_$AppDatabase, $PlayerAchievementsTableTable,
          PlayerAchievementsTableData>
    ),
    PlayerAchievementsTableData,
    PrefetchHooks Function()> {
  $$PlayerAchievementsTableTableTableManager(
      _$AppDatabase db, $PlayerAchievementsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerAchievementsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerAchievementsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerAchievementsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> achievementKey = const Value.absent(),
            Value<DateTime> unlockedAt = const Value.absent(),
            Value<DateTime?> collectedAt = const Value.absent(),
          }) =>
              PlayerAchievementsTableCompanion(
            id: id,
            playerId: playerId,
            achievementKey: achievementKey,
            unlockedAt: unlockedAt,
            collectedAt: collectedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            required String achievementKey,
            Value<DateTime> unlockedAt = const Value.absent(),
            Value<DateTime?> collectedAt = const Value.absent(),
          }) =>
              PlayerAchievementsTableCompanion.insert(
            id: id,
            playerId: playerId,
            achievementKey: achievementKey,
            unlockedAt: unlockedAt,
            collectedAt: collectedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayerAchievementsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PlayerAchievementsTableTable,
        PlayerAchievementsTableData,
        $$PlayerAchievementsTableTableFilterComposer,
        $$PlayerAchievementsTableTableOrderingComposer,
        $$PlayerAchievementsTableTableAnnotationComposer,
        $$PlayerAchievementsTableTableCreateCompanionBuilder,
        $$PlayerAchievementsTableTableUpdateCompanionBuilder,
        (
          PlayerAchievementsTableData,
          BaseReferences<_$AppDatabase, $PlayerAchievementsTableTable,
              PlayerAchievementsTableData>
        ),
        PlayerAchievementsTableData,
        PrefetchHooks Function()>;
typedef $$GuildStatusTableTableCreateCompanionBuilder
    = GuildStatusTableCompanion Function({
  Value<int> id,
  required int playerId,
  Value<String> guildRank,
  Value<int> guildReputation,
  Value<int> collarLevel,
  Value<int> totalGoldSpent,
  Value<DateTime?> joinedAt,
  Value<DateTime?> ascensionCooldown,
});
typedef $$GuildStatusTableTableUpdateCompanionBuilder
    = GuildStatusTableCompanion Function({
  Value<int> id,
  Value<int> playerId,
  Value<String> guildRank,
  Value<int> guildReputation,
  Value<int> collarLevel,
  Value<int> totalGoldSpent,
  Value<DateTime?> joinedAt,
  Value<DateTime?> ascensionCooldown,
});

class $$GuildStatusTableTableFilterComposer
    extends Composer<_$AppDatabase, $GuildStatusTableTable> {
  $$GuildStatusTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get guildRank => $composableBuilder(
      column: $table.guildRank, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get guildReputation => $composableBuilder(
      column: $table.guildReputation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get collarLevel => $composableBuilder(
      column: $table.collarLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalGoldSpent => $composableBuilder(
      column: $table.totalGoldSpent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get ascensionCooldown => $composableBuilder(
      column: $table.ascensionCooldown,
      builder: (column) => ColumnFilters(column));
}

class $$GuildStatusTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GuildStatusTableTable> {
  $$GuildStatusTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get guildRank => $composableBuilder(
      column: $table.guildRank, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get guildReputation => $composableBuilder(
      column: $table.guildReputation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get collarLevel => $composableBuilder(
      column: $table.collarLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalGoldSpent => $composableBuilder(
      column: $table.totalGoldSpent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
      column: $table.joinedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get ascensionCooldown => $composableBuilder(
      column: $table.ascensionCooldown,
      builder: (column) => ColumnOrderings(column));
}

class $$GuildStatusTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuildStatusTableTable> {
  $$GuildStatusTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get guildRank =>
      $composableBuilder(column: $table.guildRank, builder: (column) => column);

  GeneratedColumn<int> get guildReputation => $composableBuilder(
      column: $table.guildReputation, builder: (column) => column);

  GeneratedColumn<int> get collarLevel => $composableBuilder(
      column: $table.collarLevel, builder: (column) => column);

  GeneratedColumn<int> get totalGoldSpent => $composableBuilder(
      column: $table.totalGoldSpent, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get ascensionCooldown => $composableBuilder(
      column: $table.ascensionCooldown, builder: (column) => column);
}

class $$GuildStatusTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GuildStatusTableTable,
    GuildStatusTableData,
    $$GuildStatusTableTableFilterComposer,
    $$GuildStatusTableTableOrderingComposer,
    $$GuildStatusTableTableAnnotationComposer,
    $$GuildStatusTableTableCreateCompanionBuilder,
    $$GuildStatusTableTableUpdateCompanionBuilder,
    (
      GuildStatusTableData,
      BaseReferences<_$AppDatabase, $GuildStatusTableTable,
          GuildStatusTableData>
    ),
    GuildStatusTableData,
    PrefetchHooks Function()> {
  $$GuildStatusTableTableTableManager(
      _$AppDatabase db, $GuildStatusTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuildStatusTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuildStatusTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuildStatusTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> guildRank = const Value.absent(),
            Value<int> guildReputation = const Value.absent(),
            Value<int> collarLevel = const Value.absent(),
            Value<int> totalGoldSpent = const Value.absent(),
            Value<DateTime?> joinedAt = const Value.absent(),
            Value<DateTime?> ascensionCooldown = const Value.absent(),
          }) =>
              GuildStatusTableCompanion(
            id: id,
            playerId: playerId,
            guildRank: guildRank,
            guildReputation: guildReputation,
            collarLevel: collarLevel,
            totalGoldSpent: totalGoldSpent,
            joinedAt: joinedAt,
            ascensionCooldown: ascensionCooldown,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            Value<String> guildRank = const Value.absent(),
            Value<int> guildReputation = const Value.absent(),
            Value<int> collarLevel = const Value.absent(),
            Value<int> totalGoldSpent = const Value.absent(),
            Value<DateTime?> joinedAt = const Value.absent(),
            Value<DateTime?> ascensionCooldown = const Value.absent(),
          }) =>
              GuildStatusTableCompanion.insert(
            id: id,
            playerId: playerId,
            guildRank: guildRank,
            guildReputation: guildReputation,
            collarLevel: collarLevel,
            totalGoldSpent: totalGoldSpent,
            joinedAt: joinedAt,
            ascensionCooldown: ascensionCooldown,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GuildStatusTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GuildStatusTableTable,
    GuildStatusTableData,
    $$GuildStatusTableTableFilterComposer,
    $$GuildStatusTableTableOrderingComposer,
    $$GuildStatusTableTableAnnotationComposer,
    $$GuildStatusTableTableCreateCompanionBuilder,
    $$GuildStatusTableTableUpdateCompanionBuilder,
    (
      GuildStatusTableData,
      BaseReferences<_$AppDatabase, $GuildStatusTableTable,
          GuildStatusTableData>
    ),
    GuildStatusTableData,
    PrefetchHooks Function()>;
typedef $$NpcReputationTableTableCreateCompanionBuilder
    = NpcReputationTableCompanion Function({
  Value<int> id,
  required int playerId,
  required String npcId,
  Value<int> reputation,
  Value<DateTime?> lastGainAt,
  Value<int> dailyGained,
});
typedef $$NpcReputationTableTableUpdateCompanionBuilder
    = NpcReputationTableCompanion Function({
  Value<int> id,
  Value<int> playerId,
  Value<String> npcId,
  Value<int> reputation,
  Value<DateTime?> lastGainAt,
  Value<int> dailyGained,
});

class $$NpcReputationTableTableFilterComposer
    extends Composer<_$AppDatabase, $NpcReputationTableTable> {
  $$NpcReputationTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get npcId => $composableBuilder(
      column: $table.npcId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reputation => $composableBuilder(
      column: $table.reputation, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastGainAt => $composableBuilder(
      column: $table.lastGainAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dailyGained => $composableBuilder(
      column: $table.dailyGained, builder: (column) => ColumnFilters(column));
}

class $$NpcReputationTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NpcReputationTableTable> {
  $$NpcReputationTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get npcId => $composableBuilder(
      column: $table.npcId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reputation => $composableBuilder(
      column: $table.reputation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastGainAt => $composableBuilder(
      column: $table.lastGainAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dailyGained => $composableBuilder(
      column: $table.dailyGained, builder: (column) => ColumnOrderings(column));
}

class $$NpcReputationTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NpcReputationTableTable> {
  $$NpcReputationTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get npcId =>
      $composableBuilder(column: $table.npcId, builder: (column) => column);

  GeneratedColumn<int> get reputation => $composableBuilder(
      column: $table.reputation, builder: (column) => column);

  GeneratedColumn<DateTime> get lastGainAt => $composableBuilder(
      column: $table.lastGainAt, builder: (column) => column);

  GeneratedColumn<int> get dailyGained => $composableBuilder(
      column: $table.dailyGained, builder: (column) => column);
}

class $$NpcReputationTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NpcReputationTableTable,
    NpcReputationTableData,
    $$NpcReputationTableTableFilterComposer,
    $$NpcReputationTableTableOrderingComposer,
    $$NpcReputationTableTableAnnotationComposer,
    $$NpcReputationTableTableCreateCompanionBuilder,
    $$NpcReputationTableTableUpdateCompanionBuilder,
    (
      NpcReputationTableData,
      BaseReferences<_$AppDatabase, $NpcReputationTableTable,
          NpcReputationTableData>
    ),
    NpcReputationTableData,
    PrefetchHooks Function()> {
  $$NpcReputationTableTableTableManager(
      _$AppDatabase db, $NpcReputationTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NpcReputationTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NpcReputationTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NpcReputationTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> npcId = const Value.absent(),
            Value<int> reputation = const Value.absent(),
            Value<DateTime?> lastGainAt = const Value.absent(),
            Value<int> dailyGained = const Value.absent(),
          }) =>
              NpcReputationTableCompanion(
            id: id,
            playerId: playerId,
            npcId: npcId,
            reputation: reputation,
            lastGainAt: lastGainAt,
            dailyGained: dailyGained,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            required String npcId,
            Value<int> reputation = const Value.absent(),
            Value<DateTime?> lastGainAt = const Value.absent(),
            Value<int> dailyGained = const Value.absent(),
          }) =>
              NpcReputationTableCompanion.insert(
            id: id,
            playerId: playerId,
            npcId: npcId,
            reputation: reputation,
            lastGainAt: lastGainAt,
            dailyGained: dailyGained,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NpcReputationTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NpcReputationTableTable,
    NpcReputationTableData,
    $$NpcReputationTableTableFilterComposer,
    $$NpcReputationTableTableOrderingComposer,
    $$NpcReputationTableTableAnnotationComposer,
    $$NpcReputationTableTableCreateCompanionBuilder,
    $$NpcReputationTableTableUpdateCompanionBuilder,
    (
      NpcReputationTableData,
      BaseReferences<_$AppDatabase, $NpcReputationTableTable,
          NpcReputationTableData>
    ),
    NpcReputationTableData,
    PrefetchHooks Function()>;
typedef $$DiaryEntriesTableTableCreateCompanionBuilder
    = DiaryEntriesTableCompanion Function({
  Value<int> id,
  required int playerId,
  Value<String> content,
  Value<int> wordCount,
  required DateTime entryDate,
  Value<DateTime> updatedAt,
});
typedef $$DiaryEntriesTableTableUpdateCompanionBuilder
    = DiaryEntriesTableCompanion Function({
  Value<int> id,
  Value<int> playerId,
  Value<String> content,
  Value<int> wordCount,
  Value<DateTime> entryDate,
  Value<DateTime> updatedAt,
});

class $$DiaryEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTableTable> {
  $$DiaryEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wordCount => $composableBuilder(
      column: $table.wordCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get entryDate => $composableBuilder(
      column: $table.entryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$DiaryEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTableTable> {
  $$DiaryEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wordCount => $composableBuilder(
      column: $table.wordCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get entryDate => $composableBuilder(
      column: $table.entryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DiaryEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTableTable> {
  $$DiaryEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<DateTime> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DiaryEntriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiaryEntriesTableTable,
    DiaryEntriesTableData,
    $$DiaryEntriesTableTableFilterComposer,
    $$DiaryEntriesTableTableOrderingComposer,
    $$DiaryEntriesTableTableAnnotationComposer,
    $$DiaryEntriesTableTableCreateCompanionBuilder,
    $$DiaryEntriesTableTableUpdateCompanionBuilder,
    (
      DiaryEntriesTableData,
      BaseReferences<_$AppDatabase, $DiaryEntriesTableTable,
          DiaryEntriesTableData>
    ),
    DiaryEntriesTableData,
    PrefetchHooks Function()> {
  $$DiaryEntriesTableTableTableManager(
      _$AppDatabase db, $DiaryEntriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiaryEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiaryEntriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiaryEntriesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> wordCount = const Value.absent(),
            Value<DateTime> entryDate = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DiaryEntriesTableCompanion(
            id: id,
            playerId: playerId,
            content: content,
            wordCount: wordCount,
            entryDate: entryDate,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            Value<String> content = const Value.absent(),
            Value<int> wordCount = const Value.absent(),
            required DateTime entryDate,
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DiaryEntriesTableCompanion.insert(
            id: id,
            playerId: playerId,
            content: content,
            wordCount: wordCount,
            entryDate: entryDate,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DiaryEntriesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiaryEntriesTableTable,
    DiaryEntriesTableData,
    $$DiaryEntriesTableTableFilterComposer,
    $$DiaryEntriesTableTableOrderingComposer,
    $$DiaryEntriesTableTableAnnotationComposer,
    $$DiaryEntriesTableTableCreateCompanionBuilder,
    $$DiaryEntriesTableTableUpdateCompanionBuilder,
    (
      DiaryEntriesTableData,
      BaseReferences<_$AppDatabase, $DiaryEntriesTableTable,
          DiaryEntriesTableData>
    ),
    DiaryEntriesTableData,
    PrefetchHooks Function()>;
typedef $$ClassQuestsTableTableCreateCompanionBuilder
    = ClassQuestsTableCompanion Function({
  Value<int> id,
  required int playerId,
  required String classType,
  required String questKey,
  required String title,
  required String description,
  required String checkType,
  required String checkParamsJson,
  Value<int> xpReward,
  Value<int> goldReward,
  required String assignedDate,
  Value<bool> completed,
  Value<int> progress,
  Value<int> progressTarget,
});
typedef $$ClassQuestsTableTableUpdateCompanionBuilder
    = ClassQuestsTableCompanion Function({
  Value<int> id,
  Value<int> playerId,
  Value<String> classType,
  Value<String> questKey,
  Value<String> title,
  Value<String> description,
  Value<String> checkType,
  Value<String> checkParamsJson,
  Value<int> xpReward,
  Value<int> goldReward,
  Value<String> assignedDate,
  Value<bool> completed,
  Value<int> progress,
  Value<int> progressTarget,
});

class $$ClassQuestsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClassQuestsTableTable> {
  $$ClassQuestsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get classType => $composableBuilder(
      column: $table.classType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questKey => $composableBuilder(
      column: $table.questKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkType => $composableBuilder(
      column: $table.checkType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkParamsJson => $composableBuilder(
      column: $table.checkParamsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignedDate => $composableBuilder(
      column: $table.assignedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progressTarget => $composableBuilder(
      column: $table.progressTarget,
      builder: (column) => ColumnFilters(column));
}

class $$ClassQuestsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassQuestsTableTable> {
  $$ClassQuestsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get classType => $composableBuilder(
      column: $table.classType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questKey => $composableBuilder(
      column: $table.questKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkType => $composableBuilder(
      column: $table.checkType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkParamsJson => $composableBuilder(
      column: $table.checkParamsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignedDate => $composableBuilder(
      column: $table.assignedDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progressTarget => $composableBuilder(
      column: $table.progressTarget,
      builder: (column) => ColumnOrderings(column));
}

class $$ClassQuestsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassQuestsTableTable> {
  $$ClassQuestsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get classType =>
      $composableBuilder(column: $table.classType, builder: (column) => column);

  GeneratedColumn<String> get questKey =>
      $composableBuilder(column: $table.questKey, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get checkType =>
      $composableBuilder(column: $table.checkType, builder: (column) => column);

  GeneratedColumn<String> get checkParamsJson => $composableBuilder(
      column: $table.checkParamsJson, builder: (column) => column);

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);

  GeneratedColumn<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => column);

  GeneratedColumn<String> get assignedDate => $composableBuilder(
      column: $table.assignedDate, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get progressTarget => $composableBuilder(
      column: $table.progressTarget, builder: (column) => column);
}

class $$ClassQuestsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClassQuestsTableTable,
    ClassQuestsTableData,
    $$ClassQuestsTableTableFilterComposer,
    $$ClassQuestsTableTableOrderingComposer,
    $$ClassQuestsTableTableAnnotationComposer,
    $$ClassQuestsTableTableCreateCompanionBuilder,
    $$ClassQuestsTableTableUpdateCompanionBuilder,
    (
      ClassQuestsTableData,
      BaseReferences<_$AppDatabase, $ClassQuestsTableTable,
          ClassQuestsTableData>
    ),
    ClassQuestsTableData,
    PrefetchHooks Function()> {
  $$ClassQuestsTableTableTableManager(
      _$AppDatabase db, $ClassQuestsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassQuestsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassQuestsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassQuestsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> classType = const Value.absent(),
            Value<String> questKey = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> checkType = const Value.absent(),
            Value<String> checkParamsJson = const Value.absent(),
            Value<int> xpReward = const Value.absent(),
            Value<int> goldReward = const Value.absent(),
            Value<String> assignedDate = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<int> progressTarget = const Value.absent(),
          }) =>
              ClassQuestsTableCompanion(
            id: id,
            playerId: playerId,
            classType: classType,
            questKey: questKey,
            title: title,
            description: description,
            checkType: checkType,
            checkParamsJson: checkParamsJson,
            xpReward: xpReward,
            goldReward: goldReward,
            assignedDate: assignedDate,
            completed: completed,
            progress: progress,
            progressTarget: progressTarget,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            required String classType,
            required String questKey,
            required String title,
            required String description,
            required String checkType,
            required String checkParamsJson,
            Value<int> xpReward = const Value.absent(),
            Value<int> goldReward = const Value.absent(),
            required String assignedDate,
            Value<bool> completed = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<int> progressTarget = const Value.absent(),
          }) =>
              ClassQuestsTableCompanion.insert(
            id: id,
            playerId: playerId,
            classType: classType,
            questKey: questKey,
            title: title,
            description: description,
            checkType: checkType,
            checkParamsJson: checkParamsJson,
            xpReward: xpReward,
            goldReward: goldReward,
            assignedDate: assignedDate,
            completed: completed,
            progress: progress,
            progressTarget: progressTarget,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ClassQuestsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClassQuestsTableTable,
    ClassQuestsTableData,
    $$ClassQuestsTableTableFilterComposer,
    $$ClassQuestsTableTableOrderingComposer,
    $$ClassQuestsTableTableAnnotationComposer,
    $$ClassQuestsTableTableCreateCompanionBuilder,
    $$ClassQuestsTableTableUpdateCompanionBuilder,
    (
      ClassQuestsTableData,
      BaseReferences<_$AppDatabase, $ClassQuestsTableTable,
          ClassQuestsTableData>
    ),
    ClassQuestsTableData,
    PrefetchHooks Function()>;
typedef $$FactionQuestsTableTableCreateCompanionBuilder
    = FactionQuestsTableCompanion Function({
  Value<int> id,
  required int playerId,
  required String factionId,
  required String questKey,
  required String title,
  required String description,
  required String checkType,
  required String checkParamsJson,
  Value<int> xpReward,
  Value<int> goldReward,
  Value<double> factionItemChance,
  required String weekStart,
  Value<bool> completed,
  Value<int> progress,
  Value<int> progressTarget,
  Value<String> lastQuestKey,
});
typedef $$FactionQuestsTableTableUpdateCompanionBuilder
    = FactionQuestsTableCompanion Function({
  Value<int> id,
  Value<int> playerId,
  Value<String> factionId,
  Value<String> questKey,
  Value<String> title,
  Value<String> description,
  Value<String> checkType,
  Value<String> checkParamsJson,
  Value<int> xpReward,
  Value<int> goldReward,
  Value<double> factionItemChance,
  Value<String> weekStart,
  Value<bool> completed,
  Value<int> progress,
  Value<int> progressTarget,
  Value<String> lastQuestKey,
});

class $$FactionQuestsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FactionQuestsTableTable> {
  $$FactionQuestsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get factionId => $composableBuilder(
      column: $table.factionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questKey => $composableBuilder(
      column: $table.questKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkType => $composableBuilder(
      column: $table.checkType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkParamsJson => $composableBuilder(
      column: $table.checkParamsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get factionItemChance => $composableBuilder(
      column: $table.factionItemChance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progressTarget => $composableBuilder(
      column: $table.progressTarget,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastQuestKey => $composableBuilder(
      column: $table.lastQuestKey, builder: (column) => ColumnFilters(column));
}

class $$FactionQuestsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FactionQuestsTableTable> {
  $$FactionQuestsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get factionId => $composableBuilder(
      column: $table.factionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questKey => $composableBuilder(
      column: $table.questKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkType => $composableBuilder(
      column: $table.checkType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkParamsJson => $composableBuilder(
      column: $table.checkParamsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get factionItemChance => $composableBuilder(
      column: $table.factionItemChance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekStart => $composableBuilder(
      column: $table.weekStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progressTarget => $composableBuilder(
      column: $table.progressTarget,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastQuestKey => $composableBuilder(
      column: $table.lastQuestKey,
      builder: (column) => ColumnOrderings(column));
}

class $$FactionQuestsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FactionQuestsTableTable> {
  $$FactionQuestsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get factionId =>
      $composableBuilder(column: $table.factionId, builder: (column) => column);

  GeneratedColumn<String> get questKey =>
      $composableBuilder(column: $table.questKey, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get checkType =>
      $composableBuilder(column: $table.checkType, builder: (column) => column);

  GeneratedColumn<String> get checkParamsJson => $composableBuilder(
      column: $table.checkParamsJson, builder: (column) => column);

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);

  GeneratedColumn<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => column);

  GeneratedColumn<double> get factionItemChance => $composableBuilder(
      column: $table.factionItemChance, builder: (column) => column);

  GeneratedColumn<String> get weekStart =>
      $composableBuilder(column: $table.weekStart, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get progressTarget => $composableBuilder(
      column: $table.progressTarget, builder: (column) => column);

  GeneratedColumn<String> get lastQuestKey => $composableBuilder(
      column: $table.lastQuestKey, builder: (column) => column);
}

class $$FactionQuestsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FactionQuestsTableTable,
    FactionQuestsTableData,
    $$FactionQuestsTableTableFilterComposer,
    $$FactionQuestsTableTableOrderingComposer,
    $$FactionQuestsTableTableAnnotationComposer,
    $$FactionQuestsTableTableCreateCompanionBuilder,
    $$FactionQuestsTableTableUpdateCompanionBuilder,
    (
      FactionQuestsTableData,
      BaseReferences<_$AppDatabase, $FactionQuestsTableTable,
          FactionQuestsTableData>
    ),
    FactionQuestsTableData,
    PrefetchHooks Function()> {
  $$FactionQuestsTableTableTableManager(
      _$AppDatabase db, $FactionQuestsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FactionQuestsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FactionQuestsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FactionQuestsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> factionId = const Value.absent(),
            Value<String> questKey = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> checkType = const Value.absent(),
            Value<String> checkParamsJson = const Value.absent(),
            Value<int> xpReward = const Value.absent(),
            Value<int> goldReward = const Value.absent(),
            Value<double> factionItemChance = const Value.absent(),
            Value<String> weekStart = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<int> progressTarget = const Value.absent(),
            Value<String> lastQuestKey = const Value.absent(),
          }) =>
              FactionQuestsTableCompanion(
            id: id,
            playerId: playerId,
            factionId: factionId,
            questKey: questKey,
            title: title,
            description: description,
            checkType: checkType,
            checkParamsJson: checkParamsJson,
            xpReward: xpReward,
            goldReward: goldReward,
            factionItemChance: factionItemChance,
            weekStart: weekStart,
            completed: completed,
            progress: progress,
            progressTarget: progressTarget,
            lastQuestKey: lastQuestKey,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            required String factionId,
            required String questKey,
            required String title,
            required String description,
            required String checkType,
            required String checkParamsJson,
            Value<int> xpReward = const Value.absent(),
            Value<int> goldReward = const Value.absent(),
            Value<double> factionItemChance = const Value.absent(),
            required String weekStart,
            Value<bool> completed = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<int> progressTarget = const Value.absent(),
            Value<String> lastQuestKey = const Value.absent(),
          }) =>
              FactionQuestsTableCompanion.insert(
            id: id,
            playerId: playerId,
            factionId: factionId,
            questKey: questKey,
            title: title,
            description: description,
            checkType: checkType,
            checkParamsJson: checkParamsJson,
            xpReward: xpReward,
            goldReward: goldReward,
            factionItemChance: factionItemChance,
            weekStart: weekStart,
            completed: completed,
            progress: progress,
            progressTarget: progressTarget,
            lastQuestKey: lastQuestKey,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FactionQuestsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FactionQuestsTableTable,
    FactionQuestsTableData,
    $$FactionQuestsTableTableFilterComposer,
    $$FactionQuestsTableTableOrderingComposer,
    $$FactionQuestsTableTableAnnotationComposer,
    $$FactionQuestsTableTableCreateCompanionBuilder,
    $$FactionQuestsTableTableUpdateCompanionBuilder,
    (
      FactionQuestsTableData,
      BaseReferences<_$AppDatabase, $FactionQuestsTableTable,
          FactionQuestsTableData>
    ),
    FactionQuestsTableData,
    PrefetchHooks Function()>;
typedef $$GuildAscensionTableTableCreateCompanionBuilder
    = GuildAscensionTableCompanion Function({
  Value<int> id,
  required int playerId,
  required String rankFrom,
  required String rankTo,
  required int step,
  required String questKey,
  required String title,
  required String description,
  required String checkType,
  required String checkParamsJson,
  required int unlockLevel,
  required int xpReward,
  required int goldReward,
  Value<bool> completed,
  Value<int> progress,
  Value<int> progressTarget,
});
typedef $$GuildAscensionTableTableUpdateCompanionBuilder
    = GuildAscensionTableCompanion Function({
  Value<int> id,
  Value<int> playerId,
  Value<String> rankFrom,
  Value<String> rankTo,
  Value<int> step,
  Value<String> questKey,
  Value<String> title,
  Value<String> description,
  Value<String> checkType,
  Value<String> checkParamsJson,
  Value<int> unlockLevel,
  Value<int> xpReward,
  Value<int> goldReward,
  Value<bool> completed,
  Value<int> progress,
  Value<int> progressTarget,
});

class $$GuildAscensionTableTableFilterComposer
    extends Composer<_$AppDatabase, $GuildAscensionTableTable> {
  $$GuildAscensionTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rankFrom => $composableBuilder(
      column: $table.rankFrom, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rankTo => $composableBuilder(
      column: $table.rankTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get step => $composableBuilder(
      column: $table.step, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questKey => $composableBuilder(
      column: $table.questKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkType => $composableBuilder(
      column: $table.checkType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checkParamsJson => $composableBuilder(
      column: $table.checkParamsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unlockLevel => $composableBuilder(
      column: $table.unlockLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progressTarget => $composableBuilder(
      column: $table.progressTarget,
      builder: (column) => ColumnFilters(column));
}

class $$GuildAscensionTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GuildAscensionTableTable> {
  $$GuildAscensionTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rankFrom => $composableBuilder(
      column: $table.rankFrom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rankTo => $composableBuilder(
      column: $table.rankTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get step => $composableBuilder(
      column: $table.step, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questKey => $composableBuilder(
      column: $table.questKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkType => $composableBuilder(
      column: $table.checkType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checkParamsJson => $composableBuilder(
      column: $table.checkParamsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unlockLevel => $composableBuilder(
      column: $table.unlockLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpReward => $composableBuilder(
      column: $table.xpReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completed => $composableBuilder(
      column: $table.completed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progressTarget => $composableBuilder(
      column: $table.progressTarget,
      builder: (column) => ColumnOrderings(column));
}

class $$GuildAscensionTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GuildAscensionTableTable> {
  $$GuildAscensionTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get rankFrom =>
      $composableBuilder(column: $table.rankFrom, builder: (column) => column);

  GeneratedColumn<String> get rankTo =>
      $composableBuilder(column: $table.rankTo, builder: (column) => column);

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<String> get questKey =>
      $composableBuilder(column: $table.questKey, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get checkType =>
      $composableBuilder(column: $table.checkType, builder: (column) => column);

  GeneratedColumn<String> get checkParamsJson => $composableBuilder(
      column: $table.checkParamsJson, builder: (column) => column);

  GeneratedColumn<int> get unlockLevel => $composableBuilder(
      column: $table.unlockLevel, builder: (column) => column);

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);

  GeneratedColumn<int> get goldReward => $composableBuilder(
      column: $table.goldReward, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get progressTarget => $composableBuilder(
      column: $table.progressTarget, builder: (column) => column);
}

class $$GuildAscensionTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GuildAscensionTableTable,
    GuildAscensionTableData,
    $$GuildAscensionTableTableFilterComposer,
    $$GuildAscensionTableTableOrderingComposer,
    $$GuildAscensionTableTableAnnotationComposer,
    $$GuildAscensionTableTableCreateCompanionBuilder,
    $$GuildAscensionTableTableUpdateCompanionBuilder,
    (
      GuildAscensionTableData,
      BaseReferences<_$AppDatabase, $GuildAscensionTableTable,
          GuildAscensionTableData>
    ),
    GuildAscensionTableData,
    PrefetchHooks Function()> {
  $$GuildAscensionTableTableTableManager(
      _$AppDatabase db, $GuildAscensionTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GuildAscensionTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GuildAscensionTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GuildAscensionTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> rankFrom = const Value.absent(),
            Value<String> rankTo = const Value.absent(),
            Value<int> step = const Value.absent(),
            Value<String> questKey = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> checkType = const Value.absent(),
            Value<String> checkParamsJson = const Value.absent(),
            Value<int> unlockLevel = const Value.absent(),
            Value<int> xpReward = const Value.absent(),
            Value<int> goldReward = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<int> progressTarget = const Value.absent(),
          }) =>
              GuildAscensionTableCompanion(
            id: id,
            playerId: playerId,
            rankFrom: rankFrom,
            rankTo: rankTo,
            step: step,
            questKey: questKey,
            title: title,
            description: description,
            checkType: checkType,
            checkParamsJson: checkParamsJson,
            unlockLevel: unlockLevel,
            xpReward: xpReward,
            goldReward: goldReward,
            completed: completed,
            progress: progress,
            progressTarget: progressTarget,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            required String rankFrom,
            required String rankTo,
            required int step,
            required String questKey,
            required String title,
            required String description,
            required String checkType,
            required String checkParamsJson,
            required int unlockLevel,
            required int xpReward,
            required int goldReward,
            Value<bool> completed = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<int> progressTarget = const Value.absent(),
          }) =>
              GuildAscensionTableCompanion.insert(
            id: id,
            playerId: playerId,
            rankFrom: rankFrom,
            rankTo: rankTo,
            step: step,
            questKey: questKey,
            title: title,
            description: description,
            checkType: checkType,
            checkParamsJson: checkParamsJson,
            unlockLevel: unlockLevel,
            xpReward: xpReward,
            goldReward: goldReward,
            completed: completed,
            progress: progress,
            progressTarget: progressTarget,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GuildAscensionTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GuildAscensionTableTable,
    GuildAscensionTableData,
    $$GuildAscensionTableTableFilterComposer,
    $$GuildAscensionTableTableOrderingComposer,
    $$GuildAscensionTableTableAnnotationComposer,
    $$GuildAscensionTableTableCreateCompanionBuilder,
    $$GuildAscensionTableTableUpdateCompanionBuilder,
    (
      GuildAscensionTableData,
      BaseReferences<_$AppDatabase, $GuildAscensionTableTable,
          GuildAscensionTableData>
    ),
    GuildAscensionTableData,
    PrefetchHooks Function()>;
typedef $$VitalismUniqueCatalogTableTableCreateCompanionBuilder
    = VitalismUniqueCatalogTableCompanion Function({
  required String id,
  required String name,
  required String carrierName,
  required String tier,
  required String themeDescription,
  Value<int> rowid,
});
typedef $$VitalismUniqueCatalogTableTableUpdateCompanionBuilder
    = VitalismUniqueCatalogTableCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> carrierName,
  Value<String> tier,
  Value<String> themeDescription,
  Value<int> rowid,
});

class $$VitalismUniqueCatalogTableTableFilterComposer
    extends Composer<_$AppDatabase, $VitalismUniqueCatalogTableTable> {
  $$VitalismUniqueCatalogTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get carrierName => $composableBuilder(
      column: $table.carrierName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tier => $composableBuilder(
      column: $table.tier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeDescription => $composableBuilder(
      column: $table.themeDescription,
      builder: (column) => ColumnFilters(column));
}

class $$VitalismUniqueCatalogTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VitalismUniqueCatalogTableTable> {
  $$VitalismUniqueCatalogTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get carrierName => $composableBuilder(
      column: $table.carrierName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tier => $composableBuilder(
      column: $table.tier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeDescription => $composableBuilder(
      column: $table.themeDescription,
      builder: (column) => ColumnOrderings(column));
}

class $$VitalismUniqueCatalogTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VitalismUniqueCatalogTableTable> {
  $$VitalismUniqueCatalogTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get carrierName => $composableBuilder(
      column: $table.carrierName, builder: (column) => column);

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<String> get themeDescription => $composableBuilder(
      column: $table.themeDescription, builder: (column) => column);
}

class $$VitalismUniqueCatalogTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VitalismUniqueCatalogTableTable,
    VitalismUniqueCatalogTableData,
    $$VitalismUniqueCatalogTableTableFilterComposer,
    $$VitalismUniqueCatalogTableTableOrderingComposer,
    $$VitalismUniqueCatalogTableTableAnnotationComposer,
    $$VitalismUniqueCatalogTableTableCreateCompanionBuilder,
    $$VitalismUniqueCatalogTableTableUpdateCompanionBuilder,
    (
      VitalismUniqueCatalogTableData,
      BaseReferences<_$AppDatabase, $VitalismUniqueCatalogTableTable,
          VitalismUniqueCatalogTableData>
    ),
    VitalismUniqueCatalogTableData,
    PrefetchHooks Function()> {
  $$VitalismUniqueCatalogTableTableTableManager(
      _$AppDatabase db, $VitalismUniqueCatalogTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VitalismUniqueCatalogTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$VitalismUniqueCatalogTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VitalismUniqueCatalogTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> carrierName = const Value.absent(),
            Value<String> tier = const Value.absent(),
            Value<String> themeDescription = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VitalismUniqueCatalogTableCompanion(
            id: id,
            name: name,
            carrierName: carrierName,
            tier: tier,
            themeDescription: themeDescription,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String carrierName,
            required String tier,
            required String themeDescription,
            Value<int> rowid = const Value.absent(),
          }) =>
              VitalismUniqueCatalogTableCompanion.insert(
            id: id,
            name: name,
            carrierName: carrierName,
            tier: tier,
            themeDescription: themeDescription,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VitalismUniqueCatalogTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $VitalismUniqueCatalogTableTable,
        VitalismUniqueCatalogTableData,
        $$VitalismUniqueCatalogTableTableFilterComposer,
        $$VitalismUniqueCatalogTableTableOrderingComposer,
        $$VitalismUniqueCatalogTableTableAnnotationComposer,
        $$VitalismUniqueCatalogTableTableCreateCompanionBuilder,
        $$VitalismUniqueCatalogTableTableUpdateCompanionBuilder,
        (
          VitalismUniqueCatalogTableData,
          BaseReferences<_$AppDatabase, $VitalismUniqueCatalogTableTable,
              VitalismUniqueCatalogTableData>
        ),
        VitalismUniqueCatalogTableData,
        PrefetchHooks Function()>;
typedef $$PlayerVitalismAffinitiesTableTableCreateCompanionBuilder
    = PlayerVitalismAffinitiesTableCompanion Function({
  required int playerId,
  required String vitalismId,
  required int acquiredAt,
  required String acquiredVia,
  Value<int> rowid,
});
typedef $$PlayerVitalismAffinitiesTableTableUpdateCompanionBuilder
    = PlayerVitalismAffinitiesTableCompanion Function({
  Value<int> playerId,
  Value<String> vitalismId,
  Value<int> acquiredAt,
  Value<String> acquiredVia,
  Value<int> rowid,
});

class $$PlayerVitalismAffinitiesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerVitalismAffinitiesTableTable> {
  $$PlayerVitalismAffinitiesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vitalismId => $composableBuilder(
      column: $table.vitalismId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acquiredAt => $composableBuilder(
      column: $table.acquiredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acquiredVia => $composableBuilder(
      column: $table.acquiredVia, builder: (column) => ColumnFilters(column));
}

class $$PlayerVitalismAffinitiesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerVitalismAffinitiesTableTable> {
  $$PlayerVitalismAffinitiesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vitalismId => $composableBuilder(
      column: $table.vitalismId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acquiredAt => $composableBuilder(
      column: $table.acquiredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acquiredVia => $composableBuilder(
      column: $table.acquiredVia, builder: (column) => ColumnOrderings(column));
}

class $$PlayerVitalismAffinitiesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerVitalismAffinitiesTableTable> {
  $$PlayerVitalismAffinitiesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get vitalismId => $composableBuilder(
      column: $table.vitalismId, builder: (column) => column);

  GeneratedColumn<int> get acquiredAt => $composableBuilder(
      column: $table.acquiredAt, builder: (column) => column);

  GeneratedColumn<String> get acquiredVia => $composableBuilder(
      column: $table.acquiredVia, builder: (column) => column);
}

class $$PlayerVitalismAffinitiesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayerVitalismAffinitiesTableTable,
    PlayerVitalismAffinitiesTableData,
    $$PlayerVitalismAffinitiesTableTableFilterComposer,
    $$PlayerVitalismAffinitiesTableTableOrderingComposer,
    $$PlayerVitalismAffinitiesTableTableAnnotationComposer,
    $$PlayerVitalismAffinitiesTableTableCreateCompanionBuilder,
    $$PlayerVitalismAffinitiesTableTableUpdateCompanionBuilder,
    (
      PlayerVitalismAffinitiesTableData,
      BaseReferences<_$AppDatabase, $PlayerVitalismAffinitiesTableTable,
          PlayerVitalismAffinitiesTableData>
    ),
    PlayerVitalismAffinitiesTableData,
    PrefetchHooks Function()> {
  $$PlayerVitalismAffinitiesTableTableTableManager(
      _$AppDatabase db, $PlayerVitalismAffinitiesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerVitalismAffinitiesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerVitalismAffinitiesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerVitalismAffinitiesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> playerId = const Value.absent(),
            Value<String> vitalismId = const Value.absent(),
            Value<int> acquiredAt = const Value.absent(),
            Value<String> acquiredVia = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerVitalismAffinitiesTableCompanion(
            playerId: playerId,
            vitalismId: vitalismId,
            acquiredAt: acquiredAt,
            acquiredVia: acquiredVia,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int playerId,
            required String vitalismId,
            required int acquiredAt,
            required String acquiredVia,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerVitalismAffinitiesTableCompanion.insert(
            playerId: playerId,
            vitalismId: vitalismId,
            acquiredAt: acquiredAt,
            acquiredVia: acquiredVia,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayerVitalismAffinitiesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PlayerVitalismAffinitiesTableTable,
        PlayerVitalismAffinitiesTableData,
        $$PlayerVitalismAffinitiesTableTableFilterComposer,
        $$PlayerVitalismAffinitiesTableTableOrderingComposer,
        $$PlayerVitalismAffinitiesTableTableAnnotationComposer,
        $$PlayerVitalismAffinitiesTableTableCreateCompanionBuilder,
        $$PlayerVitalismAffinitiesTableTableUpdateCompanionBuilder,
        (
          PlayerVitalismAffinitiesTableData,
          BaseReferences<_$AppDatabase, $PlayerVitalismAffinitiesTableTable,
              PlayerVitalismAffinitiesTableData>
        ),
        PlayerVitalismAffinitiesTableData,
        PrefetchHooks Function()>;
typedef $$PlayerVitalismTreesTableTableCreateCompanionBuilder
    = PlayerVitalismTreesTableCompanion Function({
  required int playerId,
  required String vitalismId,
  required String nodeId,
  Value<bool> unlocked,
  Value<int?> unlockedAt,
  Value<int> rowid,
});
typedef $$PlayerVitalismTreesTableTableUpdateCompanionBuilder
    = PlayerVitalismTreesTableCompanion Function({
  Value<int> playerId,
  Value<String> vitalismId,
  Value<String> nodeId,
  Value<bool> unlocked,
  Value<int?> unlockedAt,
  Value<int> rowid,
});

class $$PlayerVitalismTreesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerVitalismTreesTableTable> {
  $$PlayerVitalismTreesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vitalismId => $composableBuilder(
      column: $table.vitalismId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nodeId => $composableBuilder(
      column: $table.nodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get unlocked => $composableBuilder(
      column: $table.unlocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnFilters(column));
}

class $$PlayerVitalismTreesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerVitalismTreesTableTable> {
  $$PlayerVitalismTreesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vitalismId => $composableBuilder(
      column: $table.vitalismId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nodeId => $composableBuilder(
      column: $table.nodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get unlocked => $composableBuilder(
      column: $table.unlocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnOrderings(column));
}

class $$PlayerVitalismTreesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerVitalismTreesTableTable> {
  $$PlayerVitalismTreesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get vitalismId => $composableBuilder(
      column: $table.vitalismId, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<bool> get unlocked =>
      $composableBuilder(column: $table.unlocked, builder: (column) => column);

  GeneratedColumn<int> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => column);
}

class $$PlayerVitalismTreesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayerVitalismTreesTableTable,
    PlayerVitalismTreesTableData,
    $$PlayerVitalismTreesTableTableFilterComposer,
    $$PlayerVitalismTreesTableTableOrderingComposer,
    $$PlayerVitalismTreesTableTableAnnotationComposer,
    $$PlayerVitalismTreesTableTableCreateCompanionBuilder,
    $$PlayerVitalismTreesTableTableUpdateCompanionBuilder,
    (
      PlayerVitalismTreesTableData,
      BaseReferences<_$AppDatabase, $PlayerVitalismTreesTableTable,
          PlayerVitalismTreesTableData>
    ),
    PlayerVitalismTreesTableData,
    PrefetchHooks Function()> {
  $$PlayerVitalismTreesTableTableTableManager(
      _$AppDatabase db, $PlayerVitalismTreesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerVitalismTreesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerVitalismTreesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerVitalismTreesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> playerId = const Value.absent(),
            Value<String> vitalismId = const Value.absent(),
            Value<String> nodeId = const Value.absent(),
            Value<bool> unlocked = const Value.absent(),
            Value<int?> unlockedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerVitalismTreesTableCompanion(
            playerId: playerId,
            vitalismId: vitalismId,
            nodeId: nodeId,
            unlocked: unlocked,
            unlockedAt: unlockedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int playerId,
            required String vitalismId,
            required String nodeId,
            Value<bool> unlocked = const Value.absent(),
            Value<int?> unlockedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerVitalismTreesTableCompanion.insert(
            playerId: playerId,
            vitalismId: vitalismId,
            nodeId: nodeId,
            unlocked: unlocked,
            unlockedAt: unlockedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayerVitalismTreesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PlayerVitalismTreesTableTable,
        PlayerVitalismTreesTableData,
        $$PlayerVitalismTreesTableTableFilterComposer,
        $$PlayerVitalismTreesTableTableOrderingComposer,
        $$PlayerVitalismTreesTableTableAnnotationComposer,
        $$PlayerVitalismTreesTableTableCreateCompanionBuilder,
        $$PlayerVitalismTreesTableTableUpdateCompanionBuilder,
        (
          PlayerVitalismTreesTableData,
          BaseReferences<_$AppDatabase, $PlayerVitalismTreesTableTable,
              PlayerVitalismTreesTableData>
        ),
        PlayerVitalismTreesTableData,
        PrefetchHooks Function()>;
typedef $$LifeVitalismPointsTableTableCreateCompanionBuilder
    = LifeVitalismPointsTableCompanion Function({
  Value<int> playerId,
  Value<int> totalPoints,
  Value<String> sourceLog,
});
typedef $$LifeVitalismPointsTableTableUpdateCompanionBuilder
    = LifeVitalismPointsTableCompanion Function({
  Value<int> playerId,
  Value<int> totalPoints,
  Value<String> sourceLog,
});

class $$LifeVitalismPointsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LifeVitalismPointsTableTable> {
  $$LifeVitalismPointsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalPoints => $composableBuilder(
      column: $table.totalPoints, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceLog => $composableBuilder(
      column: $table.sourceLog, builder: (column) => ColumnFilters(column));
}

class $$LifeVitalismPointsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LifeVitalismPointsTableTable> {
  $$LifeVitalismPointsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalPoints => $composableBuilder(
      column: $table.totalPoints, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceLog => $composableBuilder(
      column: $table.sourceLog, builder: (column) => ColumnOrderings(column));
}

class $$LifeVitalismPointsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LifeVitalismPointsTableTable> {
  $$LifeVitalismPointsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<int> get totalPoints => $composableBuilder(
      column: $table.totalPoints, builder: (column) => column);

  GeneratedColumn<String> get sourceLog =>
      $composableBuilder(column: $table.sourceLog, builder: (column) => column);
}

class $$LifeVitalismPointsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LifeVitalismPointsTableTable,
    LifeVitalismPointsTableData,
    $$LifeVitalismPointsTableTableFilterComposer,
    $$LifeVitalismPointsTableTableOrderingComposer,
    $$LifeVitalismPointsTableTableAnnotationComposer,
    $$LifeVitalismPointsTableTableCreateCompanionBuilder,
    $$LifeVitalismPointsTableTableUpdateCompanionBuilder,
    (
      LifeVitalismPointsTableData,
      BaseReferences<_$AppDatabase, $LifeVitalismPointsTableTable,
          LifeVitalismPointsTableData>
    ),
    LifeVitalismPointsTableData,
    PrefetchHooks Function()> {
  $$LifeVitalismPointsTableTableTableManager(
      _$AppDatabase db, $LifeVitalismPointsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LifeVitalismPointsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LifeVitalismPointsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LifeVitalismPointsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> playerId = const Value.absent(),
            Value<int> totalPoints = const Value.absent(),
            Value<String> sourceLog = const Value.absent(),
          }) =>
              LifeVitalismPointsTableCompanion(
            playerId: playerId,
            totalPoints: totalPoints,
            sourceLog: sourceLog,
          ),
          createCompanionCallback: ({
            Value<int> playerId = const Value.absent(),
            Value<int> totalPoints = const Value.absent(),
            Value<String> sourceLog = const Value.absent(),
          }) =>
              LifeVitalismPointsTableCompanion.insert(
            playerId: playerId,
            totalPoints: totalPoints,
            sourceLog: sourceLog,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LifeVitalismPointsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LifeVitalismPointsTableTable,
        LifeVitalismPointsTableData,
        $$LifeVitalismPointsTableTableFilterComposer,
        $$LifeVitalismPointsTableTableOrderingComposer,
        $$LifeVitalismPointsTableTableAnnotationComposer,
        $$LifeVitalismPointsTableTableCreateCompanionBuilder,
        $$LifeVitalismPointsTableTableUpdateCompanionBuilder,
        (
          LifeVitalismPointsTableData,
          BaseReferences<_$AppDatabase, $LifeVitalismPointsTableTable,
              LifeVitalismPointsTableData>
        ),
        LifeVitalismPointsTableData,
        PrefetchHooks Function()>;
typedef $$ItemsCatalogTableTableCreateCompanionBuilder
    = ItemsCatalogTableCompanion Function({
  required String key,
  required String name,
  Value<String> description,
  required String type,
  Value<String?> subtype,
  Value<String?> slot,
  Value<String?> rank,
  Value<String?> requiredRank,
  Value<String> rarity,
  Value<bool> isSecret,
  Value<bool> isUnique,
  Value<bool> isDarkItem,
  Value<bool> isEvolving,
  Value<int> requiredLevel,
  Value<String> allowedClasses,
  Value<String> allowedFactions,
  Value<String> stats,
  Value<String> effects,
  Value<String> sources,
  Value<int?> shopPriceCoins,
  Value<int?> shopPriceGems,
  Value<int> stackMax,
  Value<int?> durabilityMax,
  Value<String?> durabilityBreaksTo,
  Value<bool> isStackable,
  Value<bool> isConsumable,
  Value<bool> isEquippable,
  Value<bool> isTradable,
  Value<bool> isSellable,
  Value<bool> bindOnPickup,
  Value<String?> craftRecipeId,
  Value<String?> forgeRecipeId,
  Value<bool> enchantAllowed,
  Value<String?> sombrioContentId,
  Value<String?> evolutionStages,
  Value<String> image,
  Value<String?> icon,
  Value<int> rowid,
});
typedef $$ItemsCatalogTableTableUpdateCompanionBuilder
    = ItemsCatalogTableCompanion Function({
  Value<String> key,
  Value<String> name,
  Value<String> description,
  Value<String> type,
  Value<String?> subtype,
  Value<String?> slot,
  Value<String?> rank,
  Value<String?> requiredRank,
  Value<String> rarity,
  Value<bool> isSecret,
  Value<bool> isUnique,
  Value<bool> isDarkItem,
  Value<bool> isEvolving,
  Value<int> requiredLevel,
  Value<String> allowedClasses,
  Value<String> allowedFactions,
  Value<String> stats,
  Value<String> effects,
  Value<String> sources,
  Value<int?> shopPriceCoins,
  Value<int?> shopPriceGems,
  Value<int> stackMax,
  Value<int?> durabilityMax,
  Value<String?> durabilityBreaksTo,
  Value<bool> isStackable,
  Value<bool> isConsumable,
  Value<bool> isEquippable,
  Value<bool> isTradable,
  Value<bool> isSellable,
  Value<bool> bindOnPickup,
  Value<String?> craftRecipeId,
  Value<String?> forgeRecipeId,
  Value<bool> enchantAllowed,
  Value<String?> sombrioContentId,
  Value<String?> evolutionStages,
  Value<String> image,
  Value<String?> icon,
  Value<int> rowid,
});

class $$ItemsCatalogTableTableFilterComposer
    extends Composer<_$AppDatabase, $ItemsCatalogTableTable> {
  $$ItemsCatalogTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subtype => $composableBuilder(
      column: $table.subtype, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rank => $composableBuilder(
      column: $table.rank, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requiredRank => $composableBuilder(
      column: $table.requiredRank, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rarity => $composableBuilder(
      column: $table.rarity, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSecret => $composableBuilder(
      column: $table.isSecret, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUnique => $composableBuilder(
      column: $table.isUnique, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDarkItem => $composableBuilder(
      column: $table.isDarkItem, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEvolving => $composableBuilder(
      column: $table.isEvolving, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requiredLevel => $composableBuilder(
      column: $table.requiredLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get allowedClasses => $composableBuilder(
      column: $table.allowedClasses,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get allowedFactions => $composableBuilder(
      column: $table.allowedFactions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stats => $composableBuilder(
      column: $table.stats, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effects => $composableBuilder(
      column: $table.effects, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sources => $composableBuilder(
      column: $table.sources, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shopPriceCoins => $composableBuilder(
      column: $table.shopPriceCoins,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shopPriceGems => $composableBuilder(
      column: $table.shopPriceGems, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stackMax => $composableBuilder(
      column: $table.stackMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durabilityMax => $composableBuilder(
      column: $table.durabilityMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get durabilityBreaksTo => $composableBuilder(
      column: $table.durabilityBreaksTo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isStackable => $composableBuilder(
      column: $table.isStackable, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isConsumable => $composableBuilder(
      column: $table.isConsumable, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEquippable => $composableBuilder(
      column: $table.isEquippable, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isTradable => $composableBuilder(
      column: $table.isTradable, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSellable => $composableBuilder(
      column: $table.isSellable, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get bindOnPickup => $composableBuilder(
      column: $table.bindOnPickup, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get craftRecipeId => $composableBuilder(
      column: $table.craftRecipeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get forgeRecipeId => $composableBuilder(
      column: $table.forgeRecipeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enchantAllowed => $composableBuilder(
      column: $table.enchantAllowed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sombrioContentId => $composableBuilder(
      column: $table.sombrioContentId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evolutionStages => $composableBuilder(
      column: $table.evolutionStages,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));
}

class $$ItemsCatalogTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsCatalogTableTable> {
  $$ItemsCatalogTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subtype => $composableBuilder(
      column: $table.subtype, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rank => $composableBuilder(
      column: $table.rank, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requiredRank => $composableBuilder(
      column: $table.requiredRank,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rarity => $composableBuilder(
      column: $table.rarity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSecret => $composableBuilder(
      column: $table.isSecret, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUnique => $composableBuilder(
      column: $table.isUnique, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDarkItem => $composableBuilder(
      column: $table.isDarkItem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEvolving => $composableBuilder(
      column: $table.isEvolving, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requiredLevel => $composableBuilder(
      column: $table.requiredLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get allowedClasses => $composableBuilder(
      column: $table.allowedClasses,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get allowedFactions => $composableBuilder(
      column: $table.allowedFactions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stats => $composableBuilder(
      column: $table.stats, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effects => $composableBuilder(
      column: $table.effects, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sources => $composableBuilder(
      column: $table.sources, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shopPriceCoins => $composableBuilder(
      column: $table.shopPriceCoins,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shopPriceGems => $composableBuilder(
      column: $table.shopPriceGems,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stackMax => $composableBuilder(
      column: $table.stackMax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durabilityMax => $composableBuilder(
      column: $table.durabilityMax,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get durabilityBreaksTo => $composableBuilder(
      column: $table.durabilityBreaksTo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isStackable => $composableBuilder(
      column: $table.isStackable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isConsumable => $composableBuilder(
      column: $table.isConsumable,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEquippable => $composableBuilder(
      column: $table.isEquippable,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isTradable => $composableBuilder(
      column: $table.isTradable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSellable => $composableBuilder(
      column: $table.isSellable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get bindOnPickup => $composableBuilder(
      column: $table.bindOnPickup,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get craftRecipeId => $composableBuilder(
      column: $table.craftRecipeId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get forgeRecipeId => $composableBuilder(
      column: $table.forgeRecipeId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enchantAllowed => $composableBuilder(
      column: $table.enchantAllowed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sombrioContentId => $composableBuilder(
      column: $table.sombrioContentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evolutionStages => $composableBuilder(
      column: $table.evolutionStages,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get image => $composableBuilder(
      column: $table.image, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));
}

class $$ItemsCatalogTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsCatalogTableTable> {
  $$ItemsCatalogTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subtype =>
      $composableBuilder(column: $table.subtype, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<String> get requiredRank => $composableBuilder(
      column: $table.requiredRank, builder: (column) => column);

  GeneratedColumn<String> get rarity =>
      $composableBuilder(column: $table.rarity, builder: (column) => column);

  GeneratedColumn<bool> get isSecret =>
      $composableBuilder(column: $table.isSecret, builder: (column) => column);

  GeneratedColumn<bool> get isUnique =>
      $composableBuilder(column: $table.isUnique, builder: (column) => column);

  GeneratedColumn<bool> get isDarkItem => $composableBuilder(
      column: $table.isDarkItem, builder: (column) => column);

  GeneratedColumn<bool> get isEvolving => $composableBuilder(
      column: $table.isEvolving, builder: (column) => column);

  GeneratedColumn<int> get requiredLevel => $composableBuilder(
      column: $table.requiredLevel, builder: (column) => column);

  GeneratedColumn<String> get allowedClasses => $composableBuilder(
      column: $table.allowedClasses, builder: (column) => column);

  GeneratedColumn<String> get allowedFactions => $composableBuilder(
      column: $table.allowedFactions, builder: (column) => column);

  GeneratedColumn<String> get stats =>
      $composableBuilder(column: $table.stats, builder: (column) => column);

  GeneratedColumn<String> get effects =>
      $composableBuilder(column: $table.effects, builder: (column) => column);

  GeneratedColumn<String> get sources =>
      $composableBuilder(column: $table.sources, builder: (column) => column);

  GeneratedColumn<int> get shopPriceCoins => $composableBuilder(
      column: $table.shopPriceCoins, builder: (column) => column);

  GeneratedColumn<int> get shopPriceGems => $composableBuilder(
      column: $table.shopPriceGems, builder: (column) => column);

  GeneratedColumn<int> get stackMax =>
      $composableBuilder(column: $table.stackMax, builder: (column) => column);

  GeneratedColumn<int> get durabilityMax => $composableBuilder(
      column: $table.durabilityMax, builder: (column) => column);

  GeneratedColumn<String> get durabilityBreaksTo => $composableBuilder(
      column: $table.durabilityBreaksTo, builder: (column) => column);

  GeneratedColumn<bool> get isStackable => $composableBuilder(
      column: $table.isStackable, builder: (column) => column);

  GeneratedColumn<bool> get isConsumable => $composableBuilder(
      column: $table.isConsumable, builder: (column) => column);

  GeneratedColumn<bool> get isEquippable => $composableBuilder(
      column: $table.isEquippable, builder: (column) => column);

  GeneratedColumn<bool> get isTradable => $composableBuilder(
      column: $table.isTradable, builder: (column) => column);

  GeneratedColumn<bool> get isSellable => $composableBuilder(
      column: $table.isSellable, builder: (column) => column);

  GeneratedColumn<bool> get bindOnPickup => $composableBuilder(
      column: $table.bindOnPickup, builder: (column) => column);

  GeneratedColumn<String> get craftRecipeId => $composableBuilder(
      column: $table.craftRecipeId, builder: (column) => column);

  GeneratedColumn<String> get forgeRecipeId => $composableBuilder(
      column: $table.forgeRecipeId, builder: (column) => column);

  GeneratedColumn<bool> get enchantAllowed => $composableBuilder(
      column: $table.enchantAllowed, builder: (column) => column);

  GeneratedColumn<String> get sombrioContentId => $composableBuilder(
      column: $table.sombrioContentId, builder: (column) => column);

  GeneratedColumn<String> get evolutionStages => $composableBuilder(
      column: $table.evolutionStages, builder: (column) => column);

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);
}

class $$ItemsCatalogTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemsCatalogTableTable,
    ItemsCatalogTableData,
    $$ItemsCatalogTableTableFilterComposer,
    $$ItemsCatalogTableTableOrderingComposer,
    $$ItemsCatalogTableTableAnnotationComposer,
    $$ItemsCatalogTableTableCreateCompanionBuilder,
    $$ItemsCatalogTableTableUpdateCompanionBuilder,
    (
      ItemsCatalogTableData,
      BaseReferences<_$AppDatabase, $ItemsCatalogTableTable,
          ItemsCatalogTableData>
    ),
    ItemsCatalogTableData,
    PrefetchHooks Function()> {
  $$ItemsCatalogTableTableTableManager(
      _$AppDatabase db, $ItemsCatalogTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsCatalogTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsCatalogTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsCatalogTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> subtype = const Value.absent(),
            Value<String?> slot = const Value.absent(),
            Value<String?> rank = const Value.absent(),
            Value<String?> requiredRank = const Value.absent(),
            Value<String> rarity = const Value.absent(),
            Value<bool> isSecret = const Value.absent(),
            Value<bool> isUnique = const Value.absent(),
            Value<bool> isDarkItem = const Value.absent(),
            Value<bool> isEvolving = const Value.absent(),
            Value<int> requiredLevel = const Value.absent(),
            Value<String> allowedClasses = const Value.absent(),
            Value<String> allowedFactions = const Value.absent(),
            Value<String> stats = const Value.absent(),
            Value<String> effects = const Value.absent(),
            Value<String> sources = const Value.absent(),
            Value<int?> shopPriceCoins = const Value.absent(),
            Value<int?> shopPriceGems = const Value.absent(),
            Value<int> stackMax = const Value.absent(),
            Value<int?> durabilityMax = const Value.absent(),
            Value<String?> durabilityBreaksTo = const Value.absent(),
            Value<bool> isStackable = const Value.absent(),
            Value<bool> isConsumable = const Value.absent(),
            Value<bool> isEquippable = const Value.absent(),
            Value<bool> isTradable = const Value.absent(),
            Value<bool> isSellable = const Value.absent(),
            Value<bool> bindOnPickup = const Value.absent(),
            Value<String?> craftRecipeId = const Value.absent(),
            Value<String?> forgeRecipeId = const Value.absent(),
            Value<bool> enchantAllowed = const Value.absent(),
            Value<String?> sombrioContentId = const Value.absent(),
            Value<String?> evolutionStages = const Value.absent(),
            Value<String> image = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemsCatalogTableCompanion(
            key: key,
            name: name,
            description: description,
            type: type,
            subtype: subtype,
            slot: slot,
            rank: rank,
            requiredRank: requiredRank,
            rarity: rarity,
            isSecret: isSecret,
            isUnique: isUnique,
            isDarkItem: isDarkItem,
            isEvolving: isEvolving,
            requiredLevel: requiredLevel,
            allowedClasses: allowedClasses,
            allowedFactions: allowedFactions,
            stats: stats,
            effects: effects,
            sources: sources,
            shopPriceCoins: shopPriceCoins,
            shopPriceGems: shopPriceGems,
            stackMax: stackMax,
            durabilityMax: durabilityMax,
            durabilityBreaksTo: durabilityBreaksTo,
            isStackable: isStackable,
            isConsumable: isConsumable,
            isEquippable: isEquippable,
            isTradable: isTradable,
            isSellable: isSellable,
            bindOnPickup: bindOnPickup,
            craftRecipeId: craftRecipeId,
            forgeRecipeId: forgeRecipeId,
            enchantAllowed: enchantAllowed,
            sombrioContentId: sombrioContentId,
            evolutionStages: evolutionStages,
            image: image,
            icon: icon,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String name,
            Value<String> description = const Value.absent(),
            required String type,
            Value<String?> subtype = const Value.absent(),
            Value<String?> slot = const Value.absent(),
            Value<String?> rank = const Value.absent(),
            Value<String?> requiredRank = const Value.absent(),
            Value<String> rarity = const Value.absent(),
            Value<bool> isSecret = const Value.absent(),
            Value<bool> isUnique = const Value.absent(),
            Value<bool> isDarkItem = const Value.absent(),
            Value<bool> isEvolving = const Value.absent(),
            Value<int> requiredLevel = const Value.absent(),
            Value<String> allowedClasses = const Value.absent(),
            Value<String> allowedFactions = const Value.absent(),
            Value<String> stats = const Value.absent(),
            Value<String> effects = const Value.absent(),
            Value<String> sources = const Value.absent(),
            Value<int?> shopPriceCoins = const Value.absent(),
            Value<int?> shopPriceGems = const Value.absent(),
            Value<int> stackMax = const Value.absent(),
            Value<int?> durabilityMax = const Value.absent(),
            Value<String?> durabilityBreaksTo = const Value.absent(),
            Value<bool> isStackable = const Value.absent(),
            Value<bool> isConsumable = const Value.absent(),
            Value<bool> isEquippable = const Value.absent(),
            Value<bool> isTradable = const Value.absent(),
            Value<bool> isSellable = const Value.absent(),
            Value<bool> bindOnPickup = const Value.absent(),
            Value<String?> craftRecipeId = const Value.absent(),
            Value<String?> forgeRecipeId = const Value.absent(),
            Value<bool> enchantAllowed = const Value.absent(),
            Value<String?> sombrioContentId = const Value.absent(),
            Value<String?> evolutionStages = const Value.absent(),
            Value<String> image = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemsCatalogTableCompanion.insert(
            key: key,
            name: name,
            description: description,
            type: type,
            subtype: subtype,
            slot: slot,
            rank: rank,
            requiredRank: requiredRank,
            rarity: rarity,
            isSecret: isSecret,
            isUnique: isUnique,
            isDarkItem: isDarkItem,
            isEvolving: isEvolving,
            requiredLevel: requiredLevel,
            allowedClasses: allowedClasses,
            allowedFactions: allowedFactions,
            stats: stats,
            effects: effects,
            sources: sources,
            shopPriceCoins: shopPriceCoins,
            shopPriceGems: shopPriceGems,
            stackMax: stackMax,
            durabilityMax: durabilityMax,
            durabilityBreaksTo: durabilityBreaksTo,
            isStackable: isStackable,
            isConsumable: isConsumable,
            isEquippable: isEquippable,
            isTradable: isTradable,
            isSellable: isSellable,
            bindOnPickup: bindOnPickup,
            craftRecipeId: craftRecipeId,
            forgeRecipeId: forgeRecipeId,
            enchantAllowed: enchantAllowed,
            sombrioContentId: sombrioContentId,
            evolutionStages: evolutionStages,
            image: image,
            icon: icon,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ItemsCatalogTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemsCatalogTableTable,
    ItemsCatalogTableData,
    $$ItemsCatalogTableTableFilterComposer,
    $$ItemsCatalogTableTableOrderingComposer,
    $$ItemsCatalogTableTableAnnotationComposer,
    $$ItemsCatalogTableTableCreateCompanionBuilder,
    $$ItemsCatalogTableTableUpdateCompanionBuilder,
    (
      ItemsCatalogTableData,
      BaseReferences<_$AppDatabase, $ItemsCatalogTableTable,
          ItemsCatalogTableData>
    ),
    ItemsCatalogTableData,
    PrefetchHooks Function()>;
typedef $$PlayerInventoryTableTableCreateCompanionBuilder
    = PlayerInventoryTableCompanion Function({
  Value<int> id,
  required int playerId,
  required String itemKey,
  Value<int> quantity,
  Value<int?> durabilityCurrent,
  required int acquiredAt,
  required String acquiredVia,
  Value<String?> evolutionStage,
  Value<bool> isEquipped,
  Value<String?> appliedRuneKey,
  Value<String?> appliedSapKey,
  Value<int?> sapChargesRemaining,
});
typedef $$PlayerInventoryTableTableUpdateCompanionBuilder
    = PlayerInventoryTableCompanion Function({
  Value<int> id,
  Value<int> playerId,
  Value<String> itemKey,
  Value<int> quantity,
  Value<int?> durabilityCurrent,
  Value<int> acquiredAt,
  Value<String> acquiredVia,
  Value<String?> evolutionStage,
  Value<bool> isEquipped,
  Value<String?> appliedRuneKey,
  Value<String?> appliedSapKey,
  Value<int?> sapChargesRemaining,
});

class $$PlayerInventoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerInventoryTableTable> {
  $$PlayerInventoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemKey => $composableBuilder(
      column: $table.itemKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durabilityCurrent => $composableBuilder(
      column: $table.durabilityCurrent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get acquiredAt => $composableBuilder(
      column: $table.acquiredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acquiredVia => $composableBuilder(
      column: $table.acquiredVia, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evolutionStage => $composableBuilder(
      column: $table.evolutionStage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEquipped => $composableBuilder(
      column: $table.isEquipped, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appliedRuneKey => $composableBuilder(
      column: $table.appliedRuneKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appliedSapKey => $composableBuilder(
      column: $table.appliedSapKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sapChargesRemaining => $composableBuilder(
      column: $table.sapChargesRemaining,
      builder: (column) => ColumnFilters(column));
}

class $$PlayerInventoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerInventoryTableTable> {
  $$PlayerInventoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemKey => $composableBuilder(
      column: $table.itemKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durabilityCurrent => $composableBuilder(
      column: $table.durabilityCurrent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get acquiredAt => $composableBuilder(
      column: $table.acquiredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acquiredVia => $composableBuilder(
      column: $table.acquiredVia, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evolutionStage => $composableBuilder(
      column: $table.evolutionStage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEquipped => $composableBuilder(
      column: $table.isEquipped, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appliedRuneKey => $composableBuilder(
      column: $table.appliedRuneKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appliedSapKey => $composableBuilder(
      column: $table.appliedSapKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sapChargesRemaining => $composableBuilder(
      column: $table.sapChargesRemaining,
      builder: (column) => ColumnOrderings(column));
}

class $$PlayerInventoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerInventoryTableTable> {
  $$PlayerInventoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get durabilityCurrent => $composableBuilder(
      column: $table.durabilityCurrent, builder: (column) => column);

  GeneratedColumn<int> get acquiredAt => $composableBuilder(
      column: $table.acquiredAt, builder: (column) => column);

  GeneratedColumn<String> get acquiredVia => $composableBuilder(
      column: $table.acquiredVia, builder: (column) => column);

  GeneratedColumn<String> get evolutionStage => $composableBuilder(
      column: $table.evolutionStage, builder: (column) => column);

  GeneratedColumn<bool> get isEquipped => $composableBuilder(
      column: $table.isEquipped, builder: (column) => column);

  GeneratedColumn<String> get appliedRuneKey => $composableBuilder(
      column: $table.appliedRuneKey, builder: (column) => column);

  GeneratedColumn<String> get appliedSapKey => $composableBuilder(
      column: $table.appliedSapKey, builder: (column) => column);

  GeneratedColumn<int> get sapChargesRemaining => $composableBuilder(
      column: $table.sapChargesRemaining, builder: (column) => column);
}

class $$PlayerInventoryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayerInventoryTableTable,
    PlayerInventoryTableData,
    $$PlayerInventoryTableTableFilterComposer,
    $$PlayerInventoryTableTableOrderingComposer,
    $$PlayerInventoryTableTableAnnotationComposer,
    $$PlayerInventoryTableTableCreateCompanionBuilder,
    $$PlayerInventoryTableTableUpdateCompanionBuilder,
    (
      PlayerInventoryTableData,
      BaseReferences<_$AppDatabase, $PlayerInventoryTableTable,
          PlayerInventoryTableData>
    ),
    PlayerInventoryTableData,
    PrefetchHooks Function()> {
  $$PlayerInventoryTableTableTableManager(
      _$AppDatabase db, $PlayerInventoryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerInventoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerInventoryTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerInventoryTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> playerId = const Value.absent(),
            Value<String> itemKey = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<int?> durabilityCurrent = const Value.absent(),
            Value<int> acquiredAt = const Value.absent(),
            Value<String> acquiredVia = const Value.absent(),
            Value<String?> evolutionStage = const Value.absent(),
            Value<bool> isEquipped = const Value.absent(),
            Value<String?> appliedRuneKey = const Value.absent(),
            Value<String?> appliedSapKey = const Value.absent(),
            Value<int?> sapChargesRemaining = const Value.absent(),
          }) =>
              PlayerInventoryTableCompanion(
            id: id,
            playerId: playerId,
            itemKey: itemKey,
            quantity: quantity,
            durabilityCurrent: durabilityCurrent,
            acquiredAt: acquiredAt,
            acquiredVia: acquiredVia,
            evolutionStage: evolutionStage,
            isEquipped: isEquipped,
            appliedRuneKey: appliedRuneKey,
            appliedSapKey: appliedSapKey,
            sapChargesRemaining: sapChargesRemaining,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int playerId,
            required String itemKey,
            Value<int> quantity = const Value.absent(),
            Value<int?> durabilityCurrent = const Value.absent(),
            required int acquiredAt,
            required String acquiredVia,
            Value<String?> evolutionStage = const Value.absent(),
            Value<bool> isEquipped = const Value.absent(),
            Value<String?> appliedRuneKey = const Value.absent(),
            Value<String?> appliedSapKey = const Value.absent(),
            Value<int?> sapChargesRemaining = const Value.absent(),
          }) =>
              PlayerInventoryTableCompanion.insert(
            id: id,
            playerId: playerId,
            itemKey: itemKey,
            quantity: quantity,
            durabilityCurrent: durabilityCurrent,
            acquiredAt: acquiredAt,
            acquiredVia: acquiredVia,
            evolutionStage: evolutionStage,
            isEquipped: isEquipped,
            appliedRuneKey: appliedRuneKey,
            appliedSapKey: appliedSapKey,
            sapChargesRemaining: sapChargesRemaining,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayerInventoryTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PlayerInventoryTableTable,
        PlayerInventoryTableData,
        $$PlayerInventoryTableTableFilterComposer,
        $$PlayerInventoryTableTableOrderingComposer,
        $$PlayerInventoryTableTableAnnotationComposer,
        $$PlayerInventoryTableTableCreateCompanionBuilder,
        $$PlayerInventoryTableTableUpdateCompanionBuilder,
        (
          PlayerInventoryTableData,
          BaseReferences<_$AppDatabase, $PlayerInventoryTableTable,
              PlayerInventoryTableData>
        ),
        PlayerInventoryTableData,
        PrefetchHooks Function()>;
typedef $$PlayerEquipmentTableTableCreateCompanionBuilder
    = PlayerEquipmentTableCompanion Function({
  required int playerId,
  required String slot,
  required int inventoryId,
  Value<int> rowid,
});
typedef $$PlayerEquipmentTableTableUpdateCompanionBuilder
    = PlayerEquipmentTableCompanion Function({
  Value<int> playerId,
  Value<String> slot,
  Value<int> inventoryId,
  Value<int> rowid,
});

class $$PlayerEquipmentTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerEquipmentTableTable> {
  $$PlayerEquipmentTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get inventoryId => $composableBuilder(
      column: $table.inventoryId, builder: (column) => ColumnFilters(column));
}

class $$PlayerEquipmentTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerEquipmentTableTable> {
  $$PlayerEquipmentTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get inventoryId => $composableBuilder(
      column: $table.inventoryId, builder: (column) => ColumnOrderings(column));
}

class $$PlayerEquipmentTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerEquipmentTableTable> {
  $$PlayerEquipmentTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get inventoryId => $composableBuilder(
      column: $table.inventoryId, builder: (column) => column);
}

class $$PlayerEquipmentTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayerEquipmentTableTable,
    PlayerEquipmentTableData,
    $$PlayerEquipmentTableTableFilterComposer,
    $$PlayerEquipmentTableTableOrderingComposer,
    $$PlayerEquipmentTableTableAnnotationComposer,
    $$PlayerEquipmentTableTableCreateCompanionBuilder,
    $$PlayerEquipmentTableTableUpdateCompanionBuilder,
    (
      PlayerEquipmentTableData,
      BaseReferences<_$AppDatabase, $PlayerEquipmentTableTable,
          PlayerEquipmentTableData>
    ),
    PlayerEquipmentTableData,
    PrefetchHooks Function()> {
  $$PlayerEquipmentTableTableTableManager(
      _$AppDatabase db, $PlayerEquipmentTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerEquipmentTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerEquipmentTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerEquipmentTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> playerId = const Value.absent(),
            Value<String> slot = const Value.absent(),
            Value<int> inventoryId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerEquipmentTableCompanion(
            playerId: playerId,
            slot: slot,
            inventoryId: inventoryId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int playerId,
            required String slot,
            required int inventoryId,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerEquipmentTableCompanion.insert(
            playerId: playerId,
            slot: slot,
            inventoryId: inventoryId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayerEquipmentTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PlayerEquipmentTableTable,
        PlayerEquipmentTableData,
        $$PlayerEquipmentTableTableFilterComposer,
        $$PlayerEquipmentTableTableOrderingComposer,
        $$PlayerEquipmentTableTableAnnotationComposer,
        $$PlayerEquipmentTableTableCreateCompanionBuilder,
        $$PlayerEquipmentTableTableUpdateCompanionBuilder,
        (
          PlayerEquipmentTableData,
          BaseReferences<_$AppDatabase, $PlayerEquipmentTableTable,
              PlayerEquipmentTableData>
        ),
        PlayerEquipmentTableData,
        PrefetchHooks Function()>;
typedef $$RecipesCatalogTableTableCreateCompanionBuilder
    = RecipesCatalogTableCompanion Function({
  required String key,
  required String name,
  Value<String> description,
  required String type,
  Value<String?> requiredRank,
  Value<int> requiredLevel,
  Value<String> requiredStation,
  required String resultItemKey,
  Value<int> resultQuantity,
  required String materials,
  Value<int> costCoins,
  Value<int> durationSec,
  required String unlockSources,
  Value<String?> icon,
  Value<int> rowid,
});
typedef $$RecipesCatalogTableTableUpdateCompanionBuilder
    = RecipesCatalogTableCompanion Function({
  Value<String> key,
  Value<String> name,
  Value<String> description,
  Value<String> type,
  Value<String?> requiredRank,
  Value<int> requiredLevel,
  Value<String> requiredStation,
  Value<String> resultItemKey,
  Value<int> resultQuantity,
  Value<String> materials,
  Value<int> costCoins,
  Value<int> durationSec,
  Value<String> unlockSources,
  Value<String?> icon,
  Value<int> rowid,
});

class $$RecipesCatalogTableTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesCatalogTableTable> {
  $$RecipesCatalogTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requiredRank => $composableBuilder(
      column: $table.requiredRank, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get requiredLevel => $composableBuilder(
      column: $table.requiredLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requiredStation => $composableBuilder(
      column: $table.requiredStation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resultItemKey => $composableBuilder(
      column: $table.resultItemKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get resultQuantity => $composableBuilder(
      column: $table.resultQuantity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get materials => $composableBuilder(
      column: $table.materials, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get costCoins => $composableBuilder(
      column: $table.costCoins, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSec => $composableBuilder(
      column: $table.durationSec, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unlockSources => $composableBuilder(
      column: $table.unlockSources, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));
}

class $$RecipesCatalogTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesCatalogTableTable> {
  $$RecipesCatalogTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requiredRank => $composableBuilder(
      column: $table.requiredRank,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get requiredLevel => $composableBuilder(
      column: $table.requiredLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requiredStation => $composableBuilder(
      column: $table.requiredStation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resultItemKey => $composableBuilder(
      column: $table.resultItemKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get resultQuantity => $composableBuilder(
      column: $table.resultQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get materials => $composableBuilder(
      column: $table.materials, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get costCoins => $composableBuilder(
      column: $table.costCoins, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSec => $composableBuilder(
      column: $table.durationSec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unlockSources => $composableBuilder(
      column: $table.unlockSources,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));
}

class $$RecipesCatalogTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesCatalogTableTable> {
  $$RecipesCatalogTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get requiredRank => $composableBuilder(
      column: $table.requiredRank, builder: (column) => column);

  GeneratedColumn<int> get requiredLevel => $composableBuilder(
      column: $table.requiredLevel, builder: (column) => column);

  GeneratedColumn<String> get requiredStation => $composableBuilder(
      column: $table.requiredStation, builder: (column) => column);

  GeneratedColumn<String> get resultItemKey => $composableBuilder(
      column: $table.resultItemKey, builder: (column) => column);

  GeneratedColumn<int> get resultQuantity => $composableBuilder(
      column: $table.resultQuantity, builder: (column) => column);

  GeneratedColumn<String> get materials =>
      $composableBuilder(column: $table.materials, builder: (column) => column);

  GeneratedColumn<int> get costCoins =>
      $composableBuilder(column: $table.costCoins, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
      column: $table.durationSec, builder: (column) => column);

  GeneratedColumn<String> get unlockSources => $composableBuilder(
      column: $table.unlockSources, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);
}

class $$RecipesCatalogTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecipesCatalogTableTable,
    RecipesCatalogTableData,
    $$RecipesCatalogTableTableFilterComposer,
    $$RecipesCatalogTableTableOrderingComposer,
    $$RecipesCatalogTableTableAnnotationComposer,
    $$RecipesCatalogTableTableCreateCompanionBuilder,
    $$RecipesCatalogTableTableUpdateCompanionBuilder,
    (
      RecipesCatalogTableData,
      BaseReferences<_$AppDatabase, $RecipesCatalogTableTable,
          RecipesCatalogTableData>
    ),
    RecipesCatalogTableData,
    PrefetchHooks Function()> {
  $$RecipesCatalogTableTableTableManager(
      _$AppDatabase db, $RecipesCatalogTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesCatalogTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesCatalogTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesCatalogTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> requiredRank = const Value.absent(),
            Value<int> requiredLevel = const Value.absent(),
            Value<String> requiredStation = const Value.absent(),
            Value<String> resultItemKey = const Value.absent(),
            Value<int> resultQuantity = const Value.absent(),
            Value<String> materials = const Value.absent(),
            Value<int> costCoins = const Value.absent(),
            Value<int> durationSec = const Value.absent(),
            Value<String> unlockSources = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCatalogTableCompanion(
            key: key,
            name: name,
            description: description,
            type: type,
            requiredRank: requiredRank,
            requiredLevel: requiredLevel,
            requiredStation: requiredStation,
            resultItemKey: resultItemKey,
            resultQuantity: resultQuantity,
            materials: materials,
            costCoins: costCoins,
            durationSec: durationSec,
            unlockSources: unlockSources,
            icon: icon,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String name,
            Value<String> description = const Value.absent(),
            required String type,
            Value<String?> requiredRank = const Value.absent(),
            Value<int> requiredLevel = const Value.absent(),
            Value<String> requiredStation = const Value.absent(),
            required String resultItemKey,
            Value<int> resultQuantity = const Value.absent(),
            required String materials,
            Value<int> costCoins = const Value.absent(),
            Value<int> durationSec = const Value.absent(),
            required String unlockSources,
            Value<String?> icon = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecipesCatalogTableCompanion.insert(
            key: key,
            name: name,
            description: description,
            type: type,
            requiredRank: requiredRank,
            requiredLevel: requiredLevel,
            requiredStation: requiredStation,
            resultItemKey: resultItemKey,
            resultQuantity: resultQuantity,
            materials: materials,
            costCoins: costCoins,
            durationSec: durationSec,
            unlockSources: unlockSources,
            icon: icon,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecipesCatalogTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecipesCatalogTableTable,
    RecipesCatalogTableData,
    $$RecipesCatalogTableTableFilterComposer,
    $$RecipesCatalogTableTableOrderingComposer,
    $$RecipesCatalogTableTableAnnotationComposer,
    $$RecipesCatalogTableTableCreateCompanionBuilder,
    $$RecipesCatalogTableTableUpdateCompanionBuilder,
    (
      RecipesCatalogTableData,
      BaseReferences<_$AppDatabase, $RecipesCatalogTableTable,
          RecipesCatalogTableData>
    ),
    RecipesCatalogTableData,
    PrefetchHooks Function()>;
typedef $$PlayerRecipesUnlockedTableTableCreateCompanionBuilder
    = PlayerRecipesUnlockedTableCompanion Function({
  required int playerId,
  required String recipeKey,
  required int unlockedAt,
  required String unlockedVia,
  Value<int> rowid,
});
typedef $$PlayerRecipesUnlockedTableTableUpdateCompanionBuilder
    = PlayerRecipesUnlockedTableCompanion Function({
  Value<int> playerId,
  Value<String> recipeKey,
  Value<int> unlockedAt,
  Value<String> unlockedVia,
  Value<int> rowid,
});

class $$PlayerRecipesUnlockedTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerRecipesUnlockedTableTable> {
  $$PlayerRecipesUnlockedTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recipeKey => $composableBuilder(
      column: $table.recipeKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unlockedVia => $composableBuilder(
      column: $table.unlockedVia, builder: (column) => ColumnFilters(column));
}

class $$PlayerRecipesUnlockedTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerRecipesUnlockedTableTable> {
  $$PlayerRecipesUnlockedTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get playerId => $composableBuilder(
      column: $table.playerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recipeKey => $composableBuilder(
      column: $table.recipeKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unlockedVia => $composableBuilder(
      column: $table.unlockedVia, builder: (column) => ColumnOrderings(column));
}

class $$PlayerRecipesUnlockedTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerRecipesUnlockedTableTable> {
  $$PlayerRecipesUnlockedTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get recipeKey =>
      $composableBuilder(column: $table.recipeKey, builder: (column) => column);

  GeneratedColumn<int> get unlockedAt => $composableBuilder(
      column: $table.unlockedAt, builder: (column) => column);

  GeneratedColumn<String> get unlockedVia => $composableBuilder(
      column: $table.unlockedVia, builder: (column) => column);
}

class $$PlayerRecipesUnlockedTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayerRecipesUnlockedTableTable,
    PlayerRecipesUnlockedTableData,
    $$PlayerRecipesUnlockedTableTableFilterComposer,
    $$PlayerRecipesUnlockedTableTableOrderingComposer,
    $$PlayerRecipesUnlockedTableTableAnnotationComposer,
    $$PlayerRecipesUnlockedTableTableCreateCompanionBuilder,
    $$PlayerRecipesUnlockedTableTableUpdateCompanionBuilder,
    (
      PlayerRecipesUnlockedTableData,
      BaseReferences<_$AppDatabase, $PlayerRecipesUnlockedTableTable,
          PlayerRecipesUnlockedTableData>
    ),
    PlayerRecipesUnlockedTableData,
    PrefetchHooks Function()> {
  $$PlayerRecipesUnlockedTableTableTableManager(
      _$AppDatabase db, $PlayerRecipesUnlockedTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerRecipesUnlockedTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerRecipesUnlockedTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerRecipesUnlockedTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> playerId = const Value.absent(),
            Value<String> recipeKey = const Value.absent(),
            Value<int> unlockedAt = const Value.absent(),
            Value<String> unlockedVia = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerRecipesUnlockedTableCompanion(
            playerId: playerId,
            recipeKey: recipeKey,
            unlockedAt: unlockedAt,
            unlockedVia: unlockedVia,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int playerId,
            required String recipeKey,
            required int unlockedAt,
            required String unlockedVia,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerRecipesUnlockedTableCompanion.insert(
            playerId: playerId,
            recipeKey: recipeKey,
            unlockedAt: unlockedAt,
            unlockedVia: unlockedVia,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayerRecipesUnlockedTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PlayerRecipesUnlockedTableTable,
        PlayerRecipesUnlockedTableData,
        $$PlayerRecipesUnlockedTableTableFilterComposer,
        $$PlayerRecipesUnlockedTableTableOrderingComposer,
        $$PlayerRecipesUnlockedTableTableAnnotationComposer,
        $$PlayerRecipesUnlockedTableTableCreateCompanionBuilder,
        $$PlayerRecipesUnlockedTableTableUpdateCompanionBuilder,
        (
          PlayerRecipesUnlockedTableData,
          BaseReferences<_$AppDatabase, $PlayerRecipesUnlockedTableTable,
              PlayerRecipesUnlockedTableData>
        ),
        PlayerRecipesUnlockedTableData,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayersTableTableTableManager get playersTable =>
      $$PlayersTableTableTableManager(_db, _db.playersTable);
  $$HabitsTableTableTableManager get habitsTable =>
      $$HabitsTableTableTableManager(_db, _db.habitsTable);
  $$HabitLogsTableTableTableManager get habitLogsTable =>
      $$HabitLogsTableTableTableManager(_db, _db.habitLogsTable);
  $$ItemsTableTableTableManager get itemsTable =>
      $$ItemsTableTableTableManager(_db, _db.itemsTable);
  $$InventoryTableTableTableManager get inventoryTable =>
      $$InventoryTableTableTableManager(_db, _db.inventoryTable);
  $$ShopItemsTableTableTableManager get shopItemsTable =>
      $$ShopItemsTableTableTableManager(_db, _db.shopItemsTable);
  $$AchievementsTableTableTableManager get achievementsTable =>
      $$AchievementsTableTableTableManager(_db, _db.achievementsTable);
  $$PlayerAchievementsTableTableTableManager get playerAchievementsTable =>
      $$PlayerAchievementsTableTableTableManager(
          _db, _db.playerAchievementsTable);
  $$GuildStatusTableTableTableManager get guildStatusTable =>
      $$GuildStatusTableTableTableManager(_db, _db.guildStatusTable);
  $$NpcReputationTableTableTableManager get npcReputationTable =>
      $$NpcReputationTableTableTableManager(_db, _db.npcReputationTable);
  $$DiaryEntriesTableTableTableManager get diaryEntriesTable =>
      $$DiaryEntriesTableTableTableManager(_db, _db.diaryEntriesTable);
  $$ClassQuestsTableTableTableManager get classQuestsTable =>
      $$ClassQuestsTableTableTableManager(_db, _db.classQuestsTable);
  $$FactionQuestsTableTableTableManager get factionQuestsTable =>
      $$FactionQuestsTableTableTableManager(_db, _db.factionQuestsTable);
  $$GuildAscensionTableTableTableManager get guildAscensionTable =>
      $$GuildAscensionTableTableTableManager(_db, _db.guildAscensionTable);
  $$VitalismUniqueCatalogTableTableTableManager
      get vitalismUniqueCatalogTable =>
          $$VitalismUniqueCatalogTableTableTableManager(
              _db, _db.vitalismUniqueCatalogTable);
  $$PlayerVitalismAffinitiesTableTableTableManager
      get playerVitalismAffinitiesTable =>
          $$PlayerVitalismAffinitiesTableTableTableManager(
              _db, _db.playerVitalismAffinitiesTable);
  $$PlayerVitalismTreesTableTableTableManager get playerVitalismTreesTable =>
      $$PlayerVitalismTreesTableTableTableManager(
          _db, _db.playerVitalismTreesTable);
  $$LifeVitalismPointsTableTableTableManager get lifeVitalismPointsTable =>
      $$LifeVitalismPointsTableTableTableManager(
          _db, _db.lifeVitalismPointsTable);
  $$ItemsCatalogTableTableTableManager get itemsCatalogTable =>
      $$ItemsCatalogTableTableTableManager(_db, _db.itemsCatalogTable);
  $$PlayerInventoryTableTableTableManager get playerInventoryTable =>
      $$PlayerInventoryTableTableTableManager(_db, _db.playerInventoryTable);
  $$PlayerEquipmentTableTableTableManager get playerEquipmentTable =>
      $$PlayerEquipmentTableTableTableManager(_db, _db.playerEquipmentTable);
  $$RecipesCatalogTableTableTableManager get recipesCatalogTable =>
      $$RecipesCatalogTableTableTableManager(_db, _db.recipesCatalogTable);
  $$PlayerRecipesUnlockedTableTableTableManager
      get playerRecipesUnlockedTable =>
          $$PlayerRecipesUnlockedTableTableTableManager(
              _db, _db.playerRecipesUnlockedTable);
}
