-- =============================================================================
-- RPC domain: Factions
-- Porta fielmente a logica Dart de membership/reputacao/admissao de faccao:
--   - FactionReputationService.adjustReputation / _adjustSingle
--     (lib/domain/services/faction_reputation_service.dart)
--   - PlayerFactionReputationRepositoryDrift.delta / setAbsolute / getOrDefault
--     (lib/data/repositories/drift/player_faction_reputation_repository_drift.dart)
--   - FactionAdmissionProgressService._approveAdmission / _handleApproved /
--     _handleRejection (lib/data/datasources/local/faction_admission_progress_service.dart)
--   - LeaveFactionService.leaveFaction (lib/data/datasources/local/leave_faction_service.dart)
--   - QuestAdmissionService._incrementAttemptCount
--     (lib/data/datasources/local/quest_admission_service.dart)
--
-- Cada operacao multi-statement vira RPC para ganhar atomicidade
-- transacional (o cliente REST nao tem transacao multi-statement).
-- Player ja e auth.users.id (uuid) — players.id = uuid no schema novo.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- faction_reputation_delta — building block canonico de reputacao.
-- Origem Dart: PlayerFactionReputationRepositoryDrift.delta (que usa
-- getOrDefault default 50 + _clamp 0..100 + setAbsolute via insertOnConflictUpdate).
-- Le a reputacao atual (default 50 = neutro se nao existe row), soma o delta,
-- faz clamp 0..100 e UPSERT em player_faction_reputation. Retorna {before,after}.
-- updated_at = ms epoch (now()*1000), igual ao DateTime.now().millisecondsSinceEpoch.
-- SECURITY INVOKER: RLS (auth.uid() = player_id) protege escrita cross-player.
-- -----------------------------------------------------------------------------
create or replace function public.faction_reputation_delta(
  p_player  uuid,
  p_faction text,
  p_delta   int
) returns json
language plpgsql
security invoker
as $$
declare
  v_before int;
  v_after  int;
  v_now_ms bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  -- getOrDefault(playerId, factionId) — default 50 (neutro) se nao existe.
  select reputation into v_before
  from public.player_faction_reputation
  where player_id = p_player and faction_id = p_faction;

  if not found then
    v_before := 50;
  end if;

  -- _clamp(current + delta) — 0..100.
  v_after := least(greatest(v_before + p_delta, 0), 100);

  -- setAbsolute via insertOnConflictUpdate (upsert).
  insert into public.player_faction_reputation (player_id, faction_id, reputation, updated_at)
  values (p_player, p_faction, v_after, v_now_ms)
  on conflict (player_id, faction_id) do update
    set reputation = excluded.reputation,
        updated_at = excluded.updated_at;

  return json_build_object('before', v_before, 'after', v_after);
end;
$$;


-- -----------------------------------------------------------------------------
-- _faction_adjust_reputation_with_propagation (helper interno)
-- Origem Dart: FactionReputationService.adjustReputation — aplica o delta na
-- faccao alvo e PROPAGA via kFactionAlliances (lib/core/config/faction_alliances.dart):
-- para cada (aliada/rival, multiplier), aplica round(delta * multiplier).
-- A matrix esta inline aqui (porte literal de kFactionAlliances).
-- NOTA: o porte do _applyBuff (xpMult universal sobre delta>0) NAO esta incluido —
-- depende de FactionBuffService.getActiveMultipliers (debuff_until em runtime),
-- ainda nao portado para RPC. Ver 'assumptions'. Penalidades (delta<0), como a
-- saida de faccao (-20), passam cru de qualquer forma (Dart so buffa delta>0).
-- round() do Dart = half-away-from-zero; Postgres round(numeric) idem.
-- -----------------------------------------------------------------------------
create or replace function public._faction_adjust_reputation_with_propagation(
  p_player  uuid,
  p_faction text,
  p_delta   int
) returns void
language plpgsql
security invoker
as $$
declare
  v_alliances jsonb;
  v_ally      text;
  v_mult      numeric;
  v_propagated int;
