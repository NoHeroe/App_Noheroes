-- ============================================================================
-- Card Game — ECONOMIA: tabelas de custo (seed) + RPCs criar/desencantar/aprimorar.
--
-- Números TRANSCRITOS do vault ([[criar]], [[desencantar]], [[aprimorar]]) —
-- marcados como rascunho/provisório; por isso ficam como DADOS seedados
-- (editar seed + re-rodar pra rebalancear, sem mexer nas RPCs). Curva de CÓPIAS
-- proposta (estilo Clash Royale), também seedável. Ver ADR-0027.
--
-- Depende de 20260611140000 (player_cards.copies/level + player_cg_resources).
-- NÃO aplicada até o CEO dar db push.
-- ============================================================================

-- ── Tabelas de custo (dados) ────────────────────────────────────────────────

-- Criar: custo por (kind, rarity) = dust + 1 crystal da raridade.
create table if not exists public.card_craft_costs (
  kind   text not null,            -- 'creature' | 'relic'
  rarity text not null,            -- comum|rara|epica|lendaria
  dust   int  not null,
  crystal int not null default 1,
  primary key (kind, rarity)
);

-- Desencantar: retorno por (kind, rarity, level) = dust + mat (scroll/runes).
-- (+1 crystal da raridade é regra fixa, aplicada na RPC.)
create table if not exists public.card_disenchant_returns (
  kind   text not null,
  rarity text not null,
  level  int  not null,            -- nível atual da carta (1..8 / 1..5)
  dust   int  not null,
  mat    int  not null,            -- card_scroll (creature) | relic_runes (relic)
  primary key (kind, rarity, level)
);

-- Aprimorar: custo da transição from_level -> from_level+1 = gold + mat + soul.
create table if not exists public.card_upgrade_costs (
  kind       text not null,
  rarity     text not null,
  from_level int  not null,        -- 1..7 (creature) | 1..4 (relic)
  gold       int  not null,
  mat        int  not null,        -- card_scroll | relic_runes
  soul       int  not null,        -- card_soul   | relic_soul
  primary key (kind, rarity, from_level)
);

-- Aprimorar: cópias exigidas na transição (curva proposta — seedável).
create table if not exists public.card_upgrade_copies (
  kind       text not null,
  rarity     text not null,
  from_level int  not null,
  copies     int  not null,
  primary key (kind, rarity, from_level)
);

-- ── Seeds (idempotentes) ────────────────────────────────────────────────────

-- Criar (criar.md).
insert into public.card_craft_costs (kind, rarity, dust, crystal) values
  ('creature','comum',   20,1), ('creature','rara',  145,1),
  ('creature','epica', 1200,1), ('creature','lendaria',2300,1),
  ('relic','comum',      20,1), ('relic','rara',       95,1),
  ('relic','epica',     580,1), ('relic','lendaria', 1000,1)
on conflict (kind, rarity) do update
  set dust = excluded.dust, crystal = excluded.crystal;

-- Desencantar (desencantar.md). dust por nível + mat (scroll/runes) por nível.
-- Creature scroll por nível (igual p/ todas raridades): 0,2,4,8,14,32,64,112.
-- Relic runes por nível: 0,6,16,44,112.
insert into public.card_disenchant_returns (kind, rarity, level, dust, mat) values
  -- creature comum
  ('creature','comum',1,2,0),('creature','comum',2,10,2),('creature','comum',3,30,4),
  ('creature','comum',4,70,8),('creature','comum',5,120,14),('creature','comum',6,250,32),
  ('creature','comum',7,430,64),('creature','comum',8,670,112),
  -- creature rara
  ('creature','rara',1,20,0),('creature','rara',2,20,2),('creature','rara',3,60,4),
  ('creature','rara',4,120,8),('creature','rara',5,250,14),('creature','rara',6,380,32),
  ('creature','rara',7,560,64),('creature','rara',8,800,112),
  -- creature epica
  ('creature','epica',1,195,0),('creature','epica',2,30,2),('creature','epica',3,80,4),
  ('creature','epica',4,170,8),('creature','epica',5,300,14),('creature','epica',6,480,32),
  ('creature','epica',7,740,64),('creature','epica',8,1100,112),
  -- creature lendaria
  ('creature','lendaria',1,575,0),('creature','lendaria',2,40,2),('creature','lendaria',3,100,4),
  ('creature','lendaria',4,200,8),('creature','lendaria',5,380,14),('creature','lendaria',6,600,32),
  ('creature','lendaria',7,900,64),('creature','lendaria',8,1300,112),
  -- relic comum (L1..L5)
  ('relic','comum',1,2,0),('relic','comum',2,40,6),('relic','comum',3,90,16),
  ('relic','comum',4,150,44),('relic','comum',5,230,112),
  -- relic rara
  ('relic','rara',1,15,0),('relic','rara',2,50,6),('relic','rara',3,150,16),
  ('relic','rara',4,180,44),('relic','rara',5,270,112),
  -- relic epica
  ('relic','epica',1,100,0),('relic','epica',2,90,6),('relic','epica',3,270,16),
  ('relic','epica',4,550,44),('relic','epica',5,940,112),
  -- relic lendaria
  ('relic','lendaria',1,250,0),('relic','lendaria',2,110,6),('relic','lendaria',3,260,16),
  ('relic','lendaria',4,470,44),('relic','lendaria',5,760,112)
