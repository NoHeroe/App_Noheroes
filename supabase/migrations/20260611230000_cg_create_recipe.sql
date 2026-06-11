-- ============================================================================
-- Card Game — ECONOMIA v1, BLOCO 5: receita ampliada de CRIAR + auditoria 30%.
--
-- SPEC: criar = Poeira (tabela) + 1 Cristal do tipo+raridade (atual) + 2
-- Essências do tipo+raridade (NOVO) + R_idx Essências da Facção da carta (NOVO;
-- cartas neutras não exigem). Conceito vem como parâmetro do cliente.
--   R_idx: comum=1, rara=2, epica=3, lendaria=4.
--
-- AUDITORIA anti-exploit (rendimento do desencante ≤30% do custo de criação,
-- por raridade): no NÍVEL 1, Poeira do desencante / Poeira de criação =
--   comum 2/20=10% · rara 20/145=14% · épica 195/1200=16% · lendária 575/2300=25%
-- — todos ≤30%. Além disso, criar gasta 2 Essências + Cristal + Facção e o
-- desencante L1 devolve só 1 Essência + Poeira + Lasca(0 em L1) + chances →
-- craft→desencante é NET NEGATIVO. Auditoria PASSA: card_disenchant_returns
-- NÃO precisa de ajuste.
-- ============================================================================

-- ── Criar (3 args: + p_concept) ─────────────────────────────────────────────
drop function if exists public.cg_create_card(uuid, text);
create or replace function public.cg_create_card(
    p_player uuid, p_card_id text, p_concept text default null)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_level int; v_card record; v_cost record; v_idx int; v_facc_need int;
  v_crys_key text; v_soul_key text; v_facc_key text;
  v_now bigint := (extract(epoch from now()) * 1000)::bigint;
  v_dust bigint; v_crys bigint; v_soul bigint; v_facc bigint;
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

  v_idx := case v_card.rarity when 'comum' then 1 when 'rara' then 2 when 'epica' then 3 else 4 end;
  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_soul_key := (case when v_card.kind = 'relic' then 'relic_soul_'    else 'card_soul_'    end) || v_card.rarity;
  v_facc_need := case when p_concept is null or p_concept = 'neutro' then 0 else v_idx end;

  v_dust := public.cg_resource_amount(p_player, 'stardust');
  v_crys := public.cg_resource_amount(p_player, v_crys_key);
  v_soul := public.cg_resource_amount(p_player, v_soul_key);
  v_facc := case when v_facc_need = 0 then 0
                 else public.cg_resource_amount(p_player, 'concept_essence_' || p_concept) end;

  if v_dust < v_cost.dust or v_crys < v_cost.crystal or v_soul < 2
     or (v_facc_need > 0 and v_facc < v_facc_need) then
    return json_build_object('ok', false, 'reason', 'insufficient_resources');
  end if;

  perform public.cg_grant_resource(p_player, 'stardust', -v_cost.dust);
  perform public.cg_grant_resource(p_player, v_crys_key, -v_cost.crystal);
  perform public.cg_grant_resource(p_player, v_soul_key, -2);
  if v_facc_need > 0 then
    perform public.cg_grant_resource(p_player, 'concept_essence_' || p_concept, -v_facc_need);
  end if;
  insert into public.player_cards (player_id, card_id, acquired_at, source, copies, level)
    values (p_player, p_card_id, v_now, 'crafted', 1, 1)
  on conflict (player_id, card_id) do update
    set copies = public.player_cards.copies + 1;
  return json_build_object('ok', true, 'card_id', p_card_id);
end; $$;

-- ── Snapshot (3 args: + p_concept) — craft mostra essência + facção ────────
drop function if exists public.cg_card_info(uuid, text);
create or replace function public.cg_card_info(
    p_player uuid, p_card_id text, p_concept text default null)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_plevel int; v_gold int; v_card record; v_owned record;
  v_craft record; v_up record; v_upc int; v_dis record; v_max int;
  v_emb_need int; v_idx int; v_facc_need int;
  v_crys_key text; v_mat_key text; v_soul_key text;
  v_have_dust bigint; v_have_crys bigint; v_have_mat bigint; v_have_soul bigint; v_have_facc bigint;
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

  v_idx := case v_card.rarity when 'comum' then 1 when 'rara' then 2 when 'epica' then 3 when 'lendaria' then 4 else 1 end;
  v_mat_key  := (case when v_card.kind = 'relic' then 'relic_runes_'   else 'card_scroll_'  end) || v_card.rarity;
  v_soul_key := (case when v_card.kind = 'relic' then 'relic_soul_'    else 'card_soul_'    end) || v_card.rarity;
  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_have_dust := public.cg_resource_amount(p_player, 'stardust');
  v_have_crys := public.cg_resource_amount(p_player, v_crys_key);
  v_have_mat  := public.cg_resource_amount(p_player, v_mat_key);
  v_have_soul := public.cg_resource_amount(p_player, v_soul_key);
  v_facc_need := case when p_concept is null or p_concept = 'neutro' then 0 else v_idx end;
  v_have_facc := case when v_facc_need = 0 then 0
                      else public.cg_resource_amount(p_player, 'concept_essence_' || p_concept) end;
  v_max := case when v_card.kind = 'relic' then 5 else 8 end;

  if v_card.rarity in ('comum','rara','epica','lendaria') then
    select dust, crystal into v_craft from public.card_craft_costs
      where kind = v_card.kind and rarity = v_card.rarity;
    if v_craft.dust is not null then
      v_craft_json := json_build_object(
        'dust', v_craft.dust, 'crystal', v_craft.crystal, 'soul', 2,
        'faccao', v_facc_need,
        'can', (v_plevel >= 3 and v_have_dust >= v_craft.dust and v_have_crys >= v_craft.crystal
                and v_have_soul >= 2 and (v_facc_need = 0 or v_have_facc >= v_facc_need)));
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
        v_dis_json := json_build_object('dust', v_dis.dust, 'lasca', v_dis.mat, 'soul', 1,
          'crystal_chance', true, 'faccao_chance', true, 'can', (v_plevel >= 3));
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
