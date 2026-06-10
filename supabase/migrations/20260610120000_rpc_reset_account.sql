-- ============================================================================
-- reset_account — DEV: zera 100% a conta do jogador (full-online, ADR-0024).
-- ----------------------------------------------------------------------------
-- Apaga TODAS as tabelas de dados do jogador, restaura a row `players` aos
-- defaults de uma conta nova e re-semeia as receitas starter — espelha o que
-- `handle_new_user` faz no signup. Mantém id, email, created_at e a sessão
-- Auth (o usuário continua logado, mas como conta nova → onboarding refaz).
--
-- SECURITY DEFINER + guard `auth.uid() = p_player`: roda como owner (bypassa
-- RLS nos DELETEs e no insert de receitas), mas o usuário só pode resetar a
-- PRÓPRIA conta. Atômica (uma transação).
--
-- Ferramenta de DESENVOLVIMENTO (botão no Dev Panel). Destrutiva e sem volta.
-- ============================================================================
create or replace function public.reset_account(p_player uuid)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'reset_account: caller % cannot reset player %',
      auth.uid(), p_player using errcode = 'insufficient_privilege';
  end if;

  -- 1) Apaga todos os dados do jogador. `player_equipment` antes de
  --    `player_inventory` (FK equipment.inventory_id). As demais referenciam
  --    players.id direto — ordem indiferente.
  delete from public.player_equipment              where player_id = p_player;
  delete from public.player_inventory              where player_id = p_player;
  delete from public.player_recipes_unlocked       where player_id = p_player;
  delete from public.player_mission_progress       where player_id = p_player;
  delete from public.player_individual_missions    where player_id = p_player;
  delete from public.player_achievements_completed  where player_id = p_player;
  delete from public.npc_reputation                where player_id = p_player;
  delete from public.diary_entries                 where player_id = p_player;
  delete from public.guild_ascension_progress      where player_id = p_player;
  delete from public.guild_ascension_state         where player_id = p_player;
  delete from public.player_vitalism_affinities    where player_id = p_player;
  delete from public.player_vitalism_trees         where player_id = p_player;
  delete from public.life_vitalism_points          where player_id = p_player;
  delete from public.player_faction_reputation     where player_id = p_player;
  delete from public.active_faction_quests         where player_id = p_player;
  delete from public.player_faction_membership     where player_id = p_player;
  delete from public.faction_event_log             where player_id = p_player;
  delete from public.daily_missions                where player_id = p_player;
  delete from public.player_daily_mission_stats    where player_id = p_player;
  delete from public.player_daily_subtask_volume   where player_id = p_player;
  delete from public.player_cards                  where player_id = p_player;
  delete from public.player_decks                  where player_id = p_player;
  delete from public.player_packs                  where player_id = p_player;

  -- 2) Restaura `players` aos defaults de conta nova (mantém id, email,
  --    created_at). Espelha os defaults do schema (handle_new_user só insere
  --    id+email e deixa os DEFAULTs de coluna preencherem o resto).
  update public.players set
    shadow_name                  = 'Sombra',
    level                        = 1,
    xp                           = 0,
    xp_to_next                   = 100,
    attribute_points             = 0,
    vitalism_level               = 0,
    vitalism_xp                  = 0,
    strength                     = 1,
    dexterity                    = 1,
    intelligence                 = 1,
    constitution                 = 1,
    spirit                       = 1,
    charisma                     = 1,
    hp                           = 100,
    max_hp                       = 100,
    mp                           = 90,
    max_mp                       = 90,
    current_vitalism             = 0,
    gold                         = 0,
    gems                         = 0,
    insignias                    = 0,
    streak_days                  = 0,
    caelum_day                   = 1,
    shadow_state                 = 'stable',
    shadow_corruption            = 0,
    class_type                   = null,
    faction_type                 = null,
    guild_rank                   = 'none',
    total_quests_completed       = 0,
    narrative_mode               = 'longa',
    onboarding_done              = false,
    play_style                   = 'none',
    last_login_at                = now(),
    last_streak_date             = null,
    last_daily_reset             = null,
    last_weekly_reset            = null,
    last_daily_mission_rollover  = null,
    weight_kg                    = null,
    height_cm                    = null,
    daily_missions_streak        = 0,
    total_gems_spent             = 0,
    peak_level                   = 1,
    total_attribute_points_spent = 0,
    auto_confirm_enabled         = false,
    screens_visited_keys         = '',
    total_gold_earned_via_quests = 0,
    total_gold_earned_lifetime   = 0
  where id = p_player;

  -- 3) Re-semeia as receitas starter (mesmo passo do signup).
  perform public.unlock_starter_recipes(p_player);
end;
$$;
