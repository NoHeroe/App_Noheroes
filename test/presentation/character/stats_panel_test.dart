import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/presentation/character/widgets/stats_panel.dart';

/// Sprint 3.4 Etapa G.2 (D16) — a seção ESTATÍSTICAS deve somar o buff de
/// FACÇÃO ao bônus de XP/Ouro (antes mostrava só carisma/equipamento).
///
/// Especificação canônica: bônus exibido = bônus de carisma (xpBonus =
/// round(charisma*0.5); goldBonus = round(charisma*0.3)) + % do buff de
/// facção passado por param. Buff positivo soma; debuff (negativo) subtrai
/// — coerente com o que o RewardGrant aplica.
PlayersTableData _player({required int charisma}) {
  return PlayersTableData(
    id: 1,
    email: 't@t',
    passwordHash: 'h',
    shadowName: 'Sombra',
    level: 10,
    xp: 0,
    xpToNext: 100,
    gold: 0,
    gems: 0,
    insignias: 0,
    strength: 1,
    dexterity: 1,
    intelligence: 1,
    constitution: 1,
    spirit: 1,
    charisma: charisma,
    attributePoints: 0,
    shadowCorruption: 0,
    vitalismLevel: 0,
    vitalismXp: 0,
    currentVitalism: 0,
    shadowState: 'stable',
    classType: 'warrior',
    factionType: 'new_order',
    guildRank: 'e',
    narrativeMode: 'standard',
    playStyle: 'none',
    totalQuestsCompleted: 0,
    maxHp: 100,
    hp: 100,
    maxMp: 50,
    mp: 50,
    onboardingDone: true,
    lastLoginAt: DateTime(2026, 1, 1),
    lastStreakDate: DateTime(2026, 1, 1),
    streakDays: 0,
    caelumDay: 0,
    createdAt: DateTime(2026, 1, 1),
    dailyMissionsStreak: 0,
    totalGemsSpent: 0,
    peakLevel: 1,
    totalAttributePointsSpent: 0,
    autoConfirmEnabled: false,
    screensVisitedKeys: '',
    totalGoldEarnedViaQuests: 0,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  // charisma 10 → xpBonus = round(5.0) = 5; goldBonus = round(3.0) = 3.

  testWidgets('sem buff de facção: mostra só o bônus de carisma (+5% / +3%)',
      (tester) async {
    await _pump(tester, StatsPanel(player: _player(charisma: 10)));
    expect(find.text('+5%'), findsOneWidget); // XP
    expect(find.text('+3%'), findsOneWidget); // Ouro
  });

  testWidgets('com buff de facção (+10%): soma ao bônus exibido (+15% / +13%)',
      (tester) async {
    await _pump(
      tester,
      StatsPanel(
        player: _player(charisma: 10),
        factionXpBonusPct: 10,
        factionGoldBonusPct: 10,
      ),
    );
    expect(find.text('+15%'), findsOneWidget); // 5 + 10
    expect(find.text('+13%'), findsOneWidget); // 3 + 10
  });

  testWidgets('debuff de facção (-30%): reflete negativo no XP (-25%)',
      (tester) async {
    await _pump(
      tester,
      StatsPanel(
        player: _player(charisma: 10),
        factionXpBonusPct: -30,
        factionGoldBonusPct: -30,
      ),
    );
    expect(find.text('-25%'), findsOneWidget); // 5 + (-30)
    expect(find.text('-27%'), findsOneWidget); // 3 + (-30)
  });
}
