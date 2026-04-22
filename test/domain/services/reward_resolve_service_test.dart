import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/core/utils/guild_rank.dart';
import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/data/datasources/local/items_catalog_service.dart';
import 'package:noheroes_app/domain/enums/item_type.dart';
import 'package:noheroes_app/domain/models/item_spec.dart';
import 'package:noheroes_app/domain/models/player_snapshot.dart';
import 'package:noheroes_app/domain/models/reward_declared.dart';
import 'package:noheroes_app/domain/services/reward_resolve_service.dart';

import '../../core/utils/_item_spec_fixtures.dart';

/// Fake que sobrescreve findByRank/findAll retornando pool pré-definido.
/// Extender (não "implements") porque ItemsCatalogService é concrete
/// class. Super aceita AppDatabase in-memory que nunca é tocado.
class _FakeItemsCatalog extends ItemsCatalogService {
  final List<ItemSpec> _items;
  _FakeItemsCatalog(AppDatabase db, this._items) : super(db);

  @override
  Future<List<ItemSpec>> findAll() async => _items;

  @override
  Future<List<ItemSpec>> findByRank(GuildRank rank) async {
    return _items.where((i) => i.rank == rank).toList();
  }

  @override
  Future<List<ItemSpec>> findByType(ItemType type) async {
    return _items.where((i) => i.type == type).toList();
  }

  @override
  Future<ItemSpec?> findByKey(String key) async {
    for (final s in _items) {
      if (s.key == key) return s;
    }
    return null;
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async => db.close());

  PlayerSnapshot player({
    int level = 10,
    GuildRank rank = GuildRank.e,
  }) =>
      PlayerSnapshot(level: level, rank: rank);

  group('RewardResolveService — currencies puros', () {
    test('aplica SOULSLIKE com progressPct=100', () async {
      final service = _FakeItemsCatalog(db, const []);
      final resolver = RewardResolveService(service, random: Random(1));

      final resolved = await resolver.resolve(
        const RewardDeclared(xp: 100, gold: 50, gems: 10, seivas: 2),
        player(),
      );

      // xp: 100 * 0.4 = 40; gold: 50 * 0.35 = 17.5 → 18;
      // gems: 10 * 0.7 = 7; seivas: 2 * 0.5 = 1.
      expect(resolved.xp, 40);
      expect(resolved.gold, 18);
      expect(resolved.gems, 7);
      expect(resolved.seivas, 1);
      expect(resolved.items, isEmpty);
    });

    test('fórmula 0-300% pct=50 divide por 2 antes dos multipliers',
        () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      // xp base=100 → pct=50 → 50 → SOULSLIKE 0.4 → 20
      final resolved = await resolver.resolve(
        const RewardDeclared(xp: 100, gold: 50),
        player(),
        progressPct: 50,
      );

      expect(resolved.xp, 20);
      expect(resolved.gold, 9, reason: '50 * 0.5 = 25; 25 * 0.35 = 8.75 → 9');
    });

    test('fórmula 0-300% pct=300 aplica bonus 45%', () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      // xp base=100 → pct=300 → 100 + 100 * 0.45 * 2 = 190 → SOULSLIKE 0.4 → 76
      final resolved = await resolver.resolve(
        const RewardDeclared(xp: 100),
        player(),
        progressPct: 300,
      );

      expect(resolved.xp, 76);
    });

