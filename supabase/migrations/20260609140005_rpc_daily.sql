-- ============================================================================
-- NoHeroes — RPCs do domínio "Daily missions + stats" (Época 2, ADR-0024)
-- ----------------------------------------------------------------------------
-- Porta fiel de:
--   lib/domain/services/daily_mission_progress_service.dart
--       (confirmCompletion / applyPartialReward / applyAutoCompleted /
--        computeReward / missionFactor / _resolveStatus / incrementSubTask)
--   lib/domain/services/daily_mission_rollover_service.dart (processRollover)
--   lib/domain/services/daily_mission_stats_service.dart
--       (_onCompleted bloco incrementOnCompleted + perfectness + janelas)
--   lib/data/database/daos/daily_missions_dao.dart
--   lib/data/database/daos/player_daily_mission_stats_dao.dart
--       (incrementOnCompleted / bestStreak / consecutiveActiveDays / ...)
--   lib/data/database/daos/player_daily_subtask_volume_dao.dart (incrementVolume)
--
-- Reward (regra final linear, hotfix-2 — daily_mission_progress_service.dart):
--   factor_sub_i = min(progresso_i / alvo_i, 3.0)            -- cap 300% por sub
--   factor       = soma(factor_sub_i) / N_subs               -- subs com alvo>0
--   mult         = factor                  se factor <= 1.0
--                = 1 + 0.45 * (factor - 1)  se factor >  1.0
--   streak       = 1.5 se status='completed' AND daily_missions_streak >= 10
--   xp           = floor(base_xp   * mult * streak)
--   gold         = floor(base_gold * mult * streak)
-- failed/pending => zero. Streak NÃO aplica em partial.
--
-- NOTA SOBRE FACTION BUFFS: o path Dart aplica _applyBuffs (xpMult/goldMult)
-- por cima do reward. Esse multiplicador vive em FactionBuffService (outro
-- domínio) e no Dart é opcional/neutral (path null => sem buff). Estas RPCs
-- creditam o reward BASE; o buff de facção, se portado, deve envelopar a
-- chamada. Ver 'assumptions'.
--
-- Sub-tarefas: armazenadas em daily_missions.sub_tarefas_json (TEXT contendo
-- um array JSON). Campos por sub (daily_sub_task_instance.dart):
--   sub_task_key, escala_alvo, progresso_atual, completed.
-- Convenção dailies usa player int no Dart; aqui player_id é uuid.
-- ============================================================================

-- ───────────────────────────────────────────────────────────────────────────
-- Helper interno: calcula o reward (xp, gold) de uma missão a partir do
-- array de sub-tarefas + rank + streak + status. Espelha computeReward +
-- missionFactor do daily_mission_progress_service.dart.
-- SECURITY INVOKER, IMMUTABLE-ish (não toca tabelas).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._daily_compute_reward(
  p_subs            jsonb,
  p_rank            text,
  p_status          text,   -- 'completed' | 'partial' | 'failed' | 'pending'
  p_streak          int
) returns table (xp int, gold int)
language plpgsql
immutable
as $$
declare
  v_base_xp     int;
  v_base_gold   int;
  v_rank        text := upper(coalesce(nullif(p_rank, ''), 'E'));
  v_sub         jsonb;
  v_alvo        numeric;
  v_prog        numeric;
  v_ratio       numeric;
  v_sum         numeric := 0;
  v_count       int := 0;
  v_factor      numeric;
  v_mult        numeric;
  v_streak_mult numeric := 1.0;
