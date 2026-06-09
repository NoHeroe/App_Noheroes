-- ============================================================================
-- NoHeroes — RPCs do domínio "Player core" (Época 2, full-online — ADR-0024)
-- ----------------------------------------------------------------------------
-- Porte fiel de lib/data/database/daos/player_dao.dart +
-- lib/core/utils/xp_calculator.dart +
-- lib/domain/services/player_screens_visited_service.dart +
-- lib/domain/services/player_currency_stats_service.dart
--
-- Convenções (CONVENCOES SQL): plpgsql, schema public, corpo = 1 transação
-- atômica. SECURITY INVOKER (RLS auth.uid() = id já protege escrita de outra
-- linha). Incrementos atômicos col = col + x. Retornos json com deltas onde o
-- caller Dart publicava evento.
--
-- NOTA de tipo: o Dart usa `int id` (Drift sqlite); no Postgres players.id é
-- uuid. Todas as assinaturas usam p_player uuid (= auth.users.id).
-- ============================================================================

-- ───────────────────────────────────────────────────────────────────────────
-- Helper interno: curva de XP (XpCalculator.xpToNextLevel) — Soulslike.
-- Marcado IMMUTABLE: depende só do argumento.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._xp_to_next_level(p_level int)
  returns int
  language sql
  immutable
as $$
  select case
    when p_level <= 25 then 200  + (p_level - 1)  * 80
    when p_level <= 50 then 2200 + (p_level - 26) * 120
    when p_level <= 75 then 5200 + (p_level - 51) * 180
    else                    9700 + (p_level - 76) * 350
  end;
$$;

-- Helper: HP máximo (XpCalculator.calcMaxHp).
create or replace function public._calc_max_hp(p_constitution int, p_level int)
  returns int
  language sql
  immutable
as $$
  select 80 + (p_constitution * 10) + (p_level * 5);
$$;

-- Helper: MP máximo (XpCalculator.calcMaxMp). round() = arredondamento half-up;
-- Dart usa double.round() (round-half-away-from-zero). Valores aqui são sempre
-- positivos, então round() do Postgres (half-away) é equivalente.
create or replace function public._calc_max_mp(p_spirit int, p_constitution int, p_level int)
  returns int
  language sql
  immutable
as $$
  select round((public._calc_max_hp(p_constitution, p_level) * 0.9) + (p_spirit * 5))::int;
$$;

-- Helper: estado de sombra a partir da corrupção (XpCalculator.calcShadowState).
create or replace function public._calc_shadow_state(p_corruption int)
  returns text
  language sql
  immutable
as $$
  select case
    when p_corruption <= 15 then 'stable'
    when p_corruption <= 35 then 'unstable'
    when p_corruption <= 65 then 'chaotic'
    else 'abyssal'
  end;
$$;

-- Helper: pontos de scaling por classe/marco (PlayerDao._scalingBonusPoints).
create or replace function public._scaling_bonus_points(p_class_type text, p_marco int)
  returns int
  language sql
  immutable
as $$
  select case
    when p_class_type = 'shadowWeaver' then 1
    when p_marco >= 50 then 3
    when p_marco >= 25 then 2
    else 1
  end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- touch_last_login — porte de PlayerDao.touchLastLogin.
-- Atualiza login do dia: se já logou hoje, no-op. Senão incrementa streak
-- (XpCalculator.isStreakValid: last_streak_date == ontem → +1, senão reset=1),
-- avança caelum_day e grava last_login_at = now, last_streak_date = hoje.
-- NOTA fuso: o Dart usa DateTime.now() (local). Aqui usamos now() (timestamptz,
-- UTC); a comparação por dia usa o timezone da sessão. Ver assumptions/risks.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.touch_last_login(p_player uuid)
  returns void
  language plpgsql
  security invoker
as $$
declare
  v_last_login_at   timestamptz;
  v_last_streak     timestamptz;
  v_streak_days     int;
  v_new_streak      int;
  v_streak_valid    boolean;
