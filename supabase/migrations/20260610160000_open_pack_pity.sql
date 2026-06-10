-- ============================================================================
-- Card Game — PITY no open_pack (ponto #7, parte 1).
--
-- Design ([[pacotes]]): garante 1 LENDÁRIA a cada 30 pacotes abertos SEM
-- nenhuma lendária. O contador reseta ao receber uma lendária (natural ou pela
-- garantia). 🎚️ k_pity = 30.
--
-- Duplicata: a direção (estilo Clash Royale — acumular cópias + ouro + dust pra
-- evoluir cartas) fica para o épico de craft/upgrade ([[desencantar]]). Aqui o
-- comportamento de duplicata NÃO muda (segue `on conflict do nothing`).
--
-- Estende open_pack (create or replace). Reproduz o corpo de
-- 20260609200000_packs_rpc.sql + a lógica de pity.
-- ============================================================================

-- Contador de pity: pacotes abertos desde a última lendária.
alter table public.players
  add column if not exists card_pity_counter int not null default 0;

create or replace function public.open_pack(p_player uuid, p_type text default 'padrao')
  returns json language plpgsql security invoker as $$
declare
  k_pity   constant int := 30; -- 🎚️ pacotes sem lendária até a garantia
  v_count  int;
  v_now    bigint := (extract(epoch from now()) * 1000)::bigint;
  v_cards  json[] := '{}';
  v_pity   int;
  v_got_leg boolean := false;
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

  select card_pity_counter into v_pity from public.players where id = p_player;
  v_pity := coalesce(v_pity, 0);

  for i in 1..5 loop
    -- Pity: se até a 5ª carta nenhuma lendária saiu E este é o pacote da
    -- garantia (v_pity+1 == k_pity), força a última como lendária.
    if i = 5 and not v_got_leg and (v_pity + 1) >= k_pity then
      v_rarity := 'lendaria';
    else
      -- 🎚️ odds por carta: comum 70 / rara 23 / epica 6 / lendaria 1
      v_roll := random() * 100;
      v_rarity := case when v_roll < 70 then 'comum'
                       when v_roll < 93 then 'rara'
                       when v_roll < 99 then 'epica'
                       else 'lendaria' end;
    end if;
    if v_rarity = 'lendaria' then v_got_leg := true; end if;

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

  -- Atualiza o pity: zera ao receber lendária; senão +1.
  update public.players
     set card_pity_counter = case when v_got_leg then 0 else v_pity + 1 end
   where id = p_player;

  return json_build_object(
    'ok', true,
    'cards', array_to_json(v_cards),
    'pity', case when v_got_leg then 0 else v_pity + 1 end
  );
end; $$;

comment on function public.open_pack(uuid, text) is
  'Abre 1 pacote (5 cartas, odds 70/23/6/1) com PITY: garante lendária a cada '
  '30 pacotes sem uma. Retorna {ok, cards[], pity}.';