    test('progressPct > 300 é clampado', () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      final at300 = await resolver.resolve(
        const RewardDeclared(xp: 100),
        player(),
        progressPct: 300,
      );
      final at999 = await resolver.resolve(
        const RewardDeclared(xp: 100),
        player(),
        progressPct: 999,
      );
      expect(at300.xp, at999.xp);
    });

    test('zeros propagam zeros', () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      final resolved = await resolver.resolve(
        const RewardDeclared(),
        player(),
      );
      expect(resolved.xp, 0);
      expect(resolved.gold, 0);
      expect(resolved.gems, 0);
      expect(resolved.seivas, 0);
      expect(resolved.items, isEmpty);
    });
  });

  group('RewardResolveService — random resolver (ADR 0017)', () {
    test('RUNE_RANDOM_E sorteia de pool rune/E', () async {
      final pool = [
        makeItem(key: 'RUNE_FIRE_E', type: 'rune', rank: 'e'),
        makeItem(key: 'RUNE_WATER_E', type: 'rune', rank: 'e'),
        makeItem(key: 'RUNE_FIRE_D', type: 'rune', rank: 'd'),
        makeItem(key: 'HERB_COMMON', type: 'material', rank: 'e'),
      ];
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, pool),
          random: Random(42));

      final resolved = await resolver.resolve(
        const RewardDeclared(items: [
          RewardItemDeclared(key: 'RUNE_RANDOM_E', quantity: 1),
        ]),
        player(),
      );

      expect(resolved.items, hasLength(1));
      final picked = resolved.items.single;
      // Só items de type=rune E rank=E são candidatos.
      expect(['RUNE_FIRE_E', 'RUNE_WATER_E'], contains(picked.key));
      expect(picked.quantity, 1);
    });

    test('pool vazio pro par type/rank → item pulado silenciosamente',
        () async {
      final pool = [
        makeItem(key: 'RUNE_FIRE_E', type: 'rune', rank: 'e'),
      ];
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, pool),
          random: Random(42));

      final resolved = await resolver.resolve(
        const RewardDeclared(items: [
          // Não tem nenhum item type=weapon rank=b no pool.
          RewardItemDeclared(key: 'WEAPON_RANDOM_B', quantity: 1),
        ]),
        player(),
      );

      expect(resolved.items, isEmpty);
    });

    test('key literal (sem _RANDOM_) passa direto sem sortear', () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      final resolved = await resolver.resolve(
        const RewardDeclared(items: [
          RewardItemDeclared(key: 'HERB_COMMON', quantity: 3),
        ]),
        player(),
      );

      expect(resolved.items, hasLength(1));
      expect(resolved.items.single.key, 'HERB_COMMON');
      expect(resolved.items.single.quantity, 3);
    });

    test('key RANDOM malformada lança FormatException', () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      await expectLater(
        resolver.resolve(
          const RewardDeclared(items: [
            RewardItemDeclared(key: 'BROKEN_RANDOM_Z', quantity: 1),
          ]),
          player(),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('key RANDOM com type desconhecido lança', () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      await expectLater(
        resolver.resolve(
          const RewardDeclared(items: [
            RewardItemDeclared(key: 'NOPE_RANDOM_E', quantity: 1),
          ]),
          player(),
        ),
        throwsA(isA<FormatException>().having(
            (e) => e.toString(), 'msg', contains('NOPE_RANDOM_E'))),
      );
    });

    test('chance_pct=0 sempre pula', () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      final resolved = await resolver.resolve(
        const RewardDeclared(items: [
          RewardItemDeclared(key: 'HERB_COMMON', quantity: 1, chancePct: 0),
        ]),
        player(),
      );
      expect(resolved.items, isEmpty);
    });

    test('chance_pct determinístico com Random(42)', () async {
      final pool = [makeItem(key: 'HERB_COMMON', type: 'material', rank: 'e')];
      // Com seed(42) e chance_pct=50, a sequência é previsível.
      // Testamos que 100 tentativas dão distribuição entre 30-70 acertos.
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, pool),
          random: Random(42));

      var hits = 0;
      for (var i = 0; i < 100; i++) {
        final resolved = await resolver.resolve(
          const RewardDeclared(items: [
            RewardItemDeclared(
                key: 'HERB_COMMON', quantity: 1, chancePct: 50),
          ]),
          player(),
        );
        if (resolved.items.isNotEmpty) hits++;
      }
      expect(hits, inInclusiveRange(30, 70));
    });
  });

  group('RewardResolveService — achievements/recipes/reputação', () {
    test('propaga listas intactas pro resolved', () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      final resolved = await resolver.resolve(
        const RewardDeclared(
          xp: 100,
          achievementsToCheck: ['ACH_FIRST_CRAFT', 'ACH_SECRET'],
          recipesToUnlock: ['RECIPE_ADVANCED_POTION'],
          factionReputation:
              FactionReputationDelta(factionId: 'noryan', delta: 3),
        ),
        player(),
      );

      expect(resolved.achievementsToCheck,
          ['ACH_FIRST_CRAFT', 'ACH_SECRET']);
      expect(resolved.recipesToUnlock, ['RECIPE_ADVANCED_POTION']);
      expect(resolved.factionId, 'noryan');
      expect(resolved.factionReputationDelta, 3);
    });

    test('sem reputação em declared → factionId/Delta null em resolved',
        () async {
      final resolver = RewardResolveService(
          _FakeItemsCatalog(db, const []),
          random: Random(1));

      final resolved = await resolver.resolve(
        const RewardDeclared(xp: 100),
        player(),
      );
      expect(resolved.factionId, isNull);
      expect(resolved.factionReputationDelta, isNull);
    });
  });

  group('RewardResolveService — determinismo com Random(seed)', () {
    test('mesma seed produz mesma sequência de sorteios', () async {
      final pool = [
        makeItem(key: 'A', type: 'rune', rank: 'e'),
        makeItem(key: 'B', type: 'rune', rank: 'e'),
        makeItem(key: 'C', type: 'rune', rank: 'e'),
      ];
      final r1 = RewardResolveService(_FakeItemsCatalog(db, pool),
          random: Random(123));
      final r2 = RewardResolveService(_FakeItemsCatalog(db, pool),
          random: Random(123));

      final picks1 = <String>[];
      final picks2 = <String>[];
      for (var i = 0; i < 10; i++) {
        final res1 = await r1.resolve(
          const RewardDeclared(items: [
            RewardItemDeclared(key: 'RUNE_RANDOM_E', quantity: 1),
          ]),
          player(),
        );
        final res2 = await r2.resolve(
          const RewardDeclared(items: [
            RewardItemDeclared(key: 'RUNE_RANDOM_E', quantity: 1),
          ]),
          player(),
        );
        picks1.add(res1.items.single.key);
        picks2.add(res2.items.single.key);
      }
      expect(picks1, picks2);
    });
  });
}