begin
  -- _normalizeRank: 'none'/'' => 'E', senão upper.
  if v_rank = 'NONE' then
    v_rank := 'E';
  end if;

  -- rewardByRank (constantes do service — ver 'assumptions').
  case v_rank
    when 'E' then v_base_xp := 8;   v_base_gold := 5;
    when 'D' then v_base_xp := 16;  v_base_gold := 12;
    when 'C' then v_base_xp := 28;  v_base_gold := 20;
    when 'B' then v_base_xp := 45;  v_base_gold := 32;
    when 'A' then v_base_xp := 72;  v_base_gold := 50;
    when 'S' then v_base_xp := 120; v_base_gold := 80;
    else          v_base_xp := 8;   v_base_gold := 5;  -- fallback 'E'
  end case;

  -- failed / pending => zero.
  if p_status = 'failed' or p_status = 'pending' then
    xp := 0; gold := 0; return next; return;
  end if;

  -- missionFactor: soma(clamp(progresso/alvo, 0, 3)) / N_subs.
  -- IMPORTANTE: o divisor é subTarefas.length (TODAS as subs), não só as
  -- com alvo>0 (fiel ao Dart: `sum / subs.length`; subs com alvo<=0 são
  -- puladas na soma mas contam no length).
  if p_subs is null or jsonb_typeof(p_subs) <> 'array'
     or jsonb_array_length(p_subs) = 0 then
    v_factor := 0.0;
  else
    for v_sub in select * from jsonb_array_elements(p_subs) loop
      v_count := v_count + 1;
      v_alvo := coalesce((v_sub->>'escala_alvo')::numeric, 0);
      if v_alvo > 0 then
        v_prog  := coalesce((v_sub->>'progresso_atual')::numeric, 0);
        v_ratio := v_prog / v_alvo;
        if v_ratio < 0 then v_ratio := 0; end if;
        if v_ratio > 3.0 then v_ratio := 3.0; end if;  -- subTaskMaxFactor
        v_sum := v_sum + v_ratio;
      end if;
    end loop;
    v_factor := v_sum / v_count;
  end if;

  -- mult linear (overshootSlope = 0.45).
  if v_factor <= 1.0 then
    v_mult := v_factor;
  else
    v_mult := 1.0 + 0.45 * (v_factor - 1.0);
  end if;

  -- streak bonus só em completed com streak >= 10.
  if p_status = 'completed' and p_streak >= 10 then
    v_streak_mult := 1.5;
  end if;

  xp   := floor(v_base_xp   * v_mult * v_streak_mult)::int;
  gold := floor(v_base_gold * v_mult * v_streak_mult)::int;
  return next;
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Helper interno: resolve o status final de uma missão a partir das subs.
-- Espelha _resolveStatus do daily_mission_progress_service.dart.
--   completed  se TODAS as subs têm progresso >= alvo
--   failed     se TODAS as subs têm progresso < 25% do alvo (failureThreshold)
--   partial    caso contrário
--   failed     se subs vazias
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._daily_resolve_status(p_subs jsonb)
returns text
language plpgsql
immutable
as $$
declare
  v_sub        jsonb;
  v_alvo       numeric;
  v_prog       numeric;
  v_ratio      numeric;
  v_all_full   boolean := true;
  v_all_below  boolean := true;
begin
  if p_subs is null or jsonb_typeof(p_subs) <> 'array'
     or jsonb_array_length(p_subs) = 0 then
    return 'failed';
  end if;

  for v_sub in select * from jsonb_array_elements(p_subs) loop
    v_alvo := coalesce((v_sub->>'escala_alvo')::numeric, 0);
    if v_alvo <= 0 then
      continue;
    end if;
    v_prog  := coalesce((v_sub->>'progresso_atual')::numeric, 0);
    v_ratio := v_prog / v_alvo;
    if v_ratio < 1.0 then
      v_all_full := false;
    end if;
    if v_ratio >= 0.25 then  -- failureThreshold
      v_all_below := false;
    end if;
  end loop;

  if v_all_full then
    return 'completed';
  elsif v_all_below then
    return 'failed';
  else
    return 'partial';
  end if;
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- Helper interno: aplica xp + gold ao player (reusa add_xp / add_gold do
-- contrato canônico) e devolve o levelup json (ou null). Também soma
-- total_gold_earned_lifetime (o path Dart faz isso no mesmo UPDATE do gold).
-- Retorna json {previous_level, new_level} se add_xp rodou, senão null.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._daily_credit_reward(
  p_player uuid,
  p_xp     int,
  p_gold   int
) returns json
language plpgsql
as $$
declare
  v_levelup json := null;
