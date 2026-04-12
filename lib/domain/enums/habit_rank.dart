enum HabitRank { e, d, c, b, a, s }

extension HabitRankExt on HabitRank {
  String get label => name.toUpperCase();

    int get xpMultiplier => switch (this) {
        HabitRank.e => 1,
            HabitRank.d => 2,
                HabitRank.c => 3,
                    HabitRank.b => 5,
                        HabitRank.a => 8,
                            HabitRank.s => 13,
                              };
                              }