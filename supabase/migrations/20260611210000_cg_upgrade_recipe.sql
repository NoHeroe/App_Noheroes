-- ============================================================================
-- Card Game — ECONOMIA v1, BLOCO 3: nova receita de APRIMORAR.
--
-- SPEC: aprimorar = ouro (tabela atual) + Poeira (nova coluna) + N Emblemas da
-- RARIDADE DA CARTA (N cresce com o nível) + Essência (soul, tabela). Cópias do
-- nível (curva validada) e gates Nv3/Nv5 mantidos.
--   N Emblemas por nível atual (from_level): <3 → 1, <5 → 2, senão → 3 (calibrável).
--   Emblema = chave card_scroll_<r> / relic_runes_<r> (FONTE: forja, bloco 4).
--   Poeira (stardust): seed inicial = antigo custo de scroll (`mat`), repurposado.
-- ============================================================================

alter table public.card_upgrade_costs add column if not exists poeira int not null default 0;
-- Seed calibrável: Poeira = antigo custo de scroll (mat). Emblema agora é N
-- computado por nível (não sai mais do `mat`).
update public.card_upgrade_costs set poeira = mat where poeira = 0;

-- N emblemas por nível atual (helper inline; sem função pra não poluir).
-- (level<3 → 1, level<5 → 2, senão 3)

create or replace function public.cg_upgrade_card(p_player uuid, p_card_id text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_plevel int; v_card record; v_owned record; v_cost record; v_copies_req int;
  v_max int; v_mat_key text; v_soul_key text; v_gold int; v_emb_need int;
  v_have_emb bigint; v_have_soul bigint; v_have_dust bigint;
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

  select gold, poeira, soul into v_cost from public.card_upgrade_costs
    where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
  if v_cost.gold is null then return json_build_object('ok', false, 'reason', 'no_cost'); end if;
  select copies into v_copies_req from public.card_upgrade_copies
    where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
  v_copies_req := coalesce(v_copies_req, 0);
  v_emb_need := case when v_owned.level < 3 then 1 when v_owned.level < 5 then 2 else 3 end;

  v_mat_key  := (case when v_card.kind = 'relic' then 'relic_runes_' else 'card_scroll_' end) || v_card.rarity;
  v_soul_key := (case when v_card.kind = 'relic' then 'relic_soul_'  else 'card_soul_'  end) || v_card.rarity;
  v_have_emb  := public.cg_resource_amount(p_player, v_mat_key);
  v_have_soul := public.cg_resource_amount(p_player, v_soul_key);
  v_have_dust := public.cg_resource_amount(p_player, 'stardust');
  select gold into v_gold from public.players where id = p_player;

  if v_gold < v_cost.gold or v_have_dust < v_cost.poeira or v_have_emb < v_emb_need
     or v_have_soul < v_cost.soul or v_owned.copies <= v_copies_req then
    return json_build_object('ok', false, 'reason', 'insufficient',
      'need_copies', v_copies_req, 'have_copies', v_owned.copies,
      'need_emblema', v_emb_need, 'have_emblema', v_have_emb);
  end if;

  update public.players set gold = gold - v_cost.gold where id = p_player;
  perform public.cg_grant_resource(p_player, 'stardust', -v_cost.poeira);
  perform public.cg_grant_resource(p_player, v_mat_key,  -v_emb_need);
  perform public.cg_grant_resource(p_player, v_soul_key, -v_cost.soul);
  update public.player_cards
     set level = level + 1, copies = copies - v_copies_req
   where player_id = p_player and card_id = p_card_id;

  return json_build_object('ok', true, 'card_id', p_card_id, 'new_level', v_owned.level + 1);
end; $$;

-- Snapshot: expõe poeira + emblema_needed (N) no bloco de upgrade.
create or replace function public.cg_card_info(p_player uuid, p_card_id text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_plevel int; v_gold int; v_card record; v_owned record;
  v_craft record; v_up record; v_upc int; v_dis record; v_max int; v_emb_need int;
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
      select gold, poeira, soul into v_up from public.card_upgrade_costs
        where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
      select copies into v_upc from public.card_upgrade_copies
        where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
      v_upc := coalesce(v_upc, 0);
      v_emb_need := case when v_owned.level < 3 then 1 when v_owned.level < 5 then 2 else 3 end;
      if v_up.gold is not null then
        v_up_json := json_build_object(
          'gold', v_up.gold, 'poeira', v_up.poeira, 'emblema_needed', v_emb_need,
          'soul', v_up.soul, 'copies_needed', v_upc,
          'have_emblema', v_have_mat, 'have_soul', v_have_soul, 'have_dust', v_have_dust,
          'can', (v_plevel >= 5 and v_gold >= v_up.gold and v_have_dust >= v_up.poeira
                  and v_have_mat >= v_emb_need and v_have_soul >= v_up.soul
                  and v_owned.copies > v_upc));
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