begin
  if p_xp > 0 then
    v_levelup := public.add_xp(p_player, p_xp);
  end if;
  if p_gold > 0 then
    -- add_gold credita players.gold; total_gold_earned_lifetime é específico
    -- do path de dailies (customUpdate Dart) e não está no contrato de add_gold.
    perform public.add_gold(p_player, p_gold);
    update public.players
       set total_gold_earned_lifetime = total_gold_earned_lifetime + p_gold
     where id = p_player;
  end if;
  return v_levelup;
end;
$$;

-- ============================================================================
-- confirm_daily_mission(bigint) -> json
-- Fonte: DailyMissionProgressService.confirmCompletion.
-- Guard de idempotência (reward_claimed OU status != 'pending' => erro),
-- resolve status, credita reward, fecha missão (status/completed_at/
-- reward_claimed=true). Retorna deltas pro caller publicar eventos.
-- SECURITY INVOKER: RLS garante que só o dono escreve a própria missão.
-- ============================================================================
create or replace function public.confirm_daily_mission(p_mission_id bigint)
returns json
language plpgsql
security invoker
as $$
declare
  v_mission    public.daily_missions%rowtype;
  v_subs       jsonb;
  v_status     text;
  v_rank       text;
  v_streak     int;
  v_xp         int;
  v_gold       int;
  v_levelup    json;
  v_now_ms     bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  select * into v_mission
    from public.daily_missions
   where id = p_mission_id;

  if not found then
    raise exception 'Missao % nao existe', p_mission_id
      using errcode = 'no_data_found';
  end if;

  -- Idempotência: RewardAlreadyGrantedException.
  if v_mission.reward_claimed or v_mission.status <> 'pending' then
    raise exception 'RewardAlreadyGranted(mission=%)', p_mission_id
      using errcode = 'unique_violation';
  end if;

  v_subs   := v_mission.sub_tarefas_json::jsonb;
  v_status := public._daily_resolve_status(v_subs);

  select p.guild_rank, p.daily_missions_streak
    into v_rank, v_streak
    from public.players p
   where p.id = v_mission.player_id;

  if not found then
    raise exception 'Player % sumiu mid-flight', v_mission.player_id;
  end if;

  select r.xp, r.gold into v_xp, v_gold
    from public._daily_compute_reward(v_subs, v_rank, v_status, v_streak) r;

  v_levelup := public._daily_credit_reward(v_mission.player_id, v_xp, v_gold);

  update public.daily_missions
     set status       = v_status,
         completed_at  = v_now_ms,
         reward_claimed = true
   where id = p_mission_id;

  return json_build_object(
    'mission_id',     p_mission_id,
    'player_id',      v_mission.player_id,
    'status',         v_status,
    'modalidade',     v_mission.modalidade,
    'full_completed', v_status = 'completed',
    'partial',        v_status = 'partial',
    'failed',         v_status = 'failed',
    'gold_earned',    v_gold,
    'xp_earned',      v_xp,
    'level_up',       v_levelup
  );
end;
$$;

