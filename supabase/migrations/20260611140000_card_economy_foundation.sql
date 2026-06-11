-- ============================================================================
-- Card Game — ECONOMIA: fundação (cópias, nível, recursos) + acúmulo de
-- duplicata no open_pack.
--
-- Épico de craft/upgrade ([[criar]], [[desencantar]], [[aprimorar]]). Esta
-- migration estabelece só a FUNDAÇÃO de dados; as RPCs de criar/desencantar/
-- aprimorar vêm em migration própria (com as tabelas de custo do vault).
-- Decisões de modelagem documentadas em ADR-0027.
--
-- 1) player_cards ganha `copies` (acúmulo estilo Clash Royale — combustível de
--    evolução) e `level` (1..8 criatura / 1..5 relíquia).
-- 2) player_cg_resources: bolsa chave→valor dos recursos do card game (dust,
--    crystals por raridade, scrolls/runes, soul crystals). Chave-valor (não
--    14 colunas) porque o conjunto é grande, provisório e extensível.
-- 3) open_pack: duplicata agora ACUMULA cópia (era `do nothing`); `is_new`
--    passa a significar "primeira cópia" via (xmax = 0).
-- ============================================================================

-- 1) Cópias + nível por carta possuída.
alter table public.player_cards
  add column if not exists copies int not null default 1,
  add column if not exists level  int not null default 1;

-- 2) Bolsa de recursos do card game (chave→valor). Chaves canônicas (ADR-0027):
--    card_dust, relic_dust,
--    card_scroll, relic_runes,
--    card_soul, relic_soul,
--    card_crystal_<raridade>, relic_crystal_<raridade>  (comum|rara|epica|lendaria)
create table if not exists public.player_cg_resources (
  player_id    uuid   not null references public.players (id) on delete cascade,
  resource_key text   not null,
  amount       bigint not null default 0,
  primary key (player_id, resource_key)
);

alter table public.player_cg_resources enable row level security;

drop policy if exists "player_cg_resources_own" on public.player_cg_resources;
create policy "player_cg_resources_own" on public.player_cg_resources
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);

comment on table public.player_cg_resources is
  'Recursos do card game (dust/crystal/scroll/soul) por jogador, chave->valor. '
  'Ver ADR-0027 e [[economia_e_recursos]].';

-- 3) open_pack: acumula duplicata em `copies` (era `on conflict do nothing`).
--    is_new = primeira cópia (xmax = 0). Resto idêntico ao pity vigente.
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
    -- Duplicata acumula cópia (combustível de evolução). xmax = 0 → inserção
    -- nova (primeira cópia) = is_new; senão foi update (já possuía).
    insert into public.player_cards (player_id, card_id, acquired_at, source, copies)
      values (p_player, v_card.id, v_now, 'pack', 1)
      on conflict (player_id, card_id)
      do update set copies = public.player_cards.copies + 1
      returning (xmax = 0) into v_is_new;
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
  'Abre 1 pacote (5 cartas, odds 70/23/6/1) com PITY (lendária a cada 30 sem '
  'uma). Duplicata acumula cópia em player_cards.copies; is_new = 1a cópia.';
