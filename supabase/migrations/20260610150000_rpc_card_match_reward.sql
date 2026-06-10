-- ============================================================================
-- Card Game — RECOMPENSAS de partida PvE (ponto #1 de "fechar o card game").
--
-- Design cravado (ver .vault/.../recompensas_de_partida.md), aprovado pelo CEO:
--   - Vitória: XP + gold "cheios" nas PRIMEIRAS kCap vitórias do dia.
--   - 1ª vitória do dia: bônus = 1 PACOTE de cartas grátis (gancho diário).
--   - Vitória além do teto (kCap+): XP simbólico, sem gold, sem pacote (anti-farm
--     — PvE é repetível).
--   - Derrota: consolação simbólica de XP (não pune aprender).
--
-- Server-authoritative: o cliente NÃO decide a recompensa, só informa win/loss.
-- O contador diário vive no servidor (players.card_pve_wins_today + _date), com
-- reset no virar do dia. Atômico (1 transação implícita por function).
--
-- Números 🎚️ tunáveis estão como constantes no topo do corpo.
-- ============================================================================

-- Contador diário de vitórias PvE do card game (reset no virar do dia).
alter table public.players
  add column if not exists card_pve_wins_date  date,
  add column if not exists card_pve_wins_today int not null default 0;

-- ----------------------------------------------------------------------------
-- public.grant_card_match_reward
-- Porta: CardMatchRewardService.grant(playerId, won)
-- Retorna json: {won, xp, gold, packs, win_number, xp_result}
--   xp_result = {previous_level,new_level} do add_xp (cliente reconstrói LevelUp).
-- ----------------------------------------------------------------------------
create or replace function public.grant_card_match_reward(
  p_player uuid,
  p_won    boolean
) returns json
language plpgsql
security invoker
set search_path = public
as $$
declare
  -- 🎚️ defaults tunáveis
  k_full_xp        constant int := 30;  -- XP da vitória "cheia"
  k_full_gold      constant int := 20;  -- gold da vitória "cheia"
  k_symbolic_xp    constant int := 5;   -- XP da vitória além do teto (farm)
  k_consolation_xp constant int := 5;   -- XP de derrota
  k_cap            constant int := 3;   -- nº de vitórias "cheias" por dia
  k_first_win_pack constant int := 1;   -- pacotes na 1ª vitória do dia

  v_owner       uuid;
  v_date        date;
  v_count       int;
  v_xp          int := 0;
  v_gold        int := 0;
  v_packs       int := 0;
  v_win_number  int := 0;
  v_xp_result   json := null;
begin
  -- Guard de propriedade: só credita a própria linha (RLS cobre players, mas
  -- explicitamos para o caminho de leitura/contador).
  if auth.uid() is not null and auth.uid() <> p_player then
    raise exception 'grant_card_match_reward: forbidden'
      using errcode = 'insufficient_privilege';
  end if;

  select id, card_pve_wins_date, card_pve_wins_today
    into v_owner, v_date, v_count
    from public.players
   where id = p_player
   for update;

  if not found then
    raise exception 'player_not_found: %', p_player using errcode = 'P0002';
  end if;

  -- Reset do contador no virar do dia.
  if v_date is null or v_date <> current_date then
    v_count := 0;
    v_date  := current_date;
  end if;

  if p_won then
    v_win_number := v_count + 1;
    if v_win_number = 1 then
      v_xp    := k_full_xp;
      v_gold  := k_full_gold;
      v_packs := k_first_win_pack;
    elsif v_win_number <= k_cap then
      v_xp   := k_full_xp;
      v_gold := k_full_gold;
    else
      v_xp := k_symbolic_xp; -- além do teto: simbólico (anti-farm)
    end if;
    -- Persiste o contador (derrota não conta como vitória).
    update public.players
       set card_pve_wins_today = v_win_number,
           card_pve_wins_date  = v_date
     where id = p_player;
  else
    v_xp := k_consolation_xp;
    -- Mesmo na derrota, grava a data pra normalizar o reset diário.
    update public.players
       set card_pve_wins_date = v_date
     where id = p_player;
  end if;

  -- Créditos (reusa as RPCs canônicas). add_xp recalcula level/xp_to_next/
  -- max_hp/mp/attribute_points e concede pacote por nível ganho; retorna
  -- {previous_level,new_level} pro cliente emitir LevelUp.
  if v_xp <> 0 then
    v_xp_result := public.add_xp(p_player, v_xp);
  end if;
  if v_gold <> 0 then
    perform public.add_gold(p_player, v_gold);
    update public.players
       set total_gold_earned_lifetime = total_gold_earned_lifetime + v_gold
     where id = p_player;
  end if;
  if v_packs > 0 then
    perform public.grant_pack(p_player, v_packs, 'padrao');
  end if;

  return json_build_object(
    'won',        p_won,
    'xp',         v_xp,
    'gold',       v_gold,
    'packs',      v_packs,
    'win_number', v_win_number,
    'xp_result',  v_xp_result
  );
end;
$$;

comment on function public.grant_card_match_reward(uuid, boolean) is
  'CardMatchRewardService.grant: recompensa de partida PvE do card game. '
  'Teto diário (3 vitórias cheias), 1ª vitória do dia dá pacote, derrota = '
  'consolação. Server-authoritative + atômico.';