on conflict (kind, rarity, level) do update
  set dust = excluded.dust, mat = excluded.mat;

-- Aprimorar (aprimorar.md, detalhe por transição: gold/mat/soul).
insert into public.card_upgrade_costs (kind, rarity, from_level, gold, mat, soul) values
  -- creature comum (1->2 ... 7->8)
  ('creature','comum',1,2,30,5),('creature','comum',2,10,50,5),('creature','comum',3,20,100,10),
  ('creature','comum',4,30,150,15),('creature','comum',5,60,300,45),('creature','comum',6,120,450,80),
  ('creature','comum',7,240,600,120),
  -- creature rara
  ('creature','rara',1,10,50,5),('creature','rara',2,30,100,5),('creature','rara',3,60,200,10),
  ('creature','rara',4,100,250,15),('creature','rara',5,200,350,45),('creature','rara',6,400,450,80),
  ('creature','rara',7,600,600,120),
  -- creature epica
  ('creature','epica',1,60,100,5),('creature','epica',2,160,150,5),('creature','epica',3,320,200,10),
  ('creature','epica',4,640,300,15),('creature','epica',5,1300,450,45),('creature','epica',6,2500,650,80),
  ('creature','epica',7,4500,900,120),
  -- creature lendaria
  ('creature','lendaria',1,255,110,5),('creature','lendaria',2,545,170,5),('creature','lendaria',3,1190,270,10),
  ('creature','lendaria',4,2540,400,15),('creature','lendaria',5,3500,550,45),('creature','lendaria',6,4500,750,80),
  ('creature','lendaria',7,5500,1000,120),
  -- relic comum (1->2 ... 4->5)
  ('relic','comum',1,35,130,15),('relic','comum',2,65,170,25),('relic','comum',3,110,210,70),
  ('relic','comum',4,155,260,170),
  -- relic rara
  ('relic','rara',1,100,250,15),('relic','rara',2,165,300,25),('relic','rara',3,250,350,70),
  ('relic','rara',4,335,400,170),
  -- relic epica
  ('relic','epica',1,515,200,15),('relic','epica',2,1300,400,25),('relic','epica',3,3000,650,70),
  ('relic','epica',4,5000,1000,170),
  -- relic lendaria
  ('relic','lendaria',1,1375,300,15),('relic','lendaria',2,4000,400,25),('relic','lendaria',3,5500,550,70),
  ('relic','lendaria',4,8000,750,170)
on conflict (kind, rarity, from_level) do update
  set gold = excluded.gold, mat = excluded.mat, soul = excluded.soul;

-- Curva de CÓPIAS por transição (proposta, estilo Clash Royale — seedável).
insert into public.card_upgrade_copies (kind, rarity, from_level, copies) values
  ('creature','comum',1,2),('creature','comum',2,4),('creature','comum',3,10),('creature','comum',4,20),
  ('creature','comum',5,50),('creature','comum',6,100),('creature','comum',7,200),
  ('creature','rara',1,1),('creature','rara',2,2),('creature','rara',3,4),('creature','rara',4,10),
  ('creature','rara',5,20),('creature','rara',6,50),('creature','rara',7,100),
  ('creature','epica',1,1),('creature','epica',2,1),('creature','epica',3,2),('creature','epica',4,4),
  ('creature','epica',5,10),('creature','epica',6,20),('creature','epica',7,40),
  ('creature','lendaria',1,1),('creature','lendaria',2,1),('creature','lendaria',3,1),('creature','lendaria',4,2),
  ('creature','lendaria',5,4),('creature','lendaria',6,8),('creature','lendaria',7,16),
  ('relic','comum',1,2),('relic','comum',2,4),('relic','comum',3,10),('relic','comum',4,20),
  ('relic','rara',1,1),('relic','rara',2,2),('relic','rara',3,4),('relic','rara',4,10),
  ('relic','epica',1,1),('relic','epica',2,1),('relic','epica',3,2),('relic','epica',4,4),
  ('relic','lendaria',1,1),('relic','lendaria',2,1),('relic','lendaria',3,1),('relic','lendaria',4,2)
