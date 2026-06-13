-- ============================================================================
-- Card Game — HERÓIS no catálogo (upáveis) + banda de ELITE no drop +
-- PACOTE DE HERÓI + KIT ELITE (CEO 2026-06-12).
--
-- 1) Heróis viram cartas do catálogo (kind='hero', conceito/raridade definidos
--    pelo CEO) → inspecionáveis e UPÁVEIS como cartas comuns (custos = espelho
--    da criatura da mesma raridade; usam recursos "card_*").
-- 2) open_pack: banda de ELITE nas odds base (mais rara que lendária — CR-style)
--    e EXCLUI heróis dos pacotes normais. Pacote de herói rola só heróis.
-- 3) Pacote de herói: 1 herói, 50 gemas, comprável (+ drop em missões/conquistas
--    — PENDÊNCIA de design no vault). Pacote elite-garantido (1 elite) só via kit.
-- 4) cg_buy_kit_elite: 1000 gemas → 1 pacote elite-garantido + 5 pacotes
--    diferentes + essência/poeira.
-- ============================================================================

-- ── 1) Heróis no catálogo ──────────────────────────────────────────────────
insert into public.cards_catalog (id, kind, rarity) values
  ('trapaceiro', 'hero', 'rara'),
  ('cartomante', 'hero', 'rara'),
  ('oraculo',    'hero', 'rara'),
  ('assassino',  'hero', 'rara'),
  ('coringa',    'hero', 'epica')
on conflict (id) do update set kind = excluded.kind, rarity = excluded.rarity;

-- Custos/cópias de upgrade do herói = espelho da criatura da mesma raridade.
insert into public.card_upgrade_costs (kind, rarity, from_level, gold, mat, soul, poeira)
  select 'hero', rarity, from_level, gold, mat, soul, poeira
  from public.card_upgrade_costs
  where kind = 'creature' and rarity in ('rara', 'epica')
on conflict (kind, rarity, from_level) do nothing;

insert into public.card_upgrade_copies (kind, rarity, from_level, copies)
  select 'hero', rarity, from_level, copies
  from public.card_upgrade_copies
  where kind = 'creature' and rarity in ('rara', 'epica')
on conflict (kind, rarity, from_level) do nothing;

-- Todo jogador começa com 1 cópia (nível 1) de cada herói → aparecem como
-- cartas "possuídas" na coleção (uso em partida independe de posse).
insert into public.player_cards (player_id, card_id, acquired_at, source, copies, level)
  select p.id, h.hid, (extract(epoch from now()) * 1000)::bigint, 'starter', 1, 1
  from public.players p
  cross join (values ('trapaceiro'), ('cartomante'), ('oraculo'),
                     ('coringa'), ('assassino')) as h(hid)
on conflict (player_id, card_id) do nothing;

-- ── 2) Tipos de pacote novos ───────────────────────────────────────────────
insert into public.pack_catalog
  (pack_type, display_name, min_count, max_count, guarantee_rarity, elite_chance, exclusive_chance, price_gold, price_gems, buyable, sort) values
  ('hero_pack',      'Pacote de Herói',           1, 1, null,    0, 0, null, 50,   true,  90),
  ('elite_garantido','Pacote Elite Garantido',    1, 1, 'elite', 0, 0, null, null, false, 95)
on conflict (pack_type) do update set
  display_name = excluded.display_name, min_count = excluded.min_count,
  max_count = excluded.max_count, guarantee_rarity = excluded.guarantee_rarity,
  sort = excluded.sort;