-- ============================================================================
-- apply_partial_daily_reward(bigint) -> json
-- Fonte: DailyMissionProgressService.applyPartialReward (chamado no rollover).
-- Idempotente: no-op (retorna {applied:false}) se reward_claimed. Calcula
-- reward com status='partial' (sem streak), credita, fecha como 'partial'.
-- ============================================================================
create or replace function public.apply_partial_daily_reward(p_mission_id bigint)
returns json
language plpgsql
security invoker
as $$
declare
  v_mission    public.daily_missions%rowtype;
  v_subs       jsonb;
  v_rank       text;
  v_streak     int;
  v_xp         int;
  v_gold       int;
  v_levelup    json;
  v_now_ms     bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  select * into v_mission
    from public.daily_missions
   where id = p_mission_id;

  if not found then
    return json_build_object('applied', false, 'reason', 'not_found');
  end if;

  -- if (mission.rewardClaimed) return;  (no-op silencioso)
  if v_mission.reward_claimed then
    return json_build_object('applied', false, 'reason', 'already_claimed');
  end if;

  select p.guild_rank, p.daily_missions_streak
    into v_rank, v_streak
    from public.players p
   where p.id = v_mission.player_id;

  -- if (player == null) return;
  if not found then
    return json_build_object('applied', false, 'reason', 'player_missing');
  end if;

  v_subs := v_mission.sub_tarefas_json::jsonb;

  select r.xp, r.gold into v_xp, v_gold
    from public._daily_compute_reward(v_subs, v_rank, 'partial', v_streak) r;

  v_levelup := public._daily_credit_reward(v_mission.player_id, v_xp, v_gold);

  update public.daily_missions
     set status        = 'partial',
         completed_at   = v_now_ms,
         reward_claimed = true
   where id = p_mission_id;

  return json_build_object(
    'applied',        true,
    'mission_id',     p_mission_id,
    'player_id',      v_mission.player_id,
    'modalidade',     v_mission.modalidade,
    'full_completed', false,
    'partial',        true,
    'gold_earned',    v_gold,
    'xp_earned',      v_xp,
    'level_up',       v_levelup
  );
end;
$$;

-- ============================================================================
-- apply_auto_completed_daily(bigint) -> json
-- Fonte: DailyMissionProgressService.applyAutoCompleted.
-- Espelho de apply_partial mas status='completed' (com streak bonus) e
-- was_auto_confirmed=true. Idempotente: no-op se reward_claimed.
-- ============================================================================
create or replace function public.apply_auto_completed_daily(p_mission_id bigint)
returns json
language plpgsql
security invoker
as $$
declare
  v_mission    public.daily_missions%rowtype;
  v_subs       jsonb;
  v_rank       text;
  v_streak     int;
  v_xp         int;
  v_gold       int;
  v_levelup    json;
  v_now_ms     bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  select * into v_mission
    from public.daily_missions
   where id = p_mission_id;

  if not found then
    return json_build_object('applied', false, 'reason', 'not_found');
  end if;

  if v_mission.reward_claimed then
    return json_build_object('applied', false, 'reason', 'already_claimed');
  end if;

  select p.guild_rank, p.daily_missions_streak
    into v_rank, v_streak
    from public.players p
   where p.id = v_mission.player_id;

  if not found then
    return json_build_object('applied', false, 'reason', 'player_missing');
  end if;

  v_subs := v_mission.sub_tarefas_json::jsonb;

  select r.xp, r.gold into v_xp, v_gold
    from public._daily_compute_reward(v_subs, v_rank, 'completed', v_streak) r;

  v_levelup := public._daily_credit_reward(v_mission.player_id, v_xp, v_gold);

  update public.daily_missions
     set status             = 'completed',
         completed_at        = v_now_ms,
         reward_claimed      = true,
         was_auto_confirmed  = true
   where id = p_mission_id;

  return json_build_object(
    'applied',          true,
    'mission_id',       p_mission_id,
    'player_id',        v_mission.player_id,
    'modalidade',       v_mission.modalidade,
    'full_completed',   true,
    'partial',          false,
    'was_auto_confirmed', true,
    'gold_earned',      v_gold,
    'xp_earned',        v_xp,
    'level_up',         v_levelup
  );
end;
$$;

