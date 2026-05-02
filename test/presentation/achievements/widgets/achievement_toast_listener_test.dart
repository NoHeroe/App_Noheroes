import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/app/providers.dart';
import 'package:noheroes_app/core/events/app_event_bus.dart';
import 'package:noheroes_app/core/events/reward_events.dart';
import 'package:noheroes_app/domain/models/achievement_definition.dart';
import 'package:noheroes_app/domain/services/achievements_service.dart';
import 'package:noheroes_app/presentation/achievements/widgets/achievement_toast_listener.dart';
import 'package:noheroes_app/presentation/achievements/widgets/achievement_unlocked_toast.dart';

class _FakeBundle extends AssetBundle {
  final Map<String, String> contents;
  _FakeBundle(this.contents);

  @override
  Future<ByteData> load(String key) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(s)));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final s = contents[key];
    if (s == null) throw FlutterError('not found: $key');
    return s;
  }
}

/// Fake AchievementsService minimalista pra teste do listener — só
/// expõe `catalog` e `ensureLoaded` (suficiente pro listener buscar
/// def por key).
class _FakeAchievementsService implements AchievementsService {
  final Map<String, AchievementDefinition> _catalog;
  _FakeAchievementsService(this._catalog);

  @override
  Future<void> ensureLoaded() async {}

  @override
  Map<String, AchievementDefinition> get catalog =>
      Map.unmodifiable(_catalog);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

AchievementDefinition _def(String key,
        {bool secret = false, bool disabled = false}) =>
    AchievementDefinition(
      key: key,
      name: key,
      description: 'd',
      category: 'streak',
      trigger: const MetaTrigger(targetCount: 1),
      isSecret: secret,
      disabled: disabled,
    );

/// Harness reflete o mounting de produção: listener via
/// `MaterialApp.builder`, NÃO em `home`. Sem isso o teste mente — em
/// `home`, o listener vive abaixo do Navigator e `Overlay.of(context)`
/// funcionaria mesmo que a implementação estivesse quebrada. Hotfix
/// Etapa Final-B documentou esse pattern (lição 2026-05-02).
Widget _harness({
  required AppEventBus bus,
  required Map<String, AchievementDefinition> catalog,
}) {
  return ProviderScope(
    overrides: [
      appEventBusProvider.overrideWithValue(bus),
      achievementsServiceProvider
          .overrideWithValue(_FakeAchievementsService(catalog)),
    ],
    child: MaterialApp(
      builder: (ctx, child) =>
          AchievementToastListener(child: child ?? const SizedBox()),
      home: const Scaffold(body: Text('app')),
    ),
  );
}

void main() {
  testWidgets('AchievementUnlocked → toast aparece', (tester) async {
    final bus = AppEventBus();
    await tester.pumpWidget(_harness(
      bus: bus,
      catalog: {'K': _def('K')},
    ));
    await tester.pump();

    bus.publish(AchievementUnlocked(playerId: 1, achievementKey: 'K'));
    await tester.pump(); // microtask
    await tester.pump(const Duration(milliseconds: 400)); // slide-in
    expect(find.byType(AchievementUnlockedToast), findsOneWidget);
    expect(find.text('K'), findsOneWidget);

    await bus.dispose();
  });

  testWidgets('Disabled (shell) NÃO gera toast', (tester) async {
    final bus = AppEventBus();
    await tester.pumpWidget(_harness(
      bus: bus,
      catalog: {'SHELL': _def('SHELL', disabled: true)},
    ));
    await tester.pump();

    bus.publish(
        AchievementUnlocked(playerId: 1, achievementKey: 'SHELL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AchievementUnlockedToast), findsNothing);

    await bus.dispose();
  });

  testWidgets('Key não existente no catálogo → noop silencioso',
      (tester) async {
    final bus = AppEventBus();
    await tester.pumpWidget(_harness(
      bus: bus,
      catalog: {'OTHER': _def('OTHER')},
    ));
    await tester.pump();

    bus.publish(
        AchievementUnlocked(playerId: 1, achievementKey: 'NEXISTE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AchievementUnlockedToast), findsNothing);

    await bus.dispose();
  });

  testWidgets('Fila: 2 unlocks consecutivos → 1 toast por vez',
      (tester) async {
    final bus = AppEventBus();
    await tester.pumpWidget(_harness(
      bus: bus,
      catalog: {
        'K1': _def('K1'),
        'K2': _def('K2'),
      },
    ));
    await tester.pump();

    bus.publish(AchievementUnlocked(playerId: 1, achievementKey: 'K1'));
    bus.publish(AchievementUnlocked(playerId: 1, achievementKey: 'K2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Apenas K1 visível primeiro.
    expect(find.byType(AchievementUnlockedToast), findsOneWidget);
    expect(find.text('K1'), findsOneWidget);
    expect(find.text('K2'), findsNothing);

    // Aguarda auto-dismiss timer (4s) + reverse animation + gap.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('K2'), findsOneWidget);

    await bus.dispose();
  });
}
