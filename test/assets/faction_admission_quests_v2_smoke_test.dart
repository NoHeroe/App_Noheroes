import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/services/faction_admission_sub_task_types.dart';

/// Sprint 3.4 Etapa B (Sub-Etapa B.1) — smoke do catálogo
/// `faction_admission_quests_v2.json`.
///
/// Cobre o pattern preventivo da lição 2026-05-01 (cache listeners
/// cobertura completa): garantimos que cada `sub_type` referenciado
/// no JSON está em `FactionAdmissionSubTaskTypes.all`. Caso contrário,
/// validator silenciosamente cairia em `StateError` em produção
/// (default do switch) e a sub-task viraria zumbi.
///
/// Distribuição confirmada pelo CEO:
///   guild=2 / moon=3 / sun=3 / renegades=3 / new_order=3 /
///   black_legion=4 / trinity=4 / error=5 = 27 missões
///   sub-tasks: 4+7+7+7+9+12+11+14 = 71
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> catalog;

  setUpAll(() async {
    final raw = await rootBundle
        .loadString('assets/data/faction_admission_quests_v2.json');
    catalog = jsonDecode(raw) as Map<String, dynamic>;
  });

  test('catálogo tem entries pra todas as 8 facções esperadas', () {
    const expectedFactions = {
      'guild',
      'moon_clan',
      'sun_clan',
      'renegades',
      'new_order',
      'black_legion',
      'trinity',
      'error',
    };
    final actual = catalog.keys
        .where((k) => !k.startsWith('_'))
        .toSet();
    expect(actual, expectedFactions);
  });

  test('distribuição de missões por facção bate com plan-first', () {
    const expectedCounts = {
      'guild': 2,
      'moon_clan': 3,
      'sun_clan': 3,
      'renegades': 3,
      'new_order': 3,
      'black_legion': 4,
      'trinity': 4,
      'error': 5,
    };
    for (final entry in expectedCounts.entries) {
      final missions = catalog[entry.key] as List;
      expect(missions.length, entry.value,
          reason: '${entry.key} deveria ter ${entry.value} missões');
    }
  });

  test('total de sub-tasks bate com plan-first (71)', () {
    var total = 0;
    for (final factionKey in catalog.keys) {
      if (factionKey.startsWith('_')) continue;
      final missions = catalog[factionKey] as List;
      for (final m in missions) {
        total += (m['sub_tasks'] as List).length;
      }
    }
    expect(total, 71);
  });

  test('todos os sub_type referenciados existem em '
      'FactionAdmissionSubTaskTypes.all', () {
    final unknown = <String>[];
    for (final factionKey in catalog.keys) {
      if (factionKey.startsWith('_')) continue;
      final missions = catalog[factionKey] as List;
      for (final m in missions) {
        final subs = m['sub_tasks'] as List;
        for (final s in subs) {
          final type = s['sub_type'] as String?;
          if (type == null ||
              !FactionAdmissionSubTaskTypes.all.contains(type)) {
            unknown.add('$factionKey/${m['id']}: $type');
          }
        }
      }
    }
    expect(unknown, isEmpty,
        reason: 'sub_types não reconhecidos:\n${unknown.join("\n")}');
  });

  test('toda missão tem id, title, rank, sub_tasks com label', () {
    for (final factionKey in catalog.keys) {
      if (factionKey.startsWith('_')) continue;
      final missions = catalog[factionKey] as List;
      for (final m in missions) {
        expect(m['id'], isA<String>(), reason: '$factionKey: missão sem id');
        expect(m['title'], isA<String>(),
            reason: '${m['id']}: sem title');
        expect(m['rank'], isA<String>(),
            reason: '${m['id']}: sem rank');
        for (final s in (m['sub_tasks'] as List)) {
          expect(s['label'], isA<String>(),
              reason: '${m['id']}: sub-task sem label');
          expect(s['target'], isA<int>(),
              reason: '${m['id']}: sub-task sem target int');
        }
      }
    }
  });

  test('zero_category_window sempre tem params.modalidade obrigatório',
      () {
    for (final factionKey in catalog.keys) {
      if (factionKey.startsWith('_')) continue;
      final missions = catalog[factionKey] as List;
      for (final m in missions) {
        for (final s in (m['sub_tasks'] as List)) {
          if (s['sub_type'] ==
              FactionAdmissionSubTaskTypes.zeroCategoryWindow) {
            final params = s['params'] as Map?;
            expect(params, isNotNull,
                reason: '${m['id']}: zero_category sem params');
            expect(params!['modalidade'], isA<String>(),
                reason: '${m['id']}: zero_category sem modalidade');
          }
        }
      }
    }
  });

  test('respect_snapshot_rank só aparece em sub-tasks de rank D+', () {
    // Sanidade conceitual — não é constraint estrita, mas detectaria
    // configs sem sentido (ex: rank E exigir snapshot rank D).
    for (final factionKey in catalog.keys) {
      if (factionKey.startsWith('_')) continue;
      final missions = catalog[factionKey] as List;
      for (final m in missions) {
        final missionRank = m['rank'] as String;
        for (final s in (m['sub_tasks'] as List)) {
          final params = s['params'] as Map?;
          if (params?['respect_snapshot_rank'] == true) {
            expect(missionRank, isNot('E'),
                reason: '${m['id']}: rank E não deveria usar '
                    'respect_snapshot_rank (rank E é rank-floor)');
          }
        }
      }
    }
  });
}
