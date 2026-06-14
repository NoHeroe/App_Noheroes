-- ==========================================================================
-- Card Game — round 3 (CEO 2026-06-14): registra as 2 relíquias NOVAS no
-- cards_catalog para que entrem no pool de drop de pacotes (open_pack puxa do
-- cards_catalog por raridade). Upsert idempotente; não remove nada.
--
--   • Emblema do Suporte   (neutro, lendária): concede suporte + magnetismo.
--   • Trevo de Quatro Folhas (neutro, épica):  armadura 1 + cura 1 + sorte.
--
-- Os dados completos (custo/grants) ficam no runtime (assets/.../relics.json);
-- o cards_catalog guarda só (id, kind, rarity) usados pelo drop por raridade.
-- ==========================================================================

insert into public.cards_catalog (id, kind, rarity) values
  ('emblema_do_suporte', 'relic', 'lendaria'),
  ('trevo_de_quatro_folhas', 'relic', 'epica')
on conflict (id) do update set
  kind = excluded.kind, rarity = excluded.rarity;