on conflict (kind, rarity, from_level) do update set copies = excluded.copies;

-- ── Helpers de recurso ──────────────────────────────────────────────────────

-- Credita (delta>0) ou ajusta um recurso na bolsa do jogador.
create or replace function public.cg_grant_resource(p_player uuid, p_key text, p_delta bigint)
  returns void language plpgsql security invoker as $$
begin
  insert into public.player_cg_resources (player_id, resource_key, amount)
    values (p_player, p_key, greatest(p_delta, 0))
  on conflict (player_id, resource_key)
    do update set amount = public.player_cg_resources.amount + p_delta;
end; $$;

-- Lê o saldo de um recurso (0 se ausente).
create or replace function public.cg_resource_amount(p_player uuid, p_key text)
  returns bigint language sql stable security invoker as $$
  select coalesce((select amount from public.player_cg_resources
                   where player_id = p_player and resource_key = p_key), 0);
$$;

-- ── RPC: criar carta ────────────────────────────────────────────────────────
create or replace function public.cg_create_card(p_player uuid, p_card_id text)
  returns json language plpgsql security invoker as $$
declare
  v_level int; v_card record; v_cost record;
  v_dust_key text; v_crys_key text; v_now bigint := (extract(epoch from now())*1000)::bigint;
  v_dust bigint; v_crys bigint;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_create_card: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select level into v_level from public.players where id = p_player;
  if coalesce(v_level,1) < 3 then return json_build_object('ok',false,'reason','locked_level'); end if;

  select id, kind, rarity into v_card from public.cards_catalog where id = p_card_id;
  if v_card.id is null then return json_build_object('ok',false,'reason','unknown_card'); end if;
  if v_card.rarity not in ('comum','rara','epica','lendaria') then
    return json_build_object('ok',false,'reason','not_craftable'); -- elite/exclusiva
  end if;

  select dust, crystal into v_cost from public.card_craft_costs
    where kind = v_card.kind and rarity = v_card.rarity;
  if v_cost.dust is null then return json_build_object('ok',false,'reason','no_cost'); end if;

  v_dust_key := case when v_card.kind = 'relic' then 'relic_dust' else 'card_dust' end;
  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;
  v_dust := public.cg_resource_amount(p_player, v_dust_key);
  v_crys := public.cg_resource_amount(p_player, v_crys_key);
  if v_dust < v_cost.dust or v_crys < v_cost.crystal then
    return json_build_object('ok',false,'reason','insufficient_resources');
  end if;

  perform public.cg_grant_resource(p_player, v_dust_key, -v_cost.dust);
  perform public.cg_grant_resource(p_player, v_crys_key, -v_cost.crystal);
  insert into public.player_cards (player_id, card_id, acquired_at, source, copies, level)
    values (p_player, p_card_id, v_now, 'crafted', 1, 1)
  on conflict (player_id, card_id) do update
    set copies = public.player_cards.copies + 1;
  return json_build_object('ok',true,'card_id',p_card_id);
end; $$;

-- ── RPC: desencantar carta ──────────────────────────────────────────────────
create or replace function public.cg_disenchant_card(p_player uuid, p_card_id text)
  returns json language plpgsql security invoker as $$
