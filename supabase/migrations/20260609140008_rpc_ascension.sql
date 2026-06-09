-- ============================================================================
-- NoHeroes — RPCs do domínio "Guild Ascension" (Época 2, full-online — ADR-0024)
-- ----------------------------------------------------------------------------
-- Porte fiel da máquina de estados soulslike do Teste de Ascensão da Guilda:
--   lib/data/datasources/local/ascension_service.dart   (pay / ascend /
--                                                         checkDeadline /
--                                                         confirmManualTrial)
--   lib/data/datasources/local/guild_ascension_service.dart
--                                                        (initCycle / canAscend /
--                                                         loadCycleConfig / ascend)
--   lib/data/datasources/local/player_rank_service.dart (setRank — via RPC
--                                                         public.set_guild_rank)
--   lib/core/utils/guild_rank.dart                       (GuildRankSystem.next)
--   lib/domain/services/reward_resolve_service.dart +
--   lib/domain/balance/soulslike_balance.dart            (resolve() do reward)
--
-- Convenções (CONVENCOES SQL): plpgsql, schema public, corpo = 1 transação
-- atômica. SECURITY INVOKER (RLS auth.uid() = player_id protege escrita da
-- própria linha; estas RPCs só escrevem guild_ascension_* / players do próprio
-- jogador). Incrementos atômicos col = col + x. Retornos json com deltas onde o
-- caller Dart publicava evento (GoldSpent / RewardGranted / LevelUp).
--
-- CATÁLOGO: o Dart lê assets/data/guild_ascension.json via rootBundle. Não há
-- tabela seedada pra ascensão no schema. Para manter o porte self-contained
-- (um único .sql, sem alterar o schema), o catálogo vira um helper IMMUTABLE
-- public._ascension_cycle(rank_from) que devolve o ciclo como jsonb — espelho
-- 1:1 do JSON. Decisão registrada em assumptions.
--
-- NOTA de tipo: o Dart usa `int playerId` (Drift sqlite); no Postgres
-- players.id é uuid. Todas as assinaturas usam p_player uuid (= auth.users.id).
-- "now" do Dart é DateTime.now().millisecondsSinceEpoch; aqui usamos
-- (extract(epoch from now()) * 1000)::bigint (UTC). Ver risks (fuso).
-- ============================================================================


-- ───────────────────────────────────────────────────────────────────────────
-- Helper: catálogo de ciclos (espelho de assets/data/guild_ascension.json).
-- Devolve o ciclo cujo rank_from = canon (MAIÚSCULO 'E'..'A'); jsonb vazio se
-- não houver ciclo (rank S / 'none'). IMMUTABLE — depende só do argumento.
-- Estrutura idêntica ao JSON (unlock_requirements / fee_base / window_hours /
-- cooldown_hours / trials[] / reward).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._ascension_cycle(p_rank_from text)
  returns jsonb
  language sql
  immutable
