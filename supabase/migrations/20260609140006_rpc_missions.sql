-- ============================================================================
-- NoHeroes — RPCs do domínio "Missions assignment + individual" (Época 2)
-- ----------------------------------------------------------------------------
-- Porta fielmente a lógica Dart (Drift) destes serviços para PL/pgSQL atômico:
--   * IndividualCreationService.createIndividual   -> create_individual_mission
--   * IndividualDeleteService.deleteIndividual     -> delete_individual_mission
--   * MissionAssignmentService.ensureWeeklyFactionQuest
--       + ActiveFactionQuestsRepositoryDrift.upsertAtomic -> assign_weekly_faction_quest
--   * QuestRewardStatsService._increment          -> increment_gold_earned_via_quests
--
-- Convenções (ver migration initial_schema + nota de RPCs):
--   - SECURITY INVOKER por padrão (RLS auth.uid()=player_id protege escrita).
--   - O corpo de cada function é UMA transação implícita (atômico).
--   - Timestamps *_at em player_mission_progress são bigint ms-epoch.
--   - O caller Dart já calcula reward/target da individual e o seed da semanal;
--     essas RPCs recebem esses valores prontos (fidelidade às assinaturas
--     canônicas), apenas persistindo de forma atômica + idempotente.
-- ============================================================================


-- ───────────────────────────────────────────────────────────────────────────
-- create_individual_mission
-- Fonte Dart: IndividualCreationService.createIndividual (db.transaction).
--
-- A missão individual é uma row em player_mission_progress com
-- modality='individual', tab_origin='extras'. A reward e o target_value
-- (= soma dos requirements) são calculados no cliente (MissionBalancerService
-- + requirements.fold) e chegam prontos em p_reward_json / p_target. O
-- meta_json RICO (name/description/frequencia/deadline_at/requirements/...)
-- também é montado no cliente e chega em p_meta_json.
--
-- Guard de count-limit (IndividualCreationBalance.kMaxActiveIndividualsFree=5):
-- conta individuais ATIVAS (modality='individual', completed_at IS NULL,
-- failed_at IS NULL) DENTRO da function; se >= 5 lança erro (espelha
-- IndividualLimitExceededException). Retorna o id (bigint) da row criada.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.create_individual_mission(
  p_player      uuid,
  p_mission_key text,
  p_reward_json text,
  p_target      int,
  p_meta_json   text
) returns bigint
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_active_count int;
  v_new_id       bigint;
begin
  -- Validação básica (espelha ArgumentError no Dart): target somado > 0.
  if p_target is null or p_target <= 0 then
    raise exception 'invalid target_value: %', p_target
      using errcode = 'check_violation';
  end if;

  -- Count-limit: individuais ativas do jogador.
  select count(*) into v_active_count
  from public.player_mission_progress
  where player_id = p_player
    and modality = 'individual'
    and completed_at is null
    and failed_at is null;

  if v_active_count >= 5 then
    raise exception
      'IndividualLimitExceeded(player=%, %/5)', p_player, v_active_count
      using errcode = 'raise_exception';
  end if;

  insert into public.player_mission_progress (
    player_id, mission_key, modality, tab_origin, rank,
    target_value, current_value, reward_json, started_at,
    reward_claimed, meta_json
  ) values (
    p_player,
    p_mission_key,
    'individual',
    'extras',
    -- rank da individual: o Dart serializa GuildRank.name; o cliente já
    -- embute o rank no fluxo de criação. Como a assinatura canônica não
    -- expõe rank, derivamos do meta_json se presente, senão 'e' (default
    -- GuildRank em _rankOf). NB: assunção documentada.
    coalesce(nullif(p_meta_json::jsonb->>'rank', ''), 'e'),
    p_target,
    0,
    p_reward_json,
    (extract(epoch from now()) * 1000)::bigint,
    false,
    coalesce(p_meta_json, '{}')
  )
  returning id into v_new_id;

  return v_new_id;
end;
$$;

