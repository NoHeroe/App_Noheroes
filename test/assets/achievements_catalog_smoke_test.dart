import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/models/achievement_definition.dart';
import 'package:noheroes_app/domain/services/achievement_trigger_types.dart';

/// Sprint 3.3 Etapa 2.2 — smoke tests do catálogo `assets/data/achievements.json`.
///
/// Lê o arquivo do disco (não via `rootBundle`) pra rodar em test runner
/// puro Dart sem depender de bundle de Flutter assets. A resolução de
/// `reward_tier` (feita no `AchievementsService._doLoad`) é replicada
/// aqui em um helper local mínimo — assim cada conquista passa pelo
/// mesmo `AchievementDefinition.fromJson` que o runtime usa.
///
/// Cobertura:
/// - 85 entries presentes
/// - Todas as keys são únicas
/// - 8 conquistas `is_secret: true` (todas em categoria `secret`)
/// - 2 conquistas `disabled: true` (LOBO + VIDENTE — shell)
/// - Distribuição por categoria bate com spec da etapa
/// - Cada trigger é parseável (não lança em `fromJson`)
/// - Triggers com `params.sub_task_key` referenciam keys válidas das
///   sub-tarefas declaradas em `daily_pool_*.json`
/// - `reward_tier` referenciados existem em `tier_definitions`
void main() {
  late Map<String, dynamic> root;
  late List<Map<String, dynamic>> entries;
  late Map<String, Map<String, dynamic>> tierDefs;

  setUpAll(() {
    final file = File('assets/data/achievements.json');
    expect(file.existsSync(), isTrue,
        reason: 'achievements.json deve existir em assets/data/');
    final raw = file.readAsStringSync();
    final decoded = jsonDecode(raw);
    expect(decoded, isA<Map<String, dynamic>>());
    root = decoded as Map<String, dynamic>;

    final tdRaw = root['tier_definitions'] as Map<String, dynamic>;
    tierDefs = {
      for (final e in tdRaw.entries) e.key: e.value as Map<String, dynamic>,
    };

    entries = (root['achievements'] as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  });

  test('catálogo tem 85 entries', () {
    expect(entries.length, 85);
  });

  test('todas as keys são únicas', () {
    final keys = entries.map((e) => e['key'] as String).toList();
    final unique = keys.toSet();
    expect(unique.length, keys.length,
        reason: 'duplicate keys: ${keys.length - unique.length}');
  });

  test('8 conquistas com is_secret=true (todas em categoria "secret")', () {
    final secrets =
        entries.where((e) => (e['is_secret'] as bool?) == true).toList();
    expect(secrets.length, 8);
    for (final s in secrets) {
      expect(s['category'], 'secret', reason: 'key=${s['key']}');
    }
  });

  test('2 conquistas com disabled=true (apenas LOBO + VIDENTE)', () {
    final disabled =
        entries.where((e) => (e['disabled'] as bool?) == true).toList();
    expect(disabled.length, 2);
    final keys = disabled.map((e) => e['key'] as String).toSet();
    expect(keys, {'SECRET_LOBO_SOLITARIO', 'SECRET_QUEDA_DO_VIDENTE'});
  });

  test('distribuição por categoria bate com spec', () {
    final byCategory = <String, int>{};
    for (final e in entries) {
      final cat = e['category'] as String;
      byCategory[cat] = (byCategory[cat] ?? 0) + 1;
    }
    expect(byCategory, {
      'iniciais': 10,
      'volume': 8,
      'streak': 6,
      'best_streak': 5,
      'perfect': 8,
      'super_perfect': 6,
      'falhas': 6,
      'no_fail_streak': 6,
      'subtask_volume_indiv': 6,
      'total_subtask': 2,
      'janelas_temporais': 5,
      'fim_de_semana': 3,
      'pilar_balance': 3,
      'active_days': 1,
      'speedrun': 2,
      'secret': 8,
    });
    // Soma sanity.
    expect(byCategory.values.fold<int>(0, (a, b) => a + b), 85);
  });

  test('todos reward_tier referenciados existem em tier_definitions', () {
    for (final e in entries) {
      final tier = e['reward_tier'];
      if (tier is String) {
        expect(tierDefs.containsKey(tier), isTrue,
            reason:
                "tier '$tier' referenciado por '${e['key']}' não existe em "
                'tier_definitions');
      }
    }
  });

  test('todas as conquistas são parseáveis via AchievementDefinition.fromJson',
      () {
    // Replica a resolução de tier que o `AchievementsService._doLoad` faz.
    Map<String, dynamic> resolveTier(Map<String, dynamic> entry) {
      if (entry.containsKey('reward')) return entry;
      Map<String, dynamic>? tierMap;
      if (entry.containsKey('reward_tier_custom')) {
        tierMap = entry['reward_tier_custom'] as Map<String, dynamic>;
      } else if (entry.containsKey('reward_tier')) {
        tierMap = tierDefs[entry['reward_tier'] as String];
      }
      if (tierMap == null) return entry;
      final items = <Map<String, dynamic>>[];
      final bs = (tierMap['baus_secretos'] as int?) ?? 0;
      if (bs > 0) {
        items.add({'key': 'CHEST_SECRET', 'quantity': bs, 'chance_pct': 100});
      }
      final bd = (tierMap['baus_derrotado'] as int?) ?? 0;
      if (bd > 0) {
        items.add({'key': 'CHEST_DEFEATED', 'quantity': bd, 'chance_pct': 100});
      }
      final reward = <String, dynamic>{
        'xp': (tierMap['xp'] as int?) ?? 0,
        'gold': (tierMap['gold'] as int?) ?? 0,
        'gems': (tierMap['gems'] as int?) ?? 0,
        if (items.isNotEmpty) 'items': items,
      };
      return {...entry, 'reward': reward};
    }

    for (final e in entries) {
      final processed = resolveTier(e);
      expect(() => AchievementDefinition.fromJson(processed), returnsNormally,
          reason:
              "AchievementDefinition.fromJson lançou pra '${e['key']}'");
    }
  });

  test('triggers daily com sub_task_key referenciam keys válidas', () {
    // Carrega sub_task_keys de cada modalidade.
    final allSubTaskKeys = <String>{};
    for (final modPath in const [
      'assets/data/daily_pool_fisico.json',
      'assets/data/daily_pool_mental.json',
      'assets/data/daily_pool_espiritual.json',
      'assets/data/daily_pool_vitalismo.json',
    ]) {
      final f = File(modPath);
      if (!f.existsSync()) continue;
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final list = m['sub_tarefas'] as List?;
      if (list == null) continue;
      for (final sub in list) {
        final k = (sub as Map<String, dynamic>)['key'];
        if (k is String) allSubTaskKeys.add(k);
      }
    }

    for (final e in entries) {
      final trig = e['trigger'] as Map<String, dynamic>;
      if (trig['type'] == AchievementTriggerTypes.dailySubtaskVolume) {
        final params = trig['params'] as Map<String, dynamic>?;
        final key = params?['sub_task_key'];
        expect(key, isA<String>(),
            reason: '${e['key']}: sub_task_key ausente em params');
        expect(allSubTaskKeys.contains(key), isTrue,
            reason: '${e['key']}: sub_task_key "$key" não existe em '
                'nenhum daily_pool_*.json');
      }
    }
  });

  test(
      'triggers conhecidos (allDaily ∪ allEvents ∪ {meta, threshold_stat, '
      'event_count}) cobrem TODOS os triggers ativos exceto trigger '
      'reservado pra Sprint 3.8 (que é shell)', () {
    final knownTriggers = {
      ...AchievementTriggerTypes.allDaily,
      ...AchievementTriggerTypes.allEvents,
      'meta',
      'threshold_stat',
      'event_count',
    };
    final unknownActive = <String>[];
    for (final e in entries) {
      final disabled = (e['disabled'] as bool?) ?? false;
      if (disabled) continue;
      final type = (e['trigger'] as Map)['type'] as String;
      if (!knownTriggers.contains(type)) {
        unknownActive.add('${e['key']}: $type');
      }
    }
    expect(unknownActive, isEmpty,
        reason:
            'conquistas ativas com trigger desconhecido (não há fail-safe '
            'silencioso pra essas — corrigir ou marcar disabled=true): '
            '$unknownActive');
  });

  test('disabled secrets têm shell_reason documentando motivo', () {
    final disabled =
        entries.where((e) => (e['disabled'] as bool?) == true).toList();
    for (final e in disabled) {
      expect(e['shell_reason'], isA<String>(),
          reason:
              'shell achievement "${e['key']}" deve ter shell_reason '
              'explicando por que está disabled');
      expect((e['shell_reason'] as String).isNotEmpty, isTrue,
          reason: 'shell_reason vazio em "${e['key']}"');
    }
  });

  test('CHEST_SECRET e CHEST_DEFEATED existem em items_unified.json '
      '(referenciados via baus_*)', () {
    final f = File('assets/data/items_unified.json');
    expect(f.existsSync(), isTrue);
    final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final items = (m['items'] as List).cast<Map<String, dynamic>>();
    final keys = items.map((i) => i['key'] as String).toSet();
    expect(keys.contains('CHEST_SECRET'), isTrue);
    expect(keys.contains('CHEST_DEFEATED'), isTrue,
        reason: 'CHEST_DEFEATED é foundation pra reward_tier *_falha — '
            'tem que existir no catálogo');
  });

  test('todas as 8 secrets têm reward_tier_custom (não tier ref)', () {
    final secrets =
        entries.where((e) => (e['is_secret'] as bool?) == true);
    for (final s in secrets) {
      expect(s.containsKey('reward_tier_custom'), isTrue,
          reason: '${s['key']}: secret sem reward_tier_custom');
      expect(s.containsKey('reward_tier'), isFalse,
          reason: '${s['key']}: secret usa tier ref em vez de custom');
    }
  });
}
