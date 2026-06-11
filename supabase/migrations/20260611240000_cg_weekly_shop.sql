-- ============================================================================
-- Card Game — ECONOMIA v1, BLOCO 6: LOJA SEMANAL (Mercado).
--
-- SPEC: estoque fixo semanal (Lascas 2 lotes/tipo, Essências comum/rara 2
-- lotes/tipo, Cristal comum/raro 1/tipo) em OURO; limite semanal por item;
-- comprar além do limite custa GEMAS; 1 slot ROTATIVO raro (essência/cristal
-- épico+ por gemas). Reset semanal (semana ISO — alinhado ao relógio semanal).
--
-- Tabelas: shop_weekly_catalog (estoque, seedável) + player_shop_purchases
-- (contagem por jogador×item×semana). RPCs: cg_shop_state (lista + saldos +
-- rotativo), cg_shop_buy (compra server-authoritative).
-- ============================================================================

create table if not exists public.shop_weekly_catalog (
  item_key      text primary key,
  display_name  text not null,
  resource_key  text not null,   -- recurso concedido
  amount        int  not null,   -- quantidade por compra
  price_gold    int  not null,
  price_gems    int  not null,   -- preço além do limite (gemas)
  weekly_limit  int  not null default 2,
  sort          int  not null default 100
);

insert into public.shop_weekly_catalog
  (item_key, display_name, resource_key, amount, price_gold, price_gems, weekly_limit, sort) values
  ('lasca_card',         'Lascas de Carta',       'card_shard',          50, 400, 40, 2, 10),
  ('lasca_relic',        'Lascas de Relíquia',    'relic_shard',         50, 400, 40, 2, 11),
  ('soul_card_comum',    'Essência Criatura (C)', 'card_soul_comum',     10, 300, 30, 2, 20),
  ('soul_card_rara',     'Essência Criatura (R)', 'card_soul_rara',      10, 600, 50, 2, 21),
  ('soul_relic_comum',   'Essência Relíquia (C)', 'relic_soul_comum',    10, 300, 30, 2, 22),
  ('soul_relic_rara',    'Essência Relíquia (R)', 'relic_soul_rara',     10, 600, 50, 2, 23),
  ('crystal_card_comum', 'Cristal Carta (C)',     'card_crystal_comum',   1, 200, 20, 1, 30),
  ('crystal_card_rara',  'Cristal Carta (R)',     'card_crystal_rara',    1, 500, 40, 1, 31),
  ('crystal_relic_comum','Cristal Relíquia (C)',  'relic_crystal_comum',  1, 200, 20, 1, 32),
  ('crystal_relic_rara', 'Cristal Relíquia (R)',  'relic_crystal_rara',   1, 500, 40, 1, 33)
on conflict (item_key) do update set
  display_name = excluded.display_name, resource_key = excluded.resource_key,
  amount = excluded.amount, weekly_limit = excluded.weekly_limit, sort = excluded.sort;

alter table public.shop_weekly_catalog enable row level security;
drop policy if exists "shop_weekly_catalog_read" on public.shop_weekly_catalog;
create policy "shop_weekly_catalog_read" on public.shop_weekly_catalog for select using (true);

create table if not exists public.player_shop_purchases (
  player_id uuid not null references public.players (id) on delete cascade,
  item_key  text not null,
  week_id   text not null,           -- 'IYYY-IW' (semana ISO)
  count     int  not null default 0,
  primary key (player_id, item_key, week_id)
);
alter table public.player_shop_purchases enable row level security;
drop policy if exists "player_shop_purchases_read" on public.player_shop_purchases;
create policy "player_shop_purchases_read" on public.player_shop_purchases
  for select using (auth.uid() = player_id);

-- Slot ROTATIVO: lista fixa de ofertas épico+ (gemas); a da semana sai por
-- hash do week_id. (Função imutável pra reuso.)
create or replace function public.cg_shop_rotative(p_week text)
  returns json language plpgsql immutable as $$
