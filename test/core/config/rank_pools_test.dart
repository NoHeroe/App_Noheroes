import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/config/rank_pools.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';

void main() {
  group('RankPools.filterByRank', () {
    test('rank E → só entries E', () {
      final pool = [
        {'rank': GuildRank.e},
        {'rank': GuildRank.d},
        {'rank': GuildRank.c},
        {'rank': GuildRank.b},
      ];
      final out = RankPools.filterByRank<Map<String, dynamic>>(
        pool,
        GuildRank.e,
        (e) => e['rank'] as GuildRank,
      );
      expect(out.length, 1);
      expect(out.first['rank'], GuildRank.e);
    });

    test('rank D → E + D + C (B e acima excluídos)', () {
      final pool = [
        {'rank': GuildRank.e},
        {'rank': GuildRank.d},
        {'rank': GuildRank.c},
        {'rank': GuildRank.b},
        {'rank': GuildRank.s},
      ];
      final out = RankPools.filterByRank<Map<String, dynamic>>(
        pool,
        GuildRank.d,
        (e) => e['rank'] as GuildRank,
      );
      expect(out.map((e) => e['rank']).toSet(),
          {GuildRank.e, GuildRank.d, GuildRank.c});
    });

    test('rank S → só B/A/S (E/D/C excluídos)', () {
      final pool = [
        for (final r in GuildRank.values) {'rank': r}
      ];
      final out = RankPools.filterByRank<Map<String, dynamic>>(
        pool,
        GuildRank.s,
        (e) => e['rank'] as GuildRank,
      );
      expect(out.map((e) => e['rank']).toSet(),
          {GuildRank.b, GuildRank.a, GuildRank.s});
    });
  });

  group('RankPools.weightFor', () {
    test('soma das probabilidades pra cada rank = 1.0 ± epsilon', () {
      for (final player in GuildRank.values) {
        var sum = 0.0;
        for (final entry in RankPools.orderedRanks) {
          sum += RankPools.weightFor(player, entry);
        }
        expect(sum, closeTo(1.0, 1e-9),
            reason: 'player=$player sum=$sum');
      }
    });
  });
}
