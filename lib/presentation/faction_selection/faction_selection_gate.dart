/// Lógica pura de gating da seleção de facção, extraída pra ser testável
/// sem montar o widget inteiro (que depende de factions.json, achievements
/// repo, buff service, etc).
///
/// Histórico: hotfix pós-validação 3.4 (BUG 2 gate lvl 7 + BUG 4 mensagem).
/// Ajuste pós-inspeção: Lobo Solitário também exige lvl 7 (ITEM 1) e o
/// subtítulo virou NEUTRO (ITEM 4 — não menciona mais "nível 7").
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

  /// ITEM 1 — o Caminho do Lobo Solitário também é uma escolha do "lvl 7":
  /// só liberado a partir do nível 7, igual às ideológicas.
  static bool canSelectLoneWolf(int level) => level >= ideologicalMinLevel;

  /// Subtítulo do header da tela. NEUTRO por padrão (ITEM 4): como o
  /// jogador pode escolher em QUALQUER nível ≥ 7, a frase não menciona
  /// mais "nível 7" (antes aparecia sempre pra quem chegava exatamente no
  /// 7, soando como anúncio repetido).
  static String headerSubtitle(int level) =>
      'Caelum exige que você escolha um lado.';
}
