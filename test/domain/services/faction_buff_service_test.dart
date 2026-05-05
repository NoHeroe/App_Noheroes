import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';
import 'package:noheroes_app/domain/models/faction_buff_multipliers.dart';
import 'package:noheroes_app/domain/services/faction_buff_service.dart';

/// Sprint 3.4 Etapa C — testes do FactionBuffService.
///
/// Cobertura:
/// - Player sem facção → neutral
/// - Player com facção mapeada → multipliers do catálogo
/// - debuff_until > now → override 0.7 em xp/gold, atributos = 1.0
/// - getEffectiveAttributes aplica floor (CEO confirmou)
/// - Snapshot inclui pending textuais
/// - faction_type 'pending:X' → neutral (admissão em curso)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FactionBuffService service;
  const playerId = 1;

  // Catálogo controlado pra teste — não depende do JSON real.
  final testCatalog = <String, dynamic>{
    'guild': {
      'applied': {
        'xp_mult': 1.0,
        'gold_mult': 1.0,
        'gems_mult': 1.0,
        'strength_mult': 1.0,
        'dexterity_mult': 1.0,
        'intelligence_mult': 1.0,
        'max_hp_mult': 1.0,
      },
      'pending': [
        {'label': '+5% reputação universal (futuro)'},
      ],
    },
    'new_order': {
      'applied': {
        'xp_mult': 1.10,
        'gold_mult': 1.0,
        'gems_mult': 1.0,
        'strength_mult': 1.0,
        'dexterity_mult': 1.0,
        'intelligence_mult': 1.0,
        'max_hp_mult': 1.10,
      },
      'pending': [
        {'label': '+15% Defesa (futuro)'},
      ],
    },
    'black_legion': {
      'applied': {
        'xp_mult': 1.05,
        'strength_mult': 1.25,
      },
      'pending': [],
    },
  };

  Future<void> seedPlayer({
    String? factionType,
    int strength = 10,
    int dexterity = 10,
    int intelligence = 10,
    int maxHp = 100,
  }) async {
    await db.customStatement(
      "INSERT INTO players (id, email, password_hash, faction_type, strength, "
      "dexterity, intelligence, max_hp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
      [
        playerId,
        'test@test.com',
        'hash',
        factionType,
        strength,
        dexterity,
        intelligence,
        maxHp,
      ],
    );
  }

  Future<void> seedDebuff({required String factionId, required int untilMs}) async {
    await db.customStatement(
      'INSERT INTO player_faction_membership '
      '(player_id, faction_id, joined_at, debuff_until) VALUES (?, ?, ?, ?)',
      [playerId, factionId, DateTime.now().millisecondsSinceEpoch, untilMs],
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = FactionBuffService(db);
    service.debugSetCatalog(testCatalog);
  });

  tearDown(() async {
    await db.close();
  });

  group('FactionBuffService — getActiveMultipliers', () {
    test('player não existe → neutral', () async {
      final m = await service.getActiveMultipliers(99);
      expect(m.xpMult, 1.0);
      expect(m.hasDebuff, isFalse);
    });

    test('faction_type null → neutral', () async {
      await seedPlayer(factionType: null);
      final m = await service.getActiveMultipliers(playerId);
      expect(m.xpMult, 1.0);
      expect(m.strengthMult, 1.0);
    });

    test("faction_type 'none' → neutral", () async {
      await seedPlayer(factionType: 'none');
      final m = await service.getActiveMultipliers(playerId);
      expect(m.xpMult, 1.0);
    });

    test("faction_type 'pending:moon_clan' → neutral (admissão em curso)",
        () async {
      await seedPlayer(factionType: 'pending:moon_clan');
      final m = await service.getActiveMultipliers(playerId);
      expect(m.xpMult, 1.0);
    });

    test('Nova Ordem → xp 1.10, max_hp 1.10, demais 1.0', () async {
      await seedPlayer(factionType: 'new_order');
      final m = await service.getActiveMultipliers(playerId);
      expect(m.xpMult, 1.10);
      expect(m.maxHpMult, 1.10);
      expect(m.goldMult, 1.0);
      expect(m.strengthMult, 1.0);
      expect(m.hasDebuff, isFalse);
    });

    test('Black Legion → xp 1.05, str 1.25 (entries faltantes default 1.0)',
        () async {
      await seedPlayer(factionType: 'black_legion');
      final m = await service.getActiveMultipliers(playerId);
      expect(m.xpMult, 1.05);
      expect(m.strengthMult, 1.25);
      expect(m.dexterityMult, 1.0);
      expect(m.maxHpMult, 1.0);
    });

    test('faction_type fora do catálogo → neutral', () async {
      await seedPlayer(factionType: 'unknown_faction');
      final m = await service.getActiveMultipliers(playerId);
      expect(m.xpMult, 1.0);
    });
  });

  group('FactionBuffService — debuff override', () {
    test('debuff_until > now → xp/gold viram 0.7; atributos PRESERVAM facção',
        () async {
      // Sprint 3.4 Etapa C hotfix #3 (P0-G) — atributos NÃO sofrem
      // debuff. Player Nova Ordem com debuff ativo deve continuar
      // vendo +10% maxHp. Bug original (Etapa C) zerava todos atributos
      // pra 1.0 durante debuff, violando decisão CEO 5.
      await seedPlayer(factionType: 'new_order');
      final until =
          DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
      await seedDebuff(factionId: 'new_order', untilMs: until);

      final m = await service.getActiveMultipliers(playerId);
      expect(m.hasDebuff, isTrue);
      // Override econômico: xp/gold viram 0.7.
      expect(m.xpMult, 0.7);
      expect(m.goldMult, 0.7);
      // Atributos PRESERVAM mults da facção atual (Nova Ordem maxHp 1.10).
      expect(m.maxHpMult, 1.10,
          reason: 'maxHp da facção PRESERVADO durante debuff');
      expect(m.strengthMult, 1.0); // Nova Ordem não tem str_mult
      expect(m.dexterityMult, 1.0);
      expect(m.intelligenceMult, 1.0);
      expect(m.gemsMult, 1.0);
      expect(m.debuffEndsAt, isNotNull);
    });

    test('debuff em Black Legion → xp 0.7 mas str preserva 1.25',
        () async {
      // Black Legion: xp_mult=1.05, strength_mult=1.25. Durante debuff,
      // xp vira 0.7 (override) mas strength preserva 1.25.
      await seedPlayer(factionType: 'black_legion');
      final until =
          DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch;
      await seedDebuff(factionId: 'black_legion', untilMs: until);

      final m = await service.getActiveMultipliers(playerId);
      expect(m.hasDebuff, isTrue);
      expect(m.xpMult, 0.7); // override
      expect(m.goldMult, 0.7);
      expect(m.strengthMult, 1.25,
          reason: 'Força preserva mult da facção durante debuff');
    });

    test('debuff_until expirado (no passado) → mults da facção normais',
        () async {
      await seedPlayer(factionType: 'new_order');
      final past = DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch;
      await seedDebuff(factionId: 'new_order', untilMs: past);

      final m = await service.getActiveMultipliers(playerId);
      expect(m.hasDebuff, isFalse);
      expect(m.xpMult, 1.10); // buff Nova Ordem volta
    });

    test('debuff em facção legacy + faction_type=none → mults do debuff',
        () async {
      // Player saiu de facção; faction_type='none' mas membership row tem
      // debuff_until > now. Debuff continua aplicando.
      await seedPlayer(factionType: 'none');
      final until =
          DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch;
      await seedDebuff(factionId: 'moon_clan', untilMs: until);

      final m = await service.getActiveMultipliers(playerId);
      expect(m.hasDebuff, isTrue);
      expect(m.xpMult, 0.7);
    });
  });

  group('FactionBuffService — getEffectiveAttributes', () {
    test('Nova Ordem maxHp 100 × 1.10 = 110', () async {
      await seedPlayer(factionType: 'new_order', maxHp: 100);
      final eff = await service.getEffectiveAttributes(playerId);
      expect(eff.maxHpBase, 100);
      expect(eff.maxHpEffective, 110);
      expect(eff.maxHpDelta, 10);
    });

    test('Black Legion str 12 × 1.25 = 15.0 → floor = 15', () async {
      await seedPlayer(factionType: 'black_legion', strength: 12);
      final eff = await service.getEffectiveAttributes(playerId);
      expect(eff.strengthBase, 12);
      expect(eff.strengthEffective, 15);
    });

    test('floor (não round) — str 11 × 1.10 = 12.1 → 12, não 12', () async {
      // 11 × 1.10 = 12.1. Floor = 12. Round seria 12 também — pega caso
      // mais elucidativo.
      await seedPlayer(factionType: 'black_legion', strength: 11);
      // black_legion str = 1.25 → 11 × 1.25 = 13.75 → floor = 13
      final eff = await service.getEffectiveAttributes(playerId);
      expect(eff.strengthBase, 11);
      expect(eff.strengthEffective, 13,
          reason: 'floor(11 × 1.25) = floor(13.75) = 13');
    });

    test('debuff ativo → atributos NÃO sofrem (mantém buff da facção)',
        () async {
      // Sprint 3.4 Etapa C hotfix #3 (P0-G) — atributos preservam
      // mult da facção durante debuff. Black Legion str_mult=1.25.
      // strength 20 × 1.25 = floor(25) = 25 (mesmo durante debuff).
      await seedPlayer(factionType: 'black_legion', strength: 20);
      final until =
          DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch;
      await seedDebuff(factionId: 'black_legion', untilMs: until);

      final eff = await service.getEffectiveAttributes(playerId);
      expect(eff.strengthBase, 20);
      expect(eff.strengthEffective, 25,
          reason: 'Força preserva +25% Black Legion mesmo durante debuff');
    });

    test('player sem facção → effective = base (sem buff)', () async {
      await seedPlayer(factionType: 'none', strength: 8);
      final eff = await service.getEffectiveAttributes(playerId);
      expect(eff.strengthEffective, 8);
      expect(eff.strengthDelta, 0);
    });
  });

  group('FactionBuffService — getBuffSnapshot', () {
    test('Nova Ordem: applied tem +10% XP universal e +10% maxHp', () async {
      await seedPlayer(factionType: 'new_order');
      final snap = await service.getBuffSnapshot(playerId);
      expect(snap.applied.length, 2);
      expect(snap.applied.first.label, contains('XP universal'));
      expect(snap.applied.first.label, contains('+10%'));
      expect(snap.applied[1].label, contains('Vida máxima'));
    });

    test('Nova Ordem: pending vem do catálogo', () async {
      await seedPlayer(factionType: 'new_order');
      final snap = await service.getBuffSnapshot(playerId);
      expect(snap.pending.length, 1);
      expect(snap.pending.first.label, contains('Defesa'));
    });

    test('Guild (todos 1.0) → applied vazio, pending preserva', () async {
      await seedPlayer(factionType: 'guild');
      final snap = await service.getBuffSnapshot(playerId);
      expect(snap.applied, isEmpty);
      expect(snap.pending.length, 1);
    });

    test('Player sem facção → applied + pending vazios', () async {
      await seedPlayer(factionType: 'none');
      final snap = await service.getBuffSnapshot(playerId);
      expect(snap.applied, isEmpty);
      expect(snap.pending, isEmpty);
    });

    test('Debuff ativo → applied econômicos OMITIDOS, atributos preservados',
        () async {
      // Sprint 3.4 Etapa C hotfix #3 (P0-G) — durante debuff:
      // xp/gold viram 0.7 (override econômico). _renderAppliedEntries
      // pula econômicos via `if (!hasDebuff)` (econômicos não aparecem
      // como bônus). Atributos (maxHp 1.10) PRESERVAM mults da facção
      // → aparecem em applied.
      await seedPlayer(factionType: 'new_order');
      final until =
          DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch;
      await seedDebuff(factionId: 'new_order', untilMs: until);

      final snap = await service.getBuffSnapshot(playerId);
      expect(snap.multipliers.hasDebuff, isTrue);
      // Econômicos pulados durante debuff; maxHp 1.10 (atributo)
      // continua em applied.
      expect(snap.applied.length, 1,
          reason: 'maxHp preservado em applied durante debuff');
      expect(snap.applied.first.label, contains('Vida máxima'));
    });
  });

  group('FactionBuffMultipliers — model', () {
    test('neutral é todo 1.0 + sem debuff', () {
      const n = FactionBuffMultipliers.neutral;
      expect(n.xpMult, 1.0);
      expect(n.goldMult, 1.0);
      expect(n.gemsMult, 1.0);
      expect(n.strengthMult, 1.0);
      expect(n.dexterityMult, 1.0);
      expect(n.intelligenceMult, 1.0);
      expect(n.maxHpMult, 1.0);
      expect(n.hasDebuff, isFalse);
      expect(n.hasAnyEconomicBuff, isFalse);
      expect(n.hasAnyAttributeBuff, isFalse);
    });
  });
}