begin
  select last_login_at, last_streak_date, streak_days
    into v_last_login_at, v_last_streak, v_streak_days
    from public.players
   where id = p_player;

  if not found then
    return;  -- player == null → no-op (igual ao Dart)
  end if;

  -- if (lastLoginDay == today) return;
  if date(v_last_login_at) = current_date then
    return;
  end if;

  -- XpCalculator.isStreakValid: last_streak_date é "ontem"?
  v_streak_valid := v_last_streak is not null
                    and date(v_last_streak) = current_date - interval '1 day';

  if v_streak_valid then
    v_new_streak := v_streak_days + 1;
  else
    v_new_streak := 1;
  end if;

  update public.players
     set last_login_at    = now(),
         last_streak_date = date_trunc('day', now()),  -- DateTime(year,month,day) → meia-noite
         streak_days      = v_new_streak,
         caelum_day       = caelum_day + 1
   where id = p_player;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- add_xp — porte de PlayerDao.addXp. Credita XP, sobe nível em loop, concede
-- attribute_points (1 por nível + bônus de scaling nos marcos), recalcula
-- max_hp/max_mp, atualiza peak_level (só cresce). Retorna {previous_level,
-- new_level}. NÃO escreve hp/mp atuais (fiel ao Dart, que só toca maxHp/maxMp).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.add_xp(p_player uuid, p_amount int)
  returns json
  language plpgsql
  security invoker
as $$
declare
  v_xp            int;
  v_level         int;
  v_xp_to_next    int;
  v_attr_points   int;
  v_constitution  int;
  v_spirit        int;
  v_class_type    text;
  v_peak_level    int;
  v_old_level     int;
  v_marco         int;
  v_marcos        int[] := array[10,15,20,25,30,40,50,60,70,80,99];
begin
  select xp, level, xp_to_next, attribute_points,
         constitution, spirit, class_type, peak_level
    into v_xp, v_level, v_xp_to_next, v_attr_points,
         v_constitution, v_spirit, v_class_type, v_peak_level
    from public.players
   where id = p_player;

  if not found then
    -- player == null no Dart retorna null; aqui devolvemos json null.
    return null;
  end if;

  v_old_level := v_level;
  v_xp        := v_xp + p_amount;

  -- while (newXp >= newXpToNext) { ... }
  while v_xp >= v_xp_to_next loop
    v_xp          := v_xp - v_xp_to_next;
    v_level       := v_level + 1;
    v_attr_points := v_attr_points + 1;
    v_xp_to_next  := public._xp_to_next_level(v_level);
  end loop;

  -- Bônus de scaling nos marcos cruzados neste ganho.
  foreach v_marco in array v_marcos loop
    if v_old_level < v_marco and v_level >= v_marco then
      v_attr_points := v_attr_points
        + public._scaling_bonus_points(v_class_type, v_marco);
    end if;
  end loop;

  -- peak_level só sobe.
  if v_level > v_peak_level then
    v_peak_level := v_level;
  end if;

  update public.players
     set xp               = v_xp,
         level            = v_level,
         xp_to_next       = v_xp_to_next,
         attribute_points = v_attr_points,
         max_hp           = public._calc_max_hp(v_constitution, v_level),
         max_mp           = public._calc_max_mp(v_spirit, v_constitution, v_level),
         peak_level       = v_peak_level
   where id = p_player;

  return json_build_object(
    'previous_level', v_old_level,
    'new_level',      v_level
  );
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- distribute_point — porte de PlayerDao.distributePointWithEvent.
-- Gasta 1 ponto no atributo escolhido. Retorna {error, new_value}:
--   sucesso → {error:null, new_value:<novo valor do atributo>}
--   falha   → {error:'<msg>', new_value:null}
-- constitution recalcula max_hp/max_mp E seta hp = max_hp (igual ao Dart).
-- spirit recalcula max_mp. Incrementa total_attribute_points_spent.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.distribute_point(p_player uuid, p_attribute text)
  returns json
  language plpgsql
  security invoker
as $$
declare
  v_attr_points  int;
  v_level        int;
  v_str          int;
  v_dex          int;
  v_int          int;
  v_con          int;
  v_spi          int;
  v_cha          int;
  v_new_value    int;
  v_new_max_hp   int;
  v_new_max_mp   int;
