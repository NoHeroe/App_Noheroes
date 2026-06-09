-- ============================================================================
-- NoHeroes — Schema inicial (Época 2, full-online Supabase) — ADR-0024
-- ----------------------------------------------------------------------------
-- Tradução do schema Drift 38 → Postgres. Identidade do jogador atrelada ao
-- Supabase Auth (players.id = auth.users.id, uuid). RLS por jogador em todas
-- as tabelas de dados; catálogos são leitura pública. "Começar do zero":
-- nenhum dado migrado; catálogos serão re-seedados a partir dos JSON.
--
-- Convenções de tipo:
--   IntColumn ms-epoch / *_ms / *_at(ms)  -> bigint
--   IntColumn contador/nível/flag         -> integer
--   DateTimeColumn                         -> timestamptz
--   TextColumn                             -> text   |   BoolColumn -> boolean
-- ============================================================================

-- ───────────────────────────────────────────────────────────────────────────
-- PLAYERS  (id = auth.users.id; sem passwordHash — Auth cuida da credencial)
-- ───────────────────────────────────────────────────────────────────────────
create table public.players (
  id                              uuid primary key references auth.users (id) on delete cascade,
  email                           text,
  shadow_name                     text    not null default 'Sombra',

  -- Progressão
  level                           integer not null default 1,
  xp                              integer not null default 0,
  xp_to_next                      integer not null default 100,
  attribute_points                integer not null default 0,

  -- Vitalismo
  vitalism_level                  integer not null default 0,
  vitalism_xp                     integer not null default 0,

  -- Atributos base
  strength                        integer not null default 1,
  dexterity                       integer not null default 1,
  intelligence                    integer not null default 1,
  constitution                    integer not null default 1,
  spirit                          integer not null default 1,
  charisma                        integer not null default 1,

  -- Status derivados
  hp                              integer not null default 100,
  max_hp                          integer not null default 100,
  mp                              integer not null default 90,
  max_mp                          integer not null default 90,
  current_vitalism                integer not null default 0,

  -- Economia
  gold                            integer not null default 0,
  gems                            integer not null default 0,
  insignias                       integer not null default 0,

  -- Narrativa
  streak_days                     integer not null default 0,
  caelum_day                      integer not null default 1,
  shadow_state                    text    not null default 'stable',
  shadow_corruption               integer not null default 0,

  -- Classe / facção / rank
  class_type                      text,
  faction_type                    text,
  guild_rank                      text    not null default 'none',
  total_quests_completed          integer not null default 0,

  -- Preferências
  narrative_mode                  text    not null default 'longa',
  onboarding_done                 boolean not null default false,
  play_style                      text    not null default 'none',

  -- Timestamps
  created_at                      timestamptz not null default now(),
  last_login_at                   timestamptz not null default now(),
  last_streak_date                timestamptz,

  -- Boot-checks de reset (ms epoch)
  last_daily_reset                bigint,
  last_weekly_reset               bigint,
  last_daily_mission_rollover     bigint,

  -- Dados físicos (Calibração)
  weight_kg                       integer,
  height_cm                       integer,

  -- Streak de diárias (separada do login streak)
  daily_missions_streak           integer not null default 0,

  -- Contadores all-time (triggers de conquista / gates)
  total_gems_spent                integer not null default 0,
  peak_level                      integer not null default 1,
  total_attribute_points_spent    integer not null default 0,
  auto_confirm_enabled            boolean not null default false,
  screens_visited_keys            text    not null default '',
  total_gold_earned_via_quests    integer not null default 0,
  total_gold_earned_lifetime      integer not null default 0
);