-- ============================================================================
-- process_daily_rollover(uuid, bigint) -> json
-- Fonte: DailyMissionRolloverService.processRollover.
-- Encapsula o rollover server-side (evita N+1). p_now_ms = "agora" em ms.
--   1) guard "primeira abertura do dia" via players.last_daily_mission_rollover
--   2) fecha pendentes/parciais com data < hoje:
--        auto_confirm_enabled & todas subs em 100%+ -> apply_auto_completed_daily
--        completedSubCount >= 1                     -> apply_partial_daily_reward
--        senão                                      -> markFailed (status='failed')
--   3) streak: missões de ONTEM -> todas completed => streak++, senão reset.
--      Sem missões ontem => mantém.
--   4) marca players.last_daily_mission_rollover = p_now_ms.
-- SECURITY INVOKER: opera só nas linhas do próprio jogador (RLS).
-- ============================================================================
create or replace function public.process_daily_rollover(
  p_player uuid,
  p_now_ms bigint
) returns json
language plpgsql
security invoker
as $$
declare
  v_player           public.players%rowtype;
  v_last_ms          bigint;
  v_today            text;
  v_yesterday        text;
  v_auto_enabled     boolean;
  v_m                public.daily_missions%rowtype;
  v_subs             jsonb;
  v_sub              jsonb;
  v_all_at_target    boolean;
  v_completed_count  int;
  v_closed           int := 0;
  v_auto             int := 0;
  v_partial          int := 0;
  v_failed           int := 0;
  v_y_total          int;
  v_y_all_full       boolean;
  v_streak_action    text := 'none';
begin
  select * into v_player from public.players where id = p_player;
  if not found then
    return json_build_object('rolled_over', false, 'reason', 'player_missing');
  end if;

  v_last_ms      := v_player.last_daily_mission_rollover;
  v_auto_enabled := v_player.auto_confirm_enabled;

  -- _dateStr a partir de epoch-ms local. Usa o timezone da sessão (to_timestamp
  -- retorna timestamptz; ::date no TZ da sessão). Ver 'assumptions' (TZ).
  v_today     := to_char(to_timestamp(p_now_ms / 1000.0), 'YYYY-MM-DD');
  v_yesterday := to_char(to_timestamp(p_now_ms / 1000.0) - interval '1 day',
                         'YYYY-MM-DD');

  -- _isFirstOpenOfTheDay: null => true; senão compara dia civil.
  if v_last_ms is not null then
    if to_char(to_timestamp(v_last_ms / 1000.0), 'YYYY-MM-DD') = v_today then
      return json_build_object('rolled_over', false, 'reason', 'already_today');
    end if;
  end if;

  -- 1) Fecha pendentes/parciais com data < hoje (findPendingBefore).
  for v_m in
    select *
      from public.daily_missions
     where player_id = p_player
       and data < v_today
       and status in ('pending', 'partial')
  loop
    v_subs := v_m.sub_tarefas_json::jsonb;

    -- allSubsAtTarget: array não-vazio E toda sub com alvo>0 e prog>=alvo.
    v_all_at_target := (jsonb_typeof(v_subs) = 'array'
                        and jsonb_array_length(v_subs) > 0);
    if v_all_at_target then
      for v_sub in select * from jsonb_array_elements(v_subs) loop
        if coalesce((v_sub->>'escala_alvo')::numeric, 0) <= 0
           or coalesce((v_sub->>'progresso_atual')::numeric, 0)
              < coalesce((v_sub->>'escala_alvo')::numeric, 0) then
          v_all_at_target := false;
          exit;
        end if;
      end loop;
    end if;

    if v_auto_enabled and v_all_at_target then
      perform public.apply_auto_completed_daily(v_m.id);
      v_auto   := v_auto + 1;
      v_closed := v_closed + 1;
      continue;
    end if;

    -- completedSubCount: count de subs com completed=true.
    select count(*) into v_completed_count
      from jsonb_array_elements(v_subs) s
     where coalesce((s->>'completed')::boolean, false);

    if v_completed_count >= 1 then
      perform public.apply_partial_daily_reward(v_m.id);
      v_partial := v_partial + 1;
    else
      -- markFailed: status='failed', completed_at=now, reward_claimed=false.
      -- markFailed só age se não claimed e não já failed (garantido pelo
      -- filtro status in pending/partial acima).
      update public.daily_missions
         set status        = 'failed',
             completed_at   = p_now_ms,
             reward_claimed = false
       where id = v_m.id;
      v_failed := v_failed + 1;
    end if;
    v_closed := v_closed + 1;
  end loop;

  -- 2) Streak — missões de ONTEM (após o passo 1 ter potencialmente fechado).
  --    allFull = toda missão de ontem com status efetivo 'completed'.
  select count(*),
         bool_and(status = 'completed')
    into v_y_total, v_y_all_full
    from public.daily_missions
   where player_id = p_player
     and data = v_yesterday;

  if v_y_total > 0 then
    if v_y_all_full then
      -- incrementDailyMissionsStreak
      update public.players
         set daily_missions_streak = daily_missions_streak + 1
       where id = p_player;
      v_streak_action := 'increment';
    else
      -- resetDailyMissionsStreak
      update public.players
         set daily_missions_streak = 0
       where id = p_player;
      v_streak_action := 'reset';
    end if;
  end if;

  -- 3) markDailyMissionRollover.
  update public.players
     set last_daily_mission_rollover = p_now_ms
   where id = p_player;

  return json_build_object(
    'rolled_over',    true,
    'player_id',      p_player,
    'closed',         v_closed,
    'auto_completed', v_auto,
    'partial',        v_partial,
    'failed',         v_failed,
    'streak_action',  v_streak_action
  );
