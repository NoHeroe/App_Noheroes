/// Hotfix pós-validação Sprint 3.4 (BUG 2 + BUG 4).
///
/// Lógica pura de gating da seleção de facção, extraída pra ser
/// testável sem montar o widget inteiro (que depende de factions.json,
/// achievements repo, buff service, etc).
class FactionSelectionGate {
  /// Nível mínimo pra entrar em facção ideológica. Espelha o unlock
  /// exibido no Santuário (`if (level == 7) '🏴 Facções disponíveis'`).
  static const int ideologicalMinLevel = 7;

  /// `true` se o jogador pode jurar lealdade à facção [factionId].
  ///
  /// Facções ideológicas exigem nível 7. A Facção Guilda nível 2
  /// (`id='guild'`) NÃO usa este gate: já é restrita a Aventureiros
  /// (`guild_rank != 'none'`), modelo desbloqueado no nível 6 e filtrado
  /// em `_loadFactions`.
  static bool canSelect({required String factionId, required int level}) {
    if (factionId == 'guild') return true;
    return level >= ideologicalMinLevel;
  }

  /// Subtítulo do header da tela. Remove o anúncio "Você atingiu o nível
  /// 7" quando o jogador já passou desse nível (BUG 4 — a frase ficava
  /// redundante pra quem já estava bem além do 7).
  static String headerSubtitle(int level) {
    if (level > ideologicalMinLevel) {
      return 'Caelum exige que você escolha um lado.';
    }
    return 'Você atingiu o nível 7.\nCaelum exige que você escolha um lado.';
  }
}
