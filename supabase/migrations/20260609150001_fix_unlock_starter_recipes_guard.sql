-- ============================================================================
-- Fix (Época 2, S2): unlock_starter_recipes era chamada pelo trigger
-- handle_new_user no signup, mas o guard `auth.uid() is null OR ...` lançava
-- exceção quando auth.uid() é NULL (contexto do signup, antes de haver sessão)
-- → "Database error saving new user". Relaxa o guard: só bloqueia quando há um
-- usuário autenticado agindo por OUTRO jogador. Contexto server/trigger
-- (auth.uid() null) é confiável.
-- ============================================================================
create or replace function public.unlock_starter_recipes(p_player uuid)
  returns int
  language plpgsql
  security invoker
as $$
declare
  v_unlocked integer := 0;
  v_now      bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  -- Bloqueia só usuário autenticado agindo por outro. auth.uid() null =
  -- contexto server/trigger (signup) = permitido.
  if auth.uid() is not null and auth.uid() <> p_player then
    raise exception 'unlock_starter_recipes: caller % cannot act for player %',
      auth.uid(), p_player using errcode = 'insufficient_privilege';
  end if;

  with starters as (
    select rc.key
      from public.recipes_catalog rc
     where exists (
       select 1
         from json_array_elements(rc.unlock_sources::json) as s
        where s->>'type' = 'starter'
     )
  ),
  ins as (
    insert into public.player_recipes_unlocked (player_id, recipe_key, unlocked_at, unlocked_via)
    select p_player, key, v_now, 'starter'
      from starters
    on conflict (player_id, recipe_key) do nothing
    returning 1
  )
  select count(*)::int into v_unlocked from ins;

  return v_unlocked;
end;
$$;