comment on function public.create_individual_mission(uuid, text, text, int, text)
  is 'Porta IndividualCreationService.createIndividual: insere individual em player_mission_progress com guard de limite (5 ativas).';


-- ───────────────────────────────────────────────────────────────────────────
-- delete_individual_mission
-- Fonte Dart: IndividualDeleteService.deleteIndividual (db.transaction).
--
-- Apaga (soft) uma missão individual repetível mediante pagamento gold+gems.
-- O custo (IndividualDeleteCost.forRank) é calculado no cliente e chega em
-- p_gold_cost / p_gems_cost. Passos atômicos:
--   1. Confirma a row existe, pertence ao jogador e modality='individual'.
--   2. Valida saldos gold e gems (lança Insufficient* se faltar).
--   3. Debita ambas as currencies (col = col - x).
--   4. markFailed: failed_at = now (ms). (Schema reusa failed_at como marker
--      de "deletada", igual ao Dart — não há coluna deleted_at aqui.)
-- void: o caller Dart publica GoldSpent/GemsSpent/MissionFailed pós-commit.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.delete_individual_mission(
  p_player              uuid,
  p_mission_progress_id bigint,
  p_gold_cost           int,
  p_gems_cost           int
) returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_modality text;
  v_gold     int;
  v_gems     int;
begin
  -- 1. Lê a missão (RLS garante que só enxergamos rows do próprio jogador,
  --    mas filtramos por player_id explicitamente para o guard de fidelidade).
  select modality into v_modality
  from public.player_mission_progress
  where id = p_mission_progress_id and player_id = p_player;

  if not found then
    raise exception 'MissionNotFound(id=%)', p_mission_progress_id
      using errcode = 'no_data_found';
  end if;

  if v_modality <> 'individual' then
    raise exception 'NotIndividualMission(id=%, modality=%)',
      p_mission_progress_id, v_modality
      using errcode = 'raise_exception';
  end if;

  -- 2. Saldos DENTRO da tx (evita race leitura/débito). FOR UPDATE bloqueia
  --    a row do player até o commit.
  select gold, gems into v_gold, v_gems
  from public.players
  where id = p_player
  for update;

  if not found or v_gold < p_gold_cost then
    raise exception 'InsufficientGold(player=%, need=%, have=%)',
      p_player, p_gold_cost, coalesce(v_gold, 0)
      using errcode = 'raise_exception';
  end if;

  if v_gems < p_gems_cost then
    raise exception 'InsufficientGems(player=%, need=%, have=%)',
      p_player, p_gems_cost, v_gems
      using errcode = 'raise_exception';
  end if;

  -- 3. Debita gold + gems atomicamente.
  update public.players
  set gold = gold - p_gold_cost,
      gems = gems - p_gems_cost
  where id = p_player;

  -- 4. markFailed (failed_at = now em ms).
  update public.player_mission_progress
  set failed_at = (extract(epoch from now()) * 1000)::bigint
  where id = p_mission_progress_id and player_id = p_player;
end;
$$;

comment on function public.delete_individual_mission(uuid, bigint, int, int)
  is 'Porta IndividualDeleteService.deleteIndividual: debita gold+gems e marca failed_at (soft-delete) da individual.';


-- ───────────────────────────────────────────────────────────────────────────
-- assign_weekly_faction_quest
-- Fonte Dart: ActiveFactionQuestsRepositoryDrift.upsertAtomic
--   (chamado por MissionAssignmentService.ensureWeeklyFactionQuest).
--
-- Garante 1 missão de facção semanal pro par (jogador, facção, week_start),
-- de forma ATÔMICA e IDEMPOTENTE. Duas inserções na mesma transação:
--   1. ledger em active_faction_quests (UNIQUE player_id+faction_id+week_start)
--   2. progresso em player_mission_progress (materializado do seed)
--
-- Idempotência: ON CONFLICT no ledger detecta a corrida/reassign. Se o ledger
-- já existe, recuperamos a row existente e o progress 'faction' ativo
-- correspondente (espelha o catch SQLITE_CONSTRAINT_UNIQUE do Dart) — no-op
-- de escrita, retorna os ids já persistidos.
--
-- O seed (jsonb) tem: modality, tab_origin('faction'), rank, target_value,
-- reward_json, meta_json — montado por _toWeeklyProgressSeed no cliente.
-- Retorna json {ledger_id, progress_id}.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.assign_weekly_faction_quest(
  p_player       uuid,
  p_faction_id   text,
  p_mission_key  text,
  p_week_start   text,
  p_seed         jsonb
) returns json
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_now         bigint := (extract(epoch from now()) * 1000)::bigint;
  v_ledger_id   bigint;
  v_progress_id bigint;
  v_inserted    boolean := false;
