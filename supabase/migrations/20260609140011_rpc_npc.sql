-- RPCs do dominio "NPC reputation".
-- Porta fielmente lib/data/datasources/local/npc_reputation_service.dart (Drift -> Supabase, ADR-0024).
-- Tabela public.npc_reputation: id bigserial, player_id uuid, npc_id text,
--   reputation integer default 50, last_gain_at timestamptz, daily_gained integer default 0.
-- SECURITY INVOKER: a RLS "auth.uid() = player_id" ja protege escrita/leitura por jogador.

-- =========================================================================
-- add_npc_reputation
-- Porta NpcReputationService.addReputation (+ _ensure get-or-create).
-- Get-or-create da linha, reset diario de daily_gained, cap de +20/dia,
-- clamp da reputacao em 0..100. Retorna a quantidade efetivamente aplicada.
-- =========================================================================
create or replace function public.add_npc_reputation(
  p_player uuid,
  p_npc_id text,
  p_amount int
) returns int
language plpgsql
security invoker
as $$
declare
  v_daily_limit constant int := 20;            -- _dailyLimit
  v_row         public.npc_reputation%rowtype;
  v_daily       int;
  v_remaining   int;
  v_actual      int;
  v_new_rep     int;
  v_today       date := (now() at time zone 'utc')::date;  -- "hoje" (data, sem hora)
begin
  -- _ensure: get-or-create. Sem unique(player_id,npc_id) no schema, replicamos
  -- o select-then-insert do Dart. reputation/daily_gained usam o default do schema (50/0).
  select * into v_row
  from public.npc_reputation
  where player_id = p_player and npc_id = p_npc_id;

  if not found then
    insert into public.npc_reputation (player_id, npc_id)
    values (p_player, p_npc_id)
    returning * into v_row;
  end if;

  -- Reset diario: se nunca ganhou ou o ultimo ganho foi antes de hoje, zera daily_gained.
  v_daily := v_row.daily_gained;
  if v_row.last_gain_at is null
     or (v_row.last_gain_at at time zone 'utc')::date < v_today then
    v_daily := 0;
  end if;

  v_remaining := v_daily_limit - v_daily;
  if v_remaining <= 0 then
    return 0;                                   -- sem espaco no limite diario -> no-op
  end if;

  -- amount.clamp(0, remaining)
  v_actual := greatest(0, least(p_amount, v_remaining));
  -- (reputation + actual).clamp(0, 100)
  v_new_rep := greatest(0, least(v_row.reputation + v_actual, 100));

  update public.npc_reputation
  set reputation   = v_new_rep,
      last_gain_at = now(),
      daily_gained = v_daily + v_actual
  where player_id = p_player and npc_id = p_npc_id;

  return v_actual;
end;
$$;

-- =========================================================================
-- lose_npc_reputation
-- Porta NpcReputationService.loseReputation (+ _ensure get-or-create).
-- Subtrai amount da reputacao com clamp 0..100. Sem efeito no limite diario.
-- Operacao void no Dart -> RETURNS void.
-- =========================================================================
create or replace function public.lose_npc_reputation(
  p_player uuid,
  p_npc_id text,
  p_amount int
) returns void
language plpgsql
security invoker
as $$
declare
  v_row     public.npc_reputation%rowtype;
  v_new_rep int;
begin
  -- _ensure: get-or-create (mesma logica de add_npc_reputation).
  select * into v_row
  from public.npc_reputation
  where player_id = p_player and npc_id = p_npc_id;

  if not found then
    insert into public.npc_reputation (player_id, npc_id)
    values (p_player, p_npc_id)
    returning * into v_row;
  end if;

  -- (reputation - amount).clamp(0, 100)
  v_new_rep := greatest(0, least(v_row.reputation - p_amount, 100));

  update public.npc_reputation
  set reputation = v_new_rep
  where player_id = p_player and npc_id = p_npc_id;
end;
$$;
