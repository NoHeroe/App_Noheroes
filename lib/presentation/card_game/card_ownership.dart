/// Posse de cartas do jogador (Fatia 2 — Coleção).
///
/// Posse REAL via Supabase `player_cards`. Expõe o conjunto de `card_id` que o
/// jogador autenticado possui. A regra de posse não tem mais atalho por
/// raridade — desbloqueado = id presente no set.
///
/// Tabela: `player_cards (player_id uuid, card_id text, acquired_at bigint,
/// source text, PK(player_id,card_id))`, RLS própria (auth.uid()).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../domain/card_game/card_catalog.dart';
import '../../domain/card_game/card_models.dart';

/// Service de posse: lê `player_cards` e concede o STARTER idempotente.
///
/// Sem dependência de UI; só fala PostgREST. A RLS já filtra por `auth.uid()`,
/// mas passamos o `playerId` explícito no insert (a tabela tem `player_id`).
class CardOwnershipService {
  CardOwnershipService(this._client);

  final SupabaseClient _client;

  /// Lê os `card_id` que o jogador possui. Sem player logado → set vazio.
  Future<Set<String>> fetchOwned(String? playerId) async {
    if (playerId == null) return <String>{};
    final rows = await _client.from('player_cards').select('card_id');
    final list = (rows as List).cast<Map<String, dynamic>>();
    return list
        .map((r) => r['card_id'] as String?)
        .whereType<String>()
        .toSet();
  }

  /// Concede o STARTER se (e só se) o jogador tem 0 cartas. Idempotente:
  /// só insere quando vazio, e usa upsert com `ignoreDuplicates` na PK
  /// (player_id, card_id) pra tolerar corrida/reentrância.
  ///
  /// Retorna o conjunto final de `card_id` que o jogador possui após a
  /// operação (o starter recém-concedido, ou a posse pré-existente).
  Future<Set<String>> ensureStarter(
    String? playerId,
    CardCatalog catalog,
  ) async {
    if (playerId == null) return <String>{};

    final owned = await fetchOwned(playerId);
    if (owned.isNotEmpty) return owned;

    final starterIds = computeStarterIds(catalog);
    if (starterIds.isEmpty) return owned;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final payload = starterIds
        .map((id) => <String, dynamic>{
              'player_id': playerId,
              'card_id': id,
              'acquired_at': nowMs,
              'source': 'starter',
            })
        .toList(growable: false);

    await _client
        .from('player_cards')
        .upsert(payload, onConflict: 'player_id,card_id', ignoreDuplicates: true);

    return starterIds;
  }
}

/// Regra do STARTER (client-side, tunável).
///
/// TODO(design): set inicial tunável.
///
/// (a) Todas as criaturas `comum` do conceito starter — o conceito com MAIS
///     criaturas comuns (preferindo um com >=9 comuns; se nenhum atinge 9,
///     escolhe o de maior contagem). Isso dá ~1 deck mono-conceito jogável.
/// (b) Todas as relíquias `comum` `neutro` (universais).
///
/// Pequeno e early-game: 1 conceito de criaturas + relíquias universais.
Set<String> computeStarterIds(CardCatalog catalog) {
  // (a) conta criaturas comuns por conceito (conceito primário = concepts.first).
  final commonCreatures =
      catalog.creatures.where((c) => c.rarity == Rarity.comum).toList();

  final byConcept = <CardConcept, List<CreatureCard>>{};
  for (final c in commonCreatures) {
    if (c.concepts.isEmpty) continue;
    final key = c.concepts.first;
    if (key == CardConcept.neutro) continue; // por design não há criatura neutra
    (byConcept[key] ??= <CreatureCard>[]).add(c);
  }

  CardConcept? starterConcept;
  var bestCount = -1;
  // Itera em ordem estável (ordem do enum) pra desempate determinístico.
  for (final concept in CardConcept.values) {
    final count = byConcept[concept]?.length ?? 0;
    if (count > bestCount) {
      bestCount = count;
      starterConcept = (count > 0) ? concept : starterConcept;
    }
  }

  final ids = <String>{};
  if (starterConcept != null) {
    for (final c in byConcept[starterConcept] ?? const <CreatureCard>[]) {
      ids.add(c.id);
    }
  }

  // (b) relíquias comuns universais (neutro).
  for (final r in catalog.relics) {
    if (r.rarity == Rarity.comum && r.isUniversal) {
      ids.add(r.id);
    }
  }

  return ids;
}

/// Service singleton.
final cardOwnershipServiceProvider = Provider<CardOwnershipService>((ref) {
  return CardOwnershipService(ref.watch(supabaseClientProvider));
});

/// Posse REAL do jogador (set de `card_id` desbloqueados).
///
/// Garante o starter (idempotente) e devolve a posse final. Sem player logado
/// → set vazio (UI mostra tudo bloqueado). Erros propagam pelo AsyncValue —
/// a UI trata `error`/`loading` sem crashar.
final cardOwnershipProvider = FutureProvider<Set<String>>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return <String>{};

  final service = ref.watch(cardOwnershipServiceProvider);
  final catalog = await CardCatalog.load();
  return service.ensureStarter(player.id, catalog);
});

/// Regra de posse: desbloqueado = id presente no set de posse real.
///
/// Sem atalho por raridade (a posse vem 100% do `player_cards`).
bool isCardUnlocked({
  required String id,
  required Set<String> owned,
}) {
  return owned.contains(id);
}
