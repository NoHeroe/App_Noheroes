// OBSOLETO (Época 2, full-online Supabase — ADR-0024).
//
// No modelo full-online o items_catalog é seedado no SERVIDOR (ver
// supabase/migrations/20260609130000_seed_catalogs.sql) e lido via
// ItemsCatalogService.findAll() (Supabase REST). O seed client-side a partir
// de assets/data/items_unified.json não existe mais — este seeder virou stub
// no-op pra não quebrar callers legacy enquanto os providers são religados.
//
// TODO(remover): apagar este arquivo e seus usos depois que providers.dart
// parar de instanciá-lo.
class ItemsCatalogSeeder {
  ItemsCatalogSeeder();

  // No-op: catálogo vive no servidor (seed via migration). Mantido só pra
  // compatibilidade de assinatura até a remoção dos callers.
  Future<void> seed() async {}
}
