-- ============================================================================
-- NoHeroes — RPCs do domínio "Inventory + Equipment + Shops + Rank" (Época 2)
-- ADR-0024 (full-online Supabase). plpgsql / schema public.
-- ----------------------------------------------------------------------------
-- Porte fiel da lógica Dart:
--   inventory_add_item  <- PlayerInventoryService.addItem (stacking por stack_max)
--   equipment_equip     <- PlayerEquipmentService.equip   (desequipa ocupante)
--   equipment_unequip   <- PlayerEquipmentService.unequip
--   shop_buy_item       <- ShopsService.buyItem (débito de moeda + addItem, atômico)
--   set_guild_rank      <- PlayerRankService.setRank + _evolveCollarIfPresent
--   inventory_reset     <- PlayerInventoryService.resetInventoryFor
--
-- Cada corpo é UMA transação implícita (commit/rollback atômico) — é por isso
-- que essas operações multi-statement viram RPC (REST não tem transação).
--
-- SEGURANÇA: SECURITY INVOKER em tudo. A RLS "auth.uid() = player_id" em
-- player_inventory / player_equipment / players já garante que o cliente só
-- escreve as próprias linhas. Mantemos a assinatura canônica que recebe
-- p_player uuid (vindo do caller Dart), mas a RLS é a fronteira de verdade.
-- ============================================================================


-- ───────────────────────────────────────────────────────────────────────────
-- inventory_add_item — porte de PlayerInventoryService.addItem
-- STACKING: se o item é is_stackable, preenche entries NÃO-equipadas existentes
-- (ordenadas por id asc) até stack_max do items_catalog; o que sobrar vira
-- novas entries (cada uma capada em stack_max). Retorna o id da última entry
-- criada/atualizada; -1 se quantity<=0 ou item ausente do catálogo.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.inventory_add_item(
  p_player          uuid,
  p_item_key        text,
  p_quantity        int,
  p_acquired_via    text,
  p_evolution_stage text
) returns bigint
language plpgsql
security invoker
as $$
declare
  v_is_stackable  boolean;
  v_stack_max     int;
  v_durability    int;
  v_now           bigint := (extract(epoch from now()) * 1000)::bigint;  -- ms epoch (DateTime.now().millisecondsSinceEpoch)
  v_remaining     int;
  v_last_id       bigint := -1;
  v_available     int;
  v_to_add        int;
  v_chunk         int;
  r               record;
begin
  if p_quantity is null or p_quantity <= 0 then
    return -1;
  end if;

  -- spec = catalog.findByKey(itemKey); se null -> -1 (item não existe no catálogo)
  select is_stackable, stack_max, durability_max
    into v_is_stackable, v_stack_max, v_durability
    from public.items_catalog
   where key = p_item_key;

  if not found then
    return -1;
  end if;

  v_remaining := p_quantity;

  -- 1) Empilha em entries não-equipadas existentes (só se stackable).
  if v_is_stackable then
    for r in
      select id, quantity
        from public.player_inventory
       where player_id = p_player
         and item_key  = p_item_key
         and is_equipped = false
       order by id asc
    loop
      exit when v_remaining <= 0;
      v_available := v_stack_max - r.quantity;
      if v_available <= 0 then
        continue;
      end if;
      v_to_add := least(v_available, v_remaining);
      update public.player_inventory
         set quantity = quantity + v_to_add
       where id = r.id;
      v_last_id   := r.id;
      v_remaining := v_remaining - v_to_add;
    end loop;
  end if;

  -- 2) Cria novas entries pro restante (cada uma capada em stack_max se stackable).
  while v_remaining > 0 loop
    if v_is_stackable and v_remaining > v_stack_max then
      v_chunk := v_stack_max;
    else
      v_chunk := v_remaining;
    end if;

    insert into public.player_inventory (
      player_id, item_key, quantity, durability_current,
      acquired_at, acquired_via, evolution_stage, is_equipped
    ) values (
      p_player, p_item_key, v_chunk, v_durability,
      v_now, p_acquired_via, p_evolution_stage, false
    )
    returning id into v_last_id;

    v_remaining := v_remaining - v_chunk;
  end loop;

  return v_last_id;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- equipment_equip — porte de PlayerEquipmentService.equip
