-- ============================================================================
-- Card Game — decks do jogador (Modo Cartas ACDA).
-- Um deck = 9 criaturas + 9 relíquias (ids do catálogo client-side, sem FK).
-- Suporta múltiplos decks; um marcado is_active. RLS por jogador.
-- ============================================================================
create table public.player_decks (
  id           uuid primary key default gen_random_uuid(),
  player_id    uuid not null references public.players (id) on delete cascade,
  name         text not null default 'Meu Deck',
  creature_ids text[] not null default '{}',
  relic_ids    text[] not null default '{}',
  is_active    boolean not null default true,
  updated_at   bigint not null
);

create index idx_player_decks_player on public.player_decks (player_id);

alter table public.player_decks enable row level security;
create policy "player_decks_own" on public.player_decks
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
