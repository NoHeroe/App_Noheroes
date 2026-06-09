-- ============================================================================
-- Card Game — economia de pacotes (server-authoritative).
-- player_packs = inventario de pacotes nao-abertos. RPCs: grant/buy/open.
-- Pacote = 5 cartas (pacotes.md). Odds por raridade TUNAVEIS 🎚️ (sem pity no MVP).
-- Elite/Exclusiva NAO saem de pacote (raridades.md). Sorteio via cards_catalog.
-- ============================================================================
create table public.player_packs (
  player_id uuid not null references public.players (id) on delete cascade,
  pack_type text not null default 'padrao',
  count     int  not null default 0,
  primary key (player_id, pack_type)
);
alter table public.player_packs enable row level security;
create policy "player_packs_own" on public.player_packs
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);

-- +N pacotes (fonte: eventos, level-up, etc.). Idempotencia nao se aplica (acumula).
create or replace function public.grant_pack(p_player uuid, p_count int, p_type text default 'padrao')
  returns void language plpgsql security invoker as $$
begin
  if auth.uid() is not null and auth.uid() <> p_player then
    raise exception 'grant_pack: forbidden' using errcode = 'insufficient_privilege';
  end if;
  insert into public.player_packs (player_id, pack_type, count)
  values (p_player, p_type, greatest(p_count, 0))
  on conflict (player_id, pack_type)
    do update set count = public.player_packs.count + greatest(p_count, 0);
end; $$;

-- Compra 1 pacote por 224 gold (atomico). 🎚️ preco tunavel.
create or replace function public.buy_pack(p_player uuid, p_type text default 'padrao')
  returns json language plpgsql security invoker as $$
declare v_price int := 224; v_gold int;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'buy_pack: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select gold into v_gold from public.players where id = p_player;
  if coalesce(v_gold, 0) < v_price then
    return json_build_object('ok', false, 'reason', 'insufficient_gold', 'price', v_price);
  end if;
  update public.players set gold = gold - v_price where id = p_player;
  perform public.grant_pack(p_player, 1, p_type);
  return json_build_object('ok', true, 'price', v_price);
end; $$;

-- Abre 1 pacote: sorteia 5 cartas por raridade, grava em player_cards. Retorna as 5.
create or replace function public.open_pack(p_player uuid, p_type text default 'padrao')
  returns json language plpgsql security invoker as $$
declare
  v_count int;
  v_now   bigint := (extract(epoch from now()) * 1000)::bigint;
  v_cards json[] := '{}';
  i int; v_roll numeric; v_rarity text; v_card record; v_is_new boolean;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'open_pack: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select count into v_count from public.player_packs
    where player_id = p_player and pack_type = p_type;
  if coalesce(v_count, 0) < 1 then
    return json_build_object('ok', false, 'reason', 'no_pack');
  end if;
  update public.player_packs set count = count - 1
    where player_id = p_player and pack_type = p_type;
  for i in 1..5 loop
    -- 🎚️ odds por carta: comum 70 / rara 23 / epica 6 / lendaria 1
    v_roll := random() * 100;
    v_rarity := case when v_roll < 70 then 'comum'
                     when v_roll < 93 then 'rara'
                     when v_roll < 99 then 'epica'
                     else 'lendaria' end;
    select id, kind, rarity into v_card from public.cards_catalog
      where rarity = v_rarity order by random() limit 1;
    if v_card.id is null then
      select id, kind, rarity into v_card from public.cards_catalog
        where rarity = 'comum' order by random() limit 1;
    end if;
    insert into public.player_cards (player_id, card_id, acquired_at, source)
      values (p_player, v_card.id, v_now, 'pack')
      on conflict (player_id, card_id) do nothing;
    v_is_new := found;
    v_cards := array_append(v_cards, json_build_object(
      'card_id', v_card.id, 'kind', v_card.kind, 'rarity', v_card.rarity, 'is_new', v_is_new));
  end loop;
  return json_build_object('ok', true, 'cards', array_to_json(v_cards));
end; $$;
