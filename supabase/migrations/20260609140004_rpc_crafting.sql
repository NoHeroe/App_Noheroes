-- ============================================================================
-- NoHeroes — RPCs do domínio "Crafting + Enchant + Recipes" (Época 2, ADR-0024)
-- ----------------------------------------------------------------------------
-- Porta fielmente a lógica Dart:
--   - craft()                 <- CraftingService.craft + CraftPolicy.canCraft
--   - apply_enchant()         <- EnchantService.applyEnchantToItem + EnchantPolicy.canApply
--   - unlock_starter_recipes()<- RecipesCatalogSeeder.unlockStarterRecipesFor
--
-- Convenções (ADR-0024): plpgsql, schema public, SECURITY INVOKER (a RLS
-- 'auth.uid() = player_id' já protege escrita cross-player). Cada function é
-- uma transação implícita: qualquer RAISE faz rollback de tudo. Incrementos
-- atômicos via col = col - x. craft() delega criação de item a
-- public.inventory_add_item().
--
-- IMPORTANTE: o código Dart usa playerId int; aqui o jogador é uuid
-- (players.id = auth.users.id). Mantemos o parâmetro p_player uuid conforme
-- as assinaturas canônicas, mas dentro das funções *ignoramos* p_player e
-- usamos auth.uid() como ator quando ele coincide — ver guard no início.
-- ============================================================================

-- ───────────────────────────────────────────────────────────────────────────
-- Helper interno: ordem de rank (E<D<C<B<A<S). Espelha
-- ItemEquipPolicy.parseRank / isRankSufficient:
--   'none'/''/null/inválido -> null  (NÃO satisfaz nenhum gate de rank)
-- Retorna índice 0..5 ou NULL.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._rank_index(p_rank text)
  returns integer
  language sql
  immutable
as $$
  select case upper(coalesce(p_rank, ''))
           when 'E' then 0
           when 'D' then 1
           when 'C' then 2
           when 'B' then 3
           when 'A' then 4
           when 'S' then 5
           else null
         end;
$$;

-- ItemEquipPolicy.isRankSufficient:
--   requiredRank null -> true (sem gate)
--   playerRank  null -> false
--   senão idx(player) >= idx(required)
create or replace function public._rank_sufficient(p_player_rank text, p_required_rank text)
  returns boolean
  language sql
  immutable
as $$
  select case
           when public._rank_index(p_required_rank) is null then true
           when public._rank_index(p_player_rank) is null then false
           else public._rank_index(p_player_rank) >= public._rank_index(p_required_rank)
         end;
$$;


-- ═════════════════════════════════════════════════════════════════════════════
-- craft(p_player uuid, p_recipe_key text, p_quantity int) -> json
-- Origem Dart: CraftingService.craft (lib/.../crafting_service.dart) +
--              CraftPolicy.canCraft / calculateMaterialsNeeded.
--
-- Valida: receita existe, desbloqueada, rank, level, materiais (×qty), gold
-- (×qty), item resultado no catálogo. Debita materiais (entries não-equipadas,
-- ordem id asc, igual _debitMaterial) + gold, e chama inventory_add_item.
-- Retorna deltas pro caller Dart publicar GoldSpent/ItemCrafted.
-- ═════════════════════════════════════════════════════════════════════════════
create or replace function public.craft(
  p_player    uuid,
  p_recipe_key text,
  p_quantity  int
) returns json
  language plpgsql
  security invoker
as $$
declare
  v_recipe        public.recipes_catalog%rowtype;
  v_player        public.players%rowtype;
  v_total_cost    integer;
  v_produced_qty  integer;
  v_acquired_via  text;
  v_inv_id        bigint;
  v_mat           record;
  v_needed        integer;
  v_remaining     integer;
  v_take          integer;
  v_entry         record;