-- ── 3) open_pack v3: elite nas odds base, exclui heróis, pacote de herói ────
create or replace function public.open_pack(p_player uuid, p_type text default 'padrao')
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  k_pity   constant int := 30;
  v_pack   record; v_have int; v_count int; v_now bigint;
  v_cards  json[] := '{}'; v_pity int; v_got_leg boolean := false; v_guar_ok boolean;
  v_min_rank int; i int; v_roll numeric; v_rarity text; v_card record; v_is_new boolean;
  v_is_hero boolean;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'open_pack: forbidden' using errcode = 'insufficient_privilege';
  end if;

  select * into v_pack from public.pack_catalog where pack_type = p_type;
  if v_pack.pack_type is null then return json_build_object('ok', false, 'reason', 'unknown_pack'); end if;
  v_is_hero := (p_type = 'hero_pack');

  select count into v_have from public.player_packs
    where player_id = p_player and pack_type = p_type;
  if coalesce(v_have, 0) < 1 then return json_build_object('ok', false, 'reason', 'no_pack'); end if;
  update public.player_packs set count = count - 1
    where player_id = p_player and pack_type = p_type;

  v_count := v_pack.min_count
    + floor(random() * (v_pack.max_count - v_pack.min_count + 1))::int;
  v_min_rank := case v_pack.guarantee_rarity
                  when 'rara' then 2 when 'epica' then 3
                  when 'lendaria' then 4 when 'elite' then 5 else 0 end;
  v_guar_ok := (v_min_rank = 0);

  select coalesce(card_pity_counter, 0) into v_pity from public.players where id = p_player;
  v_now := (extract(epoch from now()) * 1000)::bigint;

  for i in 1..v_count loop
    if v_is_hero then
      -- Pacote de herói: rola só heróis (rara comum, épica rara).
      v_roll := random() * 100;
      v_rarity := case when v_roll < 85 then 'rara' else 'epica' end;
      select id, kind, rarity into v_card from public.cards_catalog
        where kind = 'hero' and rarity = v_rarity order by random() limit 1;
      if v_card.id is null then
        select id, kind, rarity into v_card from public.cards_catalog
          where kind = 'hero' order by random() limit 1;
      end if;
    else
      if i = v_count and not v_guar_ok and v_pack.guarantee_rarity = 'elite' then
        v_rarity := 'elite';                                   -- garantia de elite > pity
      elsif i = v_count and not v_got_leg and (v_pity + 1) >= k_pity then
        v_rarity := 'lendaria';                                -- pity (lendária)
      elsif i = v_count and not v_guar_ok then
        v_rarity := v_pack.guarantee_rarity;                   -- garantia do pacote
      elsif v_pack.exclusive_chance > 0 and random() < v_pack.exclusive_chance then
        v_rarity := 'exclusiva';                               -- Royale: Exclusiva
      elsif v_pack.elite_chance > 0 and random() < v_pack.elite_chance then
        v_rarity := 'elite';
      else
        v_roll := random() * 100;                              -- odds base + elite
        v_rarity := case when v_roll < 70    then 'comum'
                         when v_roll < 93    then 'rara'
                         when v_roll < 99    then 'epica'
                         when v_roll < 99.9  then 'lendaria'
                         else 'elite' end;                     -- elite < lendária
      end if;

      -- Cartas normais: NUNCA heróis (heróis só saem no pacote de herói).
      select id, kind, rarity into v_card from public.cards_catalog
        where rarity = v_rarity and kind <> 'hero' order by random() limit 1;
      if v_card.id is null then  -- raridade sem cartas → comum
        select id, kind, rarity into v_card from public.cards_catalog
          where rarity = 'comum' and kind <> 'hero' order by random() limit 1;
      end if;
    end if;

    if v_card.rarity = 'lendaria' then v_got_leg := true; end if;
    if (case v_card.rarity when 'rara' then 2 when 'epica' then 3
          when 'lendaria' then 4 when 'elite' then 5 else 1 end) >= v_min_rank then
      v_guar_ok := true;
    end if;

    insert into public.player_cards (player_id, card_id, acquired_at, source, copies)
      values (p_player, v_card.id, v_now, 'pack', 1)
      on conflict (player_id, card_id)
      do update set copies = public.player_cards.copies + 1
      returning (xmax = 0) into v_is_new;
    v_cards := array_append(v_cards, json_build_object(
      'card_id', v_card.id, 'kind', v_card.kind, 'rarity', v_card.rarity, 'is_new', v_is_new));
  end loop;

  -- Pacote de herói não mexe na pity de lendária.
  if not v_is_hero then
    update public.players
       set card_pity_counter = case when v_got_leg then 0 else v_pity + 1 end
     where id = p_player;
  end if;

  return json_build_object('ok', true, 'cards', array_to_json(v_cards),
    'pity', case when v_got_leg then 0 else v_pity + 1 end, 'count', v_count);
end; $$;

-- ── 4) Kit Elite: 1000 gemas → 1 elite garantido + 5 pacotes + recursos ─────
create or replace function public.cg_buy_kit_elite(p_player uuid)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare v_gems int; k_price constant int := 1000;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_buy_kit_elite: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select gems into v_gems from public.players where id = p_player;
  if coalesce(v_gems, 0) < k_price then
    return json_build_object('ok', false, 'reason', 'insufficient_gems');
  end if;
  update public.players set gems = gems - k_price where id = p_player;

  -- 1 pacote elite-garantido + 5 pacotes diferentes.
  insert into public.player_packs (player_id, pack_type, count) values
    (p_player, 'elite_garantido', 1),
    (p_player, 'padrao', 1),
    (p_player, 'blue',   1),
    (p_player, 'rare',   1),
    (p_player, 'epic',   1),
    (p_player, 'big',    1)
  on conflict (player_id, pack_type)
    do update set count = public.player_packs.count + excluded.count;

  -- Essência (alma épica) + poeira.
  perform public.cg_grant_resource(p_player, 'stardust', 200);
  perform public.cg_grant_resource(p_player, 'card_soul_epica', 10);

  return json_build_object('ok', true);
end; $$;

revoke all on function public.cg_buy_kit_elite(uuid) from public, anon;
grant execute on function public.cg_buy_kit_elite(uuid) to authenticated;

comment on function public.cg_buy_kit_elite is
  'Kit Elite (CEO 2026-06-12): 1000 gemas → 1 pacote elite-garantido + 5 '
  'pacotes diferentes + 200 poeira + 10 alma épica. Preço em dinheiro: a definir '
  '(monetização — etapa final). Ver [[obtencao_de_cartas]].';
