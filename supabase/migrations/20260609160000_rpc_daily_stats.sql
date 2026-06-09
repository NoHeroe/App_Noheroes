-- ============================================================================
-- Época 2, S3-C — 8 RPCs de stats diários faltando (chamadas por
-- daily_mission_stats_service). Portadas 1:1 do antigo PlayerDailyMissionStatsDao
-- (UPDATEs crus). NOTA: SQLite MAX(a,b) escalar -> Postgres GREATEST(a,b).
-- Cada uma garante a row (findOrCreate) via _ensure_daily_stats. SECURITY
-- INVOKER: RLS auth.uid()=player_id protege (listener roda na sessão do jogador).
-- ============================================================================

create or replace function public._ensure_daily_stats(p_player uuid)
  returns void language plpgsql security invoker as $$
begin
  insert into public.player_daily_mission_stats (player_id, updated_at)
  values (p_player, (extract(epoch from now()) * 1000)::bigint)
  on conflict (player_id) do nothing;
end;
$$;

-- DailyMissionGenerated
create or replace function public.increment_daily_generated(p_player uuid)
  returns void language plpgsql security invoker as $$
begin
  perform public._ensure_daily_stats(p_player);
  update public.player_daily_mission_stats
     set total_generated = total_generated + 1,
         updated_at = (extract(epoch from now()) * 1000)::bigint
   where player_id = p_player;
end;
$$;

-- Partial (terminal sem ser falha): +total_partial, reseta consecutive_fails.
create or replace function public.increment_daily_partial(p_player uuid)
  returns void language plpgsql security invoker as $$
begin
  perform public._ensure_daily_stats(p_player);
  update public.player_daily_mission_stats
     set total_partial = total_partial + 1,
         consecutive_fails_count = 0,
         updated_at = (extract(epoch from now()) * 1000)::bigint
   where player_id = p_player;
end;
$$;

-- DailyMissionFailed: +fails, +consecutive, max=GREATEST, zera days_without_failing.
create or replace function public.increment_daily_failed(p_player uuid)
  returns void language plpgsql security invoker as $$
begin
  perform public._ensure_daily_stats(p_player);
  update public.player_daily_mission_stats
     set total_failed = total_failed + 1,
         consecutive_fails_count = consecutive_fails_count + 1,
         max_consecutive_fails = GREATEST(max_consecutive_fails, consecutive_fails_count + 1),
         days_without_failing = 0,
         updated_at = (extract(epoch from now()) * 1000)::bigint
   where player_id = p_player;
end;
$$;

-- best_streak = GREATEST(best_streak, p_current_streak).
create or replace function public.update_daily_best_streak(p_player uuid, p_current_streak int)
  returns void language plpgsql security invoker as $$
begin
  perform public._ensure_daily_stats(p_player);
  update public.player_daily_mission_stats
     set best_streak = GREATEST(best_streak, p_current_streak),
         updated_at = (extract(epoch from now()) * 1000)::bigint
   where player_id = p_player;
end;
$$;

-- +days_without_failing, best=GREATEST.
create or replace function public.bump_daily_days_without_failing(p_player uuid)
  returns void language plpgsql security invoker as $$
begin
  perform public._ensure_daily_stats(p_player);
  update public.player_daily_mission_stats
     set days_without_failing = days_without_failing + 1,
         best_days_without_failing = GREATEST(best_days_without_failing, days_without_failing + 1),
         updated_at = (extract(epoch from now()) * 1000)::bigint
   where player_id = p_player;
end;
$$;

-- Virada de dia ativo: consecutive++ (continuação) ou =1 (reset). Seta last_active_day.
create or replace function public.update_daily_consecutive_active_days(
    p_player uuid, p_today text, p_consecutive boolean)
  returns void language plpgsql security invoker as $$
begin
  perform public._ensure_daily_stats(p_player);
  if p_consecutive then
    update public.player_daily_mission_stats
       set consecutive_active_days = consecutive_active_days + 1,
           best_consecutive_active_days = GREATEST(best_consecutive_active_days, consecutive_active_days + 1),
           last_active_day = p_today,
           updated_at = (extract(epoch from now()) * 1000)::bigint
     where player_id = p_player;
  else
    update public.player_daily_mission_stats
       set consecutive_active_days = 1,
           best_consecutive_active_days = GREATEST(best_consecutive_active_days, 1),
           last_active_day = p_today,
           updated_at = (extract(epoch from now()) * 1000)::bigint
     where player_id = p_player;
  end if;
end;
$$;

-- Pilar-balance: +total_days_all_pilars + seta last_pilar_balance_day.
-- Idempotente: no-op se last_pilar_balance_day == p_today (guard duplo-count).
create or replace function public.mark_daily_pilar_balance_day(p_player uuid, p_today text)
  returns void language plpgsql security invoker as $$
begin
  perform public._ensure_daily_stats(p_player);
  update public.player_daily_mission_stats
     set total_days_all_pilars = total_days_all_pilars + 1,
         last_pilar_balance_day = p_today,
         updated_at = (extract(epoch from now()) * 1000)::bigint
   where player_id = p_player
     and (last_pilar_balance_day is null or last_pilar_balance_day <> p_today);
end;
$$;

-- daily_today_count com reset lazy YYYY-MM-DD. reset=true -> =1; senão +1.
create or replace function public.increment_daily_today_count(
    p_player uuid, p_reset_to_1_if_day_changed boolean, p_today_date text)
  returns void language plpgsql security invoker as $$
begin
  perform public._ensure_daily_stats(p_player);
  if p_reset_to_1_if_day_changed then
    update public.player_daily_mission_stats
       set daily_today_count = 1,
           last_today_count_date = p_today_date,
           updated_at = (extract(epoch from now()) * 1000)::bigint
     where player_id = p_player;
  else
    update public.player_daily_mission_stats
       set daily_today_count = daily_today_count + 1,
           last_today_count_date = p_today_date,
           updated_at = (extract(epoch from now()) * 1000)::bigint
     where player_id = p_player;
  end if;
end;
$$;