begin
  -- quantity <= 0 -> CraftRejectReason.dbError no Dart; aqui erro explícito.
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'craft: invalid quantity %', p_quantity
      using errcode = 'check_violation';
  end if;

  -- Ator: a RLS já garante que só escrevemos linhas do auth.uid(); recusa
  -- chamadas que tentem craftar em nome de outro jogador.
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'craft: caller % cannot craft for player %', auth.uid(), p_player
      using errcode = 'insufficient_privilege';
  end if;

  -- 1. Receita existe? (recipeNotFound)
  select * into v_recipe from public.recipes_catalog where key = p_recipe_key;
  if not found then
    raise exception 'craft: recipe % not found', p_recipe_key
      using errcode = 'no_data_found';
  end if;

  -- 2. Receita desbloqueada? (recipeNotUnlocked)
  if not exists (
    select 1 from public.player_recipes_unlocked
     where player_id = p_player and recipe_key = p_recipe_key
  ) then
    raise exception 'craft: recipe % not unlocked for player', p_recipe_key
      using errcode = 'insufficient_privilege';
  end if;

  -- 4. Estado do jogador (gold/level/rank).
  select * into v_player from public.players where id = p_player;
  if not found then
    raise exception 'craft: player % not found', p_player
      using errcode = 'no_data_found';
  end if;

  -- 5. CraftPolicy.canCraft — ordem determinística:
  --    rankTooLow -> levelTooLow -> notEnoughMaterials -> notEnoughCoins.
  if not public._rank_sufficient(v_player.guild_rank, v_recipe.required_rank) then
    raise exception 'craft: rank too low (player=% required=%)',
      v_player.guild_rank, v_recipe.required_rank
      using errcode = 'insufficient_privilege';
  end if;

  if v_player.level < v_recipe.required_level then
    raise exception 'craft: level too low (player=% required=%)',
      v_player.level, v_recipe.required_level
      using errcode = 'insufficient_privilege';
  end if;

  -- Materiais necessários = recipe.materials × quantity (calculateMaterialsNeeded).
  -- recipes_catalog.materials é texto JSON: [{"item_key":...,"quantity":N}, ...]
  -- Soma disponível por item_key entre entries NÃO-equipadas (espelha o read
  -- do CraftingService passo 3 + _debitMaterial).
  for v_mat in
    select m->>'item_key' as item_key,
           sum((m->>'quantity')::int)::int as qty
      from json_array_elements(v_recipe.materials::json) as m
     group by m->>'item_key'
  loop
    v_needed := v_mat.qty * p_quantity;
    select coalesce(sum(quantity), 0) into v_remaining
      from public.player_inventory
     where player_id = p_player
       and item_key  = v_mat.item_key
       and is_equipped = false;
    if v_remaining < v_needed then
      raise exception 'craft: not enough materials (% have=% need=%)',
        v_mat.item_key, v_remaining, v_needed
        using errcode = 'check_violation';
    end if;
  end loop;

  -- Custo total = cost_coins × quantity.
  v_total_cost := v_recipe.cost_coins * p_quantity;
  if v_player.gold < v_total_cost then
    raise exception 'craft: not enough coins (have=% need=%)',
      v_player.gold, v_total_cost
      using errcode = 'check_violation';
  end if;

  -- 6. Item resultado existe no catálogo (itemNotInCatalog — defensivo).
  if not exists (select 1 from public.items_catalog where key = v_recipe.result_item_key) then
    raise exception 'craft: result item % not in catalog', v_recipe.result_item_key
      using errcode = 'foreign_key_violation';
  end if;

  -- 7. Debita materiais: itera entries não-equipadas (ordem id asc) e abate até
  --    zerar a quantidade necessária. Espelha CraftingService._debitMaterial.
  for v_mat in
    select m->>'item_key' as item_key,
           sum((m->>'quantity')::int)::int as qty
      from json_array_elements(v_recipe.materials::json) as m
     group by m->>'item_key'
  loop
    v_remaining := v_mat.qty * p_quantity;
    for v_entry in
      select id, quantity
        from public.player_inventory
       where player_id = p_player
         and item_key  = v_mat.item_key
         and is_equipped = false
       order by id asc
    loop
      exit when v_remaining <= 0;
      v_take := least(v_entry.quantity, v_remaining);
      if v_take >= v_entry.quantity then
        -- consome a entry inteira (removeItem zera -> deleta a linha)
        delete from public.player_inventory where id = v_entry.id;
      else
        update public.player_inventory
           set quantity = quantity - v_take
         where id = v_entry.id;
      end if;
      v_remaining := v_remaining - v_take;
    end loop;
    -- Defensivo: a checagem acima garante saldo, mas re-valida (concurrent mod).
    if v_remaining > 0 then
      raise exception 'craft: debit % failed (remaining=%) — concurrent modification?',
        v_mat.item_key, v_remaining
        using errcode = 'serialization_failure';
    end if;
  end loop;

  -- 8. Debita gold atomicamente (col = col - x).
  if v_total_cost > 0 then
    update public.players set gold = gold - v_total_cost where id = p_player;
  end if;

  -- 9. Adiciona item resultado via inventory_add_item.
  --    acquired_via: forge -> 'forge', senão 'craft' (RecipeType).
  v_acquired_via := case when v_recipe.type = 'forge' then 'forge' else 'craft' end;
  v_produced_qty := v_recipe.result_quantity * p_quantity;

  v_inv_id := public.inventory_add_item(
    p_player,
    v_recipe.result_item_key,
    v_produced_qty,
    v_acquired_via,
    null            -- p_evolution_stage: crafting não define estágio
  );

  -- Retorno pro caller Dart publicar GoldSpent (se cost>0) + ItemCrafted.
  return json_build_object(
    'inventory_id', v_inv_id,
    'item_key',     v_recipe.result_item_key,
    'recipe_key',   p_recipe_key,
    'quantity',     v_produced_qty,
    'gold_spent',   v_total_cost,
    'recipe_type',  v_recipe.type
  );
