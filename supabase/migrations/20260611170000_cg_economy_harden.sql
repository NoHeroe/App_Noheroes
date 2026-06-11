-- ============================================================================
-- Card Game — ECONOMIA: hardening de segurança.
--
-- As RPCs de economia (20260611150000/160000) foram criadas como SECURITY
-- INVOKER + helpers expostos. Dois problemas:
--   1) `cg_grant_resource` ficava exposto como RPC pública → um jogador podia
--      se conceder recursos infinitos (cheat).
--   2) Como invoker, ler as tabelas de custo (sem RLS/grant) pode falhar em
--      runtime pro role `authenticated`.
--
-- Correção: as 4 funções de economia viram SECURITY DEFINER (rodam como dono,
-- leem as tabelas de custo, mutam de forma server-authoritative — cada uma já
-- valida `auth.uid() = p_player`). Os 2 helpers ficam INTERNOS (revoke execute
-- de anon/authenticated): só as funções definer (donas) os chamam.
-- ============================================================================

-- Funções de economia → server-authoritative (definer) + search_path fixo.
alter function public.cg_create_card(uuid, text)     security definer;
alter function public.cg_disenchant_card(uuid, text) security definer;
alter function public.cg_upgrade_card(uuid, text)    security definer;
alter function public.cg_card_info(uuid, text)       security definer;

alter function public.cg_create_card(uuid, text)     set search_path = public, pg_temp;
alter function public.cg_disenchant_card(uuid, text) set search_path = public, pg_temp;
alter function public.cg_upgrade_card(uuid, text)    set search_path = public, pg_temp;
alter function public.cg_card_info(uuid, text)       set search_path = public, pg_temp;

-- Helpers de recurso: internos. Clientes não chamam direto (anti-cheat).
revoke execute on function public.cg_grant_resource(uuid, text, bigint)
  from public, anon, authenticated;
revoke execute on function public.cg_resource_amount(uuid, text)
  from public, anon, authenticated;

-- player_cg_resources: cliente só LÊ (a policy "for all" permitia o jogador
-- escrever o próprio saldo direto pelo PostgREST → cheat). Escrita fica
-- exclusiva das RPCs definer (que ignoram RLS).
drop policy if exists "player_cg_resources_own" on public.player_cg_resources;
create policy "player_cg_resources_read" on public.player_cg_resources
  for select using (auth.uid() = player_id);

-- DEV: concede um pacote de recursos pra testar a economia (sem fontes reais
-- de Soul Crystal/Dust ainda). Marcar para REMOÇÃO antes da produção real.
create or replace function public.dev_grant_card_resources(p_player uuid)
  returns json language plpgsql security definer
  set search_path = public, pg_temp as $$
declare r text;
begin
  if auth.uid() is null or auth.uid() <> p_player then
    raise exception 'dev_grant_card_resources: forbidden' using errcode = 'insufficient_privilege';
  end if;
  perform public.cg_grant_resource(p_player, 'card_dust', 5000);
  perform public.cg_grant_resource(p_player, 'relic_dust', 5000);
  perform public.cg_grant_resource(p_player, 'card_scroll', 3000);
  perform public.cg_grant_resource(p_player, 'relic_runes', 3000);
  perform public.cg_grant_resource(p_player, 'card_soul', 500);
  perform public.cg_grant_resource(p_player, 'relic_soul', 500);
  foreach r in array array['comum','rara','epica','lendaria'] loop
    perform public.cg_grant_resource(p_player, 'card_crystal_'  || r, 20);
    perform public.cg_grant_resource(p_player, 'relic_crystal_' || r, 20);
  end loop;
  return json_build_object('ok', true);
end; $$;

comment on function public.dev_grant_card_resources(uuid) is
  'DEV ONLY — concede recursos de card game pra teste. Remover na producao.';