as $$
  select coalesce(
    (
      select c
        from jsonb_array_elements('[
          {
            "rank_from": "E", "rank_to": "D",
            "unlock_requirements": {"min_level": 10, "missions_completed": 150, "gold_earned_lifetime": 10000, "card_wins": 5},
            "fee_base": 5000, "window_hours": 24, "cooldown_hours": 4,
            "trials": [
              {"key": "ed_t1", "title": "Prova do Iniciado — conclua 8 missões", "type": "auto", "check_type": "complete_any_total", "target": 8}
            ],
            "reward": {"xp": 500, "gold": 2000, "insignias": 50}
          },
          {
            "rank_from": "D", "rank_to": "C",
            "unlock_requirements": {"min_level": 20, "missions_completed": 600, "gold_earned_lifetime": 60000, "card_wins": 15},
            "fee_base": 20000, "window_hours": 48, "cooldown_hours": 4,
            "trials": [
              {"key": "dc_t1", "title": "conclua 12 missões", "type": "auto", "check_type": "complete_any_total", "target": 12},
              {"key": "dc_t2", "title": "Prova de Corpo — 100 flexões + 100 agachamentos + 100 abdominais", "type": "manual", "check_type": "manual_proof", "target": 1}
            ],
            "reward": {"xp": 1000, "gold": 5000, "insignias": 100}
          },
          {
            "rank_from": "C", "rank_to": "B",
            "unlock_requirements": {"min_level": 35, "missions_completed": 1800, "gold_earned_lifetime": 200000, "card_wins": 35},
            "fee_base": 60000, "window_hours": 72, "cooldown_hours": 4,
            "trials": [
              {"key": "cb_t1", "title": "conclua 20 missões", "type": "auto", "check_type": "complete_any_total", "target": 20},
              {"key": "cb_t2", "title": "Prova de Corpo — 200 de cada (flexão/agachamento/abdominal)", "type": "manual", "check_type": "manual_proof", "target": 1},
              {"key": "cb_t3", "title": "Duelo — vença 2 partidas sem perder nenhuma", "type": "mock", "check_type": "card_wins", "target": 2}
            ],
            "reward": {"xp": 2000, "gold": 12000, "insignias": 200}
          },
          {
            "rank_from": "B", "rank_to": "A",
            "unlock_requirements": {"min_level": 50, "missions_completed": 5000, "gold_earned_lifetime": 600000, "card_wins": 70},
            "fee_base": 150000, "window_hours": 96, "cooldown_hours": 4,
            "trials": [
              {"key": "ba_t1", "title": "conclua 40 missões", "type": "auto", "check_type": "complete_any_total", "target": 40},
              {"key": "ba_t2", "title": "conclua 3 missões espirituais", "type": "auto", "check_type": "complete_category_total", "category": "spiritual", "target": 3},
              {"key": "ba_t3", "title": "Prova de Corpo — 300 de cada", "type": "manual", "check_type": "manual_proof", "target": 1},
              {"key": "ba_t4", "title": "Duelo — vença 5 partidas sem perder", "type": "mock", "check_type": "card_wins", "target": 5}
            ],
            "reward": {"xp": 4000, "gold": 30000, "insignias": 400}
          },
          {
            "rank_from": "A", "rank_to": "S",
            "unlock_requirements": {"min_level": 70, "missions_completed": 12000, "gold_earned_lifetime": 2000000, "card_wins": 150},
            "fee_base": 400000, "window_hours": 120, "cooldown_hours": 4,
            "trials": [
              {"key": "as_t1", "title": "conclua 60 missões", "type": "auto", "check_type": "complete_any_total", "target": 60},
              {"key": "as_t2", "title": "Prova de Corpo — 500 de cada", "type": "manual", "check_type": "manual_proof", "target": 1},
              {"key": "as_boss", "title": "O Guardião do Topo — boss (gameplay futuro)", "type": "mock", "check_type": "boss_win", "target": 1}
            ],
            "reward": {"xp": 8000, "gold": 75000, "insignias": 800}
          }
        ]'::jsonb) as c
       where c->>'rank_from' = upper(coalesce(p_rank_from, ''))
       limit 1
    ),
    '{}'::jsonb
  );
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- Helper: canon do rank (GuildAscensionService._canonRank / AscensionService.
-- _canon). '', 'none' (qualquer caixa) → 'none' (sentinela, não casa ciclo).
-- Demais → UPPER. GuildRankSystem.fromString tolera caixa; o canon final é
-- sempre maiúsculo.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._ascension_canon(p_rank text)
  returns text
  language sql
  immutable
as $$
  select case
    when btrim(coalesce(p_rank, '')) = '' then 'none'
    when lower(btrim(p_rank)) = 'none'    then 'none'
    else upper(btrim(p_rank))
  end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- Helper: próximo rank (GuildRankSystem.next). Ordem e<d<c<b<a<s. NULL se já é
-- S ou se 'none'. Retorna sempre o canon MAIÚSCULO.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._ascension_next_rank(p_canon text)
  returns text
  language sql
  immutable
