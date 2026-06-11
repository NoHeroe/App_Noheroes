-- ============================================================================
-- Card Game — ECONOMIA: RPC de snapshot por carta (pra UI).
--
-- Uma chamada → tudo que a tela precisa pra uma carta: posse (copies/level),
-- custo de criar, custo da próxima melhoria (+ cópias), retorno do desencantar,
-- saldos relevantes e flags de "pode" (affordability + gate de nível). Evita
-- espelhar as tabelas de custo no cliente (servidor é a fonte). Ver ADR-0027.
--
-- Depende de 20260611150000 (tabelas de custo + helpers). security invoker.
-- ============================================================================

create or replace function public.cg_card_info(p_player uuid, p_card_id text)
  returns json language plpgsql security invoker as $$
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

  v_dust_key := case when v_card.kind = 'relic' then 'relic_dust'  else 'card_dust'  end;
  v_mat_key  := case when v_card.kind = 'relic' then 'relic_runes' else 'card_scroll' end;
  v_soul_key := case when v_card.kind = 'relic' then 'relic_soul'  else 'card_soul'  end;
  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_have_dust := public.cg_resource_amount(p_player, v_dust_key);
  v_have_crys := public.cg_resource_amount(p_player, v_crys_key);
  v_have_mat  := public.cg_resource_amount(p_player, v_mat_key);
  v_have_soul := public.cg_resource_amount(p_player, v_soul_key);
  v_max := case when v_card.kind = 'relic' then 5 else 8 end;

  -- Criar (só raridades craftáveis).
  if v_card.rarity in ('comum','rara','epica','lendaria') then
    select dust, crystal into v_craft from public.card_craft_costs
      where kind = v_card.kind and rarity = v_card.rarity;
    if v_craft.dust is not null then
      v_craft_json := json_build_object(
        'dust', v_craft.dust, 'crystal', v_craft.crystal,
        'can', (v_plevel >= 3 and v_have_dust >= v_craft.dust and v_have_crys >= v_craft.crystal));
    end if;
  end if;

  if v_owned.copies is not null then
    -- Aprimorar (se não está no teto).
    if v_owned.level < v_max then
      select gold, mat, soul into v_up from public.card_upgrade_costs
        where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
      select copies into v_upc from public.card_upgrade_copies
        where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
      v_upc := coalesce(v_upc, 0);
      if v_up.gold is not null then
        v_up_json := json_build_object(
          'gold', v_up.gold, 'mat', v_up.mat, 'soul', v_up.soul, 'copies_needed', v_upc,
          'can', (v_plevel >= 5 and v_gold >= v_up.gold and v_have_mat >= v_up.mat
                  and v_have_soul >= v_up.soul and v_owned.copies > v_upc));
      end if;
    end if;
    -- Desencantar (raridades desencantáveis).
    if v_card.rarity in ('comum','rara','epica','lendaria') then
      select dust, mat into v_dis from public.card_disenchant_returns
        where kind = v_card.kind and rarity = v_card.rarity and level = v_owned.level;
      if v_dis.dust is not null then
        v_dis_json := json_build_object('dust', v_dis.dust, 'mat', v_dis.mat, 'crystal', 1,
          'can', (v_plevel >= 3));
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

comment on function public.cg_card_info(uuid, text) is
  'Snapshot de economia por carta pra UI: posse, custos de criar/aprimorar/'
  'desencantar, saldos e flags de affordability. Ver ADR-0027.';
