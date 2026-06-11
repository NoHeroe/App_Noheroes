-- ============================================================================
-- Card Game — ECONOMIA v1, BLOCO 1: vocabulário + Poeira Estelar unificada.
--
-- Reconciliação de vocabulário (SPEC do CEO 2026-06-11):
--   dust (card_dust + relic_dust) → POEIRA ESTELAR, chave ÚNICA `stardust`.
--   card_crystal_<r>/relic_crystal_<r> = Cristal de Carta/Relíquia (mantém).
--   card_soul_<r>/relic_soul_<r>       = Essência de Criatura/Relíquia (mantém chave).
--   card_scroll_<r>/relic_runes_<r>    = Emblema de Evolução (mantém chave).
--   NOVAS (usadas nos blocos 4-5): card_shard/relic_shard (Lasca, por tipo, SEM
--     raridade) e concept_essence_<conceito> (Essência de Facção, por CardConcept
--     exceto neutro). São só chaves na bolsa chave→valor — sem schema novo.
--
-- 1) Migra saldos: card_dust + relic_dust → stardust (soma por jogador).
-- 2) Recria cg_create_card / cg_disenchant_card / cg_card_info /
--    dev_grant_card_resources usando 'stardust' (mantendo SECURITY DEFINER).
-- ============================================================================

-- 1) Funde os saldos antigos em 'stardust' e remove as chaves antigas.
insert into public.player_cg_resources (player_id, resource_key, amount)
  select player_id, 'stardust', sum(amount)
  from public.player_cg_resources
  where resource_key in ('card_dust', 'relic_dust')
  group by player_id
on conflict (player_id, resource_key)
  do update set amount = public.player_cg_resources.amount + excluded.amount;
delete from public.player_cg_resources where resource_key in ('card_dust', 'relic_dust');

