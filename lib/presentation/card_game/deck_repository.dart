/// Repositório/providers do DECK do jogador (Construtor de Deck — ACDA).
///
/// Um deck = 9 criaturas + 9 relíquias (ids = `card.id` do catálogo). MVP: 1
/// deck ATIVO por jogador. Persistido em `player_decks` (Supabase, RLS própria):
///
///   player_decks(
///     id uuid pk default gen_random_uuid(),
///     player_id uuid,
///     name text,
///     creature_ids text[],
///     relic_ids text[],
///     is_active boolean,
///     updated_at bigint)
///
/// A RLS já filtra por `auth.uid()`, mas o `player_id` é gravado explícito no
/// INSERT (a tabela tem a coluna).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';

/// Modelo do deck do jogador. Imutável o suficiente pro fluxo (a tela edita
/// listas próprias e só constrói este modelo ao salvar).
class PlayerDeck {
  const PlayerDeck({
    this.id,
    required this.name,
    required this.creatureIds,
    required this.relicIds,
    this.isActive = true,
  });

  final String? id;
  final String name;
  final List<String> creatureIds;
  final List<String> relicIds;
  final bool isActive;

  /// Um deck válido tem exatamente 9 criaturas + 9 relíquias.
  bool get isValid => creatureIds.length == 9 && relicIds.length == 9;

  PlayerDeck copyWith({
    String? id,
    String? name,
    List<String>? creatureIds,
    List<String>? relicIds,
    bool? isActive,
  }) {
    return PlayerDeck(
      id: id ?? this.id,
      name: name ?? this.name,
      creatureIds: creatureIds ?? this.creatureIds,
      relicIds: relicIds ?? this.relicIds,
      isActive: isActive ?? this.isActive,
    );
  }

  factory PlayerDeck.fromRow(Map<String, dynamic> row) {
    List<String> ids(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList(growable: false);
      }
      return const <String>[];
    }

    return PlayerDeck(
      id: row['id'] as String?,
      name: (row['name'] as String?) ?? 'Meu Deck',
      creatureIds: ids(row['creature_ids']),
      relicIds: ids(row['relic_ids']),
      isActive: (row['is_active'] as bool?) ?? false,
    );
  }
}

/// Service de deck: lê/grava `player_decks` via PostgREST.
class DeckRepository {
  DeckRepository(this._client);

  final SupabaseClient _client;

  /// Lê o deck ATIVO do jogador. Sem player logado → null. A RLS filtra a
  /// linha pelo `auth.uid()`; o filtro `is_active` desempata caso o jogador
  /// tenha mais de um (MVP só mantém um ativo).
  Future<PlayerDeck?> fetchActive(String? playerId) async {
    if (playerId == null) return null;
    final row = await _client
        .from('player_decks')
        .select()
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return PlayerDeck.fromRow(row);
  }

  /// Salva (upsert) o deck ATIVO do jogador. Se já existe deck ativo, UPDATE
  /// no `id` existente; senão INSERT novo (is_active=true). `updated_at` =
  /// epoch ms.
  ///
  /// Devolve o deck salvo (com `id`). Sem player logado → lança (a UI trata).
  Future<PlayerDeck> saveActive({
    required String playerId,
    required PlayerDeck deck,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final existing = await fetchActive(playerId);

    final payload = <String, dynamic>{
      'player_id': playerId,
      'name': deck.name,
      'creature_ids': deck.creatureIds,
      'relic_ids': deck.relicIds,
      'is_active': true,
      'updated_at': nowMs,
    };

    Map<String, dynamic> savedRow;
    if (existing?.id != null) {
      final rows = await _client
          .from('player_decks')
          .update(payload)
          .eq('id', existing!.id!)
          .select()
          .limit(1);
      savedRow = (rows as List).cast<Map<String, dynamic>>().first;
    } else {
      final rows = await _client
          .from('player_decks')
          .insert(payload)
          .select()
          .limit(1);
      savedRow = (rows as List).cast<Map<String, dynamic>>().first;
    }

    return PlayerDeck.fromRow(savedRow);
  }
}

/// Service singleton.
final deckRepositoryProvider = Provider<DeckRepository>((ref) {
  return DeckRepository(ref.watch(supabaseClientProvider));
});

/// Deck ATIVO do jogador (ou null). Erros propagam pelo AsyncValue — a UI
/// trata `error`/`loading` sem crashar. Sem player logado → null.
final activeDeckProvider = FutureProvider<PlayerDeck?>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return null;
  final repo = ref.watch(deckRepositoryProvider);
  return repo.fetchActive(player.id);
});
