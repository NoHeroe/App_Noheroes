import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/services/weekly_faction_validator.dart';

/// FATIA B1/B4 — smoke + D13 (teste matemático) do catálogo
/// `missions_faction_weekly.json`.
///
/// D13 (dívida catalogada): cada target de sub-task de contagem deve
/// caber no MÁXIMO TEÓRICO semanal do seu sub_type, dado o modelo fixo
/// de diárias (1 físico + 1 mental + 1 espiritual/dia = 3 dailies/dia).
/// Em 7 dias: dailies quaisquer 21; por pilar 7; dias perfeitos/sem-
/// partial 7; diário 7; streak 7. `gold_earned` (BASE rank E, escalado
/// no assign), `individual_completed` e `equipment_improved` NÃO têm cap
/// de contagem — fora do D13.
///
/// FATIA B4: 5 variantes por facção (40 missões); SEM `rank`/`reward` no
/// JSON (reward vem da curva por guild-rank no assign).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const maxAny = 21;
  const maxPerPillar = 7;
  const maxDiary = 7;
  const maxPerfectDay = 7;
  const maxNoPartial = 7;
  const maxStreak = 7;

  const expectedFactions = {
    'moon_clan',
    'sun_clan',
    'renegades',
    'new_order',
    'black_legion',
    'trinity',
    'error',
    'guild',
  };

  late Map<String, dynamic> catalog;

  setUpAll(() async {
    final raw = await rootBundle
        .loadString('assets/data/missions_faction_weekly.json');
    catalog = jsonDecode(raw) as Map<String, dynamic>;
  });

  Iterable<MapEntry<String, dynamic>> factionEntries() =>
      catalog.entries.where((e) => !e.key.startsWith('_'));

  Iterable<Map<String, dynamic>> allMissions() sync* {
    for (final e in factionEntries()) {
      for (final m in (e.value as List)) {
        yield (m as Map).cast<String, dynamic>();
      }
    }
  }

  test('catálogo cobre as 8 facções, 5 variantes cada (40 missões)', () {
    expect(factionEntries().map((e) => e.key).toSet(), expectedFactions);
    for (final e in factionEntries()) {
      expect((e.value as List).length, 5,
          reason: '${e.key} deveria ter 5 variantes semanais');
    }
    expect(allMissions().length, 40);
  });

  test('ids são únicos', () {
    final ids = allMissions().map((m) => m['id'] as String).toList();
    expect(ids.toSet().length, ids.length, reason: 'ids duplicados');
  });

  test('toda missão tem id/title/description e sub_tasks com label+target '
      '(SEM rank/reward — vêm do assign)', () {
    for (final m in allMissions()) {
      expect(m['id'], isA<String>());
      expect(m['title'], isA<String>(), reason: '${m['id']}: sem title');
      expect(m['description'], isA<String>(),
          reason: '${m['id']}: sem description');
      expect(m.containsKey('rank'), isFalse,
          reason: '${m['id']}: rank não deve estar no JSON (B4)');
      expect(m.containsKey('reward'), isFalse,
          reason: '${m['id']}: reward não deve estar no JSON (B4)');
      final subs = m['sub_tasks'] as List;
      expect(subs, isNotEmpty);
      for (final s in subs) {
        expect(s['label'], isA<String>(),
            reason: '${m['id']}: sub-task sem label');
        expect(s['target'], isA<int>(),
            reason: '${m['id']}: sub-task sem target int');
      }
    }
  });

  test('todos os sub_type existem em WeeklyFactionSubTaskTypes.all', () {
    final unknown = <String>[];
    for (final m in allMissions()) {
      for (final s in (m['sub_tasks'] as List)) {
        final type = s['sub_type'] as String?;
        if (type == null || !WeeklyFactionSubTaskTypes.all.contains(type)) {
          unknown.add('${m['id']}: $type');
        }
      }
    }
    expect(unknown, isEmpty,
        reason: 'sub_types não reconhecidos:\n${unknown.join("\n")}');
  });

  test('NUNCA usa modalidade=vitalismo como filtro (0/semana — D22)', () {
    final offenders = <String>[];
    for (final m in allMissions()) {
      for (final s in (m['sub_tasks'] as List)) {
        if ((s['params'] as Map?)?['modalidade'] == 'vitalismo') {
          offenders.add('${m['id']}: ${s['label']}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'vitalismo é impossível:\n${offenders.join("\n")}');
  });

  test('D13 — todo target ≤ máximo teórico semanal do seu sub_type', () {
    final violations = <String>[];

    void check(String missionId, String label, bool ok, int target, int cap,
        String kind) {
      if (!ok) {
        violations.add('$missionId · "$label" · $kind '
            'target=$target > cap=$cap');
      }
    }

    for (final m in allMissions()) {
      final id = m['id'] as String;
      for (final raw in (m['sub_tasks'] as List)) {
        final s = (raw as Map).cast<String, dynamic>();
        final type = s['sub_type'] as String;
        final target = s['target'] as int;
        final label = (s['label'] as String?) ?? type;
        final modalidade = (s['params'] as Map?)?['modalidade'] as String?;

        switch (type) {
          case WeeklyFactionSubTaskTypes.modalityCountWindow:
            if (modalidade == null) {
              check(id, label, target <= maxAny, target, maxAny, 'any');
            } else {
              check(id, label, target <= maxPerPillar, target, maxPerPillar,
                  'pilar:$modalidade');
            }
            break;
          case WeeklyFactionSubTaskTypes.diaryEntryWindow:
            check(id, label, target <= maxDiary, target, maxDiary, 'diary');
            break;
          case WeeklyFactionSubTaskTypes.fullPerfectDayWindow:
            check(id, label, target <= maxPerfectDay, target, maxPerfectDay,
                'perfect_day');
            break;
          case WeeklyFactionSubTaskTypes.noPartialDayWindow:
            check(id, label, target <= maxNoPartial, target, maxNoPartial,
                'no_partial');
            break;
          case WeeklyFactionSubTaskTypes.streakMinimum:
            check(id, label, target <= maxStreak, target, maxStreak, 'streak');
            break;
          // gold_earned / gold_balance / individual_completed /
          // equipment_improved: sem cap de contagem — fora do D13.
          default:
            break;
        }
      }
    }

    expect(violations, isEmpty,
        reason: 'targets matematicamente inviáveis (D24-class):\n'
            '${violations.join("\n")}');
  });
}
