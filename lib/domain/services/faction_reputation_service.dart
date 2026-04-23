import '../../core/config/faction_alliances.dart';
import '../../core/events/app_event_bus.dart';
import '../../core/events/faction_events.dart';
import '../repositories/player_faction_reputation_repository.dart';

/// Sprint 3.1 Bloco 13b — CRUD + propagação via alianças.
///
/// Reputação 0-100 por `(playerId, factionId)`. Default 50 (neutro).
/// `adjustReputation(playerId, factionId, delta)`:
///
///   1. Lê reputação atual da facção alvo
///   2. Aplica delta (clamp 0-100 via repo.delta)
///   3. Emite `FactionReputationChanged` pra facção alvo
///   4. Itera `kFactionAlliances[factionId]` — pra cada (aliada/rival,
///      multiplier): aplica `delta × multiplier` na aliada + emit evento
///
/// Matrix vazia (neutra) → passo 4 é noop. Código pronto; dados placeholder.
///
/// Multiplier pode ser negativo (rival) — `repo.delta` aceita delta
/// negativo e faz clamp 0 na base.
class FactionReputationService {
  final PlayerFactionReputationRepository _repo;
  final AppEventBus _bus;

  FactionReputationService({
    required PlayerFactionReputationRepository repo,
    required AppEventBus bus,
  })  : _repo = repo,
        _bus = bus;

  /// Reputação atual (cria lazy default 50 se não existe).
  Future<int> current(int playerId, String factionId) =>
      _repo.getOrDefault(playerId, factionId);

  /// Todas as reputações do jogador.
  Future<Map<String, int>> all(int playerId) =>
      _repo.findAllByPlayer(playerId);

  /// Aplica [delta] em [factionId] + propaga via matrix.
  ///
  /// Delta positivo = subiu reputação. Matrix aliada aplica sinal
  /// preservado; matrix rival aplica sinal invertido via multiplier
  /// negativo.
  ///
  /// Emite `FactionReputationChanged` pra cada facção afetada.
  Future<void> adjustReputation({
    required int playerId,
    required String factionId,
    required int delta,
  }) async {
    if (delta == 0) return;

    // 1. Aplica delta principal.
    await _adjustSingle(
      playerId: playerId,
      factionId: factionId,
      delta: delta,
    );

    // 2. Propaga via matrix de alianças (neutra = noop).
    final allies = kFactionAlliances[factionId] ?? const <String, double>{};
    for (final entry in allies.entries) {
      final ally = entry.key;
      final mult = entry.value;
      final propagated = (delta * mult).round();
      if (propagated == 0) continue;
      await _adjustSingle(
        playerId: playerId,
        factionId: ally,
        delta: propagated,
      );
    }
  }

  Future<void> _adjustSingle({
    required int playerId,
    required String factionId,
    required int delta,
  }) async {
    final before = await _repo.getOrDefault(playerId, factionId);
    await _repo.delta(playerId, factionId, delta);
    final after = await _repo.getOrDefault(playerId, factionId);
    // Só emite se houve mudança real (clamp 0-100 pode engolir delta).
    if (after != before) {
      _bus.publish(FactionReputationChanged(
        playerId: playerId,
        factionId: factionId,
        newValue: after,
        previousValue: before,
      ));
    }
  }
}