end;
$$;


-- ═════════════════════════════════════════════════════════════════════════════
-- apply_enchant(p_player uuid, p_inventory_item_id bigint, p_enchant_key text,
--               p_confirm_replacement bool) -> json
-- Origem Dart: EnchantService.applyEnchantToItem + EnchantPolicy.canApply.
--
-- Valida: runa existe e é type='rune'; item alvo do jogador existe; spec do
-- item; jogador possui a runa; rank do item >= rank da runa; allowed_classes;
-- gemas suficientes; soft-gate de substituição. Debita gems, consome 1 runa,
-- seta applied_rune_key (runa anterior é perdida). Retorna deltas pro caller.
-- ═════════════════════════════════════════════════════════════════════════════
create or replace function public.apply_enchant(
  p_player             uuid,
  p_inventory_item_id  bigint,
  p_enchant_key        text,
  p_confirm_replacement bool
) returns json
  language plpgsql
  security invoker
as $$
declare
  v_rune        public.items_catalog%rowtype;  -- runa = item type='rune'
  v_inv         public.player_inventory%rowtype;
  v_item        public.items_catalog%rowtype;   -- item alvo
  v_player      public.players%rowtype;
  v_cost        integer;
  v_has_rune    boolean;
  v_current_rune_key text;
  v_replaced_same_slot boolean := false;
  v_consumed_id bigint;
  v_class_allowed boolean;
