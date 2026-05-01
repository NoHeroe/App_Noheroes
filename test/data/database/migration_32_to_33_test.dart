import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';

/// Sprint 3.3 Etapa 2.1c-δ — migration 32→33 adiciona 2 colunas em
/// `player_daily_mission_stats` (`daily_today_count`,
/// `last_today_count_date`). ZERO mudança em `players.caelum_day` —
/// este teste explicitamente verifica isso (sistema de lore intocado).
///
/// Verificação via PRAGMA `table_info` em DB fresh (Drift `createAll`
/// na inicialização gera schema atual = 33). A correção do
/// `m.addColumn` é coberta indiretamente: se o codegen + tabela não
/// estivessem corretos, o build_runner ou `createAll` falhariam antes
/// deste teste rodar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('schema 33: player_daily_mission_stats tem daily_today_count + '
      'last_today_count_date', () async {
    final cols = await db
        .customSelect("PRAGMA table_info('player_daily_mission_stats')")
        .get();
    final names = cols.map((r) => r.read<String>('name')).toSet();

    expect(names.contains('daily_today_count'), isTrue,
        reason: 'coluna daily_today_count deve existir após migration 33');
    expect(names.contains('last_today_count_date'), isTrue,
        reason:
            'coluna last_today_count_date deve existir após migration 33');

    // Default da nova int col = 0 (Constant(0) na tabela).
    final dailyTodayCountCol =
        cols.firstWhere((r) => r.read<String>('name') == 'daily_today_count');
    expect(dailyTodayCountCol.read<int>('notnull'), 1,
        reason: 'daily_today_count NOT NULL (tem default)');

    // last_today_count_date é nullable (sem default).
    final lastDateCol = cols
        .firstWhere((r) => r.read<String>('name') == 'last_today_count_date');
    expect(lastDateCol.read<int>('notnull'), 0,
        reason: 'last_today_count_date é nullable');
  });

  test('schema 33: caelum_day em players INTOCADO (sistema de lore '
      'paralelo)', () async {
    final cols = await db.customSelect("PRAGMA table_info('players')").get();
    final names = cols.map((r) => r.read<String>('name')).toSet();

    expect(names.contains('caelum_day'), isTrue,
        reason: 'caelum_day deve continuar existindo em players — '
            'sistema de lore narrativa, não tocado pela Etapa 2.1c-δ');

    // ⚠️ Garantia explícita: NENHUMA coluna *today* (do Etapa 2.1c-δ)
    // deve aparecer em players. Esse contador vive só em
    // player_daily_mission_stats.
    expect(names.contains('daily_today_count'), isFalse,
        reason: 'daily_today_count NÃO deve existir em players');
    expect(names.contains('last_today_count_date'), isFalse,
        reason: 'last_today_count_date NÃO deve existir em players');
  });
}
