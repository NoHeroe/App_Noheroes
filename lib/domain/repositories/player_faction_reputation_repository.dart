/// Sprint 3.1 Bloco 4 — Repository de reputação do jogador com facções
/// (`player_faction_reputation`). Reputação é int em 0..100, default
/// neutro 50, clamp aplicado na camada de repositório.
abstract class PlayerFactionReputationRepository {
  /// Retorna reputação atual. Se não existe linha pra o par
  /// (player, faction), cria lazy com default 50 e retorna 50.
  Future<int> getOrDefault(int playerId, String factionId);

  /// Todas as reputações do jogador — `Map<factionId, reputation>`.
  /// Facções sem linha registrada **não** aparecem (caller decide
  /// default por UI).
  Future<Map<String, int>> findAllByPlayer(int playerId);

  /// Seta reputação absoluta em [reputation]. Valor é clampeado em
  /// 0..100 antes de persistir. Upsert — cria linha se não existe.
  Future<void> setAbsolute(
    int playerId,
    String factionId,
    int reputation,
  );

  /// Aplica delta (positivo ou negativo) sobre o valor atual, clampeando
  /// o resultado em 0..100. Upsert — se não existe, usa default 50
  /// como base antes de aplicar.
  Future<void> delta(int playerId, String factionId, int delta);
}