as $$
  select case upper(coalesce(p_canon, ''))
    when 'E' then 'D'
    when 'D' then 'C'
    when 'C' then 'B'
    when 'B' then 'A'
    when 'A' then 'S'
    else null            -- 'S' / 'none' / desconhecido → sem próximo
  end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- Helper: canAscend (GuildAscensionService.canAscend). True sse há ≥1 trial
-- materializado pro ciclo (player_id, rank_from) E todos estão completed.
-- Lista vazia → false (igual ao Dart: missions.isEmpty → false).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._ascension_can_ascend(p_player uuid, p_canon text)
  returns boolean
  language sql
  stable
as $$
  select exists (
           select 1 from public.guild_ascension_progress
            where player_id = p_player and rank_from = p_canon
         )
     and not exists (
           select 1 from public.guild_ascension_progress
            where player_id = p_player and rank_from = p_canon
              and completed = false
         );
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- Helper: materializa os trials do ciclo (GuildAscensionService.initCycle +
-- _trialParams). No-op se já existem trials pro (player, rank_from). Trials
-- type='mock' nascem auto-satisfeitos (completed + progress=target) — card-game
-- /boss inexistentes. check_params_json espelha _trialParams por check_type.
-- xp_reward/gold_reward das rows = 0 (reward é nível-ciclo, pago no ascend).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._ascension_init_cycle(p_player uuid, p_canon text)
  returns void
  language plpgsql
  security invoker
as $$
declare
  v_cycle     jsonb := public._ascension_cycle(p_canon);
  v_rank_to   text;
  v_min_level int;
  v_trial     jsonb;
  v_step      int := 1;
  v_target    int;
  v_is_mock   boolean;
  v_check     text;
  v_type      text;
  v_params    jsonb;