begin
  select attribute_points, level, strength, dexterity, intelligence,
         constitution, spirit, charisma
    into v_attr_points, v_level, v_str, v_dex, v_int,
         v_con, v_spi, v_cha
    from public.players
   where id = p_player;

  if not found then
    return json_build_object('error', 'Jogador não encontrado', 'new_value', null);
  end if;

  if v_attr_points <= 0 then
    return json_build_object('error', 'Sem pontos disponíveis', 'new_value', null);
  end if;

  if p_attribute = 'strength' then
    v_new_value := v_str + 1;
    update public.players
       set strength                     = v_new_value,
           attribute_points             = attribute_points - 1,
           total_attribute_points_spent = total_attribute_points_spent + 1
     where id = p_player;

  elsif p_attribute = 'dexterity' then
    v_new_value := v_dex + 1;
    update public.players
       set dexterity                    = v_new_value,
           attribute_points             = attribute_points - 1,
           total_attribute_points_spent = total_attribute_points_spent + 1
     where id = p_player;

  elsif p_attribute = 'intelligence' then
    v_new_value := v_int + 1;
    update public.players
       set intelligence                 = v_new_value,
           attribute_points             = attribute_points - 1,
           total_attribute_points_spent = total_attribute_points_spent + 1
     where id = p_player;

  elsif p_attribute = 'constitution' then
    v_new_value  := v_con + 1;
    v_new_max_hp := public._calc_max_hp(v_new_value, v_level);
    v_new_max_mp := public._calc_max_mp(v_spi, v_new_value, v_level);
    update public.players
       set constitution                 = v_new_value,
           max_hp                       = v_new_max_hp,
           max_mp                       = v_new_max_mp,
           hp                           = v_new_max_hp,
           attribute_points             = attribute_points - 1,
           total_attribute_points_spent = total_attribute_points_spent + 1
     where id = p_player;

  elsif p_attribute = 'spirit' then
    v_new_value  := v_spi + 1;
    v_new_max_mp := public._calc_max_mp(v_new_value, v_con, v_level);
    update public.players
       set spirit                       = v_new_value,
           max_mp                       = v_new_max_mp,
           attribute_points             = attribute_points - 1,
           total_attribute_points_spent = total_attribute_points_spent + 1
     where id = p_player;

  elsif p_attribute = 'charisma' then
    v_new_value := v_cha + 1;
    update public.players
       set charisma                     = v_new_value,
           attribute_points             = attribute_points - 1,
           total_attribute_points_spent = total_attribute_points_spent + 1
     where id = p_player;

  else
    return json_build_object('error', 'Atributo inválido', 'new_value', null);
  end if;

  return json_build_object('error', null, 'new_value', v_new_value);
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- add_gold — porte de PlayerDao.addGold. Incrementa gold (pode ser negativo);
-- total_gold_earned_lifetime conta só o GANHO (amount > 0). Atômico.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.add_gold(p_player uuid, p_amount int)
  returns void
  language plpgsql
  security invoker
as $$
begin
  update public.players
     set gold                       = gold + p_amount,
         total_gold_earned_lifetime = total_gold_earned_lifetime
                                       + greatest(p_amount, 0)  -- lifeGold = amount>0 ? amount : 0
   where id = p_player;
  -- player == null no Dart → no-op; aqui o update simplesmente não afeta linhas.
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- update_shadow — porte de PlayerDao.updateShadow. Reduz corrupção por
-- shadow_impact, clamp [0,100], recalcula shadow_state.
-- NOTA: o Dart faz (corruption - shadowImpact); shadow_impact positivo REDUZ
-- corrupção (cura). Mantido fiel.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.update_shadow(p_player uuid, p_shadow_impact int)
  returns void
  language plpgsql
  security invoker
as $$
declare
  v_corruption     int;
  v_new_corruption int;
begin
  select shadow_corruption into v_corruption
    from public.players
   where id = p_player;

  if not found then
    return;
  end if;

  v_new_corruption := least(greatest(v_corruption - p_shadow_impact, 0), 100);

  update public.players
     set shadow_corruption = v_new_corruption,
         shadow_state      = public._calc_shadow_state(v_new_corruption)
   where id = p_player;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- reset_level_attributes — porte de PlayerDao.resetLevelAttributes.
