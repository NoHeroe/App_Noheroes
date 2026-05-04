import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/services.dart' show rootBundle;

import '../../data/database/app_database.dart';
import '../models/faction_buff_multipliers.dart';

/// Sprint 3.4 Etapa C — buffs de facção em runtime.
///
/// Stateless. Lê catálogo de `assets/data/faction_buffs.json` (lazy, 1×
/// por instância) + state do player (`players.faction_type` +
/// `player_faction_membership.debuff_until`) e produz multipliers
/// efetivos.
///
/// **Aplicação dos multipliers:**
/// - **Econômicos** (xp/gold/gems) → `RewardGrantService` aplica antes
///   do clamp SOULSLIKE.
/// - **`xpMult` universal** → também aplica em
///   `FactionReputationService.adjustReputation` (mesma porcentagem).
/// - **Atributos** (str/dex/int/maxHp) → `getEffectiveAttributes`
///   computes virtualmente; UI/Unity engine consomem `EffectiveAttributes`
///   sem mexer no DB.
///
/// **Debuff de saída** (`debuffUntil > now` em
/// `player_faction_membership`):
/// - Override completo: `xpMult = 0.7`, `goldMult = 0.7`.
/// - `gemsMult` e atributos = `1.0` (não afetados pelo debuff).
class FactionBuffService {
  final AppDatabase _db;

  Map<String, dynamic>? _catalogCache;
  Future<Map<String, dynamic>>? _loadFuture;

  FactionBuffService(this._db);

  /// Path do catálogo. Override em testes via construtor secundário.
  static const _catalogAsset = 'assets/data/faction_buffs.json';

  Future<Map<String, dynamic>> _loadCatalog() {
    if (_catalogCache != null) return Future.value(_catalogCache!);
    return _loadFuture ??= rootBundle.loadString(_catalogAsset).then((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      _catalogCache = m;
      return m;
    });
  }

  /// Override para testes — injeta JSON sem precisar do bundle.
  void debugSetCatalog(Map<String, dynamic> catalog) {
    _catalogCache = catalog;
    _loadFuture = null;
  }

  /// Retorna multipliers efetivos pro player.
  ///
  /// Combina:
  /// 1. Buffs `applied` da facção atual (`players.faction_type`).
  /// 2. Override de debuff se `debuff_until > now`.
  ///
  /// Retorna `FactionBuffMultipliers.neutral` se:
  /// - Player não existe
  /// - `faction_type` é `null`/`'none'`/vazio
  /// - `faction_type` começa com `'pending:'` (admissão em curso — sem buff
  ///   até admissão completar)
  /// - Catálogo não tem entry pra essa facção
  Future<FactionBuffMultipliers> getActiveMultipliers(int playerId) async {
    final playerRows = await _db.customSelect(
      'SELECT faction_type FROM players WHERE id = ? LIMIT 1',
      variables: [Variable.withInt(playerId)],
    ).get();
    if (playerRows.isEmpty) return FactionBuffMultipliers.neutral;

    final factionType = playerRows.first.read<String?>('faction_type');
    if (factionType == null ||
        factionType.isEmpty ||
        factionType == 'none' ||
        factionType.startsWith('pending:')) {
      return _withDebuffIfActive(
          playerId, FactionBuffMultipliers.neutral, factionType);
    }

    final catalog = await _loadCatalog();
    final entry = catalog[factionType] as Map<String, dynamic>?;
    if (entry == null) {
      return _withDebuffIfActive(
          playerId, FactionBuffMultipliers.neutral, factionType);
    }
    final applied = (entry['applied'] as Map<String, dynamic>?) ?? const {};

    final base = FactionBuffMultipliers(
      xpMult: _readMult(applied, 'xp_mult'),
      goldMult: _readMult(applied, 'gold_mult'),
      gemsMult: _readMult(applied, 'gems_mult'),
      strengthMult: _readMult(applied, 'strength_mult'),
      dexterityMult: _readMult(applied, 'dexterity_mult'),
      intelligenceMult: _readMult(applied, 'intelligence_mult'),
      maxHpMult: _readMult(applied, 'max_hp_mult'),
      hasDebuff: false,
      debuffEndsAt: null,
    );

    return _withDebuffIfActive(playerId, base, factionType);
  }