-- Cria a row de player automaticamente quando um usuário Auth nasce.
create function public.handle_new_user()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  insert into public.players (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ───────────────────────────────────────────────────────────────────────────
-- CATÁLOGOS (imutáveis, leitura pública — re-seedados a partir dos JSON)
-- ───────────────────────────────────────────────────────────────────────────
create table public.items_catalog (
  key                  text primary key,
  name                 text not null,
  description          text not null default '',
  type                 text not null,
  subtype              text,
  slot                 text,
  rank                 text,
  required_rank        text,
  rarity               text not null default 'common',
  is_secret            boolean not null default false,
  is_unique            boolean not null default false,
  is_dark_item         boolean not null default false,
  is_evolving          boolean not null default false,
  required_level       integer not null default 1,
  allowed_classes      text not null default '[]',
  allowed_factions     text not null default '[]',
  stats                text not null default '{}',
  effects              text not null default '{}',
  sources              text not null default '[]',
  shop_price_coins     integer,
  shop_price_gems      integer,
  stack_max            integer not null default 1,
  durability_max       integer,
  durability_breaks_to text,
  is_stackable         boolean not null default false,
  is_consumable        boolean not null default false,
  is_equippable        boolean not null default false,
  is_tradable          boolean not null default true,
  is_sellable          boolean not null default true,
  bind_on_pickup       boolean not null default false,
  craft_recipe_id      text,
  forge_recipe_id      text,
  enchant_allowed      boolean not null default true,
  sombrio_content_id   text,
  evolution_stages     text,
  image                text not null default '',
  icon                 text
);

create table public.recipes_catalog (
  key              text primary key,
  name             text not null,
  description      text not null default '',
  type             text not null,
  required_rank    text,
  required_level   integer not null default 1,
  required_station text not null default 'workshop',
  result_item_key  text not null references public.items_catalog (key),
  result_quantity  integer not null default 1,
  materials        text not null,
  cost_coins       integer not null default 0,
  duration_sec     integer not null default 0,
  unlock_sources   text not null,
  icon             text
);

create table public.vitalism_unique_catalog (
  id                text primary key,
  name              text not null,
  carrier_name      text not null,
  tier              text not null,
  theme_description text not null
);

-- ───────────────────────────────────────────────────────────────────────────
-- TABELAS DE JOGADOR  (player_id uuid -> players.id, cascade)
-- ───────────────────────────────────────────────────────────────────────────
create table public.npc_reputation (
  id           bigserial primary key,
  player_id    uuid not null references public.players (id) on delete cascade,
  npc_id       text not null,
  reputation   integer not null default 50,
  last_gain_at timestamptz,
  daily_gained integer not null default 0
);

create table public.diary_entries (
  id         bigserial primary key,
  player_id  uuid not null references public.players (id) on delete cascade,
  content    text not null default '',
  word_count integer not null default 0,
  entry_date timestamptz not null,
  updated_at timestamptz not null default now()
);

create table public.guild_ascension_progress (
  id                bigserial primary key,
  player_id         uuid not null references public.players (id) on delete cascade,
  rank_from         text not null,
  rank_to           text not null,
  step              integer not null,
  quest_key         text not null,
  title             text not null,
  description       text not null,
  check_type        text not null,
  check_params_json text not null,
  unlock_level      integer not null,
  xp_reward         integer not null,
  gold_reward       integer not null,
  completed         boolean not null default false,
  progress          integer not null default 0,
  progress_target   integer not null default 1
);

create table public.guild_ascension_state (
  player_id          uuid not null references public.players (id) on delete cascade,
  rank_from          text not null,
  attempts           integer not null default 0,
  failures           integer not null default 0,
  paid_cost          integer not null default 0,
  cooldown_until_ms  bigint,
  window_started_ms  bigint,
  window_deadline_ms bigint,
  status             text not null default 'locked',
  primary key (player_id, rank_from)
);

create table public.player_vitalism_affinities (
  player_id    uuid not null references public.players (id) on delete cascade,
  vitalism_id  text not null references public.vitalism_unique_catalog (id),
  acquired_at  bigint not null,
  acquired_via text not null,
  primary key (player_id, vitalism_id)
);

create table public.player_vitalism_trees (
  player_id   uuid not null references public.players (id) on delete cascade,
  vitalism_id text not null,
  node_id     text not null,
  unlocked    boolean not null default false,
  unlocked_at bigint,
  primary key (player_id, vitalism_id, node_id)
);

create table public.life_vitalism_points (
  player_id    uuid primary key references public.players (id) on delete cascade,
  total_points integer not null default 0,
  source_log   text not null default '[]'
);

create table public.player_inventory (
  id                    bigserial primary key,
  player_id             uuid not null references public.players (id) on delete cascade,
  item_key              text not null references public.items_catalog (key),
  quantity              integer not null default 1,
  durability_current    integer,
  acquired_at           bigint not null,
  acquired_via          text not null,
  evolution_stage       text,
  is_equipped           boolean not null default false,
  applied_rune_key      text,
  applied_sap_key       text,
  sap_charges_remaining integer
);

create table public.player_equipment (
  player_id    uuid not null references public.players (id) on delete cascade,
  slot         text not null,
  inventory_id bigint not null references public.player_inventory (id) on delete cascade,
  primary key (player_id, slot)
);

create table public.player_recipes_unlocked (
  player_id    uuid not null references public.players (id) on delete cascade,
  recipe_key   text not null references public.recipes_catalog (key),
  unlocked_at  bigint not null,
  unlocked_via text not null,
  primary key (player_id, recipe_key)
);

create table public.player_mission_progress (
  id             bigserial primary key,
  player_id      uuid not null references public.players (id) on delete cascade,
  mission_key    text not null,
  modality       text not null,
  tab_origin     text not null,
  rank           text not null,
  target_value   integer not null,
  current_value  integer not null default 0,
  reward_json    text not null,
  started_at     bigint not null,
  completed_at   bigint,
  failed_at      bigint,
  reward_claimed boolean not null default false,
  meta_json      text not null default '{}'
);

create table public.player_individual_missions (
  id               bigserial primary key,
  player_id        uuid not null references public.players (id) on delete cascade,
  name             text not null,
  description      text,
  category         text not null,
  intensity_index  integer not null,
  frequency        text not null,
  repeats          boolean not null default true,
  reward_json      text not null,
  created_at       bigint not null,
  deleted_at       bigint,
  completion_count integer not null default 0,
  failure_count    integer not null default 0
);

create table public.player_achievements_completed (
  player_id       uuid not null references public.players (id) on delete cascade,
  achievement_key text not null,
  completed_at    bigint not null,
  reward_claimed  boolean not null default false,
  primary key (player_id, achievement_key)
);

create table public.player_faction_reputation (
  player_id  uuid not null references public.players (id) on delete cascade,
  faction_id text not null,
  reputation integer not null default 50,
  updated_at bigint not null,
  primary key (player_id, faction_id)
);

create table public.active_faction_quests (
  id          bigserial primary key,
  player_id   uuid not null references public.players (id) on delete cascade,
  faction_id  text not null,
  mission_key text not null,
  week_start  text not null,
  assigned_at bigint not null,
  unique (player_id, faction_id, week_start)
);

create table public.daily_missions (
  id                 bigserial primary key,
  player_id          uuid not null references public.players (id) on delete cascade,
  data               text not null,
  modalidade         text not null,
  sub_categoria      text,
  titulo_key         text not null,
  titulo_resolvido   text not null,
  quote_resolvida    text not null,
  sub_tarefas_json   text not null,
  status             text not null default 'pending',
  created_at         bigint not null,
  completed_at       bigint,
  reward_claimed     boolean not null default false,
  was_auto_confirmed boolean not null default false
);
create index idx_daily_missions_player_data on public.daily_missions (player_id, data);

create table public.player_daily_mission_stats (
  player_id                           uuid primary key references public.players (id) on delete cascade,
  total_completed                     integer not null default 0,
  total_failed                        integer not null default 0,
  total_partial                       integer not null default 0,
  total_perfect                       integer not null default 0,
  total_super_perfect                 integer not null default 0,
  total_generated                     integer not null default 0,
  total_confirmed                     integer not null default 0,
  best_streak                         integer not null default 0,
  days_without_failing                integer not null default 0,
  best_days_without_failing           integer not null default 0,
  consecutive_fails_count             integer not null default 0,
  max_consecutive_fails               integer not null default 0,
  consecutive_active_days             integer not null default 0,
  best_consecutive_active_days        integer not null default 0,
  total_sub_tasks_completed           integer not null default 0,
  total_sub_tasks_overshoot           integer not null default 0,
  total_confirmed_before_8am          integer not null default 0,
  total_confirmed_after_10pm          integer not null default 0,
  total_confirmed_on_weekend          integer not null default 0,
  days_of_week_completed_bitmask      integer not null default 0,
  total_zero_progress_confirms        integer not null default 0,
  total_days_all_pilars               integer not null default 0,
  total_speedrun_completions          integer not null default 0,
  total_auto_confirm_completions      integer not null default 0,
  total_zero_progress_manual_confirms integer not null default 0,
  first_completed_at                  bigint,
  last_completed_at                   bigint,
  last_pilar_balance_day              text,
  last_active_day                     text,
  daily_today_count                   integer not null default 0,
  last_today_count_date               text,
  updated_at                          bigint not null
);

create table public.player_daily_subtask_volume (
  player_id    uuid not null references public.players (id) on delete cascade,
  sub_task_key text not null,
  total_units  integer not null default 0,
  updated_at   bigint not null,
  primary key (player_id, sub_task_key)
);

create table public.player_faction_membership (
  player_id          uuid not null references public.players (id) on delete cascade,
  faction_id         text not null,
  joined_at          bigint,
  left_at            bigint,
  locked_until       bigint,
  debuff_until       bigint,
  admission_attempts integer not null default 0,
  primary key (player_id, faction_id)
);

create table public.faction_event_log (
  id         bigserial primary key,
  player_id  uuid not null references public.players (id) on delete cascade,
  faction_id text not null,
  event_type text not null,
  payload    text,
  created_at bigint not null
);

-- ============================================================================
-- RLS — Row Level Security
-- ----------------------------------------------------------------------------
-- Catálogos: leitura pública (qualquer usuário autenticado). Escrita só via
-- service_role (seed), que bypassa RLS.
-- Tabelas de jogador: cada um só enxerga/escreve as próprias linhas
-- (auth.uid() = player_id). players usa auth.uid() = id.
-- ============================================================================

-- players
alter table public.players enable row level security;
create policy "players_select_own" on public.players for select using (auth.uid() = id);
create policy "players_insert_own" on public.players for insert with check (auth.uid() = id);
create policy "players_update_own" on public.players for update using (auth.uid() = id) with check (auth.uid() = id);

-- catálogos (leitura pública)
alter table public.items_catalog enable row level security;
create policy "items_catalog_read" on public.items_catalog for select using (true);
alter table public.recipes_catalog enable row level security;
create policy "recipes_catalog_read" on public.recipes_catalog for select using (true);
alter table public.vitalism_unique_catalog enable row level security;
create policy "vitalism_catalog_read" on public.vitalism_unique_catalog for select using (true);

-- Para cada tabela de jogador: RLS on + política "own rows" em ALL.
do $$
declare
  t text;
  player_tables text[] := array[
    'npc_reputation','diary_entries','guild_ascension_progress',
    'guild_ascension_state','player_vitalism_affinities','player_vitalism_trees',
    'life_vitalism_points','player_inventory','player_equipment',
    'player_recipes_unlocked','player_mission_progress','player_individual_missions',
    'player_achievements_completed','player_faction_reputation','active_faction_quests',
    'daily_missions','player_daily_mission_stats','player_daily_subtask_volume',
    'player_faction_membership','faction_event_log'
  ];
begin
  foreach t in array player_tables loop
    execute format('alter table public.%I enable row level security;', t);
    execute format(
      'create policy "%1$s_own" on public.%1$I for all '
      'using (auth.uid() = player_id) with check (auth.uid() = player_id);', t);
  end loop;
end;
$$;
