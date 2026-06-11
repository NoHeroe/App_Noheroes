-- ============================================================================
-- Card Game — TIPOS DE PACOTE (catálogo seedável) + open/buy por tipo.
--
-- Tipos definidos pelo CEO (2026-06-11):
--   Basic (padrao) / Blue / Rare (garante >=1 rara) / Big (8-10 cartas) /
--   Epic (garante >=1 epica) / Elite (chance pequena de elite) /
--   Royale (chance de Exclusiva Secreta) / New Releases (chance de carta nova
--   + chance pequena de elite).
--
-- Regras viram DADOS (pack_catalog) — quantidade, garantia de raridade, chances
-- de elite/exclusiva, preço e se é comprável. Preços em aberto ficam NULL +
-- buyable=false (obtém via grant/eventos) até o CEO cravar. Elite/Exclusiva/
-- "nova" só saem se existirem no cards_catalog (hoje não há → cai pro normal).
--
-- Basic = pack_type 'padrao' (preserva dados/Dart existentes). open_pack/
-- buy_pack viram type-aware + SECURITY DEFINER (server-authoritative).
-- ============================================================================

create table if not exists public.pack_catalog (
  pack_type         text primary key,
  display_name      text not null,
  min_count         int  not null default 5,
  max_count         int  not null default 5,
  guarantee_rarity  text,                    -- null | 'rara' | 'epica' | 'lendaria'
  elite_chance      numeric not null default 0,   -- 0..1 por carta
  exclusive_chance  numeric not null default 0,   -- 0..1 por carta (Exclusiva Secreta)
  price_gold        int,
  price_gems        int,
  buyable           boolean not null default false,
  sort              int not null default 100
);

insert into public.pack_catalog
  (pack_type, display_name, min_count, max_count, guarantee_rarity, elite_chance, exclusive_chance, price_gold, price_gems, buyable, sort) values
  ('padrao',       'Pacote Padrão',      5, 5, null,       0,     0,     224,  null, true,  10),
  ('blue',         'Pacote Azul',        5, 5, null,       0,     0,     null, null, false, 20),
  ('rare',         'Pacote Raro',        5, 5, 'rara',     0,     0,     null, null, false, 30),
  ('big',          'Pacote Grande',      8, 10,null,       0,     0,     null, null, false, 40),
  ('epic',         'Pacote Épico',       5, 5, 'epica',    0,     0,     null, null, false, 50),
  ('elite',        'Pacote Elite',       5, 5, null,       0.05,  0,     null, 300,  false, 60),
  ('royale',       'Pacote Royale',      5, 5, null,       0,     0.03,  null, null, false, 70),
  ('new_releases', 'Pacote Lançamentos', 5, 5, null,       0.03,  0,     null, null, false, 80)
on conflict (pack_type) do update set
  display_name = excluded.display_name, min_count = excluded.min_count,
  max_count = excluded.max_count, guarantee_rarity = excluded.guarantee_rarity,
  elite_chance = excluded.elite_chance, exclusive_chance = excluded.exclusive_chance,
  sort = excluded.sort;
  -- preço/buyable NÃO sobrescritos no conflito (preserva ajustes do CEO).

alter table public.pack_catalog enable row level security;
drop policy if exists "pack_catalog_read" on public.pack_catalog;
create policy "pack_catalog_read" on public.pack_catalog for select using (true);

