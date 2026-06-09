-- ============================================================================
-- RPC: Rewards (dominio mais critico) — Epoca 2 full-online (ADR-0024)
-- Porta fielmente lib/data/services/reward_grant_service.dart
--   - grant_mission_reward  <- RewardGrantService.grant
--   - grant_achievement_reward <- RewardGrantService.grantAchievement
--
-- p_resolved e o RewardResolved JA RESOLVIDO pelo client (RewardResolveService):
-- SOULSLIKE multipliers, formula 0-300%, random keys e buffs de faccao
-- (FactionBuffService roda client-side ANTES da transacao em _applyBuffs) JA
-- estao aplicados em xp/gold/gems. Aqui creditamos os valores como vem.
--
-- Shape de p_resolved (ver lib/domain/models/reward_resolved.dart -> toJson):
--   {
--     "xp": int, "gold": int, "gems": int, "seivas": int, "insignias": int,
--     "items": [{"key": text, "quantity": int}, ...],
--     "achievements_to_check": [text, ...],
--     "recipes_to_unlock": [text, ...],
--     "faction_id": text?,                 -- so existe se houve rep
--     "faction_reputation_delta": int?     -- coexiste com faction_id
--   }
--
-- ATOMICIDADE: corpo da function = 1 transacao implicita (rollback total em erro),
-- exatamente como db.transaction(...) no Dart. Evento RewardGranted/LevelUp e
-- responsabilidade do client APOS o RPC retornar OK (fora de escopo do SQL).
--
-- SEGURANCA: SECURITY INVOKER. RLS (auth.uid() = player_id) protege os writes;
-- o player so credita a propria linha. p_player deve ser o jogador-ator.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- public.grant_mission_reward
-- Porta: RewardGrantService.grant(missionProgressId, playerId, resolved)
-- Guard de idempotencia: player_mission_progress.reward_claimed.
-- Incrementa total_quests_completed (CADA missao que grantou reward conta 1x).
-- ----------------------------------------------------------------------------
create or replace function public.grant_mission_reward(
  p_player              uuid,
  p_mission_progress_id bigint,
  p_resolved            jsonb
) returns json
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_claimed        boolean;
  v_owner          uuid;
  v_xp             int  := coalesce((p_resolved->>'xp')::int, 0);
  v_gold           int  := coalesce((p_resolved->>'gold')::int, 0);
  v_gems           int  := coalesce((p_resolved->>'gems')::int, 0);
  v_insignias      int  := coalesce((p_resolved->>'insignias')::int, 0);
  v_faction_id     text := p_resolved->>'faction_id';
  v_faction_delta  int  := (p_resolved->>'faction_reputation_delta')::int;
  v_life_gold      int;
  v_xp_result      json := null;
  v_item           jsonb;
  v_recipe         text;
