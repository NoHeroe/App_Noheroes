import '../enums/habit_rank.dart';
import '../enums/quest_status.dart';

enum HabitCategory { physical, mental, spiritual, order }

class Habit {
  final String id;
    final String title;
      final String description;
        final HabitCategory category;
          final HabitRank rank;
            final int xpReward;
              final int goldReward;
                final bool isSystemHabit;
                  final bool isRepeatable;
                    final QuestStatus todayStatus;
                      final int streakCount;
                        final DateTime createdAt;

                          const Habit({
                              required this.id,
                                  required this.title,
                                      required this.description,
                                          required this.category,
                                              required this.rank,
                                                  required this.xpReward,
                                                      required this.goldReward,
                                                          required this.isSystemHabit,
                                                              required this.isRepeatable,
                                                                  required this.todayStatus,
                                                                      required this.streakCount,
                                                                          required this.createdAt,
                                                                            });

                                                                              Habit copyWith({
                                                                                  String? id,
                                                                                      String? title,
                                                                                          String? description,
                                                                                              HabitCategory? category,
                                                                                                  HabitRank? rank,
                                                                                                      int? xpReward,
                                                                                                          int? goldReward,
                                                                                                              bool? isSystemHabit,
                                                                                                                  bool? isRepeatable,
                                                                                                                      QuestStatus? todayStatus,
                                                                                                                          int? streakCount,
                                                                                                                              DateTime? createdAt,
                                                                                                                                }) {
                                                                                                                                    return Habit(
                                                                                                                                          id: id ?? this.id,
                                                                                                                                                title: title ?? this.title,
                                                                                                                                                      description: description ?? this.description,
                                                                                                                                                            category: category ?? this.category,
                                                                                                                                                                  rank: rank ?? this.rank,
                                                                                                                                                                        xpReward: xpReward ?? this.xpReward,
                                                                                                                                                                              goldReward: goldReward ?? this.goldReward,
                                                                                                                                                                                    isSystemHabit: isSystemHabit ?? this.isSystemHabit,
                                                                                                                                                                                          isRepeatable: isRepeatable ?? this.isRepeatable,
                                                                                                                                                                                                todayStatus: todayStatus ?? this.todayStatus,
                                                                                                                                                                                                      streakCount: streakCount ?? this.streakCount,
                                                                                                                                                                                                            createdAt: createdAt ?? this.createdAt,
                                                                                                                                                                                                                );
                                                                                                                                                                                                                  }
                                                                                                                                                                                                                  }