begin
  -- Ator (RLS já protege; recusa cross-player).
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'apply_enchant: caller % cannot act for player %', auth.uid(), p_player
      using errcode = 'insufficient_privilege';
  end if;

  -- 1. Spec da runa (enchantNotFound). _loadRuneSpec: existe E type='rune'.
  select * into v_rune from public.items_catalog where key = p_enchant_key;
  if not found or v_rune.type <> 'rune' then
    raise exception 'apply_enchant: enchant % not found / not a rune', p_enchant_key
      using errcode = 'no_data_found';
  end if;

  -- 2. Row do item no inventário do jogador (itemNotFound).
  select * into v_inv
    from public.player_inventory
   where id = p_inventory_item_id and player_id = p_player;
  if not found then
    raise exception 'apply_enchant: inventory item % not found for player',
      p_inventory_item_id using errcode = 'no_data_found';
  end if;

  -- 3. Spec do item alvo (itemNotFound).
  select * into v_item from public.items_catalog where key = v_inv.item_key;
  if not found then
    raise exception 'apply_enchant: item % not in catalog', v_inv.item_key
      using errcode = 'no_data_found';
  end if;

  -- Estado do jogador (gemas / classe).
  select * into v_player from public.players where id = p_player;
  if not found then
    raise exception 'apply_enchant: player % not found', p_player
      using errcode = 'no_data_found';
  end if;

  -- 4. Jogador possui a runa? (qualquer entry com quantity>0).
  v_has_rune := exists (
    select 1 from public.player_inventory
     where player_id = p_player and item_key = p_enchant_key and quantity > 0
  );

  -- 5. Runa atualmente aplicada (se houver). Valida que ainda é runa válida.
  v_current_rune_key := null;
  if v_inv.applied_rune_key is not null then
    if exists (
      select 1 from public.items_catalog
       where key = v_inv.applied_rune_key and type = 'rune'
    ) then
      v_current_rune_key := v_inv.applied_rune_key;
    end if;
  end if;

  -- 6. EnchantPolicy.canApply — ordem determinística.
  --   6.1 itemNotEnchantable: tipo não em {weapon,armor,shield,accessory} OU
  --       key bloqueada (_unenchantableItemKeys = {'COLLAR_GUILD'}).
  if v_item.type not in ('weapon','armor','shield','accessory') then
    raise exception 'apply_enchant: item type % not enchantable', v_item.type
      using errcode = 'check_violation';
  end if;
  if v_item.key = 'COLLAR_GUILD' then
    raise exception 'apply_enchant: item % is unenchantable', v_item.key
      using errcode = 'check_violation';
  end if;

  --   6.2 enchantNotInInventory.
  if not v_has_rune then
    raise exception 'apply_enchant: enchant % not in inventory', p_enchant_key
      using errcode = 'check_violation';
  end if;

  --   6.3 rankInsufficient: rank do ITEM >= rank requerido da RUNA.
  --       (EnchantSpec.requiredRank vem de items_catalog.required_rank da runa.)
  if not public._rank_sufficient(v_item.required_rank, v_rune.required_rank) then
    raise exception 'apply_enchant: item rank % insufficient for rune req %',
      v_item.required_rank, v_rune.required_rank
      using errcode = 'insufficient_privilege';
  end if;

  --   6.4 classRestricted: allowed_classes da runa (JSON array). Tecelão
  --       Sombrio ('shadowWeaver') é híbrido universal -> ignora gate.
  --       Vazio/'[]' -> sem gate.
  if v_rune.allowed_classes is not null
     and v_rune.allowed_classes <> ''
     and v_rune.allowed_classes <> '[]' then
    v_class_allowed := (
      v_player.class_type = 'shadowWeaver'
      or (
        v_player.class_type is not null
        and exists (
          select 1
            from json_array_elements_text(v_rune.allowed_classes::json) as c
           where c = v_player.class_type
        )
      )
    );
    if not v_class_allowed then
      raise exception 'apply_enchant: class % restricted for rune %',
        v_player.class_type, p_enchant_key
        using errcode = 'insufficient_privilege';
    end if;
  end if;

  --   6.5 insufficientGems: cost = rune.shop_price_gems (EnchantSpec.costGems).
  v_cost := coalesce(v_rune.shop_price_gems, 0);
  if v_player.gems < v_cost then
    raise exception 'apply_enchant: insufficient gems (have=% need=%)',
      v_player.gems, v_cost using errcode = 'check_violation';
  end if;

  --   6.6 alreadyEnchantedSameSlot (SOFT): item já tem runa.
  --       Sem confirmReplacement -> retorna sinal pra UI (não escreve nada).
  --       Com confirmReplacement -> re-valida como slot vazio (os gates acima
  --       já passaram com currentRune ignorado), runa anterior é perdida.
  if v_current_rune_key is not null then
    if not coalesce(p_confirm_replacement, false) then
      return json_build_object(
        'applied',            false,
        'needs_confirmation', true,
        'reason',             'alreadyEnchantedSameSlot',
        'current_rune_key',   v_current_rune_key,
        'item_key',           v_inv.item_key
      );
    end if;
    v_replaced_same_slot := true;
  end if;

  -- 8. Transação atômica: debit gems + consume 1 runa + set applied_rune_key.
  if v_cost > 0 then
    update public.players set gems = gems - v_cost where id = p_player;
  end if;

  -- Consome 1 unidade da runa (consumeOneByKey): pega a 1ª entry não-equipada
  -- (ordem id asc), decrementa 1; se zerar, deleta a linha.
  select id into v_consumed_id
    from public.player_inventory
   where player_id = p_player and item_key = p_enchant_key
     and is_equipped = false and quantity > 0
   order by id asc
   limit 1;
  if v_consumed_id is null then
    -- defensivo: hasItem aprovou mas não há entry consumível -> rollback.
    raise exception 'apply_enchant: rune % vanished — concurrent modification?',
      p_enchant_key using errcode = 'serialization_failure';
  end if;
  update public.player_inventory
     set quantity = quantity - 1
   where id = v_consumed_id;
  delete from public.player_inventory where id = v_consumed_id and quantity <= 0;

  -- Grava runa aplicada no item (anterior perdida implicitamente).
  update public.player_inventory
     set applied_rune_key = p_enchant_key
   where id = p_inventory_item_id;

  -- Retorno pro caller publicar GemsSpent (se cost>0) + ItemEnchanted.
  return json_build_object(
    'applied',        true,
    'item_key',       v_inv.item_key,
    'rune_key',       p_enchant_key,
    'replaced_rune_key', v_current_rune_key,
    'gems_spent',     v_cost
  );
