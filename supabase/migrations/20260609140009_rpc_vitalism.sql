-- ============================================================================
-- RPCs — Domínio "Vitalism" (Vitalismos Únicos)
-- ----------------------------------------------------------------------------
-- Porta a lógica de lib/data/datasources/local/vitalism_unique_service.dart
-- + lib/core/utils/vitalism_unique_policy.dart (decisões puras) para PL/pgSQL.
-- Época 2, full-online Supabase (ADR-0024). Ver ADRs 0004 (unicidade global do
-- pool de Comuns), 0005 (árvore preservada), 0006 (PvP via engine).
--
-- Constantes de pontos de vida por tier (placeholders v0.27.0, ADR 0008 futuro),
-- de AffinityTierExt.lifeRitualPoints em lib/domain/enums/affinity_tier.dart:
--   common => 10 | rare => 50 | special => 0
-- ============================================================================

-- ───────────────────────────────────────────────────────────────────────────
-- available_common_vitalisms_in_pool()
-- Porta: VitalismUniqueService.availableCommonVitalismsInPool
-- Comuns do catálogo que NÃO estão em posse de NENHUM jogador (unicidade GLOBAL
-- — ADR 0004). SECURITY DEFINER porque precisa ler afinidades de todos os
-- jogadores (a RLS por jogador esconderia as linhas alheias).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.available_common_vitalisms_in_pool()
  returns text[]
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  result text[];
begin
  select coalesce(array_agg(c.id order by c.id), array[]::text[])
    into result
  from public.vitalism_unique_catalog c
  where c.tier = 'common'
    and not exists (
      select 1
      from public.player_vitalism_affinities a
      where a.vitalism_id = c.id
    );
  return result;
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- awake_from_crystal(p_player uuid) -> text
-- Porta: VitalismUniqueService.awakeFromCrystal
-- Cerimônia do Cristal. No-op se o jogador já tem qualquer afinidade. Sorteia
-- um Comum do pool global (random() server-side); se o pool está vazio,
-- desperta sem afinidade (retorna null). Insere com acquired_via='crystal'
-- (insertOrIgnore -> on conflict do nothing). Retorna o vitalism_id sorteado.
-- SECURITY INVOKER: a RLS garante que só escreve linha do próprio jogador; o
-- pool é lido via available_common_vitalisms_in_pool() (DEFINER).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.awake_from_crystal(p_player uuid)
  returns text
  language plpgsql
  security invoker
  set search_path = public
as $$
declare
  v_existing  int;
  v_pool      text[];
  v_picked    text;
  v_now       bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
begin
  -- Já tem afinidade? No-op (pickRandom não roda).
  select count(*) into v_existing
  from public.player_vitalism_affinities
  where player_id = p_player;
  if v_existing > 0 then
    return null;
  end if;

  v_pool := public.available_common_vitalisms_in_pool();
  if v_pool is null or array_length(v_pool, 1) is null then
    return null; -- pool vazio: desperta sem afinidade
  end if;

  -- VitalismUniquePolicy.pickRandomFromPool: índice aleatório uniforme.
  v_picked := v_pool[floor(random() * array_length(v_pool, 1))::int + 1];

  insert into public.player_vitalism_affinities
    (player_id, vitalism_id, acquired_at, acquired_via)
  values (p_player, v_picked, v_now, 'crystal')
  on conflict (player_id, vitalism_id) do nothing;

  return v_picked;
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- perform_life_ritual(p_player uuid, p_sacrificed_rare_ids text[]) -> int
-- Porta: VitalismUniqueService.performLifeRitual (+ Policy.validate/canPerform).
-- Ritual do Vazio: valida o sacrifício de exatamente 3 Raros distintos em posse;
-- valida que o jogador ainda NÃO tem Vida ('life'); converte TODAS as afinidades
-- em posse em pontos da Vida (opção B), zera afinidades, insere a Vida com
-- acquired_via='life_ritual' e adiciona os pontos. Retorna os pontos convertidos,
-- ou null se rejeitado (validação falhou) — espelha o Future<int?>.
-- SECURITY INVOKER: só toca linhas do próprio jogador (protegido por RLS).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.perform_life_ritual(
  p_player              uuid,
  p_sacrificed_rare_ids text[]
)
  returns int
  language plpgsql
  security invoker
  set search_path = public
as $$
declare
  v_distinct    text[];
  v_rare_owned  int;
  v_has_life    boolean;
  v_points      int;
  v_now         bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
  v_converted   text[];
  v_entry       jsonb;
