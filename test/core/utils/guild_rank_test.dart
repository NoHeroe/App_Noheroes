import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/core/utils/guild_rank.dart';

/// Sprint 3.4 Etapa G.2 (D14) — gate de rank pra facções extremas (ERROR
/// exige rank B+). Especificação canônica: ordem e<d<c<b<a<s; B+ aceita
/// b/a/s, rejeita e/d/c.
void main() {
  group('GuildRankSystem.meetsMinimum', () {
    test('B+ aceita b, a, s', () {
      expect(GuildRankSystem.meetsMinimum(GuildRank.b, GuildRank.b), isTrue);
      expect(GuildRankSystem.meetsMinimum(GuildRank.a, GuildRank.b), isTrue);
      expect(GuildRankSystem.meetsMinimum(GuildRank.s, GuildRank.b), isTrue);
    });

    test('B+ rejeita e, d, c', () {
      expect(GuildRankSystem.meetsMinimum(GuildRank.e, GuildRank.b), isFalse);
      expect(GuildRankSystem.meetsMinimum(GuildRank.d, GuildRank.b), isFalse);
      expect(GuildRankSystem.meetsMinimum(GuildRank.c, GuildRank.b), isFalse);
    });

    test('respeita a ordem completa e<d<c<b<a<s', () {
      const order = [
        GuildRank.e,
        GuildRank.d,
        GuildRank.c,
        GuildRank.b,
        GuildRank.a,
        GuildRank.s,
      ];
      for (var i = 0; i < order.length; i++) {
        for (var j = 0; j < order.length; j++) {
          expect(
            GuildRankSystem.meetsMinimum(order[i], order[j]),
            i >= j,
            reason: '${order[i].name} >= ${order[j].name} deveria ser ${i >= j}',
          );
        }
      }
    });

    test('fromString("none") → e → NÃO atinge B (gate ERROR bloqueia)', () {
      expect(
        GuildRankSystem.meetsMinimum(
            GuildRankSystem.fromString('none'), GuildRank.b),
        isFalse,
      );
      expect(
        GuildRankSystem.meetsMinimum(
            GuildRankSystem.fromString('a'), GuildRank.b),
        isTrue,
      );
    });
  });
}
