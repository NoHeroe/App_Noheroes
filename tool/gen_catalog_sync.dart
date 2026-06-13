// Gera uma migration que SINCRONIZA cards_catalog (id, kind, rarity) com o
// catálogo atual (creatures.json + relics.json) — corrige drift de raridade
// pós-import do docx (fix do drop-rate, #56). Upsert idempotente; não remove.
//
// Uso: dart run tool/gen_catalog_sync.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final cri = (jsonDecode(
          File('assets/data/card_game/creatures.json').readAsStringSync())
      as List);
  final rel = (jsonDecode(
          File('assets/data/card_game/relics.json').readAsStringSync())
      as List);

  final rows = <String>[];
  for (final j in cri) {
    final m = j as Map<String, dynamic>;
    rows.add("  ('${m['id']}', 'creature', '${m['rarity']}')");
  }
  for (final j in rel) {
    final m = j as Map<String, dynamic>;
    rows.add("  ('${m['id']}', 'relic', '${m['rarity']}')");
  }

  final out = StringBuffer()
    ..writeln('-- ${'=' * 74}')
    ..writeln(
        '-- Card Game — SYNC do cards_catalog com o catálogo balanceado (docx).')
    ..writeln('--')
    ..writeln(
        '-- Pós-import do docx (2026-06-12), várias rarezas mudaram. O drop de')
    ..writeln(
        '-- pacote puxa do cards_catalog por raridade → precisa refletir o JSON.')
    ..writeln(
        '-- Upsert idempotente (id, kind, rarity). NÃO remove (IDs são estáveis).')
    ..writeln('-- Gerado por tool/gen_catalog_sync.dart.')
    ..writeln('-- ${'=' * 74}')
    ..writeln()
    ..writeln('insert into public.cards_catalog (id, kind, rarity) values')
    ..writeln(rows.join(',\n'))
    ..writeln('on conflict (id) do update set')
    ..writeln('  kind = excluded.kind, rarity = excluded.rarity;');

  File('supabase/migrations/20260612010000_cg_catalog_sync.sql')
      .writeAsStringSync(out.toString());
  stdout.writeln(
      'Migration gerada: 20260612010000_cg_catalog_sync.sql (${rows.length} cards)');
}
