import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/data/database/app_database.dart';

/// Sprint 3.4 Etapa H — migration 35→36 adiciona `players.insignias`
/// (moeda de facção, int NOT NULL default 0).
///
/// Verificação via PRAGMA `table_info('players')` em DB fresh (Drift
/// `createAll` na inicialização gera o schema atual = 36). A correção do
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

  test('schemaVersion >= 36', () {
    expect(db.schemaVersion, greaterThanOrEqualTo(36));
  });

  test('schema 36: players tem coluna insignias (int NOT NULL default 0)',
      () async {
    final cols = await db.customSelect("PRAGMA table_info('players')").get();
    final names = cols.map((r) => r.read<String>('name')).toSet();

    expect(names.contains('insignias'), isTrue,
        reason: 'coluna insignias deve existir após migration 36');

    final col =
        cols.firstWhere((r) => r.read<String>('name') == 'insignias');
    expect(col.read<int>('notnull'), 1,
        reason: 'insignias NOT NULL (tem default 0)');
    expect(col.read<String?>('dflt_value'), '0',
        reason: 'default da coluna insignias é 0');
  });

  test('insignias começa em 0 e aceita crédito/débito', () async {
    // Seed mínimo via customStatement (evita data class pitfall ADR-0019).
    await db.customStatement(
      "INSERT INTO players (id, email, password_hash) "
      "VALUES (1, 'h@h.com', 'x')",
    );
    final before = await db
        .customSelect('SELECT insignias FROM players WHERE id = 1')
        .getSingle();
    expect(before.read<int>('insignias'), 0);

    await db.customStatement(
        'UPDATE players SET insignias = insignias + 100 WHERE id = 1');
    final after = await db
        .customSelect('SELECT insignias FROM players WHERE id = 1')
        .getSingle();
    expect(after.read<int>('insignias'), 100);
  });
}
