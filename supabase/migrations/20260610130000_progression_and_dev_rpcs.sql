-- ============================================================================
-- Grupo 3+4 — contador de missões (gate da Guilda) + RPCs de DEV.
-- ============================================================================

-- increment_total_quests_completed — contador all-time de missões concluídas.
-- É o gate da Guilda de Aventureiros ("complete 15 missões"). Estava parado em
-- 0 porque nada incrementava após a migração S2. Single-writer no cliente:
-- QuestRewardStatsService (mesmo serviço que já soma total_gold_earned_via_quests).
-- security invoker: o jogador atualiza a própria row (RLS auth.uid()=id).
create or replace function public.increment_total_quests_completed(
  p_player uuid,
  p_amount int
) returns void
language plpgsql
security invoker
as $$
begin
  update public.players
     set total_quests_completed = total_quests_completed + p_amount
   where id = p_player;
end;
$$;

-- DEV: reseta classe + facção (pra re-testar os gatilhos de level-up L5/L7).
-- Zera class_type, faction_type='none' e remove a membership ativa.
-- SECURITY DEFINER + guard auth.uid()=p_player (só a própria conta).
create or replace function public.dev_reset_class_faction(p_player uuid)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'dev_reset_class_faction: caller % cannot act for player %',
      auth.uid(), p_player using errcode = 'insufficient_privilege';
  end if;
  update public.players
     set class_type = null, faction_type = 'none'
   where id = p_player;
  delete from public.player_faction_membership where player_id = p_player;
end;
$$;

-- DEV: apaga as conquistas concluídas do jogador (pra re-testar o pipeline de
-- conquistas). SECURITY DEFINER + guard auth.uid()=p_player.
create or replace function public.dev_reset_achievements(p_player uuid)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'dev_reset_achievements: caller % cannot act for player %',
      auth.uid(), p_player using errcode = 'insufficient_privilege';
  end if;
  delete from public.player_achievements_completed where player_id = p_player;
end;
$$;
