/// Posse de cartas do jogador (Fatia 2 — Coleção).
///
/// Stub de posse: expõe o conjunto de IDs de cartas DESBLOQUEADAS. Hoje a
/// regra é um PLACEHOLDER puramente visual — não há fonte real ainda.
///
/// TODO: posse real via Supabase `player_cards` (substituir a regra placeholder
/// por uma query/stream da tabela do jogador autenticado).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/card_game/card_models.dart';

/// IDs das cartas que o jogador possui (desbloqueadas).
///
/// Placeholder: começa vazio; o catálogo é resolvido em runtime e a regra de
/// posse é aplicada por [isCardUnlocked]. Mantido como `Set<String>` para já
/// modelar a forma final (posse real será um set de ids vindos do back-end).
final cardOwnershipProvider = StateProvider<Set<String>>((ref) {
  // TODO: posse real via Supabase player_cards.
  // Por ora o set fica vazio e a posse é derivada pela regra placeholder
  // em `isCardUnlocked` (raridade comum = desbloqueada).
  return <String>{};
});

/// Regra de posse PLACEHOLDER.
///
/// Desbloqueado = raridade `comum` OU id presente no set de posse real. Assim
/// AMBOS os estados (bloqueado/desbloqueado) aparecem na coleção mesmo sem
/// back-end.
///
/// TODO: posse real via Supabase player_cards — remover o fallback por raridade
/// e passar a confiar só no [owned].
bool isCardUnlocked({
  required String id,
  required Rarity rarity,
  required Set<String> owned,
}) {
  if (owned.contains(id)) return true;
  return rarity == Rarity.comum;
}