-- Valida posse + slot do item, desequipa o ocupante atual do slot (se houver),
-- faz upsert na player_equipment (insertOrReplace) e marca is_equipped=true.
-- NOTA: os gates de ItemEquipPolicy.canEquipItem (nível/rank/classe/atributos)
-- são avaliados no cliente Dart com o PlayerSnapshot; a RPC só efetiva a
-- escrita atômica. Guards de posse e slot ficam aqui.
-- Levanta exception (rollback) quando o item não existe / não é do jogador /
-- não tem slot — espelha os EquipResult.rejected do Dart.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.equipment_equip(
  p_player       uuid,
  p_inventory_id bigint
) returns void
language plpgsql
security invoker
as $$
declare
  v_item_key   text;
  v_owner      uuid;
  v_slot       text;
  v_occupant   bigint;
begin
  -- entry = playerInventory[inventoryId]
  select item_key, player_id
    into v_item_key, v_owner
    from public.player_inventory
   where id = p_inventory_id;

  if not found or v_owner is distinct from p_player then
    raise exception 'equip rejected: inventory % not found for player %',
      p_inventory_id, p_player using errcode = 'P0001';
  end if;

  -- spec = catalog.findByKey(entry.itemKey); slot obrigatório
  select slot into v_slot
    from public.items_catalog
   where key = v_item_key;

  if v_slot is null then
    raise exception 'equip rejected: item % is not equippable (no slot)',
      v_item_key using errcode = 'P0001';
  end if;

  -- Desequipa o ocupante atual do slot (se houver): zera is_equipped + remove linha.
  select inventory_id into v_occupant
    from public.player_equipment
   where player_id = p_player and slot = v_slot;

  if found then
    update public.player_inventory
       set is_equipped = false
     where id = v_occupant;
    delete from public.player_equipment
     where player_id = p_player and slot = v_slot;
  end if;

  -- insertOrReplace na player_equipment.
  insert into public.player_equipment (player_id, slot, inventory_id)
  values (p_player, v_slot, p_inventory_id)
  on conflict (player_id, slot)
  do update set inventory_id = excluded.inventory_id;

  -- Marca a nova entry como equipada.
  update public.player_inventory
     set is_equipped = true
   where id = p_inventory_id;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- equipment_unequip — porte de PlayerEquipmentService.unequip
-- No-op se o slot estiver vazio. Senão zera is_equipped da entry e remove a
-- linha de player_equipment. p_slot é o dbValue do slot (text).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.equipment_unequip(
  p_player uuid,
  p_slot   text
) returns void
language plpgsql
security invoker
as $$
declare
  v_inventory_id bigint;
begin
  select inventory_id into v_inventory_id
    from public.player_equipment
   where player_id = p_player and slot = p_slot;

  if not found then
    return;  -- slot vazio -> no-op (Dart: row == null => return)
  end if;

  update public.player_inventory
     set is_equipped = false
   where id = v_inventory_id;

  delete from public.player_equipment
   where player_id = p_player and slot = p_slot;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- shop_buy_item — porte de ShopsService.buyItem (transação de débito + credit)
-- Os gates de loja/jogador (shop existe, item na loja, rank/level/classe/facção)
-- são resolvidos no cliente Dart (ShopsService lê shops.json) ANTES de chamar.
-- A RPC reproduz fielmente a `db.transaction` final (Sprint 3.1 Bloco 14.5):
-- debita gold/gems/insignias conforme os preços passados e credita o item via
-- inventory_add_item(acquired_via='shop'). Tudo atômico.
--
-- Preços: passar NULL (ou <=0) para a moeda que não se aplica. Pelo menos uma
-- deve ser > 0 (espelha noPriceDefined do Dart). Guard defensivo de saldo
-- insuficiente levanta exception (rollback) — a checagem primária é do cliente,
-- mas confiar só nela permitiria saldo negativo se o estado divergir.
-- Retorna o inventory_id criado/atualizado (>0); levanta em qualquer falha.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.shop_buy_item(
  p_player    uuid,
  p_shop_key  text,
  p_item_key  text,
  p_coins     int,
  p_gems      int,
  p_insignias int
) returns bigint
language plpgsql
security invoker
as $$
declare
  v_coins     int := coalesce(p_coins, 0);
  v_gems      int := coalesce(p_gems, 0);
  v_insignias int := coalesce(p_insignias, 0);
  v_gold_now  int;
  v_gems_now  int;
  v_insig_now int;
  v_inv_id    bigint;
