-- Sprint sweep UI (2026-06-11) — sexo biológico + idade no player, para
-- cálculo realista de água/proteína (BodyMetricsService). Ambos nullable;
-- preenchidos no onboarding (calibração) ou no /perfil. Sem default — null
-- significa "ainda não informado" e o serviço cai no cálculo só-por-peso.
alter table public.players
  add column if not exists sex text,
  add column if not exists age integer;

-- Guard leve de domínio (não bloqueia null).
alter table public.players
  drop constraint if exists players_sex_chk;
alter table public.players
  add constraint players_sex_chk
  check (sex is null or sex in ('male', 'female'));

alter table public.players
  drop constraint if exists players_age_chk;
alter table public.players
  add constraint players_age_chk
  check (age is null or (age >= 5 and age <= 120));