begin
  -- if (delta == 0) return;
  if p_delta = 0 then
    return;
  end if;

  -- 1. Aplica delta principal (faction_reputation_delta = _adjustSingle + clamp).
  perform public.faction_reputation_delta(p_player, p_faction, p_delta);

  -- 2. Propaga via matrix de aliancas (kFactionAlliances). Base = delta ORIGINAL.
  v_alliances := jsonb_build_object(
    'moon_clan',    jsonb_build_object('error', 0.4, 'sun_clan', -0.5, 'guild', 0.1),
    'sun_clan',     jsonb_build_object('moon_clan', -0.5, 'guild', 0.1),
    'error',        jsonb_build_object('moon_clan', 0.4, 'guild', 0.1),
    'black_legion', jsonb_build_object('new_order', -0.4, 'guild', 0.1),
    'new_order',    jsonb_build_object('black_legion', -0.4, 'guild', 0.1),
    'trinity',      jsonb_build_object('renegades', -0.3, 'guild', 0.1),
    'renegades',    jsonb_build_object('trinity', -0.3, 'guild', 0.1),
    'guild',        jsonb_build_object(
                      'moon_clan', 0.1, 'sun_clan', 0.1, 'black_legion', 0.1,
                      'new_order', 0.1, 'trinity', 0.1, 'renegades', 0.1, 'error', 0.1)
  );

  for v_ally, v_mult in
    select key, value::numeric
    from jsonb_each_text(coalesce(v_alliances -> p_faction, '{}'::jsonb))
  loop
    -- propagated = (delta * mult).round(); if (propagated == 0) continue;
    v_propagated := round(p_delta::numeric * v_mult)::int;
    if v_propagated = 0 then
      continue;
    end if;
    perform public.faction_reputation_delta(p_player, v_ally, v_propagated);
  end loop;
end;
$$;


-- -----------------------------------------------------------------------------
-- increment_admission_attempts — incrementa contador de tentativas.
-- Origem Dart: QuestAdmissionService._incrementAttemptCount.
-- INSERT OR IGNORE (cria row pendente joined_at NULL se nao existe) +
-- increment admission_attempts + retorna novo valor.
-- -----------------------------------------------------------------------------
create or replace function public.increment_admission_attempts(
  p_player  uuid,
  p_faction text
) returns int
language plpgsql
security invoker
as $$
declare
  v_attempts int;
begin
  -- INSERT OR IGNORE (cria row pendente se nao existe).
  insert into public.player_faction_membership
    (player_id, faction_id, joined_at, left_at, locked_until, debuff_until, admission_attempts)
  values (p_player, p_faction, null, null, null, null, 0)
  on conflict (player_id, faction_id) do nothing;

  -- Increment + retorna novo valor (RETURNING e atomico, sem re-select).
  update public.player_faction_membership
     set admission_attempts = admission_attempts + 1
   where player_id = p_player and faction_id = p_faction
  returning admission_attempts into v_attempts;

  return coalesce(v_attempts, 1);
end;
$$;


-- -----------------------------------------------------------------------------
-- approve_faction_admission — promove o jogador a membro da faccao.
-- Origem Dart: FactionAdmissionProgressService._approveAdmission (+ paridade
-- com _handleApproved). Passos:
--   1. players.faction_type = factionId.
--   2. Welcome bonus +100 insignias — SO em join NOVO (idempotente: nao
--      recredita se o jogador ja era membro desta faccao). Guard: faction_type
--      ainda nao == factionId AND nao existe membership com joined_at setado.
--   3. UPSERT membership (INSERT OR IGNORE + set joined_at se NULL).
-- NAO atribui a semanal de faccao (MissionAssignmentService — fora do dominio
-- Factions; _assignWeeklyOnJoin e responsabilidade do dominio Missions).
-- needsReview: logica de jogo critica (grant de moeda + membership).
-- -----------------------------------------------------------------------------
create or replace function public.approve_faction_admission(
  p_player  uuid,
  p_faction text
) returns void
language plpgsql
security invoker
as $$
declare
  v_current_faction text;
  v_already_member  boolean;
  v_now_ms          bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  -- Estado atual para o guard de welcome bonus (join novo).
  select faction_type into v_current_faction
  from public.players
  where id = p_player;

  if not found then
    return; -- player nao existe — no-op (porte do early-return Dart).
  end if;

  select exists(
    select 1 from public.player_faction_membership
    where player_id = p_player and faction_id = p_faction and joined_at is not null
  ) into v_already_member;

  -- 1. Promove faction_type.
  update public.players
     set faction_type = p_faction
   where id = p_player;

  -- 2. Welcome bonus +100 insignias — somente join novo.
  if v_current_faction is distinct from p_faction and not v_already_member then
    update public.players
       set insignias = insignias + 100
     where id = p_player;
  end if;

  -- 3. UPSERT membership (cria se nao existe; seta joined_at se ainda NULL).
  insert into public.player_faction_membership
    (player_id, faction_id, joined_at, left_at, locked_until, debuff_until, admission_attempts)
  values (p_player, p_faction, v_now_ms, null, null, null, 0)
  on conflict (player_id, faction_id) do update
    set joined_at = case
                      when public.player_faction_membership.joined_at is null
                      then v_now_ms
                      else public.player_faction_membership.joined_at
                    end;
end;
$$;