  /// Aplica debuff de saída se `debuff_until > now`. Override completo:
  /// xpMult/goldMult viram 0.7, demais voltam pra 1.0 (debuff só afeta
  /// economia/progressão).
  ///
  /// Lê `player_faction_membership` da PRÓPRIA facção atual quando
  /// `factionType` aponta pra uma. Se `factionType` é `none` ou null,
  /// busca a row mais recente com `debuff_until > now` (player saiu de
  /// uma facção e ainda está debuffado — caso normal).
  Future<FactionBuffMultipliers> _withDebuffIfActive(
    int playerId,
    FactionBuffMultipliers base,
    String? factionType,
  ) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Busca debuff ativo em qualquer membership do player.
    final rows = await _db.customSelect(
      'SELECT debuff_until FROM player_faction_membership '
      'WHERE player_id = ? AND debuff_until IS NOT NULL '
      'ORDER BY debuff_until DESC LIMIT 1',
      variables: [Variable.withInt(playerId)],
    ).get();

    if (rows.isEmpty) return base;
    final debuffUntilMs = rows.first.read<int?>('debuff_until');
    if (debuffUntilMs == null || debuffUntilMs <= nowMs) return base;

    // Debuff ATIVO. Override econômico, atributos voltam pra 1.0.
    return FactionBuffMultipliers(
      xpMult: 0.7,
      goldMult: 0.7,
      gemsMult: 1.0,
      strengthMult: 1.0,
      dexterityMult: 1.0,
      intelligenceMult: 1.0,
      maxHpMult: 1.0,
      hasDebuff: true,
      debuffEndsAt: DateTime.fromMillisecondsSinceEpoch(debuffUntilMs),
    );
  }

  double _readMult(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is num) return v.toDouble();
    return 1.0;
  }

  /// Snapshot pra UI/dev panel — applied (runtime) + pending (futuros).
  Future<FactionBuffSnapshot> getBuffSnapshot(int playerId) async {
    final mults = await getActiveMultipliers(playerId);

    final playerRows = await _db.customSelect(
      'SELECT faction_type FROM players WHERE id = ? LIMIT 1',
      variables: [Variable.withInt(playerId)],
    ).get();
    if (playerRows.isEmpty) {
      return FactionBuffSnapshot(
        applied: const [],
        pending: const [],
        multipliers: mults,
      );
    }

    final factionType = playerRows.first.read<String?>('faction_type');
    if (factionType == null ||
        factionType.isEmpty ||
        factionType == 'none' ||
        factionType.startsWith('pending:')) {
      return FactionBuffSnapshot(
        applied: const [],
        pending: const [],
        multipliers: mults,
      );
    }

    final applied = _renderAppliedEntries(mults);

    final catalog = await _loadCatalog();
    final entry = catalog[factionType] as Map<String, dynamic>?;
    final pendingRaw =
        (entry?['pending'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final pending = pendingRaw
        .map((m) => FactionBuffEntry(
              category: 'pending',
              label: (m['label'] as String?) ?? '?',
            ))
        .toList(growable: false);

    return FactionBuffSnapshot(
      applied: applied,
      pending: pending,
      multipliers: mults,
    );
  }

  /// Gera labels dinâmicos baseado nos multipliers > 1.0. Pula 1.0 puros.
  /// Durante debuff, NÃO mostra applied econômicos (vão pro alerta de
  /// debuff na UI). Mantém atributos > 1.0 mesmo durante debuff (não
  /// sofrem debuff).
  List<FactionBuffEntry> _renderAppliedEntries(FactionBuffMultipliers m) {
    final out = <FactionBuffEntry>[];
    if (!m.hasDebuff) {
      if (m.xpMult > 1.0) {
        out.add(FactionBuffEntry(
          category: 'applied',
          label: '+${_pct(m.xpMult)}% XP universal (XP + reputação)',
        ));
      }
      if (m.goldMult > 1.0) {
        out.add(FactionBuffEntry(
          category: 'applied',
          label: '+${_pct(m.goldMult)}% ouro',
        ));
      }
      if (m.gemsMult > 1.0) {
        out.add(FactionBuffEntry(
          category: 'applied',
          label: '+${_pct(m.gemsMult)}% gemas',
        ));
      }
    }
    if (m.strengthMult > 1.0) {
      out.add(FactionBuffEntry(
        category: 'applied',
        label: '+${_pct(m.strengthMult)}% Força',
      ));
    }
    if (m.dexterityMult > 1.0) {
      out.add(FactionBuffEntry(
        category: 'applied',
        label: '+${_pct(m.dexterityMult)}% Destreza',
      ));
    }
    if (m.intelligenceMult > 1.0) {
      out.add(FactionBuffEntry(
        category: 'applied',
        label: '+${_pct(m.intelligenceMult)}% Inteligência',
      ));
    }
    if (m.maxHpMult > 1.0) {
      out.add(FactionBuffEntry(
        category: 'applied',
        label: '+${_pct(m.maxHpMult)}% Vida máxima',
      ));
    }
    return out;
  }

  int _pct(double mult) => ((mult - 1.0) * 100).round();

  /// Sprint 3.4 Etapa C hotfix #1 — preview SEM player (UI de seleção
  /// de facção precisa exibir buffs de cada facção antes do player
  /// escolher). Lê apenas do catálogo, sem `getActiveMultipliers` que
  /// depende de `players.faction_type`. Não considera debuff (não
  /// aplicável quando player ainda não é member).
  Future<({List<String> applied, List<String> pending})>
      previewLabelsForFaction(String factionId) async {
    final catalog = await _loadCatalog();
    final entry = catalog[factionId] as Map<String, dynamic>?;
    if (entry == null) {
      return (applied: const <String>[], pending: const <String>[]);
    }

    final appliedRaw =
        (entry['applied'] as Map<String, dynamic>?) ?? const {};
    final mults = FactionBuffMultipliers(
      xpMult: _readMult(appliedRaw, 'xp_mult'),
      goldMult: _readMult(appliedRaw, 'gold_mult'),
      gemsMult: _readMult(appliedRaw, 'gems_mult'),
      strengthMult: _readMult(appliedRaw, 'strength_mult'),
      dexterityMult: _readMult(appliedRaw, 'dexterity_mult'),
      intelligenceMult: _readMult(appliedRaw, 'intelligence_mult'),
      maxHpMult: _readMult(appliedRaw, 'max_hp_mult'),
      hasDebuff: false,
      debuffEndsAt: null,
    );
    final applied = _renderAppliedEntries(mults)
        .map((e) => e.label)
        .toList(growable: false);

    final pendingRaw =
        (entry['pending'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
    final pending = pendingRaw
        .map((m) => (m['label'] as String?) ?? '?')
        .toList(growable: false);

    return (applied: applied, pending: pending);
  }

  /// Atributos efetivos (base + buff aplicado). Usado pela UI /personagem
  /// e pela engine Unity (lê via DAO/API quando integrado).
  ///
  /// Arredondamento: floor (CEO confirmou — conservador. strength 12 ×
  /// 1.10 = 13.2 → 13).
  Future<EffectiveAttributes> getEffectiveAttributes(int playerId) async {
    final rows = await _db.customSelect(
      'SELECT strength, dexterity, intelligence, max_hp '
      'FROM players WHERE id = ? LIMIT 1',
      variables: [Variable.withInt(playerId)],
    ).get();
    if (rows.isEmpty) return EffectiveAttributes.empty;

    final mults = await getActiveMultipliers(playerId);
    final r = rows.first;
    final s = r.read<int>('strength');
    final d = r.read<int>('dexterity');
    final i = r.read<int>('intelligence');
    final h = r.read<int>('max_hp');

    return EffectiveAttributes(
      strengthBase: s,
      strengthEffective: (s * mults.strengthMult).floor(),
      dexterityBase: d,
      dexterityEffective: (d * mults.dexterityMult).floor(),
      intelligenceBase: i,
      intelligenceEffective: (i * mults.intelligenceMult).floor(),
      maxHpBase: h,
      maxHpEffective: (h * mults.maxHpMult).floor(),
    );
  }
}