begin
  -- 1. Upsert do ledger. ON CONFLICT DO NOTHING + RETURNING só devolve a row
  --    quando ELA foi inserida agora; senão v_ledger_id fica null e tratamos
  --    como conflito (reassign idempotente).
  insert into public.active_faction_quests (
    player_id, faction_id, mission_key, week_start, assigned_at
  ) values (
    p_player, p_faction_id, p_mission_key, p_week_start, v_now
  )
  on conflict (player_id, faction_id, week_start) do nothing
  returning id into v_ledger_id;

  if v_ledger_id is not null then
    v_inserted := true;
  else
    -- Conflito: recupera o ledger já existente.
    select id into v_ledger_id
    from public.active_faction_quests
    where player_id = p_player
      and faction_id = p_faction_id
      and week_start = p_week_start;
  end if;

  if v_inserted then
    -- 2. Materializa o progresso na mesma transação (mission_key do ledger).
    insert into public.player_mission_progress (
      player_id, mission_key, modality, tab_origin, rank,
      target_value, current_value, reward_json, started_at,
      reward_claimed, meta_json
    ) values (
      p_player,
      p_mission_key,
      p_seed->>'modality',
      'faction',
      p_seed->>'rank',
      (p_seed->>'target_value')::int,
      0,
      coalesce(p_seed->>'reward_json', (p_seed->'reward')::text),
      v_now,
      false,
      coalesce(p_seed->>'meta_json', '{}')
    )
    returning id into v_progress_id;
  else
    -- Idempotente: busca o progress 'faction' ativo já existente
    -- (mesma query do Dart: tab_origin='faction', completed/failed null).
    select id into v_progress_id
    from public.player_mission_progress
    where player_id = p_player
      and mission_key = (
        select mission_key from public.active_faction_quests
        where player_id = p_player
          and faction_id = p_faction_id
          and week_start = p_week_start
      )
      and tab_origin = 'faction'
      and completed_at is null
      and failed_at is null
    limit 1;
  end if;

  return json_build_object(
    'ledger_id', v_ledger_id,
    'progress_id', v_progress_id
  );
end;
$$;

comment on function public.assign_weekly_faction_quest(uuid, text, text, text, jsonb)
  is 'Porta ActiveFactionQuestsRepositoryDrift.upsertAtomic: upsert idempotente ledger+progress da semanal de facção.';


-- ───────────────────────────────────────────────────────────────────────────
-- increment_gold_earned_via_quests
-- Fonte Dart: QuestRewardStatsService._increment (single writer).
--
-- Incremento atômico all-time de players.total_gold_earned_via_quests. Os
-- listeners Dart (RewardGranted/DailyMissionCompleted) já filtram fontes
-- inválidas (achievement cascade, ascensão, gold<=0); aqui apenas somamos.
-- void.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.increment_gold_earned_via_quests(
  p_player uuid,
  p_amount int
) returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  if p_amount is null or p_amount <= 0 then
    return; -- no-op (espelha guard amount<=0 do listener Dart)
  end if;

  update public.players
  set total_gold_earned_via_quests = total_gold_earned_via_quests + p_amount
  where id = p_player;
end;
$$;

comment on function public.increment_gold_earned_via_quests(uuid, int)
  is 'Porta QuestRewardStatsService._increment: soma all-time em players.total_gold_earned_via_quests.';