declare
  v_plevel int; v_card record; v_owned record; v_ret record;
  v_dust_key text; v_mat_key text; v_crys_key text;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_disenchant_card: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select level into v_plevel from public.players where id = p_player;
  if coalesce(v_plevel,1) < 3 then return json_build_object('ok',false,'reason','locked_level'); end if;

  select id, kind, rarity into v_card from public.cards_catalog where id = p_card_id;
  if v_card.id is null then return json_build_object('ok',false,'reason','unknown_card'); end if;
  if v_card.rarity not in ('comum','rara','epica','lendaria') then
    return json_build_object('ok',false,'reason','not_disenchantable');
  end if;

  select copies, level into v_owned from public.player_cards
    where player_id = p_player and card_id = p_card_id;
  if v_owned.copies is null then return json_build_object('ok',false,'reason','not_owned'); end if;

  select dust, mat into v_ret from public.card_disenchant_returns
    where kind = v_card.kind and rarity = v_card.rarity and level = v_owned.level;
  if v_ret.dust is null then return json_build_object('ok',false,'reason','no_return'); end if;

  v_dust_key := case when v_card.kind = 'relic' then 'relic_dust' else 'card_dust' end;
  v_mat_key  := case when v_card.kind = 'relic' then 'relic_runes' else 'card_scroll' end;
  v_crys_key := (case when v_card.kind = 'relic' then 'relic_crystal_' else 'card_crystal_' end) || v_card.rarity;

  perform public.cg_grant_resource(p_player, v_dust_key, v_ret.dust);
  perform public.cg_grant_resource(p_player, v_mat_key,  v_ret.mat);
  perform public.cg_grant_resource(p_player, v_crys_key, 1); -- +1 crystal da raridade (fixo)

  if v_owned.copies > 1 then
    update public.player_cards set copies = copies - 1
      where player_id = p_player and card_id = p_card_id;
  else
    delete from public.player_cards
      where player_id = p_player and card_id = p_card_id;
  end if;
  return json_build_object('ok',true,'card_id',p_card_id,
    'dust',v_ret.dust,'mat',v_ret.mat,'crystal',1);
end; $$;

-- ── RPC: aprimorar carta ────────────────────────────────────────────────────
create or replace function public.cg_upgrade_card(p_player uuid, p_card_id text)
  returns json language plpgsql security invoker as $$
declare
  v_plevel int; v_card record; v_owned record; v_cost record; v_copies_req int;
  v_max int; v_mat_key text; v_soul_key text; v_gold int; v_have_mat bigint; v_have_soul bigint;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'cg_upgrade_card: forbidden' using errcode = 'insufficient_privilege';
  end if;
  select level into v_plevel from public.players where id = p_player;
  if coalesce(v_plevel,1) < 5 then return json_build_object('ok',false,'reason','locked_level'); end if;

  select id, kind, rarity into v_card from public.cards_catalog where id = p_card_id;
  if v_card.id is null then return json_build_object('ok',false,'reason','unknown_card'); end if;

  select copies, level into v_owned from public.player_cards
    where player_id = p_player and card_id = p_card_id;
  if v_owned.copies is null then return json_build_object('ok',false,'reason','not_owned'); end if;

  v_max := case when v_card.kind = 'relic' then 5 else 8 end;
  if v_owned.level >= v_max then return json_build_object('ok',false,'reason','max_level'); end if;

  select gold, mat, soul into v_cost from public.card_upgrade_costs
    where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
  if v_cost.gold is null then return json_build_object('ok',false,'reason','no_cost'); end if;
  select copies into v_copies_req from public.card_upgrade_copies
    where kind = v_card.kind and rarity = v_card.rarity and from_level = v_owned.level;
  v_copies_req := coalesce(v_copies_req, 0);

  v_mat_key  := case when v_card.kind = 'relic' then 'relic_runes' else 'card_scroll' end;
  v_soul_key := case when v_card.kind = 'relic' then 'relic_soul'  else 'card_soul' end;
  v_have_mat  := public.cg_resource_amount(p_player, v_mat_key);
  v_have_soul := public.cg_resource_amount(p_player, v_soul_key);
  select gold into v_gold from public.players where id = p_player;

  -- precisa de cópias EXTRAS (além da que mantém a carta): copies > copies_req
  if v_gold < v_cost.gold or v_have_mat < v_cost.mat or v_have_soul < v_cost.soul
     or v_owned.copies <= v_copies_req then
    return json_build_object('ok',false,'reason','insufficient',
      'need_copies', v_copies_req, 'have_copies', v_owned.copies);
  end if;

  update public.players set gold = gold - v_cost.gold where id = p_player;
  perform public.cg_grant_resource(p_player, v_mat_key,  -v_cost.mat);
  perform public.cg_grant_resource(p_player, v_soul_key, -v_cost.soul);
  update public.player_cards
     set level = level + 1, copies = copies - v_copies_req
   where player_id = p_player and card_id = p_card_id;

  return json_build_object('ok',true,'card_id',p_card_id,'new_level',v_owned.level + 1);
end; $$;
