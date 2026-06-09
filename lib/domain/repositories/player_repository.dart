import '../entities/player.dart';

/// Repositório do jogador (Época 2, full-online — ADR-0024).
///
/// Abstrai o acesso à tabela `players` no Supabase. A identidade é o uuid do
/// Supabase Auth (`players.id = auth.users.id`). Substitui o acesso Drift do
/// antigo `PlayerDao` na camada de leitura/escrita simples; operações
/// atômicas (add_xp, add_gold, distribute_point, etc.) são RPCs server-side.
abstract class PlayerRepository {
  /// Carrega o jogador por uuid. Null se não existir.
  Future<Player?> fetchById(String id);

  /// Carrega o jogador da sessão Auth atual (`auth.uid()`). Null se deslogado.
  Future<Player?> fetchCurrent();

  /// Update parcial de colunas (snake_case). A RLS garante que só o próprio
  /// jogador escreve (`auth.uid() = id`).
  Future<void> updateFields(String id, Map<String, dynamic> patch);

  /// Conclui o onboarding (nome da Sombra + modo narrativo).
  Future<void> completeOnboarding(
      String id, String shadowName, String narrativeMode);
}