-- Zera atributos base para 1, devolve attribute_points = level-1, cobra
-- gold_cost. NÃO recalcula max_hp/max_mp (fiel ao Dart — não toca esses campos).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.reset_level_attributes(
  p_player uuid,
  p_level int,
  p_gold_cost int
)
  returns void
  language plpgsql
  security invoker
as $$
begin
  update public.players
     set strength         = 1,
         dexterity        = 1,
         intelligence     = 1,
         constitution     = 1,
         spirit           = 1,
         charisma         = 1,
         attribute_points = p_level - 1,  -- pointsFromLevel
         gold             = gold - p_gold_cost
   where id = p_player;
  -- player == null no Dart → no-op.
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- increment_daily_missions_streak — porte de PlayerDao.incrementDailyMissionsStreak.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.increment_daily_missions_streak(p_player uuid)
  returns void
  language plpgsql
  security invoker
as $$
begin
  update public.players
     set daily_missions_streak = daily_missions_streak + 1
   where id = p_player;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- reset_daily_missions_streak — porte de PlayerDao.resetDailyMissionsStreak.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.reset_daily_missions_streak(p_player uuid)
  returns void
  language plpgsql
  security invoker
as $$
begin
  update public.players
     set daily_missions_streak = 0
   where id = p_player;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- increment_gems_spent — porte de PlayerCurrencyStatsService._onGemsSpent.
-- Single writer de total_gems_spent. Incremento atômico.
-- (O Dart faz: UPDATE players SET total_gems_spent = total_gems_spent + ?)
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.increment_gems_spent(p_player uuid, p_amount int)
  returns void
  language plpgsql
  security invoker
as $$
begin
  update public.players
     set total_gems_spent = total_gems_spent + p_amount
   where id = p_player;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────
-- record_screen_visit — porte de PlayerScreensVisitedService.recordVisit.
-- Read-modify-write atômico sobre o CSV screens_visited_keys.
-- Retorna boolean = isFirstVisit (true se a tela foi adicionada agora).
--   - normaliza (trim + remove ?query e #fragment)
--   - path vazio → false (no-op)
--   - path em excludedFromTracking ('/', '/login', '/register') → false
--   - já visitado → false; novo → append e true
-- Normalização e parse CSV portados de _normalize / parseCSV.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.record_screen_visit(p_player uuid, p_screen_key text)
  returns boolean
  language plpgsql
  security invoker
as $$
declare
  v_normalized text;
  v_q_idx      int;
  v_f_idx      int;
  v_csv        text;
  v_visited    text[];
begin
  -- _normalize: trim, corta a partir de '?' e de '#'.
  v_normalized := btrim(coalesce(p_screen_key, ''));
  v_q_idx := position('?' in v_normalized);
  if v_q_idx > 0 then
    v_normalized := substring(v_normalized from 1 for v_q_idx - 1);
  end if;
  v_f_idx := position('#' in v_normalized);
  if v_f_idx > 0 then
    v_normalized := substring(v_normalized from 1 for v_f_idx - 1);
  end if;

  -- if (normalized.isEmpty) return;  → não é primeira visita (no-op)
  if v_normalized = '' then
    return false;
  end if;

  -- excludedFromTracking → noop sem registrar.
  if v_normalized in ('/', '/login', '/register') then
    return false;
  end if;

  -- transação implícita: SELECT ... FOR UPDATE evita race (read-modify-write).
  select screens_visited_keys into v_csv
    from public.players
   where id = p_player
   for update;

  if not found then
    return false;  -- player == null → no-op
  end if;

  -- parseCSV: split por vírgula, trim, descarta vazias.
  select coalesce(
           array_agg(t) filter (where t <> ''),
           array[]::text[]
         )
    into v_visited
    from (
      select btrim(unnest(string_to_array(coalesce(v_csv, ''), ','))) as t
    ) s;

  if v_normalized = any(v_visited) then
    return false;  -- já visitado
  end if;

  v_visited := v_visited || v_normalized;

  update public.players
     set screens_visited_keys = array_to_string(v_visited, ',')
   where id = p_player;

  return true;  -- isFirstVisit
end;
$$;