-- -----------------------------------------------------------------------------
-- reject_faction_admission — reprova a admissao eliminatoria.
-- Origem Dart: FactionAdmissionProgressService._handleRejection.
-- Params: p_player, p_faction, p_lock_until_ms (now+48h, calculado no caller),
--         p_rep_delta (default -10 = _rejectRepDelta).
-- Passos:
--   1. markFailed em TODAS as MissionProgress da admissao desta faccao
--      (player_mission_progress, tab_origin='admission', pendentes — sem
--      completed_at e sem failed_at, meta_json->>'faction_id' = factionId).
--   2. Aplica rep_delta na faccao (SEM propagacao — Dart usa _factionRepo.delta
--      direto, nao adjustReputation; comentario Dart confirma "sem propagacao").
--   3. Set locked_until = p_lock_until_ms em player_faction_membership.
--   4. Reverte players.faction_type para 'none'.
-- needsReview: logica de jogo critica (lifecycle de admissao + penalidade).
-- -----------------------------------------------------------------------------
create or replace function public.reject_faction_admission(
  p_player        uuid,
  p_faction       text,
  p_lock_until_ms bigint,
  p_rep_delta     int
) returns void
language plpgsql
security invoker
as $$
declare
  v_now_ms bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  -- 1. markFailed das missoes de admissao pendentes desta faccao.
  --    MissionRepository.markFailed seta failed_at = now (porte: failed_at = v_now_ms).
  update public.player_mission_progress
     set failed_at = v_now_ms
   where player_id = p_player
     and tab_origin = 'admission'
     and completed_at is null
     and failed_at is null
     and (meta_json::jsonb ->> 'faction_id') = p_faction;

  -- 2. -10 reputacao (rep_delta). Sem propagacao aliada/rival (delta direto no repo).
  perform public.faction_reputation_delta(p_player, p_faction, p_rep_delta);

  -- 3. Lock 48h em player_faction_membership (linha ja existe da tentativa).
  update public.player_faction_membership
     set locked_until = p_lock_until_ms
   where player_id = p_player and faction_id = p_faction;

  -- 4. Reverte faction_type para 'none'.
  update public.players
     set faction_type = 'none'
   where id = p_player;
end;
$$;


-- -----------------------------------------------------------------------------
-- leave_faction — sai da faccao com todas as penalidades, atomico.
-- Origem Dart: LeaveFactionService.leaveFaction.
-- Params: p_player, p_faction, p_now_ms, p_lock_until_ms (now+7d),
--         p_debuff_until_ms (now+48h). Timestamps calculados no caller (paridade
--         com o Dart, que usa DateTime.now()), passados explicitamente.
-- Passos:
--   1. Valida membership: players.faction_type DEVE == factionId (raise senao).
--      Tambem rejeita factionId vazio / 'none' (porte do guard Dart).
--   2. Aplica -20 reputacao COM propagacao via kFactionAlliances
--      (LeaveFactionService usa _factionRep.adjustReputation, que propaga).
--   3. UPDATE membership: left_at, locked_until (7d), debuff_until (48h).
--   4. players.faction_type = 'none'. guild_rank NAO e tocado (modelo dual).
-- needsReview: logica de jogo critica (penalidades de saida + propagacao de rep).
-- -----------------------------------------------------------------------------
create or replace function public.leave_faction(
  p_player          uuid,
  p_faction         text,
  p_now_ms          bigint,
  p_lock_until_ms   bigint,
  p_debuff_until_ms bigint
) returns void
language plpgsql
security invoker
as $$
declare
  v_current_faction text;
begin
  -- Guard de factionId invalido (porte do early-throw Dart).
  if p_faction is null or p_faction = '' or p_faction = 'none' then
    raise exception 'LeaveFactionException: factionId invalido: "%"', p_faction;
  end if;

  -- 1. Valida membership atual.
  select faction_type into v_current_faction
  from public.players
  where id = p_player;

  if not found then
    raise exception 'LeaveFactionException: Player % nao existe', p_player;
  end if;

  if v_current_faction is distinct from p_faction then
    raise exception 'LeaveFactionException: Player % nao e membro de "%" (faction_type atual: "%")',
      p_player, p_faction, v_current_faction;
  end if;

  -- 2. -20 reputacao COM propagacao via matrix (adjustReputation).
  perform public._faction_adjust_reputation_with_propagation(p_player, p_faction, -20);

  -- 3. Atualiza membership (left_at + lock 7d + debuff 48h).
  update public.player_faction_membership
     set left_at      = p_now_ms,
         locked_until = p_lock_until_ms,
         debuff_until = p_debuff_until_ms
   where player_id = p_player and faction_id = p_faction;

  -- 4. Reverte faction_type para 'none'. guild_rank intocado (modelo dual).
  update public.players
     set faction_type = 'none'
   where id = p_player;
end;
$$;