end;
$$;

-- ============================================================================
-- increment_subtask_volume(uuid, text, int)
-- Fonte: PlayerDailySubtaskVolumeDao.incrementVolume (UPSERT incremental).
-- delta=0 => no-op. INSERT ... ON CONFLICT (player_id, sub_task_key) DO UPDATE
-- total_units = total_units + delta. updated_at em ms.
-- ============================================================================
create or replace function public.increment_subtask_volume(
  p_player       uuid,
  p_sub_task_key text,
  p_delta        int
) returns void
language plpgsql
security invoker
as $$
declare
  v_now_ms bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  if p_delta = 0 then
    return;
  end if;

  insert into public.player_daily_subtask_volume
    (player_id, sub_task_key, total_units, updated_at)
  values (p_player, p_sub_task_key, p_delta, v_now_ms)
  on conflict (player_id, sub_task_key) do update
    set total_units = public.player_daily_subtask_volume.total_units + p_delta,
        updated_at  = v_now_ms;
end;
$$;

-- ============================================================================
-- record_daily_on_completed(uuid, flags...) -> void
-- Fonte: PlayerDailyMissionStatsDao.incrementOnCompleted (bloco _onCompleted
-- do DailyMissionStatsService). Consolida o UPDATE composto que o PostgREST
-- não expressa (col=col+1 / MAX / bitmask / COALESCE).
--
-- Garante a row via findOrCreate (insertOrIgnore) antes do UPDATE.
-- manual_zero = zero_progress AND NOT was_auto_confirmed (anti-cheese).
-- p_confirmed_at_ms é o timestamp de confirmação (ms) — usado em
-- first/last_completed_at.
-- ============================================================================
create or replace function public.record_daily_on_completed(
  p_player              uuid,
  p_is_perfect          boolean,
  p_is_super_perfect    boolean,
  p_sub_tasks_completed int,
  p_sub_tasks_overshoot int,
  p_confirmed_at_ms     bigint,
  p_day_of_week         int,      -- 0=domingo .. 6=sábado
  p_is_before_8am       boolean,
  p_is_after_10pm       boolean,
  p_is_weekend          boolean,
  p_is_speedrun         boolean,
  p_zero_progress       boolean,
  p_was_auto_confirmed  boolean default false
) returns void
language plpgsql
security invoker
as $$
declare
  v_now_ms      bigint := (extract(epoch from now()) * 1000)::bigint;
  v_dow_mask    int := (1 << p_day_of_week);
  v_manual_zero boolean := p_zero_progress and not p_was_auto_confirmed;
