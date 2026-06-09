-- ============================================================================
-- Card Game — posse de cartas do jogador (Modo Cartas ACDA).
-- Quais cartas o jogador POSSUI (desbloqueadas). card_id = id da carta no
-- catálogo client-side (sem FK; o catálogo vive em assets/JSON). RLS por jogador.
-- Fontes de obtenção (starter, pacotes, level-up, etc.) gravam aqui.
-- ============================================================================
create table public.player_cards (
  player_id   uuid   not null references public.players (id) on delete cascade,
  card_id     text   not null,
  acquired_at bigint not null,
  source      text   not null default 'starter',
  primary key (player_id, card_id)
);

alter table public.player_cards enable row level security;
create policy "player_cards_own" on public.player_cards
  for all using (auth.uid() = player_id) with check (auth.uid() = player_id);