begin
  -- 1. Check existencia + idempotencia DENTRO da transacao (bloqueia race com
  --    outro caller grantando a mesma missao). FOR UPDATE trava a linha.
  select reward_claimed, player_id
    into v_claimed, v_owner
    from public.player_mission_progress
   where id = p_mission_progress_id
   for update;

  if not found then
    -- equivale a MissionNotFoundException
    raise exception 'mission_not_found: %', p_mission_progress_id
      using errcode = 'P0002';
  end if;

  -- Guard de propriedade: missao tem de ser do jogador-ator (a RLS de players
  -- nao cobre player_mission_progress neste caminho de leitura).
  if v_owner <> p_player then
    raise exception 'mission_not_owned: % by %', p_mission_progress_id, p_player
      using errcode = '42501';
  end if;

  if v_claimed then
    -- equivale a RewardAlreadyGrantedException
    raise exception 'reward_already_granted: mission % player %',
      p_mission_progress_id, p_player
      using errcode = 'P0001';
  end if;

  -- 2. Marca missao completa + reward_claimed=true (markCompleted at=now,
  --    rewardClaimed=true). completed_at e ms epoch (bigint) como no Drift.
  update public.player_mission_progress
     set completed_at   = (extract(epoch from now()) * 1000)::bigint,
         reward_claimed = true
   where id = p_mission_progress_id;

  -- 3. XP via add_xp (recalcula level/xp_to_next/max_hp/max_mp/attribute_points
  --    via XpCalculator). Retorna {previous_level,new_level} pro client emitir
  --    LevelUp. So chama se xp != 0 (igual ao Dart).
  if v_xp <> 0 then
    v_xp_result := public.add_xp(p_player, v_xp);
  end if;

  -- 3. Gold via add_gold + gems/lifetime inline. O Dart faz um UNICO UPDATE de
  --    gold + total_gold_earned_lifetime + gems quando gold!=0 OR gems!=0.
  --    total_gold_earned_lifetime conta so ouro GANHO (>0).
  if v_gold <> 0 or v_gems <> 0 then
    if v_gold <> 0 then
      perform public.add_gold(p_player, v_gold);
    end if;
    v_life_gold := case when v_gold > 0 then v_gold else 0 end;
    update public.players
       set total_gold_earned_lifetime = total_gold_earned_lifetime + v_life_gold,
           gems                        = gems + v_gems
     where id = p_player;
  end if;

  -- 3a-bis. Insignias (moeda de faccao). Credito FIXO: NAO passa por buff/0-300%,
  --         vem cru do resolver. Coluna players.insignias.
  if v_insignias <> 0 then
    update public.players
       set insignias = insignias + v_insignias
     where id = p_player;
  end if;

  -- 3b. total_quests_completed +1. Idempotencia garantida pelo guard do passo 1.
  --     Especifico do grant de MISSAO (achievement NAO incrementa).
  update public.players
     set total_quests_completed = total_quests_completed + 1
   where id = p_player;

  -- 4. Items via inventory_add_item (respeita stack_max/durabilidade).
  --    SourceType.questReward -> acquired_via='questReward'. Sem evolution_stage.
  if jsonb_typeof(p_resolved->'items') = 'array' then
    for v_item in select * from jsonb_array_elements(p_resolved->'items')
    loop
      perform public.inventory_add_item(
        p_player,
        v_item->>'key',
        (v_item->>'quantity')::int,
        'questReward',
        null
      );
    end loop;
  end if;

  -- 5. Recipes unlock. SourceType.questReward -> via='questReward'.
  if jsonb_typeof(p_resolved->'recipes_to_unlock') = 'array' then
    for v_recipe in
      select jsonb_array_elements_text(p_resolved->'recipes_to_unlock')
    loop
      insert into public.player_recipes_unlocked
        (player_id, recipe_key, unlocked_at, unlocked_via)
      values
        (p_player, v_recipe, (extract(epoch from now()) * 1000)::bigint,
         'questReward')
      on conflict (player_id, recipe_key) do nothing;
    end loop;
  end if;

  -- 6. Reputacao de faccao (se aplicavel). faction_id e delta coexistem ou
  --    ambos ausentes (invariante do RewardResolved). Clamp 0..100 vive dentro
  --    de faction_reputation_delta. Delta ja vem com buff aplicado pelo client
  --    (_applyBuffToRepDelta), entao passa cru aqui.
  if v_faction_id is not null and v_faction_delta is not null then
    perform public.faction_reputation_delta(p_player, v_faction_id, v_faction_delta);
  end if;

  -- Retorno: o client precisa do delta de level pra emitir LevelUp.
  return json_build_object(
    'mission_progress_id', p_mission_progress_id,
    'xp_result',           v_xp_result,
    'xp',                  v_xp,
    'gold',                v_gold,
    'gems',                v_gems,
    'insignias',           v_insignias
  );
end;
$$;

comment on function public.grant_mission_reward(uuid, bigint, jsonb) is
  'RewardGrantService.grant: credita reward de missao atomicamente. Guard reward_claimed; incrementa total_quests_completed.';


-- ----------------------------------------------------------------------------
-- public.grant_achievement_reward
-- Porta: RewardGrantService.grantAchievement(playerId, achievementKey, resolved)
-- Guard: player_achievements_completed.reward_claimed. NAO incrementa
-- total_quests_completed. Caller deve ter chamado markCompleted ANTES (a row
-- precisa existir); este RPC nao cria a row.
-- ----------------------------------------------------------------------------
create or replace function public.grant_achievement_reward(
  p_player          uuid,
  p_achievement_key text,
  p_resolved        jsonb
) returns json
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_claimed        boolean;
  v_xp             int  := coalesce((p_resolved->>'xp')::int, 0);
  v_gold           int  := coalesce((p_resolved->>'gold')::int, 0);
  v_gems           int  := coalesce((p_resolved->>'gems')::int, 0);
  v_insignias      int  := coalesce((p_resolved->>'insignias')::int, 0);
  v_faction_id     text := p_resolved->>'faction_id';
  v_faction_delta  int  := (p_resolved->>'faction_reputation_delta')::int;
  v_life_gold      int;
  v_xp_result      json := null;
  v_item           jsonb;
  v_recipe         text;
