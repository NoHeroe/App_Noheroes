-- ============================================================================
-- Card Game — ECONOMIA v1, BLOCO 4: forja de emblema, fusão de essência e
-- desencante reformulado (Lasca + chances).
--
-- SPEC:
--  - Desencantar passa a dar: Poeira (principal) + Essência (1 da raridade) +
--    Lasca (bônus = antigo custo de scroll/`mat`) + Cristal (CHANCE) + Essência
--    de Facção (CHANCE, do conceito da carta). NÃO dá mais Emblema.
--    O conceito vem como parâmetro do cliente (cards_catalog não tem conceito;
--    ponto de confiança menor — endurece no PvP).
--  - Fusão: 5 Essências de R + 50×R_idx Poeira → 1 Essência de R+1 (sem RNG).
--  - Forja de Emblema (Ferreiro, hybrid): 1 Emblema R = 10×R_idx Lascas + 2
--    Essências do tipo R + 100×R_idx Poeira. Execução server-side (player_cg_
--    resources), renderizado na tela do Ferreiro.
--  R_idx: comum=1, rara=2, epica=3, lendaria=4.
-- ============================================================================

-- ── Desencantar reformulado (3 args: + p_concept) ──────────────────────────
drop function if exists public.cg_disenchant_card(uuid, text);
create or replace function public.cg_disenchant_card(
    p_player uuid, p_card_id text, p_concept text default null)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_plevel int; v_card record; v_owned record; v_ret record;
  v_lasca_key text; v_crys_key text; v_soul_key text;
  v_got_crystal int := 0; v_got_facc int := 0;
  k_crystal_chance constant numeric := 0.35; -- 🎚️ calibrável
  k_facc_chance    constant numeric := 0.35; -- 🎚️ calibrável
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

  v_lasca_key := case when v_card.kind = 'relic' then 'relic_shard'    else 'card_shard'    end;
  v_crys_key  := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_soul_key  := (case when v_card.kind = 'relic' then 'relic_soul_'    else 'card_soul_'    end) || v_card.rarity;

  perform public.cg_grant_resource(p_player, 'stardust', v_ret.dust);     -- Poeira (principal)
  perform public.cg_grant_resource(p_player, v_lasca_key, v_ret.mat);     -- Lasca (bônus)
  perform public.cg_grant_resource(p_player, v_soul_key, 1);             -- Essência (1 da raridade)
  if random() < k_crystal_chance then
    perform public.cg_grant_resource(p_player, v_crys_key, 1);            -- Cristal (chance)
    v_got_crystal := 1;
  end if;
  if p_concept is not null and p_concept <> 'neutro' and random() < k_facc_chance then
    perform public.cg_grant_resource(p_player, 'concept_essence_' || p_concept, 1);
    v_got_facc := 1;
  end if;

  if v_owned.copies > 1 then
    update public.player_cards set copies = copies - 1
      where player_id = p_player and card_id = p_card_id;
  else
    delete from public.player_cards where player_id = p_player and card_id = p_card_id;
  end if;
  return json_build_object('ok', true, 'card_id', p_card_id,
    'dust', v_ret.dust, 'lasca', v_ret.mat, 'soul', 1,
    'crystal', v_got_crystal, 'faccao', v_got_facc);
end; $$;

-- ── Fusão de essência: 5×R + 50×R_idx Poeira → 1×(R+1) ─────────────────────
create or replace function public.cg_fuse_essence(
    p_player uuid, p_kind text, p_from_rarity text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_idx int; v_to text; v_soul_from text; v_soul_to text; v_poeira int;
  v_have_soul bigint; v_have_dust bigint;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_fuse_essence: forbidden' using errcode = 'insufficient_privilege';
  end if;
  if p_kind not in ('card','relic') then return json_build_object('ok', false, 'reason', 'bad_kind'); end if;
  v_idx := case p_from_rarity when 'comum' then 1 when 'rara' then 2 when 'epica' then 3 else 0 end;
  if v_idx = 0 then return json_build_object('ok', false, 'reason', 'bad_rarity'); end if; -- lendária não funde
  v_to := case p_from_rarity when 'comum' then 'rara' when 'rara' then 'epica' else 'lendaria' end;

  v_soul_from := (case when p_kind = 'relic' then 'relic_soul_' else 'card_soul_' end) || p_from_rarity;
  v_soul_to   := (case when p_kind = 'relic' then 'relic_soul_' else 'card_soul_' end) || v_to;
  v_poeira := 50 * v_idx;

  v_have_soul := public.cg_resource_amount(p_player, v_soul_from);
  v_have_dust := public.cg_resource_amount(p_player, 'stardust');
  if v_have_soul < 5 or v_have_dust < v_poeira then
    return json_build_object('ok', false, 'reason', 'insufficient');
  end if;
  perform public.cg_grant_resource(p_player, v_soul_from, -5);
  perform public.cg_grant_resource(p_player, 'stardust', -v_poeira);
  perform public.cg_grant_resource(p_player, v_soul_to, 1);
  return json_build_object('ok', true, 'to_rarity', v_to);
end; $$;

-- ── Forja de Emblema: 10×R_idx Lascas + 2 Essências(R) + 100×R_idx Poeira ──
create or replace function public.cg_forge_emblem(
    p_player uuid, p_kind text, p_rarity text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_idx int; v_lasca_key text; v_soul_key text; v_emb_key text;
  v_need_lasca int; v_need_poeira int;
  v_have_lasca bigint; v_have_soul bigint; v_have_dust bigint;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_forge_emblem: forbidden' using errcode = 'insufficient_privilege';
  end if;
  if p_kind not in ('card','relic') then return json_build_object('ok', false, 'reason', 'bad_kind'); end if;
  v_idx := case p_rarity when 'comum' then 1 when 'rara' then 2 when 'epica' then 3 when 'lendaria' then 4 else 0 end;
  if v_idx = 0 then return json_build_object('ok', false, 'reason', 'bad_rarity'); end if;

  v_lasca_key := case when p_kind = 'relic' then 'relic_shard' else 'card_shard' end;
  v_soul_key  := (case when p_kind = 'relic' then 'relic_soul_'  else 'card_soul_'  end) || p_rarity;
  v_emb_key   := (case when p_kind = 'relic' then 'relic_runes_' else 'card_scroll_' end) || p_rarity;
  v_need_lasca := 10 * v_idx;
  v_need_poeira := 100 * v_idx;

  v_have_lasca := public.cg_resource_amount(p_player, v_lasca_key);
  v_have_soul  := public.cg_resource_amount(p_player, v_soul_key);
  v_have_dust  := public.cg_resource_amount(p_player, 'stardust');
  if v_have_lasca < v_need_lasca or v_have_soul < 2 or v_have_dust < v_need_poeira then
    return json_build_object('ok', false, 'reason', 'insufficient',
      'need_lasca', v_need_lasca, 'need_soul', 2, 'need_poeira', v_need_poeira);
  end if;
  perform public.cg_grant_resource(p_player, v_lasca_key, -v_need_lasca);
  perform public.cg_grant_resource(p_player, v_soul_key, -2);
  perform public.cg_grant_resource(p_player, 'stardust', -v_need_poeira);
  perform public.cg_grant_resource(p_player, v_emb_key, 1);
  return json_build_object('ok', true, 'emblema', v_emb_key);
end; $$;

-- ── Snapshot: desencante agora mostra Lasca + chances (não Emblema) ────────
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
