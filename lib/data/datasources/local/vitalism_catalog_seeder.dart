import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../../database/app_database.dart';

// Popula vitalism_unique_catalog com os 31 Vitalismos Únicos a partir do JSON.
// Idempotente via insertOrIgnore — rodar várias vezes não duplica.
class VitalismCatalogSeeder {
  final AppDatabase _db;
  VitalismCatalogSeeder(this._db);

  Future<void> seed() async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/vitalismos_unicos.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final list = (data['vitalismos'] as List).cast<Map<String, dynamic>>();
      for (final v in list) {
        await _db.into(_db.vitalismUniqueCatalogTable).insert(
          VitalismUniqueCatalogTableCompanion(
            id:               Value(v['id'] as String),
            name:             Value(v['name'] as String),
            carrierName:      Value(v['carrierName'] as String),
            tier:             Value(v['tier'] as String),
            themeDescription: Value(v['themeDescription'] as String),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    } catch (_) {
      // Fallback silencioso — padrão dos outros seeders do projeto
      // (asset ainda não carregado em certos momentos do boot).
    }
  }
}