begin
  -- findOrCreate (insertOrIgnore).
  insert into public.player_daily_mission_stats (player_id, updated_at)
  values (p_player, v_now_ms)
  on conflict (player_id) do nothing;

  update public.player_daily_mission_stats set
    total_completed                 = total_completed + 1,
    total_confirmed                 = total_confirmed + 1,
    total_perfect                   = total_perfect + (case when p_is_perfect then 1 else 0 end),
    total_super_perfect             = total_super_perfect + (case when p_is_super_perfect then 1 else 0 end),
    total_sub_tasks_completed       = total_sub_tasks_completed + p_sub_tasks_completed,
    total_sub_tasks_overshoot       = total_sub_tasks_overshoot + p_sub_tasks_overshoot,
    total_confirmed_before_8am      = total_confirmed_before_8am + (case when p_is_before_8am then 1 else 0 end),
    total_confirmed_after_10pm      = total_confirmed_after_10pm + (case when p_is_after_10pm then 1 else 0 end),
    total_confirmed_on_weekend      = total_confirmed_on_weekend + (case when p_is_weekend then 1 else 0 end),
    days_of_week_completed_bitmask  = days_of_week_completed_bitmask | v_dow_mask,
    consecutive_fails_count         = 0,
    total_zero_progress_confirms    = total_zero_progress_confirms + (case when p_zero_progress then 1 else 0 end),
    total_zero_progress_manual_confirms = total_zero_progress_manual_confirms + (case when v_manual_zero then 1 else 0 end),
    total_speedrun_completions      = total_speedrun_completions + (case when p_is_speedrun then 1 else 0 end),
    total_auto_confirm_completions  = total_auto_confirm_completions + (case when p_was_auto_confirmed then 1 else 0 end),
    first_completed_at              = coalesce(first_completed_at, p_confirmed_at_ms),
    last_completed_at               = p_confirmed_at_ms,
    updated_at                      = v_now_ms
  where player_id = p_player;
end;
$$;

-- ============================================================================
-- count_full_perfect_days(uuid, bigint, bigint) -> int
-- Agregado GROUP BY/HAVING (blueprint). Conta dias (daily_missions.data) no
-- intervalo [win_start, win_end] (ms epoch) em que TODAS as missões do dia
-- fecharam status='completed' E o dia teve >=1 missão.
-- "perfect day" = dia inteiro completed (todas as dailies do dia 100%).
-- Janela aplicada sobre created_at (ms) das missões. Ver 'assumptions'.
-- ============================================================================
create or replace function public.count_full_perfect_days(
  p_player    uuid,
  p_win_start bigint,
  p_win_end   bigint
) returns int
language plpgsql
stable
security invoker
as $$
declare
  v_count int;
begin
  select count(*) into v_count
    from (
      select data
        from public.daily_missions
       where player_id = p_player
         and created_at >= p_win_start
         and created_at <= p_win_end
       group by data
      having count(*) > 0
         and bool_and(status = 'completed')
    ) days;
  return coalesce(v_count, 0);
end;
$$;

-- ============================================================================
-- count_no_partial_days(uuid, bigint, bigint) -> int
-- Agregado GROUP BY/HAVING. Conta dias no intervalo em que NENHUMA missão
-- ficou 'partial' (e o dia teve >=1 missão). "dia sem parcial" = todas as
-- dailies do dia ou completed ou failed, nunca partial.
-- ============================================================================
create or replace function public.count_no_partial_days(
  p_player    uuid,
  p_win_start bigint,
  p_win_end   bigint
) returns int
language plpgsql
stable
security invoker
as $$
declare
  v_count int;
begin
  select count(*) into v_count
    from (
      select data
        from public.daily_missions
       where player_id = p_player
         and created_at >= p_win_start
         and created_at <= p_win_end
       group by data
      having count(*) > 0
         and count(*) filter (where status = 'partial') = 0
    ) days;
  return coalesce(v_count, 0);
end;
$$;
