import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/domain/enums/intensity.dart';
import 'package:noheroes_app/domain/enums/mission_category.dart';
import 'package:noheroes_app/domain/services/mission_balancer_service.dart';

/// Sprint 3.1 Bloco 11a — unit tests do `MissionBalancerService`.
///
/// Fórmula (Sprint_Missoes Bloco 11):
///   - base_xp   = intensity × 30 × categoryMult
///   - base_gold = intensity × 20 × categoryMult
///   - final_xp   = base × SOULSLIKE.xp   × repetivel_penalty
///   - final_gold = base × SOULSLIKE.gold × repetivel_penalty
///
/// Multipliers: xp=0.4, gold=0.35, repetivel_penalty=0.7
///
/// Categorias: fisico=1.0, mental=1.1, espiritual=1.2, vitalismo=1.15

void main() {
  const service = MissionBalancerService();

  BalancerInput input({
    MissionCategory categoria = MissionCategory.fisico,
    Intensity intensity = Intensity.light,
    GuildRank rank = GuildRank.e,
    bool isRepetivel = false,
  }) =>
      BalancerInput(
        categoria: categoria,
        intensity: intensity,
        rank: rank,
        isRepetivel: isRepetivel,
      );

  group('MissionBalancerService.calculate', () {
    test('rank E × leve × físico (mult 1.0) → 12 xp / 7 gold', () {
      // 1 × 30 × 1.0 × 0.4 = 12; 1 × 20 × 1.0 × 0.35 = 7
      final r = service.calculate(input());
      expect(r.xp, 12);
      expect(r.gold, 7);
    });

    test('rank S × pesado × vitalismo → valores máximos', () {
      // 3 × 30 × 1.15 × 0.4 = 41.4 → 41
      // 3 × 20 × 1.15 × 0.35 = 24.15 → 24
      final r = service.calculate(input(
        categoria: MissionCategory.vitalismo,
        intensity: Intensity.heavy,
        rank: GuildRank.s,
      ));
      expect(r.xp, 41);
      expect(r.gold, 24);
    });

    test('categoria mental (1.1x) vs físico (1.0x)', () {
      final fisico = service.calculate(input(intensity: Intensity.medium));
      final mental = service.calculate(input(
          categoria: MissionCategory.mental, intensity: Intensity.medium));
      // 2×30×1.0×0.4=24; 2×30×1.1×0.4=26.4→26
      expect(fisico.xp, 24);
      expect(mental.xp, 26);
    });

    test('categoria espiritual aplica 1.2x', () {
      final r = service.calculate(input(
          categoria: MissionCategory.espiritual, intensity: Intensity.medium));
      // 2×30×1.2×0.4=28.8→29
      expect(r.xp, 29);
    });

    test('isRepetivel reduz 30% (aplica 0.7 na reward final)', () {
      final normal = service.calculate(input(intensity: Intensity.medium));
      final repet = service.calculate(input(
          intensity: Intensity.medium, isRepetivel: true));
      // normal: 2×30×1.0×0.4 = 24
      // repet:  2×30×1.0×0.4×0.7 = 16.8 → 17
      expect(normal.xp, 24);
      expect(repet.xp, 17);
    });

    test('determinístico: mesmo input = mesmo output', () {
      final a = service.calculate(input(
        categoria: MissionCategory.mental,
        intensity: Intensity.heavy,
        rank: GuildRank.b,
        isRepetivel: true,
      ));
      final b = service.calculate(input(
        categoria: MissionCategory.mental,
        intensity: Intensity.heavy,
        rank: GuildRank.b,
        isRepetivel: true,
      ));
      expect(a.xp, b.xp);
      expect(a.gold, b.gold);
    });

    test('Intensity.adaptive rejeitada com ArgumentError', () {
      expect(
        () => service.calculate(input(intensity: Intensity.adaptive)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
