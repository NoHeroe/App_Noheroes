/// Habilidades runtime (keywords) do Card Game "Modo Cartas ACDA".
///
/// Keywords com runtime no engine. (As 12 originais batiam os dados reais; o Lote 2
/// adicionou 5 defensivas — atribuição às cartas é a passada de balanceamento.)
/// Os dados trazem variantes de grafia ("Ataque Duplo" vs "AtaqueDuplo",
/// "Silêncio" vs "Silencio") — o engine canoniza tudo via
/// [abilityKeywordFromString] para o enum interno [AbilityKeyword].
///
/// Keywords do catálogo que NÃO estão nos dados reais (ex.: "Golpe (Charge)",
/// "Tiro Corpo a Corpo") não têm runtime no MVP: o normalizador retorna null
/// e o engine as ignora silenciosamente.
library;

/// As 17 habilidades com runtime no engine (12 originais + 5 do Lote 2).
enum AbilityKeyword {
  /// Redireciona ataques à distância/mágicos inimigos para esta criatura.
  provocar,

  /// Armadura inata (🎚️ `kEscudoArmor`), soma com armadura de relíquia.
  escudo,

  /// Evasão: 50% vs corpo a corpo, 25% vs à distância (vs atacante sem Voo).
  voo,

  /// Melee da frente que acerta causa dano verdadeiro extra a um inimigo
  /// aleatório da retaguarda.
  ataqueDuplo,

  /// Permite atacar corpo a corpo da retaguarda.
  alcance,

  /// No início do turno do dono: aliados (não ele) ganham ataque melee
  /// temporário (🎚️ `kInspirarBonus`; só o maior — bônus fixo = aplica 1×).
  inspirar,

  /// Dano físico excedente transborda para a próxima criatura inimiga.
  pisotear,

  /// Aura: enquanto viva, criaturas INIMIGAS não usam mágico nem cura.
  silencio,

  /// Na retaguarda, não pode ser alvo de ataques à distância/mágicos.
  furtividade,

  /// Ao destruir uma criatura inimiga com seu ataque, o dono ganha +1 cristal
  /// (creditado no início do PRÓXIMO turno do dono — `pendingCrystals`).
  cristalDeDrenagem,

  /// Ao acertar um ataque (dano > 0): PV atual e máximo do atacante
  /// +🎚️ `kRouboDePvAmount`.
  rouboDePv,

  /// No início do turno do dono: ataque melee +🎚️ `kInvestidaBonus` até o fim
  /// do turno do OPONENTE (dura a rodada inteira).
  investida,

  // ── Lote 2 (defensivas) ──────────────────────────────────────────────────

  /// Ao ser atingida por melee, causa 🎚️ `kEspinhosDamage` de dano verdadeiro
  /// ao atacante. (Simplificação: o "danifica a armadura primeiro" do rascunho
  /// não se aplica — armadura aqui é redução fixa por golpe, não pool.)
  espinhos,

  /// Reduz dano MÁGICO recebido em 🎚️ `kEscudoEspelhadoArmor` (armadura mágica).
  escudoEspelhado,

  /// Reduz dano FÍSICO e MÁGICO recebido em 🎚️ `kEscudoSagradoArmor`.
  escudoSagrado,

  /// Ao ser atingida por melee, 🎚️ `kContraAtaqueChance` de contra-atacar com
  /// um ataque melee (= ataque melee da defensora) no atacante.
  contraAtaque,

  /// Se fosse ser destruída, NÃO é: ressuscita com vida cheia. 1×/partida.
  inabalavel,
}

/// Nome canônico (forma "bonita" com espaço/acento) — usado em eventos
/// narráveis (`AbilityTriggered.ability`).
String abilityKeywordLabel(AbilityKeyword k) {
  switch (k) {
    case AbilityKeyword.provocar:
      return 'Provocar';
    case AbilityKeyword.escudo:
      return 'Escudo';
    case AbilityKeyword.voo:
      return 'Voo';
    case AbilityKeyword.ataqueDuplo:
      return 'Ataque Duplo';
    case AbilityKeyword.alcance:
      return 'Alcance';
    case AbilityKeyword.inspirar:
      return 'Inspirar';
    case AbilityKeyword.pisotear:
      return 'Pisotear';
    case AbilityKeyword.silencio:
      return 'Silêncio';
    case AbilityKeyword.furtividade:
      return 'Furtividade';
    case AbilityKeyword.cristalDeDrenagem:
      return 'Cristal de Drenagem';
    case AbilityKeyword.rouboDePv:
      return 'Roubo de PV';
    case AbilityKeyword.investida:
      return 'Investida';
    case AbilityKeyword.espinhos:
      return 'Espinhos';
    case AbilityKeyword.escudoEspelhado:
      return 'Escudo Espelhado';
    case AbilityKeyword.escudoSagrado:
      return 'Escudo Sagrado';
    case AbilityKeyword.contraAtaque:
      return 'Contra-Ataque';
    case AbilityKeyword.inabalavel:
      return 'Inabalável';
  }
}

/// Canoniza uma string de habilidade vinda dos dados. Aceita variantes com e
/// sem espaço/acento/caixa ("AtaqueDuplo", "Silencio", "roubo de pv"...).
/// Retorna null se não for uma keyword com runtime.
AbilityKeyword? abilityKeywordFromString(String raw) =>
    _canonical[_fold(raw)];

/// Normaliza: minúsculas, remove acentos e tudo que não for [a-z0-9].
String _fold(String s) {
  final lower = s.toLowerCase();
  final sb = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final mapped = _accentMap[ch] ?? ch;
    for (final c in mapped.codeUnits) {
      if ((c >= 0x61 && c <= 0x7a) || (c >= 0x30 && c <= 0x39)) {
        sb.writeCharCode(c);
      }
    }
  }
  return sb.toString();
}

const Map<String, String> _accentMap = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

const Map<String, AbilityKeyword> _canonical = {
  'provocar': AbilityKeyword.provocar,
  'escudo': AbilityKeyword.escudo,
  'voo': AbilityKeyword.voo,
  'ataqueduplo': AbilityKeyword.ataqueDuplo,
  'alcance': AbilityKeyword.alcance,
  'inspirar': AbilityKeyword.inspirar,
  'pisotear': AbilityKeyword.pisotear,
  'silencio': AbilityKeyword.silencio,
  'furtividade': AbilityKeyword.furtividade,
  'cristaldedrenagem': AbilityKeyword.cristalDeDrenagem,
  'roubodepv': AbilityKeyword.rouboDePv,
  'investida': AbilityKeyword.investida,
  'espinhos': AbilityKeyword.espinhos,
  'escudoespelhado': AbilityKeyword.escudoEspelhado,
  'escudosagrado': AbilityKeyword.escudoSagrado,
  'contraataque': AbilityKeyword.contraAtaque,
  'inabalavel': AbilityKeyword.inabalavel,
};
