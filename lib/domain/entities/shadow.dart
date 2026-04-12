import '../enums/shadow_state.dart';

class Shadow {
  final String id;
    final String playerId;
      final ShadowState state;
        final int corruptionLevel; // 0-100
          final int stabilityPoints;
            final List<String> activeArchetypes;
              final bool hasBossActive;
                final String currentPhrase;
                  final DateTime lastUpdated;

                    const Shadow({
                        required this.id,
                            required this.playerId,
                                required this.state,
                                    required this.corruptionLevel,
                                        required this.stabilityPoints,
                                            required this.activeArchetypes,
                                                required this.hasBossActive,
                                                    required this.currentPhrase,
                                                        required this.lastUpdated,
                                                          });

                                                            Shadow copyWith({
                                                                String? id,
                                                                    String? playerId,
                                                                        ShadowState? state,
                                                                            int? corruptionLevel,
                                                                                int? stabilityPoints,
                                                                                    List<String>? activeArchetypes,
                                                                                        bool? hasBossActive,
                                                                                            String? currentPhrase,
                                                                                                DateTime? lastUpdated,
                                                                                                  }) {
                                                                                                      return Shadow(
                                                                                                            id: id ?? this.id,
                                                                                                                  playerId: playerId ?? this.playerId,
                                                                                                                        state: state ?? this.state,
                                                                                                                              corruptionLevel: corruptionLevel ?? this.corruptionLevel,
                                                                                                                                    stabilityPoints: stabilityPoints ?? this.stabilityPoints,
                                                                                                                                          activeArchetypes: activeArchetypes ?? this.activeArchetypes,
                                                                                                                                                hasBossActive: hasBossActive ?? this.hasBossActive,
                                                                                                                                                      currentPhrase: currentPhrase ?? this.currentPhrase,
                                                                                                                                                            lastUpdated: lastUpdated ?? this.lastUpdated,
                                                                                                                                                                );
                                                                                                                                                                  }
                                                                                                                                                                  }