-- ── open_pack v2: quantidade + garantia + chances por tipo ─────────────────
create or replace function public.open_pack(p_player uuid, p_type text default 'padrao')
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  k_pity   constant int := 30;
  v_pack   record; v_have int; v_count int; v_now bigint;
  v_cards  json[] := '{}'; v_pity int; v_got_leg boolean := false; v_guar_ok boolean;
  v_min_rank int; i int; v_roll numeric; v_rarity text; v_card record; v_is_new boolean;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'open_pack: forbidden' using errcode = 'insufficient_privilege';
  end if;

  select * into v_pack from public.pack_catalog where pack_type = p_type;
  if v_pack.pack_type is null then return json_build_object('ok', false, 'reason', 'unknown_pack'); end if;

  select count into v_have from public.player_packs
    where player_id = p_player and pack_type = p_type;
  if coalesce(v_have, 0) < 1 then return json_build_object('ok', false, 'reason', 'no_pack'); end if;
  update public.player_packs set count = count - 1
    where player_id = p_player and pack_type = p_type;

  v_count := v_pack.min_count
    + floor(random() * (v_pack.max_count - v_pack.min_count + 1))::int;
  v_min_rank := case v_pack.guarantee_rarity
                  when 'rara' then 2 when 'epica' then 3 when 'lendaria' then 4 else 0 end;
  v_guar_ok := (v_min_rank = 0);

  select coalesce(card_pity_counter, 0) into v_pity from public.players where id = p_player;
  v_now := (extract(epoch from now()) * 1000)::bigint;

  for i in 1..v_count loop
    if i = v_count and not v_got_leg and (v_pity + 1) >= k_pity then
      v_rarity := 'lendaria';                                  -- pity (lendária)
    elsif i = v_count and not v_guar_ok then
      v_rarity := v_pack.guarantee_rarity;                     -- garantia do pacote
    elsif v_pack.exclusive_chance > 0 and random() < v_pack.exclusive_chance then
      v_rarity := 'exclusiva';                                 -- Royale: Exclusiva Secreta
    elsif v_pack.elite_chance > 0 and random() < v_pack.elite_chance then
      v_rarity := 'elite';
    else
      v_roll := random() * 100;                                -- odds base 70/23/6/1
      v_rarity := case when v_roll < 70 then 'comum'
                       when v_roll < 93 then 'rara'
                       when v_roll < 99 then 'epica' else 'lendaria' end;
    end if;

    select id, kind, rarity into v_card from public.cards_catalog
      where rarity = v_rarity order by random() limit 1;
    if v_card.id is null then  -- raridade sem cartas (elite/exclusiva hoje) → comum
      select id, kind, rarity into v_card from public.cards_catalog
        where rarity = 'comum' order by random() limit 1;
    end if;

    if v_card.rarity = 'lendaria' then v_got_leg := true; end if;
    if (case v_card.rarity when 'rara' then 2 when 'epica' then 3
          when 'lendaria' then 4 else 1 end) >= v_min_rank then v_guar_ok := true; end if;

    insert into public.player_cards (player_id, card_id, acquired_at, source, copies)
      values (p_player, v_card.id, v_now, 'pack', 1)
      on conflict (player_id, card_id)
      do update set copies = public.player_cards.copies + 1
      returning (xmax = 0) into v_is_new;
    v_cards := array_append(v_cards, json_build_object(
      'card_id', v_card.id, 'kind', v_card.kind, 'rarity', v_card.rarity, 'is_new', v_is_new));
  end loop;

  update public.players
     set card_pity_counter = case when v_got_leg then 0 else v_pity + 1 end
   where id = p_player;

  return json_build_object('ok', true, 'cards', array_to_json(v_cards),
    'pity', case when v_got_leg then 0 else v_pity + 1 end, 'count', v_count);
end; $$;

-- ── buy_pack v2: preço/moeda por tipo ──────────────────────────────────────
create or replace function public.buy_pack(p_player uuid, p_type text default 'padrao')
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare v_pack record; v_gold int; v_gems int;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'buy_pack: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select * into v_pack from public.pack_catalog where pack_type = p_type;
  if v_pack.pack_type is null or not v_pack.buyable then
    return json_build_object('ok', false, 'reason', 'not_buyable');
  end if;

  if coalesce(v_pack.price_gems, 0) > 0 then
    select gems into v_gems from public.players where id = p_player;
    if coalesce(v_gems, 0) < v_pack.price_gems then
      return json_build_object('ok', false, 'reason', 'insufficient_gems');
    end if;
    update public.players set gems = gems - v_pack.price_gems where id = p_player;
  elsif coalesce(v_pack.price_gold, 0) > 0 then
    select gold into v_gold from public.players where id = p_player;
    if coalesce(v_gold, 0) < v_pack.price_gold then
      return json_build_object('ok', false, 'reason', 'insufficient_gold');
    end if;
    update public.players set gold = gold - v_pack.price_gold where id = p_player;
  else
    return json_build_object('ok', false, 'reason', 'not_buyable');
  end if;

  insert into public.player_packs (player_id, pack_type, count)
    values (p_player, p_type, 1)
  on conflict (player_id, pack_type) do update set count = public.player_packs.count + 1;
  return json_build_object('ok', true);
end; $$;

-- ── DEV: concede 1 de cada tipo de pacote (teste) ──────────────────────────
create or replace function public.dev_grant_all_packs(p_player uuid)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare t text;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'dev_grant_all_packs: forbidden' using errcode = 'insufficient_privilege';
  end if;
  for t in select pack_type from public.pack_catalog loop
    insert into public.player_packs (player_id, pack_type, count)
      values (p_player, t, 3)
    on conflict (player_id, pack_type) do update set count = public.player_packs.count + 3;
  end loop;
  return json_build_object('ok', true);
end; $$;

comment on table public.pack_catalog is
  'Catálogo de tipos de pacote (regras + preço). Preços NULL = a definir. '
  'Ver [[pacotes]] e [[obtencao_de_cartas]].';
