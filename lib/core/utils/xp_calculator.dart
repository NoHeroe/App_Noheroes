class XpCalculator {
  static int xpToNextLevel(int level) {
    // Soulslike: progressão mais lenta e pesada
    if (level <= 25) return 200 + (level - 1) * 80;
    if (level <= 50) return 2200 + (level - 26) * 120;
    if (level <= 75) return 5200 + (level - 51) * 180;
    return 9700 + (level - 76) * 350;
  }

  static int calcMaxHp(int constitution, int level) {
    return 80 + (constitution * 10) + (level * 5);
  }

  static int calcMaxMp(int spirit, int constitution, int level) {
    return ((calcMaxHp(constitution, level) * 0.9) + (spirit * 5)).round();
  }

  // CORRIGIDO: Ascendente só após superar Caótico/Abissal
  // O estado 'ascending' é setado manualmente após Shadow Boss
  // Aqui apenas mapeamos corrupção → estado normal
  static String calcShadowState(int corruption) {
    if (corruption <= 15) return 'stable';
    if (corruption <= 35) return 'unstable';
    if (corruption <= 65) return 'chaotic';
    return 'abyssal';
  }

  // Chamado após vencer Shadow Boss — concede estado ascendente temporário
  static String calcShadowStateAfterBossVictory() => 'ascending';

  static bool isStreakValid(DateTime? lastStreakDate) {
    if (lastStreakDate == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return lastStreakDate.year == yesterday.year &&
        lastStreakDate.month == yesterday.month &&
        lastStreakDate.day == yesterday.day;
  }

  // Calcula estatísticas derivadas baseado nos atributos base
  static Map<String, int> calcDerivedStats({
    required int strength,
    required int dexterity,
    required int intelligence,
    required int constitution,
    required int spirit,
    required int charisma,
    required int level,
    String? classType,
    String? factionType,
  }) {
    final maxHp = calcMaxHp(constitution, level);
    final maxMp = calcMaxMp(spirit, constitution, level);

    // Dano físico: Força * 2.5 + nível
    final physicalDmg = (strength * 2.5 + level).round();

    // Dano mágico: Inteligência * 2.5 + Espírito * 0.5
    final magicDmg = (intelligence * 2.5 + spirit * 0.5).round();

    // Dano vitalista: só para classes aptas, Força * 1.9
    final vitalistDmg = _hasVitalism(classType)
        ? (strength * 1.9).round()
        : 0;

    // Crítico físico: Destreza * 1.5 (%)
    final physCrit = (dexterity * 1.5).round();

    // Crítico mágico: Inteligência * 1.2 (%)
    final magicCrit = (intelligence * 1.2).round();

    // Defesa física: Constituição * 3
    final physDef = constitution * 3;

    // Defesa mágica: Espírito * 2 + Inteligência
    final magicDef = spirit * 2 + intelligence;

    // Agilidade/Evasão: Destreza * 2
    final evasion = dexterity * 2;

    // Precisão: Destreza * 1.8 + nível * 0.5
    final accuracy = (dexterity * 1.8 + level * 0.5).round();

    // Bônus XP: Carisma * 0.5 (%)
    final xpBonus = (charisma * 0.5).round();

    // Bônus ouro: Carisma * 0.3 (%)
    final goldBonus = (charisma * 0.3).round();

    // Regeneração passiva: Constituição * 0.5 + Espírito * 0.3
    final regen = (constitution * 0.5 + spirit * 0.3).round();

    // Resistência sombria: Espírito * 2.5
    final shadowRes = (spirit * 2.5).round();

    return {
      'hp':          maxHp,
      'mp':          maxMp,
      'physDmg':     physicalDmg,
      'magicDmg':    magicDmg,
      'vitalistDmg': vitalistDmg,
      'physCrit':    physCrit,
      'magicCrit':   magicCrit,
      'physDef':     physDef,
      'magicDef':    magicDef,
      'evasion':     evasion,
      'accuracy':    accuracy,
      'xpBonus':     xpBonus,
      'goldBonus':   goldBonus,
      'regen':       regen,
      'shadowRes':   shadowRes,
    };
  }

  static bool _hasVitalism(String? classType) {
    return ['warrior', 'colossus', 'rogue', 'hunter', 'shadowWeaver']
        .contains(classType);
  }
}