begin
  -- validateLifeRitualSacrifices: exatamente 3, todos distintos.
  if p_sacrificed_rare_ids is null or array_length(p_sacrificed_rare_ids, 1) <> 3 then
    return null;
  end if;
  select array_agg(distinct s) into v_distinct
  from unnest(p_sacrificed_rare_ids) as s;
  if array_length(v_distinct, 1) <> 3 then
    return null;
  end if;

  -- ...e todos em posse E do tier 'rare' (join afinidade -> catálogo).
  select count(*) into v_rare_owned
  from public.player_vitalism_affinities a
  join public.vitalism_unique_catalog c on c.id = a.vitalism_id
  where a.player_id = p_player
    and a.vitalism_id = any(p_sacrificed_rare_ids)
    and c.tier = 'rare';
  if v_rare_owned <> 3 then
    return null;
  end if;

  -- ownedByTier.containsKey('life') -> rejeita se já tem Vida.
  select exists (
    select 1 from public.player_vitalism_affinities
    where player_id = p_player and vitalism_id = 'life'
  ) into v_has_life;
  if v_has_life then
    return null;
  end if;

  -- calculateLifePointsFromAffinities sobre TODAS as afinidades em posse.
  -- Afinidades sem linha de catálogo / tier inválido são ignoradas (parseTier
  -- == null no Dart) e contribuem 0 — replicado pelo join + CASE.
  select
    coalesce(sum(case c.tier
                   when 'common'  then 10
                   when 'rare'    then 50
                   when 'special' then 0
                   else 0
                 end), 0),
    coalesce(array_agg(a.vitalism_id order by a.vitalism_id), array[]::text[])
    into v_points, v_converted
  from public.player_vitalism_affinities a
  join public.vitalism_unique_catalog c on c.id = a.vitalism_id
  where a.player_id = p_player;

  -- Zera afinidades em posse (árvore NÃO é tocada — ADR 0005).
  delete from public.player_vitalism_affinities where player_id = p_player;

  -- Adiciona a Vida.
  insert into public.player_vitalism_affinities
    (player_id, vitalism_id, acquired_at, acquired_via)
  values (p_player, 'life', v_now, 'life_ritual')
  on conflict (player_id, vitalism_id) do nothing;

  -- _addLifePoints(source='life_ritual', extra={sacrificed, converted}).
  v_entry := jsonb_build_object(
    'at',         v_now,
    'delta',      v_points,
    'source',     'life_ritual',
    'sacrificed', to_jsonb(p_sacrificed_rare_ids),
    'converted',  to_jsonb(v_converted)
  );
  perform public._vitalism_add_life_points(p_player, v_points, v_entry);

  return v_points;
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- steal_affinities(p_winner uuid, p_loser uuid)
-- Porta: VitalismUniqueService.stealAllAffinitiesFromLoser.
-- PvP: se o winner é Vitalista da Vida -> delega pra destroy_affinities_grant_life
-- (shouldDestroyInsteadOfSteal). Caso contrário, transfere TODAS as afinidades do
-- loser pro winner com acquired_via='pvp_steal' (insertOrIgnore) e remove do loser.
-- A árvore (player_vitalism_trees) de ambos é preservada (ADR 0005).
-- SECURITY DEFINER + guard: escreve linhas do OUTRO jogador (loser), o que a RLS
-- bloquearia. Guard: o ator (auth.uid()) deve ser o winner.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.steal_affinities(
  p_winner uuid,
  p_loser  uuid
)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_winner_is_life boolean;
  v_now            bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
begin
  -- Guard: o caller só pode atuar como ele mesmo (winner). auth.uid() é null em
  -- chamadas service_role — nesse caso confiamos no orquestrador (engine PvP).
  if auth.uid() is not null and auth.uid() <> p_winner then
    raise exception 'steal_affinities: caller % is not the winner %', auth.uid(), p_winner;
  end if;

  -- isVitalistaDaVida(winner) -> destrói em vez de roubar.
  select exists (
    select 1 from public.player_vitalism_affinities
    where player_id = p_winner and vitalism_id = 'life'
  ) into v_winner_is_life;

  if v_winner_is_life then
    perform public.destroy_affinities_grant_life(p_winner, p_loser);
    return;
  end if;

  -- Sem afinidades no loser: no-op.
  if not exists (
    select 1 from public.player_vitalism_affinities where player_id = p_loser
  ) then
    return;
  end if;

  -- Transfere: insere no winner (insertOrIgnore) cada afinidade do loser.
  insert into public.player_vitalism_affinities
    (player_id, vitalism_id, acquired_at, acquired_via)
  select p_winner, a.vitalism_id, v_now, 'pvp_steal'
  from public.player_vitalism_affinities a
  where a.player_id = p_loser
  on conflict (player_id, vitalism_id) do nothing;

  -- Remove TODAS as afinidades do loser.
  delete from public.player_vitalism_affinities where player_id = p_loser;
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- destroy_affinities_grant_life(p_vitalista_vida uuid, p_loser uuid)
-- Porta: VitalismUniqueService.destroyAffinitiesAndGrantLifePoints.
-- Vitalista da Vida destrói TODAS as afinidades do derrotado e ganha pontos
-- (calculateLifePointsFromAffinities sobre os tiers do loser). No-op se o loser
-- não tem afinidades. A árvore do loser é preservada (ADR 0005).
-- SECURITY DEFINER + guard: deleta linhas do loser (a RLS bloquearia).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.destroy_affinities_grant_life(
  p_vitalista_vida uuid,
  p_loser          uuid
)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_points    int;
  v_destroyed text[];
  v_count     int;
  v_now       bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
  v_entry     jsonb;
