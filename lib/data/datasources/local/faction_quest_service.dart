import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../../domain/models/active_faction_quest.dart';
import '../../../domain/repositories/active_faction_quests_repository.dart';

/// Sprint 3.1 Bloco 7b — reescrita do FactionQuestService legado.
///
/// Antes (sprint 2.x): `assignWeeklyQuest` tinha race condition (bug 3
/// da Sprint 2.3) — 2 invalidations concorrentes inseriam 2 rows
/// duplicadas com mesma `(player_id, faction_id, week_start)`.
///
/// Agora delega pro [ActiveFactionQuestsRepository.upsertAtomic] do
/// Bloco 4, que envolve o assignment em `db.transaction` + catch de
/// UNIQUE violation + fallback de retornar os ids existentes. Bug 3
/// fechado pelo schema 24 (UNIQUE constraint) + transação.
///
/// Service fica com responsabilidade única: sortear quest do pool JSON
/// por facção e delegar o ledger+progress row pro repo.
class FactionQuestService {
  final ActiveFactionQuestsRepository _repo;
  final Random _random;

  FactionQuestService(this._repo, {Random? random})
      : _random = random ?? Random();

  /// yyyy-MM-dd da segunda-feira desta semana (âncora do reset semanal).
  static String weekStart([DateTime? ref]) {
    final now = ref ?? DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final y = monday.year.toString().padLeft(4, '0');
    final m = monday.month.toString().padLeft(2, '0');
    final d = monday.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Duration timeUntilNextWeek() {
    final now = DateTime.now();
    final nextMonday = now.add(Duration(days: 8 - now.weekday));
    final reset = DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
    return reset.difference(now);
  }

  /// Retorna o ledger da quest ativa desta semana (se já foi assignada),
  /// ou null caso contrário.
  Future<ActiveFactionQuest?> getActiveQuest(
    int playerId,
    String factionId,
  ) async {
    return _repo.findActiveFor(playerId, factionId, weekStart());
  }

  /// Garante que existe uma weekly quest pra (player, faction, semana
  /// atual). Idempotente e race-safe por design do repo (Bloco 4).
  ///
  /// Retorna o ledger — tanto recém-criado quanto existente.
  Future<ActiveFactionQuest?> ensureWeeklyQuest(
    int playerId,
    String factionId, {
    DateTime? now,
  }) async {
    final ws = weekStart(now);

    // Se já existe, retorna sem re-sortear.
    final existing = await _repo.findActiveFor(playerId, factionId, ws);
    if (existing != null) return existing;

    // Sorteia do pool JSON.
    final pool = await _loadPool(factionId);
    if (pool.isEmpty) return null;

    final chosen = pool[_random.nextInt(pool.length)];
    final chosenKey = chosen['key'] as String;
    final chosenXp = (chosen['xp'] as int?) ?? 0;
    final chosenGold = (chosen['gold'] as int?) ?? 0;

    // Cria ledger + progress row na mesma transação.
    await _repo.upsertAtomic(
      playerId: playerId,
      factionId: factionId,
      missionKey: chosenKey,
      weekStart: ws,
      progressSeedJson: {
        'modality': 'internal',
        'rank': 'e',
        'target_value': 1,
        'reward': {'xp': chosenXp, 'gold': chosenGold},
        'meta_json': '{}',
      },
    );
    return _repo.findActiveFor(playerId, factionId, ws);
  }

  Future<List<Map<String, dynamic>>> _loadPool(String factionId) async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/faction_quests_weekly.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final poolMap = json['faction_quests'] as Map<String, dynamic>?;
      final pool =
          (poolMap?[factionId] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
      return List<Map<String, dynamic>>.from(pool);
    } catch (_) {
      return const [];
    }
  }
}
