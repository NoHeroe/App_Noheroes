import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/balance/soulslike_balance.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';

void main() {
  group('SoulslikeBalance — constantes ADR 0013', () {
    test('multipliers estão corretos', () {
      expect(SoulslikeBalance.xpMultiplier, 0.4);
      expect(SoulslikeBalance.goldMultiplier, 0.35);
      expect(SoulslikeBalance.gemsMultiplier, 0.7);
      expect(SoulslikeBalance.seivasMultiplier, 0.5);
      expect(SoulslikeBalance.itemsMultiplier, 1.0);
    });

    test('late-game constants ADR 0017', () {
      expect(SoulslikeBalance.lateGameMinLevel, 91);
      expect(SoulslikeBalance.lateGameSPlusBonus, 0.05);
    });
  });

  group('clampProgressPct', () {
    test('limita em [0, 300]', () {
      expect(clampProgressPct(-10), 0);
      expect(clampProgressPct(0), 0);
      expect(clampProgressPct(50), 50);
      expect(clampProgressPct(100), 100);
      expect(clampProgressPct(300), 300);
      expect(clampProgressPct(500), 300);
    });
  });

  group('applyExtraFormula (ADR 0013 §4)', () {
    test('base 0 retorna 0 seja qual for o pct', () {
      expect(applyExtraFormula(0, 100), 0);
      expect(applyExtraFormula(0, 300), 0);
    });

    test('pct=0 retorna 0', () {
      expect(applyExtraFormula(10, 0), 0);
    });

    test('pct=50 retorna metade (exemplo do ADR 0013 §4)', () {
      expect(applyExtraFormula(10, 50), 5);
    });

    test('pct=100 retorna base', () {
      expect(applyExtraFormula(10, 100), 10);
    });

    test('pct=150 aplica bonus 45% sobre 50% excedente', () {
      // base + base * 0.45 * 0.5 = 10 + 2.25 = 12.25 → 12 (round)
      expect(applyExtraFormula(10, 150), 12);
    });

    test('pct=300 (limite) retorna base * (1 + 0.45 * 2)', () {
      // 10 + 10 * 0.45 * 2.0 = 10 + 9 = 19
      expect(applyExtraFormula(10, 300), 19);
    });

    test('pct > 300 é clampado (igual 300)', () {
      expect(applyExtraFormula(10, 400), 19);
      expect(applyExtraFormula(10, 999), 19);
    });

    test('valor típico de flexões ADR 0013 §4', () {
      // base 10 XP / missão 10 flexões
      expect(applyExtraFormula(10, 50), 5);
      expect(applyExtraFormula(10, 100), 10);
      expect(applyExtraFormula(10, 150), 12);
      expect(applyExtraFormula(10, 300), 19);
    });
  });

  group('applySoulslikeCurrency', () {
    test('aplica multipliers arredondando cada currency', () {
      // xp=100*0.4=40; gold=50*0.35=17.5→18; gems=10*0.7=7; seivas=2*0.5=1
      final r = applySoulslikeCurrency(
        xp: 100,
        gold: 50,
        gems: 10,
        seivas: 2,
      );
      expect(r.xp, 40);
      expect(r.gold, 18);
      expect(r.gems, 7);
      expect(r.seivas, 1);
    });

    test('zeros não quebram', () {
      final r = applySoulslikeCurrency(xp: 0, gold: 0, gems: 0, seivas: 0);
      expect(r.xp, 0);
      expect(r.gold, 0);
      expect(r.gems, 0);
      expect(r.seivas, 0);
    });

    test('valores negativos propagam arredondados', () {
      final r = applySoulslikeCurrency(
          xp: -100, gold: -50, gems: 0, seivas: 0);
      expect(r.xp, -40);
      expect(r.gold, -18);
    });
  });

  group('isLateGameBoostEligible', () {
    test('rank S + level >= 91 → true', () {
      expect(
        isLateGameBoostEligible(
            const PlayerSnapshot(level: 91, rank: GuildRank.s)),
        isTrue,
      );
      expect(
        isLateGameBoostEligible(
            const PlayerSnapshot(level: 99, rank: GuildRank.s)),
        isTrue,
      );
    });

    test('rank S + level 90 → false (exige ≥ 91)', () {
      expect(
        isLateGameBoostEligible(
            const PlayerSnapshot(level: 90, rank: GuildRank.s)),
        isFalse,
      );
    });

    test('rank A + level 99 → false (exige rank S)', () {
      expect(
        isLateGameBoostEligible(
            const PlayerSnapshot(level: 99, rank: GuildRank.a)),
        isFalse,
      );
    });

    test('rank null → false', () {
      expect(
        isLateGameBoostEligible(const PlayerSnapshot(level: 99)),
        isFalse,
      );
    });
  });
}
