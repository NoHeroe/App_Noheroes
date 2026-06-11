-- ============================================================================
-- Card Game — ECONOMIA v1, BLOCO 7: preços de pacote + GEMAS na ascensão.
--
-- SPEC:
--  - pack_catalog: Blue 600 ouro · Rare 1.500 ouro · Big 3.000 ouro · Epic 80
--    gemas · Royale 250 gemas · Elite 300 gemas (buyable=false, event-gated) ·
--    New Releases não-comprável. Calibrável.
--  - Gemas: recompensa de ascensão de rank concede gemas (→D 20 · →C 50 ·
--    →B 100 · →A 200 · →S 400). Amarra guilda↔cartas.
--  - Elite/Exclusiva: flags futuras; pacotes dependentes ficam buyable=false
--    (já é o caso). Nada bloqueado agora.
-- ============================================================================

-- Preços dos pacotes (calibrável).
update public.pack_catalog set price_gold = 600,  price_gems = null, buyable = true  where pack_type = 'blue';
update public.pack_catalog set price_gold = 1500, price_gems = null, buyable = true  where pack_type = 'rare';
update public.pack_catalog set price_gold = 3000, price_gems = null, buyable = true  where pack_type = 'big';
update public.pack_catalog set price_gold = null, price_gems = 80,   buyable = true  where pack_type = 'epic';
update public.pack_catalog set price_gold = null, price_gems = 250,  buyable = true  where pack_type = 'royale';
update public.pack_catalog set price_gold = null, price_gems = 300,  buyable = false where pack_type = 'elite';        -- event-gated
update public.pack_catalog set buyable = false                                  where pack_type = 'new_releases'; -- recompensa de evento

-- ── ascension_ascend: + GEMAS por rank alvo ────────────────────────────────
-- Recria a função (idêntica à 20260609140008) adicionando a concessão de gemas
-- pelo rank de destino (v_next). v_gems já existe; só passa a ter valor.
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
  v_gems        int := 0;
  v_ins         int;
  v_life_gold   int;
  v_next        text;
  v_xp_json     json;
  v_prev_level  int;
  v_new_level   int;
begin
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

  v_next := public._ascension_next_rank(v_canon);
  if v_next is null then
    return json_build_object('ok', false, 'new_rank', null, 'reason', 'noop');
  end if;

  -- SPEC economia v1: gemas por rank alvo (amarra guilda↔cartas).
  v_gems := case v_next
              when 'D' then 20 when 'C' then 50 when 'B' then 100
              when 'A' then 200 when 'S' then 400 else 0 end;

  v_reward_xp   := coalesce((v_cycle#>>'{reward,xp}')::int, 0);
  v_reward_gold := coalesce((v_cycle#>>'{reward,gold}')::int, 0);
  v_reward_ins  := coalesce((v_cycle#>>'{reward,insignias}')::int, 0);

  v_xp   := round(v_reward_xp   * 0.4)::int;
  v_gold := round(v_reward_gold * 0.35)::int;
  v_ins  := v_reward_ins;

  if v_xp <> 0 then
    v_xp_json   := public.add_xp(p_player, v_xp);
    v_prev_level := (v_xp_json->>'previous_level')::int;
    v_new_level  := (v_xp_json->>'new_level')::int;
  end if;

  if v_gold <> 0 or v_gems <> 0 then
    v_life_gold := greatest(v_gold, 0);
    update public.players
       set gold                       = gold + v_gold,
           total_gold_earned_lifetime = total_gold_earned_lifetime + v_life_gold,
           gems                       = gems + v_gems
     where id = p_player;
  end if;

  if v_ins <> 0 then
    update public.players set insignias = insignias + v_ins where id = p_player;
  end if;

  perform public.set_guild_rank(p_player, v_next);

  update public.guild_ascension_state
     set cooldown_until_ms  = null,
         window_started_ms  = null,
         window_deadline_ms = null,
         status             = 'done'
   where player_id = p_player and rank_from = v_canon;

  return json_build_object(
    'ok',             true,
    'new_rank',       v_next,
    'reason',         null,
    'reward_xp',      v_xp,
    'reward_gold',    v_gold,
    'reward_gems',    v_gems,
    'reward_insignias', v_ins,
    'previous_level', v_prev_level,
    'new_level',      v_new_level
  );
end;
$$;