begin
  -- 1. Precondition (isCompleted) + idempotencia (isRewardClaimed) DENTRO da
  --    transacao. FOR UPDATE trava a row do achievement.
  select reward_claimed
    into v_claimed
    from public.player_achievements_completed
   where player_id = p_player
     and achievement_key = p_achievement_key
   for update;

  if not found then
    -- equivale a AchievementNotUnlockedException (row nao existe ainda)
    raise exception 'achievement_not_unlocked: % player %',
      p_achievement_key, p_player
      using errcode = 'P0002';
  end if;

  if v_claimed then
    -- equivale a AchievementRewardAlreadyGrantedException
    raise exception 'achievement_reward_already_granted: % player %',
      p_achievement_key, p_player
      using errcode = 'P0001';
  end if;

  -- 2. XP via add_xp (mesmo fix de scaling do grant). So se xp != 0.
  if v_xp <> 0 then
    v_xp_result := public.add_xp(p_player, v_xp);
  end if;

  -- 2. Gold via add_gold + gems/lifetime inline (mesma regra do grant).
  if v_gold <> 0 or v_gems <> 0 then
    if v_gold <> 0 then
      perform public.add_gold(p_player, v_gold);
    end if;
    v_life_gold := case when v_gold > 0 then v_gold else 0 end;
    update public.players
       set total_gold_earned_lifetime = total_gold_earned_lifetime + v_life_gold,
           gems                        = gems + v_gems
     where id = p_player;
  end if;

  -- 2-bis. Insignias fixas (sem buff). Achievement raramente paga, mas o
  --        contrato declarativo suporta — paridade com payload do RewardGranted.
  if v_insignias <> 0 then
    update public.players
       set insignias = insignias + v_insignias
     where id = p_player;
  end if;

  -- NOTA: grantAchievement NAO incrementa total_quests_completed (contador de
  -- missoes, nao de conquistas).

  -- 3. Items via inventory_add_item. SourceType.achievement -> 'achievement'.
  if jsonb_typeof(p_resolved->'items') = 'array' then
    for v_item in select * from jsonb_array_elements(p_resolved->'items')
    loop
      perform public.inventory_add_item(
        p_player,
        v_item->>'key',
        (v_item->>'quantity')::int,
        'achievement',
        null
      );
    end loop;
  end if;

  -- 4. Recipes unlock. SourceType.achievement -> via='achievement'.
  if jsonb_typeof(p_resolved->'recipes_to_unlock') = 'array' then
    for v_recipe in
      select jsonb_array_elements_text(p_resolved->'recipes_to_unlock')
    loop
      insert into public.player_recipes_unlocked
        (player_id, recipe_key, unlocked_at, unlocked_via)
      values
        (p_player, v_recipe, (extract(epoch from now()) * 1000)::bigint,
         'achievement')
      on conflict (player_id, recipe_key) do nothing;
    end loop;
  end if;

  -- 5. Reputacao de faccao (raro em achievement, mas suportado). Delta ja
  --    bufado pelo client.
  if v_faction_id is not null and v_faction_delta is not null then
    perform public.faction_reputation_delta(p_player, v_faction_id, v_faction_delta);
  end if;

  -- 6. Marca reward_claimed=true (markRewardClaimed). Previne re-grant no retry.
  update public.player_achievements_completed
     set reward_claimed = true
   where player_id = p_player
     and achievement_key = p_achievement_key;

  return json_build_object(
    'achievement_key', p_achievement_key,
    'xp_result',       v_xp_result,
    'xp',              v_xp,
    'gold',            v_gold,
    'gems',            v_gems,
    'insignias',       v_insignias
  );
end;
$$;

comment on function public.grant_achievement_reward(uuid, text, jsonb) is
  'RewardGrantService.grantAchievement: credita reward de conquista atomicamente. Guard reward_claimed; NAO incrementa total_quests_completed.';