declare
  v_offers json[] := array[
    json_build_object('key','rot_soul_card_epica',  'name','Essência Criatura (É)','resource','card_soul_epica',    'amount',5,'gems',120),
    json_build_object('key','rot_soul_relic_epica', 'name','Essência Relíquia (É)','resource','relic_soul_epica',   'amount',5,'gems',120),
    json_build_object('key','rot_crys_card_epica',  'name','Cristal Carta (É)',    'resource','card_crystal_epica', 'amount',1,'gems',150),
    json_build_object('key','rot_crys_relic_epica', 'name','Cristal Relíquia (É)', 'resource','relic_crystal_epica','amount',1,'gems',150),
    json_build_object('key','rot_soul_card_lend',   'name','Essência Criatura (L)','resource','card_soul_lendaria', 'amount',3,'gems',260),
    json_build_object('key','rot_crys_card_lend',   'name','Cristal Carta (L)',    'resource','card_crystal_lendaria','amount',1,'gems',300)
  ];
  v_n int := array_length(v_offers, 1);
  v_i int := (abs(hashtext(p_week)) % v_n) + 1;
begin
  return v_offers[v_i];
end; $$;

-- Estado da loja: catálogo + contagem da semana + oferta rotativa.
create or replace function public.cg_shop_state(p_player uuid)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_week text := to_char(now() at time zone 'utc', 'IYYY-IW');
  v_items json;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_shop_state: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select json_agg(row_to_json(t) order by t.sort) into v_items from (
    select c.item_key, c.display_name, c.resource_key, c.amount, c.price_gold,
           c.price_gems, c.weekly_limit, c.sort,
           coalesce(p.count, 0) as bought
    from public.shop_weekly_catalog c
    left join public.player_shop_purchases p
      on p.player_id = p_player and p.item_key = c.item_key and p.week_id = v_week
  ) t;
  return json_build_object('ok', true, 'week', v_week,
    'items', coalesce(v_items, '[]'::json),
    'rotative', public.cg_shop_rotative(v_week));
end; $$;

-- Compra: item normal (ouro até o limite, gemas além) ou rotativo (gemas).
create or replace function public.cg_shop_buy(p_player uuid, p_item_key text)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare
  v_week text := to_char(now() at time zone 'utc', 'IYYY-IW');
  v_item record; v_bought int; v_rot json; v_gems int; v_gold int;
  v_use_gems boolean;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_shop_buy: forbidden' using errcode = 'insufficient_privilege';
  end if;

  if p_item_key = 'rotative' then
    v_rot := public.cg_shop_rotative(v_week);
    select gems into v_gems from public.players where id = p_player;
    if coalesce(v_gems, 0) < (v_rot->>'gems')::int then
      return json_build_object('ok', false, 'reason', 'insufficient_gems');
    end if;
    update public.players set gems = gems - (v_rot->>'gems')::int where id = p_player;
    perform public.cg_grant_resource(p_player, v_rot->>'resource', (v_rot->>'amount')::int);
    return json_build_object('ok', true, 'resource', v_rot->>'resource');
  end if;

  select * into v_item from public.shop_weekly_catalog where item_key = p_item_key;
  if v_item.item_key is null then return json_build_object('ok', false, 'reason', 'unknown_item'); end if;

  select coalesce(count, 0) into v_bought from public.player_shop_purchases
    where player_id = p_player and item_key = p_item_key and week_id = v_week;
  v_bought := coalesce(v_bought, 0);
  v_use_gems := v_bought >= v_item.weekly_limit; -- além do limite → gemas

  if v_use_gems then
    select gems into v_gems from public.players where id = p_player;
    if coalesce(v_gems, 0) < v_item.price_gems then
      return json_build_object('ok', false, 'reason', 'insufficient_gems');
    end if;
    update public.players set gems = gems - v_item.price_gems where id = p_player;
  else
    select gold into v_gold from public.players where id = p_player;
    if coalesce(v_gold, 0) < v_item.price_gold then
      return json_build_object('ok', false, 'reason', 'insufficient_gold');
    end if;
    update public.players set gold = gold - v_item.price_gold where id = p_player;
  end if;

  perform public.cg_grant_resource(p_player, v_item.resource_key, v_item.amount);
  insert into public.player_shop_purchases (player_id, item_key, week_id, count)
    values (p_player, p_item_key, v_week, 1)
  on conflict (player_id, item_key, week_id)
    do update set count = public.player_shop_purchases.count + 1;
  return json_build_object('ok', true, 'paid', case when v_use_gems then 'gems' else 'gold' end);
end; $$;

comment on table public.shop_weekly_catalog is
  'Loja semanal do card game (estoque fixo seedável). Ver economia_e_recursos.';
