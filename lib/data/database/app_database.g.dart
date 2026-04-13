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
        gold,
        gems,
        streakDays,
        caelumDay,
        shadowState,
        shadowCorruption,
        classType,
        factionType,
        narrativeMode,
        onboardingDone,
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
      narrativeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}narrative_mode'])!,
      onboardingDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}onboarding_done'])!,
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
  final int gold;
  final int gems;
  final int streakDays;
  final int caelumDay;
  final String shadowState;
  final int shadowCorruption;
  final String? classType;
  final String? factionType;
  final String narrativeMode;
  final bool onboardingDone;
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
      required this.gold,
      required this.gems,
      required this.streakDays,
      required this.caelumDay,
      required this.shadowState,
      required this.shadowCorruption,
      this.classType,
      this.factionType,
      required this.narrativeMode,
      required this.onboardingDone,
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
    map['narrative_mode'] = Variable<String>(narrativeMode);
    map['onboarding_done'] = Variable<bool>(onboardingDone);
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
      narrativeMode: Value(narrativeMode),
      onboardingDone: Value(onboardingDone),
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
      gold: serializer.fromJson<int>(json['gold']),
      gems: serializer.fromJson<int>(json['gems']),
      streakDays: serializer.fromJson<int>(json['streakDays']),
      caelumDay: serializer.fromJson<int>(json['caelumDay']),
      shadowState: serializer.fromJson<String>(json['shadowState']),
      shadowCorruption: serializer.fromJson<int>(json['shadowCorruption']),
      classType: serializer.fromJson<String?>(json['classType']),
      factionType: serializer.fromJson<String?>(json['factionType']),
      narrativeMode: serializer.fromJson<String>(json['narrativeMode']),
      onboardingDone: serializer.fromJson<bool>(json['onboardingDone']),
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
      'gold': serializer.toJson<int>(gold),
      'gems': serializer.toJson<int>(gems),
      'streakDays': serializer.toJson<int>(streakDays),
      'caelumDay': serializer.toJson<int>(caelumDay),
      'shadowState': serializer.toJson<String>(shadowState),
      'shadowCorruption': serializer.toJson<int>(shadowCorruption),
      'classType': serializer.toJson<String?>(classType),
      'factionType': serializer.toJson<String?>(factionType),
      'narrativeMode': serializer.toJson<String>(narrativeMode),
      'onboardingDone': serializer.toJson<bool>(onboardingDone),
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
          int? gold,
          int? gems,
          int? streakDays,
          int? caelumDay,
          String? shadowState,
          int? shadowCorruption,
          Value<String?> classType = const Value.absent(),
          Value<String?> factionType = const Value.absent(),
          String? narrativeMode,
          bool? onboardingDone,
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
        gold: gold ?? this.gold,
        gems: gems ?? this.gems,
        streakDays: streakDays ?? this.streakDays,
        caelumDay: caelumDay ?? this.caelumDay,
        shadowState: shadowState ?? this.shadowState,
        shadowCorruption: shadowCorruption ?? this.shadowCorruption,
        classType: classType.present ? classType.value : this.classType,
        factionType: factionType.present ? factionType.value : this.factionType,
        narrativeMode: narrativeMode ?? this.narrativeMode,
        onboardingDone: onboardingDone ?? this.onboardingDone,
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
      narrativeMode: data.narrativeMode.present
          ? data.narrativeMode.value
          : this.narrativeMode,
      onboardingDone: data.onboardingDone.present
          ? data.onboardingDone.value
          : this.onboardingDone,
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
          ..write('gold: $gold, ')
          ..write('gems: $gems, ')
          ..write('streakDays: $streakDays, ')
          ..write('caelumDay: $caelumDay, ')
          ..write('shadowState: $shadowState, ')
          ..write('shadowCorruption: $shadowCorruption, ')
          ..write('classType: $classType, ')
          ..write('factionType: $factionType, ')
          ..write('narrativeMode: $narrativeMode, ')
          ..write('onboardingDone: $onboardingDone, ')
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
        gold,
        gems,
        streakDays,
        caelumDay,
        shadowState,
        shadowCorruption,
        classType,
        factionType,
        narrativeMode,
        onboardingDone,
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
          other.gold == this.gold &&
          other.gems == this.gems &&
          other.streakDays == this.streakDays &&
          other.caelumDay == this.caelumDay &&
          other.shadowState == this.shadowState &&
          other.shadowCorruption == this.shadowCorruption &&
          other.classType == this.classType &&
          other.factionType == this.factionType &&
          other.narrativeMode == this.narrativeMode &&
          other.onboardingDone == this.onboardingDone &&
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
  final Value<int> gold;
  final Value<int> gems;
  final Value<int> streakDays;
  final Value<int> caelumDay;
  final Value<String> shadowState;
  final Value<int> shadowCorruption;
  final Value<String?> classType;
  final Value<String?> factionType;
  final Value<String> narrativeMode;
  final Value<bool> onboardingDone;
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
    this.gold = const Value.absent(),
    this.gems = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.caelumDay = const Value.absent(),
    this.shadowState = const Value.absent(),
    this.shadowCorruption = const Value.absent(),
    this.classType = const Value.absent(),
    this.factionType = const Value.absent(),
    this.narrativeMode = const Value.absent(),
    this.onboardingDone = const Value.absent(),
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
    this.gold = const Value.absent(),
    this.gems = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.caelumDay = const Value.absent(),
    this.shadowState = const Value.absent(),
    this.shadowCorruption = const Value.absent(),
    this.classType = const Value.absent(),
    this.factionType = const Value.absent(),
    this.narrativeMode = const Value.absent(),
    this.onboardingDone = const Value.absent(),
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
    Expression<int>? gold,
    Expression<int>? gems,
    Expression<int>? streakDays,
    Expression<int>? caelumDay,
    Expression<String>? shadowState,
    Expression<int>? shadowCorruption,
    Expression<String>? classType,
    Expression<String>? factionType,
    Expression<String>? narrativeMode,
    Expression<bool>? onboardingDone,
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
      if (gold != null) 'gold': gold,
      if (gems != null) 'gems': gems,
      if (streakDays != null) 'streak_days': streakDays,
      if (caelumDay != null) 'caelum_day': caelumDay,
      if (shadowState != null) 'shadow_state': shadowState,
      if (shadowCorruption != null) 'shadow_corruption': shadowCorruption,
      if (classType != null) 'class_type': classType,
      if (factionType != null) 'faction_type': factionType,
      if (narrativeMode != null) 'narrative_mode': narrativeMode,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
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
      Value<int>? gold,
      Value<int>? gems,
      Value<int>? streakDays,
      Value<int>? caelumDay,
      Value<String>? shadowState,
      Value<int>? shadowCorruption,
      Value<String?>? classType,
      Value<String?>? factionType,
      Value<String>? narrativeMode,
      Value<bool>? onboardingDone,
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
      gold: gold ?? this.gold,
      gems: gems ?? this.gems,
      streakDays: streakDays ?? this.streakDays,
      caelumDay: caelumDay ?? this.caelumDay,
      shadowState: shadowState ?? this.shadowState,
      shadowCorruption: shadowCorruption ?? this.shadowCorruption,
      classType: classType ?? this.classType,
      factionType: factionType ?? this.factionType,
      narrativeMode: narrativeMode ?? this.narrativeMode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
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
    if (narrativeMode.present) {
      map['narrative_mode'] = Variable<String>(narrativeMode.value);
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<bool>(onboardingDone.value);
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
          ..write('gold: $gold, ')
          ..write('gems: $gems, ')
          ..write('streakDays: $streakDays, ')
          ..write('caelumDay: $caelumDay, ')
          ..write('shadowState: $shadowState, ')
          ..write('shadowCorruption: $shadowCorruption, ')
          ..write('classType: $classType, ')
          ..write('factionType: $factionType, ')
          ..write('narrativeMode: $narrativeMode, ')
          ..write('onboardingDone: $onboardingDone, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTableTable playersTable = $PlayersTableTable(this);
  late final $HabitsTableTable habitsTable = $HabitsTableTable(this);
  late final $HabitLogsTableTable habitLogsTable = $HabitLogsTableTable(this);
  late final $ItemsTableTable itemsTable = $ItemsTableTable(this);
  late final $InventoryTableTable inventoryTable = $InventoryTableTable(this);
  late final $ShopItemsTableTable shopItemsTable = $ShopItemsTableTable(this);
  late final PlayerDao playerDao = PlayerDao(this as AppDatabase);
  late final HabitDao habitDao = HabitDao(this as AppDatabase);
  late final InventoryDao inventoryDao = InventoryDao(this as AppDatabase);
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
        shopItemsTable
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
  Value<int> gold,
  Value<int> gems,
  Value<int> streakDays,
  Value<int> caelumDay,
  Value<String> shadowState,
  Value<int> shadowCorruption,
  Value<String?> classType,
  Value<String?> factionType,
  Value<String> narrativeMode,
  Value<bool> onboardingDone,
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
  Value<int> gold,
  Value<int> gems,
  Value<int> streakDays,
  Value<int> caelumDay,
  Value<String> shadowState,
  Value<int> shadowCorruption,
  Value<String?> classType,
  Value<String?> factionType,
  Value<String> narrativeMode,
  Value<bool> onboardingDone,
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

  ColumnFilters<String> get narrativeMode => $composableBuilder(
      column: $table.narrativeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get onboardingDone => $composableBuilder(
      column: $table.onboardingDone,
      builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<String> get narrativeMode => $composableBuilder(
      column: $table.narrativeMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get onboardingDone => $composableBuilder(
      column: $table.onboardingDone,
      builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<String> get narrativeMode => $composableBuilder(
      column: $table.narrativeMode, builder: (column) => column);

  GeneratedColumn<bool> get onboardingDone => $composableBuilder(
      column: $table.onboardingDone, builder: (column) => column);

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
            Value<int> gold = const Value.absent(),
            Value<int> gems = const Value.absent(),
            Value<int> streakDays = const Value.absent(),
            Value<int> caelumDay = const Value.absent(),
            Value<String> shadowState = const Value.absent(),
            Value<int> shadowCorruption = const Value.absent(),
            Value<String?> classType = const Value.absent(),
            Value<String?> factionType = const Value.absent(),
            Value<String> narrativeMode = const Value.absent(),
            Value<bool> onboardingDone = const Value.absent(),
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
            gold: gold,
            gems: gems,
            streakDays: streakDays,
            caelumDay: caelumDay,
            shadowState: shadowState,
            shadowCorruption: shadowCorruption,
            classType: classType,
            factionType: factionType,
            narrativeMode: narrativeMode,
            onboardingDone: onboardingDone,
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
            Value<int> gold = const Value.absent(),
            Value<int> gems = const Value.absent(),
            Value<int> streakDays = const Value.absent(),
            Value<int> caelumDay = const Value.absent(),
            Value<String> shadowState = const Value.absent(),
            Value<int> shadowCorruption = const Value.absent(),
            Value<String?> classType = const Value.absent(),
            Value<String?> factionType = const Value.absent(),
            Value<String> narrativeMode = const Value.absent(),
            Value<bool> onboardingDone = const Value.absent(),
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
            gold: gold,
            gems: gems,
            streakDays: streakDays,
            caelumDay: caelumDay,
            shadowState: shadowState,
            shadowCorruption: shadowCorruption,
            classType: classType,
            factionType: factionType,
            narrativeMode: narrativeMode,
            onboardingDone: onboardingDone,
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
}
