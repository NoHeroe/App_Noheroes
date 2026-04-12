import '../enums/class_type.dart';
import '../enums/shadow_state.dart';

class Player {
  final String id;
    final String name;
      final ClassType classType;
        final int level;
          final int xp;
            final int xpToNextLevel;
              final int caelumDay;
                final int hp;
                  final int maxHp;
                    final int mp;
                      final int maxMp;
                        final int gold;
                          final int gems;
                            final ShadowState shadowState;
                              final int streakDays;
                                final DateTime createdAt;
                                  final DateTime lastLoginAt;

                                    const Player({
                                        required this.id,
                                            required this.name,
                                                required this.classType,
                                                    required this.level,
                                                        required this.xp,
                                                            required this.xpToNextLevel,
                                                                required this.caelumDay,
                                                                    required this.hp,
                                                                        required this.maxHp,
                                                                            required this.mp,
                                                                                required this.maxMp,
                                                                                    required this.gold,
                                                                                        required this.gems,
                                                                                            required this.shadowState,
                                                                                                required this.streakDays,
                                                                                                    required this.createdAt,
                                                                                                        required this.lastLoginAt,
                                                                                                          });

                                                                                                            Player copyWith({
                                                                                                                String? id,
                                                                                                                    String? name,
                                                                                                                        ClassType? classType,
                                                                                                                            int? level,
                                                                                                                                int? xp,
                                                                                                                                    int? xpToNextLevel,
                                                                                                                                        int? caelumDay,
                                                                                                                                            int? hp,
                                                                                                                                                int? maxHp,
                                                                                                                                                    int? mp,
                                                                                                                                                        int? maxMp,
                                                                                                                                                            int? gold,
                                                                                                                                                                int? gems,
                                                                                                                                                                    ShadowState? shadowState,
                                                                                                                                                                        int? streakDays,
                                                                                                                                                                            DateTime? createdAt,
                                                                                                                                                                                DateTime? lastLoginAt,
                                                                                                                                                                                  }) {
                                                                                                                                                                                      return Player(
                                                                                                                                                                                            id: id ?? this.id,
                                                                                                                                                                                                  name: name ?? this.name,
                                                                                                                                                                                                        classType: classType ?? this.classType,
                                                                                                                                                                                                              level: level ?? this.level,
                                                                                                                                                                                                                    xp: xp ?? this.xp,
                                                                                                                                                                                                                          xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
                                                                                                                                                                                                                                caelumDay: caelumDay ?? this.caelumDay,
                                                                                                                                                                                                                                      hp: hp ?? this.hp,
                                                                                                                                                                                                                                            maxHp: maxHp ?? this.maxHp,
                                                                                                                                                                                                                                                  mp: mp ?? this.mp,
                                                                                                                                                                                                                                                        maxMp: maxMp ?? this.maxMp,
                                                                                                                                                                                                                                                              gold: gold ?? this.gold,
                                                                                                                                                                                                                                                                    gems: gems ?? this.gems,
                                                                                                                                                                                                                                                                          shadowState: shadowState ?? this.shadowState,
                                                                                                                                                                                                                                                                                streakDays: streakDays ?? this.streakDays,
                                                                                                                                                                                                                                                                                      createdAt: createdAt ?? this.createdAt,
                                                                                                                                                                                                                                                                                            lastLoginAt: lastLoginAt ?? this.lastLoginAt,
                                                                                                                                                                                                                                                                                                );
                                                                                                                                                                                                                                                                                                  }
                                                                                                                                                                                                                                                                                                  }