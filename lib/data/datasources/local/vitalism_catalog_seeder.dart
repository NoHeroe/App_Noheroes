// OBSOLETO (Época 2 — full-online Supabase, ADR-0024).
//
// O catálogo de Vitalismos Únicos (public.vitalism_unique_catalog) agora vive no
// servidor e é re-seedado lá a partir do JSON via service_role (bypassa RLS).
// O cliente NÃO popula mais catálogos localmente — eles são leitura pública.
//
// Stub mantido só para não quebrar wiring/imports legados. `seed()` é no-op.
// Pode ser removido junto com o provider quando o boot for limpo.
class VitalismCatalogSeeder {
  VitalismCatalogSeeder();

  // No-op: catálogo é server-side no full-online.
  Future<void> seed() async {}
}
