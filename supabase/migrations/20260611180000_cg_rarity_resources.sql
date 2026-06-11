-- ============================================================================
-- Card Game — ECONOMIA: scroll/soul por RARIDADE + Soul Crystal vindo do
-- desencantar.
--
-- Decisão do CEO (2026-06-11): "cada carta desencantada gera 1 Soul Crystal da
-- raridade da carta". Isso confirma que Soul Crystals são por raridade — e, pelo
-- rascunho, os Scrolls/Runes também (Elite pede recurso de 2 raridades). A
-- fundação modelou soul/scroll como pool ÚNICO; aqui corrige para chaves por
-- raridade e adiciona o +1 Soul no desencante (a fonte que faltava pro upgrade).
--
-- Keys novas: card_scroll_<r> / relic_runes_<r> / card_soul_<r> / relic_soul_<r>
-- (<r> = comum|rara|epica|lendaria). Dust e crystal já estavam corretos (dust
-- pool único; crystal por raridade). Recria as 3 RPCs que usam scroll/soul +
-- cg_card_info + dev grant (mantendo SECURITY DEFINER + search_path do harden).
-- cg_create_card NÃO muda (só usa dust + crystal).
-- ============================================================================

-- ── Desencantar: +scroll(r) +crystal(r) +SOUL(r) ───────────────────────────
create or replace function public.cg_disenchant_card(p_player uuid, p_card_id text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_plevel int; v_card record; v_owned record; v_ret record;
  v_dust_key text; v_mat_key text; v_crys_key text; v_soul_key text;
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

  v_dust_key := case when v_card.kind = 'relic' then 'relic_dust' else 'card_dust' end;
  v_mat_key  := (case when v_card.kind = 'relic' then 'relic_runes_'   else 'card_scroll_'  end) || v_card.rarity;
  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_soul_key := (case when v_card.kind = 'relic' then 'relic_soul_'    else 'card_soul_'    end) || v_card.rarity;

  perform public.cg_grant_resource(p_player, v_dust_key, v_ret.dust);
  perform public.cg_grant_resource(p_player, v_mat_key,  v_ret.mat);
  perform public.cg_grant_resource(p_player, v_crys_key, 1);  -- +1 crystal da raridade (fixo)
  perform public.cg_grant_resource(p_player, v_soul_key, 1);  -- +1 soul da raridade (CEO 2026-06-11)

  if v_owned.copies > 1 then
    update public.player_cards set copies = copies - 1
      where player_id = p_player and card_id = p_card_id;
  else
    delete from public.player_cards
      where player_id = p_player and card_id = p_card_id;
  end if;
  return json_build_object('ok', true, 'card_id', p_card_id,
    'dust', v_ret.dust, 'mat', v_ret.mat, 'crystal', 1, 'soul', 1);
end; $$;

-- ── Aprimorar: gasta scroll(r) + soul(r) ───────────────────────────────────
create or replace function public.cg_upgrade_card(p_player uuid, p_card_id text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_plevel int; v_card record; v_owned record; v_cost record; v_copies_req int;
  v_max int; v_mat_key text; v_soul_key text; v_gold int; v_have_mat bigint; v_have_soul bigint;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_upgrade_card: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select level into v_plevel from public.players where id = p_player;
  if coalesce(v_plevel, 1) < 5 then return json_build_object('ok', false, 'reason', 'locked_level'); end if;

  select id, kind, rarity into v_card from public.cards_catalog where id = p_card_id;
  if v_card.id is null then return json_build_object('ok', false, 'reason', 'unknown_card'); end if;

  select copies, level into v_owned from public.player_cards
    where player_id = p_player and card_id = p_card_id;
  if v_owned.copies is null then return json_build_object('ok', false, 'reason', 'not_owned'); end if;

  v_max := case when v_card.kind = 'relic' then 5 else 8 end;
  if v_owned.level >= v_max then return json_build_object('ok', false, 'reason', 'max_level'); end if;

  select gold, mat, soul into v_cost from public.card_upgrade_costs
    where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
  if v_cost.gold is null then return json_build_object('ok', false, 'reason', 'no_cost'); end if;
  select copies into v_copies_req from public.card_upgrade_copies
    where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
  v_copies_req := coalesce(v_copies_req, 0);

  v_mat_key  := (case when v_card.kind = 'relic' then 'relic_runes_' else 'card_scroll_' end) || v_card.rarity;
  v_soul_key := (case when v_card.kind = 'relic' then 'relic_soul_'  else 'card_soul_'  end) || v_card.rarity;
  v_have_mat  := public.cg_resource_amount(p_player, v_mat_key);
  v_have_soul := public.cg_resource_amount(p_player, v_soul_key);
  select gold into v_gold from public.players where id = p_player;

  if v_gold < v_cost.gold or v_have_mat < v_cost.mat or v_have_soul < v_cost.soul
     or v_owned.copies <= v_copies_req then
    return json_build_object('ok', false, 'reason', 'insufficient',
      'need_copies', v_copies_req, 'have_copies', v_owned.copies);
  end if;

  update public.players set gold = gold - v_cost.gold where id = p_player;
  perform public.cg_grant_resource(p_player, v_mat_key,  -v_cost.mat);
  perform public.cg_grant_resource(p_player, v_soul_key, -v_cost.soul);
  update public.player_cards
     set level = level + 1, copies = copies - v_copies_req
   where player_id = p_player and card_id = p_card_id;

  return json_build_object('ok', true, 'card_id', p_card_id, 'new_level', v_owned.level + 1);
end; $$;

-- ── Snapshot por carta: keys por raridade + soul do desencantar ────────────
create or replace function public.cg_card_info(p_player uuid, p_card_id text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_plevel int; v_gold int; v_card record; v_owned record;
  v_craft record; v_up record; v_upc int; v_dis record; v_max int;
  v_dust_key text; v_crys_key text; v_mat_key text; v_soul_key text;
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

  v_dust_key := case when v_card.kind = 'relic' then 'relic_dust' else 'card_dust' end;
  v_mat_key  := (case when v_card.kind = 'relic' then 'relic_runes_'   else 'card_scroll_'  end) || v_card.rarity;
  v_soul_key := (case when v_card.kind = 'relic' then 'relic_soul_'    else 'card_soul_'    end) || v_card.rarity;
  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_have_dust := public.cg_resource_amount(p_player, v_dust_key);
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

-- ── Dev grant: recursos por raridade ───────────────────────────────────────
create or replace function public.dev_grant_card_resources(p_player uuid)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare r text;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'dev_grant_card_resources: forbidden' using errcode = 'insufficient_privilege';
  end if;
  perform public.cg_grant_resource(p_player, 'card_dust', 5000);
  perform public.cg_grant_resource(p_player, 'relic_dust', 5000);
  foreach r in array array['comum','rara','epica','lendaria'] loop
    perform public.cg_grant_resource(p_player, 'card_crystal_'  || r, 20);
    perform public.cg_grant_resource(p_player, 'relic_crystal_' || r, 20);
    perform public.cg_grant_resource(p_player, 'card_scroll_'   || r, 3000);
    perform public.cg_grant_resource(p_player, 'relic_runes_'   || r, 3000);
    perform public.cg_grant_resource(p_player, 'card_soul_'     || r, 500);
    perform public.cg_grant_resource(p_player, 'relic_soul_'    || r, 500);
  end loop;
  return json_build_object('ok', true);
end; $$;