-- 2) Criar: Poeira (stardust) + Cristal do tipo+raridade.
create or replace function public.cg_create_card(p_player uuid, p_card_id text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_level int; v_card record; v_cost record;
  v_crys_key text; v_now bigint := (extract(epoch from now()) * 1000)::bigint;
  v_dust bigint; v_crys bigint;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_create_card: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select level into v_level from public.players where id = p_player;
  if coalesce(v_level, 1) < 3 then return json_build_object('ok', false, 'reason', 'locked_level'); end if;
  select id, kind, rarity into v_card from public.cards_catalog where id = p_card_id;
  if v_card.id is null then return json_build_object('ok', false, 'reason', 'unknown_card'); end if;
  if v_card.rarity not in ('comum','rara','epica','lendaria') then
    return json_build_object('ok', false, 'reason', 'not_craftable');
  end if;
  select dust, crystal into v_cost from public.card_craft_costs
    where kind = v_card.kind and rarity = v_card.rarity;
  if v_cost.dust is null then return json_build_object('ok', false, 'reason', 'no_cost'); end if;

  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_dust := public.cg_resource_amount(p_player, 'stardust');
  v_crys := public.cg_resource_amount(p_player, v_crys_key);
  if v_dust < v_cost.dust or v_crys < v_cost.crystal then
    return json_build_object('ok', false, 'reason', 'insufficient_resources');
  end if;

  perform public.cg_grant_resource(p_player, 'stardust', -v_cost.dust);
  perform public.cg_grant_resource(p_player, v_crys_key, -v_cost.crystal);
  insert into public.player_cards (player_id, card_id, acquired_at, source, copies, level)
    values (p_player, p_card_id, v_now, 'crafted', 1, 1)
  on conflict (player_id, card_id) do update
    set copies = public.player_cards.copies + 1;
  return json_build_object('ok', true, 'card_id', p_card_id);
end; $$;

-- 2) Desencantar: Poeira (stardust) + Emblema(mat) + Cristal(r) + Essência(r).
create or replace function public.cg_disenchant_card(p_player uuid, p_card_id text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_plevel int; v_card record; v_owned record; v_ret record;
  v_mat_key text; v_crys_key text; v_soul_key text;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_disenchant_card: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select level into v_plevel from public.players where id = p_player;
  if coalesce(v_plevel, 1) < 3 then return json_build_object('ok', false, 'reason', 'locked_level'); end if;
  select id, kind, rarity into v_card from public.cards_catalog where id = p_card_id;
  if v_card.id is null then return json_build_object('ok', false, 'reason', 'unknown_card'); end if;
  if v_card.rarity not in ('comum','rara','epica','lendaria') then
    return json_build_object('ok', false, 'reason', 'not_disenchantable');
  end if;
  select copies, level into v_owned from public.player_cards
    where player_id = p_player and card_id = p_card_id;
  if v_owned.copies is null then return json_build_object('ok', false, 'reason', 'not_owned'); end if;
  select dust, mat into v_ret from public.card_disenchant_returns
    where kind = v_card.kind and rarity = v_card.rarity and level = v_owned.level;
  if v_ret.dust is null then return json_build_object('ok', false, 'reason', 'no_return'); end if;

  v_mat_key  := (case when v_card.kind = 'relic' then 'relic_runes_'   else 'card_scroll_'  end) || v_card.rarity;
  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_soul_key := (case when v_card.kind = 'relic' then 'relic_soul_'    else 'card_soul_'    end) || v_card.rarity;

  perform public.cg_grant_resource(p_player, 'stardust', v_ret.dust);
  perform public.cg_grant_resource(p_player, v_mat_key,  v_ret.mat);
  perform public.cg_grant_resource(p_player, v_crys_key, 1);
  perform public.cg_grant_resource(p_player, v_soul_key, 1);

  if v_owned.copies > 1 then
    update public.player_cards set copies = copies - 1
      where player_id = p_player and card_id = p_card_id;
  else
    delete from public.player_cards where player_id = p_player and card_id = p_card_id;
  end if;
  return json_build_object('ok', true, 'card_id', p_card_id,
    'dust', v_ret.dust, 'mat', v_ret.mat, 'crystal', 1, 'soul', 1);
end; $$;

-- 2) Snapshot por carta: have_dust agora = stardust.
create or replace function public.cg_card_info(p_player uuid, p_card_id text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_plevel int; v_gold int; v_card record; v_owned record;
  v_craft record; v_up record; v_upc int; v_dis record; v_max int;
  v_crys_key text; v_mat_key text; v_soul_key text;
  v_have_dust bigint; v_have_crys bigint; v_have_mat bigint; v_have_soul bigint;
  v_craft_json json := null; v_up_json json := null; v_dis_json json := null;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_card_info: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select level, gold into v_plevel, v_gold from public.players where id = p_player;
  v_plevel := coalesce(v_plevel, 1);
  select id, kind, rarity into v_card from public.cards_catalog where id = p_card_id;
  if v_card.id is null then return json_build_object('ok', false, 'reason', 'unknown_card'); end if;
  select copies, level into v_owned from public.player_cards
    where player_id = p_player and card_id = p_card_id;

  v_mat_key  := (case when v_card.kind = 'relic' then 'relic_runes_'   else 'card_scroll_'  end) || v_card.rarity;
  v_soul_key := (case when v_card.kind = 'relic' then 'relic_soul_'    else 'card_soul_'    end) || v_card.rarity;
  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_have_dust := public.cg_resource_amount(p_player, 'stardust');
  v_have_crys := public.cg_resource_amount(p_player, v_crys_key);
  v_have_mat  := public.cg_resource_amount(p_player, v_mat_key);
  v_have_soul := public.cg_resource_amount(p_player, v_soul_key);
  v_max := case when v_card.kind = 'relic' then 5 else 8 end;

  if v_card.rarity in ('comum','rara','epica','lendaria') then
    select dust, crystal into v_craft from public.card_craft_costs
      where kind = v_card.kind and rarity = v_card.rarity;
    if v_craft.dust is not null then
      v_craft_json := json_build_object('dust', v_craft.dust, 'crystal', v_craft.crystal,
        'can', (v_plevel >= 3 and v_have_dust >= v_craft.dust and v_have_crys >= v_craft.crystal));
    end if;
  end if;

  if v_owned.copies is not null then
    if v_owned.level < v_max then
      select gold, mat, soul into v_up from public.card_upgrade_costs
        where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
      select copies into v_upc from public.card_upgrade_copies
        where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
      v_upc := coalesce(v_upc, 0);
      if v_up.gold is not null then
        v_up_json := json_build_object('gold', v_up.gold, 'mat', v_up.mat, 'soul', v_up.soul,
          'copies_needed', v_upc,
          'can', (v_plevel >= 5 and v_gold >= v_up.gold and v_have_mat >= v_up.mat
                  and v_have_soul >= v_up.soul and v_owned.copies > v_upc));
      end if;
    end if;
    if v_card.rarity in ('comum','rara','epica','lendaria') then
      select dust, mat into v_dis from public.card_disenchant_returns
        where kind = v_card.kind and rarity = v_card.rarity and level = v_owned.level;
      if v_dis.dust is not null then
        v_dis_json := json_build_object('dust', v_dis.dust, 'mat', v_dis.mat,
          'crystal', 1, 'soul', 1, 'can', (v_plevel >= 3));
      end if;
    end if;
  end if;

  return json_build_object('ok', true,
    'card_id', v_card.id, 'kind', v_card.kind, 'rarity', v_card.rarity,
    'owned', (v_owned.copies is not null),
    'copies', coalesce(v_owned.copies, 0), 'level', coalesce(v_owned.level, 0),
    'max_level', v_max, 'player_level', v_plevel,
    'have_dust', v_have_dust, 'have_crystal', v_have_crys,
    'have_mat', v_have_mat, 'have_soul', v_have_soul,
    'craft', v_craft_json, 'upgrade', v_up_json, 'disenchant', v_dis_json);
end; $$;

-- 2) Dev grant: Poeira unificada + recursos por raridade + lascas + facção.
create or replace function public.dev_grant_card_resources(p_player uuid)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare r text; c text;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'dev_grant_card_resources: forbidden' using errcode = 'insufficient_privilege';
  end if;
  perform public.cg_grant_resource(p_player, 'stardust', 50000);
  perform public.cg_grant_resource(p_player, 'card_shard', 2000);
  perform public.cg_grant_resource(p_player, 'relic_shard', 2000);
  foreach r in array array['comum','rara','epica','lendaria'] loop
    perform public.cg_grant_resource(p_player, 'card_crystal_'  || r, 20);
    perform public.cg_grant_resource(p_player, 'relic_crystal_' || r, 20);
    perform public.cg_grant_resource(p_player, 'card_scroll_'   || r, 3000);
    perform public.cg_grant_resource(p_player, 'relic_runes_'   || r, 3000);
    perform public.cg_grant_resource(p_player, 'card_soul_'     || r, 500);
    perform public.cg_grant_resource(p_player, 'relic_soul_'    || r, 500);
  end loop;
  foreach c in array array['vitalismo','chrysalis','celestial','magico','corrompido'] loop
    perform public.cg_grant_resource(p_player, 'concept_essence_' || c, 200);
  end loop;
  return json_build_object('ok', true);
end; $$;
