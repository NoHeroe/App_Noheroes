class XpCalculator {
  // XP necessário para ir do nível atual para o próximo
  static int xpToNextLevel(int level) {
    if (level <= 25) return 100 + (level - 1) * 50;
    if (level <= 50) return 1350 + (level - 26) * 75;
    if (level <= 75) return 3225 + (level - 51) * 100;
    return 5725 + (level - 76) * 200;
  }

  // HP máximo baseado em constituição e nível
  static int calcMaxHp(int constitution, int level) {
    return 80 + (constitution * 10) + (level * 5);
  }

  // MP máximo baseado em espírito e constituição
  static int calcMaxMp(int spirit, int constitution, int level) {
    return ((calcMaxHp(constitution, level) * 0.9) + (spirit * 5)).round();
  }

  // Calcula estado da sombra baseado no impacto acumulado
  static String calcShadowState(int corruption) {
    if (corruption <= 0) return 'ascending';
    if (corruption <= 20) return 'stable';
    if (corruption <= 40) return 'unstable';
    if (corruption <= 70) return 'chaotic';
    return 'abyssal';
  }

  // Streak: verifica se o jogador logou ontem
  static bool isStreakValid(DateTime? lastStreakDate) {
    if (lastStreakDate == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return lastStreakDate.year == yesterday.year &&
        lastStreakDate.month == yesterday.month &&
        lastStreakDate.day == yesterday.day;
  }
}