begin
  if v_cycle = '{}'::jsonb then
    return;  -- sem ciclo → no-op
  end if;

  -- existing.isNotEmpty → return (idempotente).
  if exists (select 1 from public.guild_ascension_progress
              where player_id = p_player and rank_from = p_canon) then
    return;
  end if;

  v_rank_to   := v_cycle->>'rank_to';
  v_min_level := coalesce((v_cycle#>>'{unlock_requirements,min_level}')::int, 0);

  for v_trial in select * from jsonb_array_elements(v_cycle->'trials') loop
    v_target  := coalesce((v_trial->>'target')::int, 1);
    v_check   := v_trial->>'check_type';
    v_type    := v_trial->>'type';
    v_is_mock := (v_type = 'mock');

    -- _trialParams: monta check_params_json por check_type.
    if v_check in ('complete_any_total', 'complete_category_total', 'achievements_count') then
      v_params := jsonb_build_object('count', v_target, 'type', v_type);
      if v_trial ? 'category' then
        v_params := v_params || jsonb_build_object('category', v_trial->>'category');
      end if;
    elsif v_check = 'streak_days' then
      v_params := jsonb_build_object('days', v_target, 'type', v_type);
    elsif v_check = 'diary_total_words' then
      v_params := jsonb_build_object('words', v_target, 'type', v_type);
    else  -- manual_proof / card_wins / boss_win
      v_params := jsonb_build_object('target', v_target, 'type', v_type);
    end if;

    insert into public.guild_ascension_progress (
      player_id, rank_from, rank_to, step, quest_key, title, description,
      check_type, check_params_json, unlock_level, xp_reward, gold_reward,
      completed, progress, progress_target
    ) values (
      p_player, p_canon, v_rank_to, v_step,
      v_trial->>'key',
      coalesce(v_trial->>'title', v_trial->>'key'),
      coalesce(v_trial->>'title', ''),
      v_check, v_params::text, v_min_level, 0, 0,
      v_is_mock,
      case when v_is_mock then v_target else 0 end,
      v_target
    );
    v_step := v_step + 1;
  end loop;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- ascension_pay — porte de AscensionService.pay.
-- Precondição: a VIEW derivada deve ser `payable`. Aqui revalidamos o mínimo
-- necessário p/ atomicidade: ciclo existe, jogador no rank_from (cadeia
-- sequencial), gates de unlock satisfeitos, status não-bloqueante (idle /
-- cooldown expirado / fora de janela ativa), e ouro suficiente.
-- Custo corrente = round(fee_base * 1.10^failures). Debita ouro (GoldSpent —
-- NÃO toca total_gold_earned_lifetime, é gasto), abre a janela (status='active',
-- attempts+1, window_started/deadline) e materializa os trials.
-- Retorna json:
--   sucesso → {ok:true, cost:<int>, reason:null}
--   falha   → {ok:false, cost:<int>, reason:'not_payable'|'no_cycle'|'insufficient_gold'}
-- (reason espelha PayResult.reason do Dart.)
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.ascension_pay(p_player uuid, p_rank_from text)
  returns json
  language plpgsql
  security invoker
as $$
declare
  v_canon         text  := public._ascension_canon(p_rank_from);
  v_cycle         jsonb := public._ascension_cycle(v_canon);
  v_fee_base      int;
  v_window_hours  int;
  v_failures      int;
  v_attempts      int;
  v_status        text;
  v_cooldown      bigint;
  v_deadline      bigint;
  v_cost          int;
  v_now           bigint := (extract(epoch from now()) * 1000)::bigint;
  -- gates
  v_level         int;
  v_gold          int;
  v_gold_life     int;
  v_guild_rank    text;
  v_missions      int;
  v_req_level     int;
  v_req_missions  int;
  v_req_gold      int;
  v_gates_ok      boolean;
  v_payable       boolean;
begin
  if v_cycle = '{}'::jsonb then
    return json_build_object('ok', false, 'reason', 'no_cycle', 'cost', 0);
  end if;

  v_fee_base     := coalesce((v_cycle->>'fee_base')::int, 0);
  v_window_hours := coalesce((v_cycle->>'window_hours')::int, 0);
  v_req_level    := coalesce((v_cycle#>>'{unlock_requirements,min_level}')::int, 0);
  v_req_missions := coalesce((v_cycle#>>'{unlock_requirements,missions_completed}')::int, 0);
  v_req_gold     := coalesce((v_cycle#>>'{unlock_requirements,gold_earned_lifetime}')::int, 0);

  -- Estado atual (pode não existir → idle).
  select failures, attempts, status, cooldown_until_ms, window_deadline_ms
    into v_failures, v_attempts, v_status, v_cooldown, v_deadline
    from public.guild_ascension_state
   where player_id = p_player and rank_from = v_canon
   for update;
  if not found then
    v_failures := 0; v_attempts := 0; v_status := 'idle';
    v_cooldown := null; v_deadline := null;
  end if;

  -- Custo corrente = round(fee_base * 1.10^failures) (AscensionService._currentCost).
  -- Cast p/ numeric antes do round → half-away-from-zero (igual a Dart .round();
  -- round(double precision) usaria rint half-to-even do platform).
  v_cost := round((v_fee_base * power(1.10, v_failures))::numeric)::int;

  -- Snapshot do jogador p/ gates (AscensionService.evaluateGates).
  select level, gold, total_gold_earned_lifetime, guild_rank
    into v_level, v_gold, v_gold_life, v_guild_rank
    from public.players
   where id = p_player
   for update;
  if not found then
    return json_build_object('ok', false, 'reason', 'not_payable', 'cost', v_cost);
  end if;

  -- missions_completed: UNIÃO daily_missions + player_mission_progress, lifetime
  -- (countMissionsCompleted sem janela). "Completada" = completed_at not null
  -- (+ status='completed' nas daily).
  v_missions := (
      select count(*) from public.daily_missions
       where player_id = p_player and completed_at is not null and status = 'completed'
    ) + (
      select count(*) from public.player_mission_progress
       where player_id = p_player and completed_at is not null
    );

  -- Gates (level / missions / gold_lifetime). card_wins é mock-satisfeito.
  -- Cadeia sequencial: rank atual do jogador == rank_from do ciclo.
  v_gates_ok := upper(v_guild_rank) = v_canon
                and v_level     >= v_req_level
                and v_missions  >= v_req_missions
                and v_gold_life >= v_req_gold;

  -- VIEW == payable? (status não bloqueante + gates_ok). Espelha o derive de
  -- evaluateGates: done/active-na-janela/cooldown-ativo NÃO são payable.
  v_payable := v_gates_ok
               and v_status <> 'done'
               and not (v_status = 'cooldown' and v_cooldown is not null and v_now < v_cooldown)
               and not (v_status = 'active'   and v_deadline is not null and v_now < v_deadline);

  if not v_payable then
    return json_build_object('ok', false, 'reason', 'not_payable', 'cost', v_cost);
  end if;

  -- Ouro suficiente? (checado DENTRO da tx, igual ao Dart).
  if v_gold < v_cost then
    return json_build_object('ok', false, 'reason', 'insufficient_gold', 'cost', v_cost);
  end if;

  -- Debita a fee (gasto — NÃO mexe em total_gold_earned_lifetime).
  update public.players set gold = gold - v_cost where id = p_player;

  -- Abre a janela (insertOnConflictUpdate). failures preservado.
  insert into public.guild_ascension_state (
    player_id, rank_from, attempts, failures, paid_cost,
    cooldown_until_ms, window_started_ms, window_deadline_ms, status
  ) values (
    p_player, v_canon, v_attempts + 1, v_failures, v_cost,
    null, v_now, v_now + v_window_hours * 3600000, 'active'
  )
  on conflict (player_id, rank_from) do update set
    attempts           = excluded.attempts,
    failures           = excluded.failures,
    paid_cost          = excluded.paid_cost,
    cooldown_until_ms  = excluded.cooldown_until_ms,
    window_started_ms  = excluded.window_started_ms,
    window_deadline_ms = excluded.window_deadline_ms,
    status             = excluded.status;

  -- Materializa os trials (motor avança o progresso por evento).
  perform public._ascension_init_cycle(p_player, v_canon);

  -- O caller Dart publicava GoldSpent(amount=cost, source=ascension).
  return json_build_object('ok', true, 'reason', null, 'cost', v_cost);
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- ascension_ascend — porte de AscensionService.ascend.
-- Precondições: status='active', janela não vencida, canAscend (todos trials
-- completos), ciclo existe. Idempotente: relê o status DENTRO da tx; se já
-- 'done' → no-op ('noop').
-- Reward (RewardResolveService.resolve com progressPct=100):
--   xp        = round(reward.xp * 0.4)   (SOULSLIKE xpMultiplier; fórmula
--                                          0-300% é identidade em 100%)
--   gold      = round(reward.gold * 0.35)(goldMultiplier)
--   gems      = round(0 * 0.7) = 0       (ascensão não declara gems)
--   insignias = reward.insignias (CRU — não passa por fórmula nem multiplier)
-- Crédito: add_xp(xp); gold += gold E total_gold_earned_lifetime += max(gold,0)
-- E gems += gems (mesmo UPDATE do Dart); insignias += insignias. Sobe rank via
-- set_guild_rank(next) — que também evolui o Colar da Guilda. status='done'.
-- Retorna json:
--   sucesso → {ok:true, new_rank:<'D'..'S'>, reason:null, previous_level, new_level}
--   falha   → {ok:false, new_rank:null,
--              reason:'not_active'|'window_expired'|'trials_incomplete'|'no_cycle'|'noop'}
-- (reason espelha AscendResult.reason. previous_level/new_level p/ o LevelUp.)
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.ascension_ascend(p_player uuid, p_rank_from text)
  returns json
  language plpgsql
  security invoker
as $$
declare
  v_canon       text  := public._ascension_canon(p_rank_from);
  v_cycle       jsonb := public._ascension_cycle(v_canon);
  v_status      text;
  v_deadline    bigint;
  v_attempts    int;
  v_failures    int;
  v_paid        int;
  v_now         bigint := (extract(epoch from now()) * 1000)::bigint;
  v_reward_xp   int;
  v_reward_gold int;
  v_reward_ins  int;
  v_xp          int;
  v_gold        int;
  v_gems        int := 0;  -- ascensão não declara gems → resolved.gems = 0
  v_ins         int;
  v_life_gold   int;
  v_next        text;
  v_xp_json     json;
  v_prev_level  int;
  v_new_level   int;
begin
  -- Pré-checks (espelham os guards do Dart, fora da tx-lógica; aqui já estamos
  -- numa transação implícita, então lemos com FOR UPDATE p/ idempotência).
  select status, window_deadline_ms, attempts, failures, paid_cost
    into v_status, v_deadline, v_attempts, v_failures, v_paid
    from public.guild_ascension_state
   where player_id = p_player and rank_from = v_canon
   for update;

  if not found or v_status <> 'active' then
    return json_build_object('ok', false, 'new_rank', null, 'reason', 'not_active');
  end if;
  if v_deadline is null or v_now >= v_deadline then
    return json_build_object('ok', false, 'new_rank', null, 'reason', 'window_expired');
  end if;
  if not public._ascension_can_ascend(p_player, v_canon) then
    return json_build_object('ok', false, 'new_rank', null, 'reason', 'trials_incomplete');
  end if;
  if v_cycle = '{}'::jsonb then
    return json_build_object('ok', false, 'new_rank', null, 'reason', 'no_cycle');
  end if;

  -- Idempotência: status já foi lido FOR UPDATE acima e é 'active'; uma 2ª
  -- chamada concorrente bloqueia até esta tx commitar e então verá 'done'
  -- (cai em not_active). Fiel ao "relê DENTRO da tx" do Dart.

  v_next := public._ascension_next_rank(v_canon);
  if v_next is null then
    -- canon == 'S'/'none' → GuildAscensionService.ascend retorna null → noop.
    return json_build_object('ok', false, 'new_rank', null, 'reason', 'noop');
  end if;

  -- Reward declarado do ciclo → resolve (progressPct=100).
  v_reward_xp   := coalesce((v_cycle#>>'{reward,xp}')::int, 0);
  v_reward_gold := coalesce((v_cycle#>>'{reward,gold}')::int, 0);
  v_reward_ins  := coalesce((v_cycle#>>'{reward,insignias}')::int, 0);

  -- 0.4 / 0.35 são literais numeric → round() half-away-from-zero (= Dart .round()).
  v_xp   := round(v_reward_xp   * 0.4)::int;  -- SoulslikeBalance.xpMultiplier
  v_gold := round(v_reward_gold * 0.35)::int; -- SoulslikeBalance.goldMultiplier
  v_ins  := v_reward_ins;                     -- insígnias cru (sem multiplier)

  -- Crédito DIRETO (igual ao Dart; add_xp p/ XP, UPDATE p/ gold/gems/insignias).
  if v_xp <> 0 then
    v_xp_json   := public.add_xp(p_player, v_xp);
    v_prev_level := (v_xp_json->>'previous_level')::int;
    v_new_level  := (v_xp_json->>'new_level')::int;
  end if;

  if v_gold <> 0 or v_gems <> 0 then
    v_life_gold := greatest(v_gold, 0);  -- lifeGold = gold>0 ? gold : 0
    update public.players
       set gold                       = gold + v_gold,
           total_gold_earned_lifetime = total_gold_earned_lifetime + v_life_gold,
           gems                       = gems + v_gems
     where id = p_player;
  end if;

  if v_ins <> 0 then
    update public.players set insignias = insignias + v_ins where id = p_player;
  end if;

  -- Rank↑ + colar (GuildAscensionService.ascend → PlayerRankService.setRank).
  perform public.set_guild_rank(p_player, v_next);

  -- status = 'done' (encerra a janela).
  update public.guild_ascension_state
     set cooldown_until_ms  = null,
         window_started_ms  = null,
         window_deadline_ms = null,
         status             = 'done'
   where player_id = p_player and rank_from = v_canon;

  -- O caller Dart publicava RewardGranted(fromAscension:true) + LevelUp.
  return json_build_object(
    'ok',             true,
    'new_rank',       v_next,
    'reason',         null,
    'reward_xp',      v_xp,
    'reward_gold',    v_gold,
    'reward_insignias', v_ins,
    'previous_level', v_prev_level,
    'new_level',      v_new_level
  );
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- ascension_check_deadline — porte de AscensionService.checkDeadline.
-- Boot/abertura da tab: se a janela do ciclo venceu E o jogador NÃO completou
-- os trials (não canAscend) → FALHA: status='cooldown', failures+1,
-- cooldown_until = now + cooldown_hours, zera janela, e DELETA os trials
-- (próxima tentativa recomeça do zero). Caso contrário (sem state / não-active /
-- janela vigente / já completou) → no-op. Sem retorno (void).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.ascension_check_deadline(p_player uuid, p_rank_from text)
  returns void
  language plpgsql
  security invoker
as $$
declare
  v_canon      text  := public._ascension_canon(p_rank_from);
  v_status     text;
  v_deadline   bigint;
  v_attempts   int;
  v_failures   int;
  v_paid       int;
  v_now        bigint := (extract(epoch from now()) * 1000)::bigint;
  v_cooldown_h int;
begin
  select status, window_deadline_ms, attempts, failures, paid_cost
    into v_status, v_deadline, v_attempts, v_failures, v_paid
    from public.guild_ascension_state
   where player_id = p_player and rank_from = v_canon
   for update;

  if not found or v_status <> 'active' then
    return;  -- state == null || status != 'active' → no-op
  end if;
  if v_deadline is null then
    return;
  end if;
  if v_now < v_deadline then
    return;  -- janela ainda vigente
  end if;
  -- Vencido mas já completou os trials → deixa pro ascend (não falha).
  if public._ascension_can_ascend(p_player, v_canon) then
    return;
  end if;

  -- cooldown_hours do ciclo (default 4 se sem ciclo — config?.cooldownHours ?? 4).
  v_cooldown_h := coalesce(
    (public._ascension_cycle(v_canon)->>'cooldown_hours')::int, 4);

  update public.guild_ascension_state
     set attempts           = v_attempts,
         failures           = v_failures + 1,
         paid_cost          = v_paid,
         cooldown_until_ms  = v_now + v_cooldown_h * 3600000,
         window_started_ms  = null,
         window_deadline_ms = null,
         status             = 'cooldown'
   where player_id = p_player and rank_from = v_canon;

  -- Reset dos trials — próxima tentativa recomeça do zero.
  delete from public.guild_ascension_progress
   where player_id = p_player and rank_from = v_canon;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- ascension_confirm_manual_trial — porte de AscensionService.confirmManualTrial.
-- Marca um trial MANUAL (check_type='manual_proof') como concluído (auto-report
-- físico). Guards: status='active' + janela não vencida; o trial existe, é
-- 'manual_proof' e ainda não está completed. Retorna boolean = marcou agora.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.ascension_confirm_manual_trial(
  p_player    uuid,
  p_rank_from text,
  p_trial_key text
) returns boolean
  language plpgsql
  security invoker
as $$
declare
  v_canon    text := public._ascension_canon(p_rank_from);
  v_status   text;
  v_deadline bigint;
  v_now      bigint := (extract(epoch from now()) * 1000)::bigint;
  v_id       bigint;
  v_check    text;
  v_completed boolean;
  v_target   int;
begin
  select status, window_deadline_ms
    into v_status, v_deadline
    from public.guild_ascension_state
   where player_id = p_player and rank_from = v_canon
   for update;

  if not found or v_status <> 'active' then
    return false;
  end if;
  if v_deadline is null or v_now >= v_deadline then
    return false;
  end if;

  -- rows.isEmpty → false; pega o trial pela chave (questKey) no ciclo.
  select id, check_type, completed, progress_target
    into v_id, v_check, v_completed, v_target
    from public.guild_ascension_progress
   where player_id = p_player and rank_from = v_canon and quest_key = p_trial_key
   for update
   limit 1;

  if not found then
    return false;
  end if;
  -- Só marca se é manual_proof e ainda não completo.
  if v_check <> 'manual_proof' or v_completed then
    return false;
  end if;

  update public.guild_ascension_progress
     set completed = true,
         progress  = v_target
   where id = v_id;

  return true;
end;
$$;
