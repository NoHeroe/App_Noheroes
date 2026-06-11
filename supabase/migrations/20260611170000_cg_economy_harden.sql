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