begin
  -- Guard: ator deve ser o Vitalista da Vida (winner). service_role: auth.uid() null.
  if auth.uid() is not null and auth.uid() <> p_vitalista_vida then
    raise exception 'destroy_affinities_grant_life: caller % is not %', auth.uid(), p_vitalista_vida;
  end if;

  -- _affinitiesWithTiersOf(loser): só afinidades com linha de catálogo/tier válido.
  select
    coalesce(sum(case c.tier
                   when 'common'  then 10
                   when 'rare'    then 50
                   when 'special' then 0
                   else 0
                 end), 0),
    coalesce(array_agg(a.vitalism_id order by a.vitalism_id), array[]::text[]),
    count(*)
    into v_points, v_destroyed, v_count
  from public.player_vitalism_affinities a
  join public.vitalism_unique_catalog c on c.id = a.vitalism_id
  where a.player_id = p_loser;

  -- loserWithTiers.isEmpty -> no-op (não deleta, não credita).
  if v_count = 0 then
    return;
  end if;

  -- Destrói TODAS as afinidades do loser (inclui eventuais sem catálogo).
  delete from public.player_vitalism_affinities where player_id = p_loser;

  -- _addLifePoints(source='pvp_destroy', extra={loser_id, destroyed}).
  v_entry := jsonb_build_object(
    'at',        v_now,
    'delta',     v_points,
    'source',    'pvp_destroy',
    'loser_id',  p_loser,
    'destroyed', to_jsonb(v_destroyed)
  );
  perform public._vitalism_add_life_points(p_vitalista_vida, v_points, v_entry);
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- unlock_tree_node(p_player uuid, p_vitalism_id text, p_node_id text) -> bool
-- Porta: VitalismUniqueService.unlockTreeNode.
-- Desbloqueia um nó da árvore do jogador. Retorna false se:
--   - a afinidade não está ATIVA (não evolui árvore dormente), ou
--   - o nó já estava desbloqueado.
-- Caller checa requisito de nível (não é responsabilidade desta função).
-- insertOrReplace -> upsert. SECURITY INVOKER (RLS protege).
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public.unlock_tree_node(
  p_player      uuid,
  p_vitalism_id text,
  p_node_id     text
)
  returns boolean
  language plpgsql
  security invoker
  set search_path = public
as $$
declare
  v_active           boolean;
  v_already_unlocked boolean;
  v_now              bigint := (extract(epoch from clock_timestamp()) * 1000)::bigint;
begin
  -- Afinidade precisa estar em posse (ativa).
  select exists (
    select 1 from public.player_vitalism_affinities
    where player_id = p_player and vitalism_id = p_vitalism_id
  ) into v_active;
  if not v_active then
    return false;
  end if;

  -- Já desbloqueado? Retorna false (existing != null && existing.unlocked).
  select coalesce(t.unlocked, false) into v_already_unlocked
  from public.player_vitalism_trees t
  where t.player_id = p_player
    and t.vitalism_id = p_vitalism_id
    and t.node_id = p_node_id;
  if v_already_unlocked then
    return false;
  end if;

  -- insertOrReplace: upsert do nó como desbloqueado.
  insert into public.player_vitalism_trees
    (player_id, vitalism_id, node_id, unlocked, unlocked_at)
  values (p_player, p_vitalism_id, p_node_id, true, v_now)
  on conflict (player_id, vitalism_id, node_id) do update
    set unlocked = true, unlocked_at = v_now;

  return true;
end;
$$;

-- ───────────────────────────────────────────────────────────────────────────
-- _vitalism_add_life_points (helper interno)
-- Porta: VitalismUniqueService._addLifePoints.
-- Upsert em life_vitalism_points: total_points += delta e append do entry no
-- source_log (JSON array em coluna text). Não exposto como RPC pública.
-- SECURITY DEFINER: chamado por destroy_affinities_grant_life (PvP) creditando
-- o winner — em fluxo service_role/PvP o ator pode não ser o dono da linha.
-- ───────────────────────────────────────────────────────────────────────────
create or replace function public._vitalism_add_life_points(
  p_player uuid,
  p_delta  int,
  p_entry  jsonb
)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  insert into public.life_vitalism_points (player_id, total_points, source_log)
  values (p_player, p_delta, jsonb_build_array(p_entry)::text)
  on conflict (player_id) do update
    set total_points = public.life_vitalism_points.total_points + p_delta,
        source_log   = (
          (public.life_vitalism_points.source_log::jsonb) || p_entry
        )::text;
end;
$$;