end;
$$;


-- ═════════════════════════════════════════════════════════════════════════════
-- unlock_starter_recipes(p_player uuid) -> int
-- Origem Dart: RecipesCatalogSeeder.unlockStarterRecipesFor.
--
-- Desbloqueia toda receita cujo unlock_sources contém {"type":"starter"}.
-- Idempotente (insertOrIgnore -> on conflict do nothing). Retorna o nº de
-- receitas efetivamente inseridas nesta chamada (não as já presentes).
-- ═════════════════════════════════════════════════════════════════════════════
create or replace function public.unlock_starter_recipes(p_player uuid)
  returns int
  language plpgsql
  security invoker
as $$
declare
  v_unlocked integer := 0;
  v_now      bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'unlock_starter_recipes: caller % cannot act for player %',
      auth.uid(), p_player using errcode = 'insufficient_privilege';
  end if;

  -- unlock_sources é texto JSON array: [{"type":"starter"}, ...].
  with starters as (
    select rc.key
      from public.recipes_catalog rc
     where exists (
       select 1
         from json_array_elements(rc.unlock_sources::json) as s
        where s->>'type' = 'starter'
     )
  ),
  ins as (
    insert into public.player_recipes_unlocked (player_id, recipe_key, unlocked_at, unlocked_via)
    select p_player, key, v_now, 'starter'
      from starters
    on conflict (player_id, recipe_key) do nothing
    returning 1
  )
  select count(*)::int into v_unlocked from ins;

  return v_unlocked;
end;
$$;