begin
  if v_coins <= 0 and v_gems <= 0 and v_insignias <= 0 then
    raise exception 'shop_buy_item: no price defined (shop=% item=%)',
      p_shop_key, p_item_key using errcode = 'P0001';
  end if;

  -- Saldo atual do jogador (guard defensivo de fundos).
  select gold, gems, insignias
    into v_gold_now, v_gems_now, v_insig_now
    from public.players
   where id = p_player;

  if not found then
    raise exception 'shop_buy_item: player % not found', p_player
      using errcode = 'P0001';
  end if;

  if v_coins     > 0 and v_gold_now  < v_coins     then
    raise exception 'shop_buy_item: insufficient coins (have % need %)',
      v_gold_now, v_coins using errcode = 'P0001';
  end if;
  if v_gems      > 0 and v_gems_now  < v_gems      then
    raise exception 'shop_buy_item: insufficient gems (have % need %)',
      v_gems_now, v_gems using errcode = 'P0001';
  end if;
  if v_insignias > 0 and v_insig_now < v_insignias then
    raise exception 'shop_buy_item: insufficient insignias (have % need %)',
      v_insig_now, v_insignias using errcode = 'P0001';
  end if;

  -- Débito atômico (incrementos col = col - x).
  if v_coins > 0 then
    update public.players set gold      = gold      - v_coins      where id = p_player;
  end if;
  if v_gems > 0 then
    update public.players set gems      = gems      - v_gems       where id = p_player;
  end if;
  if v_insignias > 0 then
    update public.players set insignias = insignias - v_insignias  where id = p_player;
  end if;

  -- Credit do item (qty=1, via='shop'). Se < 0, item não existe -> rollback.
  v_inv_id := public.inventory_add_item(
    p_player          => p_player,
    p_item_key        => p_item_key,
    p_quantity        => 1,
    p_acquired_via    => 'shop',
    p_evolution_stage => null
  );

  if v_inv_id < 0 then
    raise exception 'shop_buy_item: inventory_add_item returned % (shop=% item=%)',
      v_inv_id, p_shop_key, p_item_key using errcode = 'P0001';
  end if;

  return v_inv_id;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- set_guild_rank — porte de PlayerRankService.setRank + _evolveCollarIfPresent
-- Escreve players.guild_rank com o valor normalizado (uppercase 'E'..'S' ou
-- 'none' como sentinela de "sem rank"). Em seguida auto-evolui o evolution_stage
-- do COLLAR_GUILD do jogador, se ele o possui (senão no-op).
--
-- p_rank: aceita 'E'..'S' (qualquer caixa), 'none'/NULL para "sem rank".
-- Stage do colar: 'stage_null' quando sem rank, senão 'stage_<RANK UPPER>'.
-- (Espelha exatamente a construção de string do Dart: rank==null ? 'stage_null'
--  : 'stage_${rank.name.toUpperCase()}'.)
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.set_guild_rank(
  p_player uuid,
  p_rank   text
) returns void
language plpgsql
security invoker
as $$
declare
  v_is_none    boolean := (p_rank is null or lower(p_rank) = 'none');
  v_rank_value text;
  v_stage_key  text;
begin
  if v_is_none then
    v_rank_value := 'none';
    v_stage_key  := 'stage_null';
  else
    v_rank_value := upper(p_rank);
    v_stage_key  := 'stage_' || upper(p_rank);
  end if;

  update public.players
     set guild_rank = v_rank_value
   where id = p_player;

  -- Auto-evolui o Colar da Guilda (no-op se o jogador não o tem).
  update public.player_inventory
     set evolution_stage = v_stage_key
   where player_id = p_player
     and item_key  = 'COLLAR_GUILD';
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- inventory_reset — porte de PlayerInventoryService.resetInventoryFor (Dev Panel)
-- Destrutivo: remove TODOS os equipamentos + itens do jogador. Equipment antes
-- do inventory (FK player_equipment.inventory_id -> player_inventory tem
-- ON DELETE CASCADE, mas seguimos a ordem explícita do Dart). Atômico.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.inventory_reset(
  p_player uuid
) returns void
language plpgsql
security invoker
as $$
begin
  delete from public.player_equipment where player_id = p_player;
  delete from public.player_inventory where player_id = p_player;
end;
$$;
