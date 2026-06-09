-- ============================================================================
-- Época 2, S2 — onboarding atômico (decisão: starter recipes via trigger).
-- Estende handle_new_user pra desbloquear as receitas starter no MESMO passo
-- do signup. Roda como SECURITY DEFINER (owner) → bypassa RLS no insert de
-- player_recipes_unlocked. unlock_starter_recipes definida em
-- 20260609140004_rpc_crafting.sql.
-- ============================================================================
create or replace function public.handle_new_user()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  insert into public.players (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  perform public.unlock_starter_recipes(new.id);
  return new;
end;
$$;
