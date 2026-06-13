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

/// As 45 habilidades com runtime no engine (12 originais + 5 do Lote 2 + 4 do
/// Lote 3a + 4 do Lote 3b + 6 do Lote 5 + Reflexo Mágico + 6 do Lote 6 +
/// 6 do Lote 7 + Esquiva dos heróis).
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

  /// Ao ser atingida por MÁGICO, 🎚️ `kReflexoMagicoChance` de IGNORAR o dano e
  /// devolvê-lo ao atacante. Suprimido pela Doença na criatura que o possui.
  reflexoMagico,

  /// Se fosse ser destruída, NÃO é: ressuscita com vida cheia. 1×/partida.
  inabalavel,

  // ── Lote 3a (status / DoT) ────────────────────────────────────────────────

  /// Ao ACERTAR dano físico, aplica/renova Sangramento no alvo: +1 acúmulo e a
  /// duração reseta para 🎚️ `kSangramentoTurns`. No início do turno do DONO da
  /// carta sangrando (ao clicar "encerrar turno"), ela sofre dano verdadeiro =
  /// acúmulos × 🎚️ `kSangramentoPerStack`; depois −1 turno (decai sozinho).
  /// Curar a carta remove o efeito.
  sangramento,

  /// Ao ACERTAR, aplica Veneno no alvo: dano verdadeiro de 🎚️ `kVenenoPerTurn`
  /// por turno do dono (mesmo tick do Sangramento), SEM duração-limite (persiste
  /// até morrer ou ser CURADA). Não escala com acúmulos.
  veneno,

  /// Ao ACERTAR corpo a corpo (100%), atordoa o alvo: ele pula a PRÓXIMA Fase de
  /// Ataque dele. A habilidade tem cooldown de 🎚️ `kAtordoarCooldownTurns` turno
  /// (não atordoa em turnos seguidos).
  atordoar,

  /// Ao ACERTAR um alvo com Voo (🎚️ `kEnredarChance`), enreda: remove o Voo e
  /// prende — o alvo pula a próxima Fase de Ataque dele. Só afeta alvos voadores.
  enredar,

  // ── Lote 3b (auras de redução + combo Doença/Surto) ──────────────────────

  /// Aura: no início do turno do dono, reduz o ataque MELEE de todos os inimigos
  /// em 🎚️ `kDesmoralizarReduction` (só o maior aplica). Dura a rodada do
  /// inimigo (até ele atacar). Suprimida pela Doença na criatura que a possui.
  desmoralizar,

  /// Aura: no início do turno do dono, reduz o ataque MÁGICO de todos os
  /// inimigos em 🎚️ `kSuprimirReduction` (só o maior aplica). Dura a rodada do
  /// inimigo (até ele atacar).
  suprimirMagia,

  /// Ao causar dano físico/verdadeiro, aplica 1 acúmulo de Doença no alvo.
  /// Enquanto doente, o alvo perde Inspirar e Desmoralizar (suprimidas).
  /// Removível por cura.
  doenca,

  /// Ao causar dano físico/verdadeiro a um alvo DOENTE: remove a Doença e reduz
  /// o PV MÁXIMO do alvo (permanente) em acúmulos × 🎚️ `kSurtoMaxHpPerStack`.
  surto,

  // ── Lote 5 (exóticas) ─────────────────────────────────────────────────────

  /// Ao DESTRUIR uma criatura inimiga, ganha 🎚️ `kAndorinhaGain` PERMANENTE em
  /// TODOS os ataques e no PV máximo.
  andorinha,

  /// Após ser CURADA, ganha 🎚️ `kCrescimentoGain` PERMANENTE em todos os ataques
  /// e no PV máximo.
  crescimento,

  /// Ao ENTRAR em jogo, copia stats (atk/PV/tipo) e keywords de um alvo marcado
  /// (aliado ou inimigo). Cópia única na entrada.
  mimico,

  /// Ao morrer, em vez de ir pro cemitério, VOLTA PRA MÃO enfraquecida
  /// (−🎚️ `kZumbiAtkPenalty` atk / −🎚️ `kZumbiHpPenalty` PV) e sem Zumbi (1×).
  zumbi,

  /// Auto-revive: se fosse destruída, volta com PV REDUZIDO
  /// (🎚️ `kRessurreicaoPercent` do máximo). 1×/partida. (Inabalável = vida cheia.)
  ressurreicao,

  /// Ao cair a 🎚️ `kTransformarTrigger` do PV máximo, ativa a 2ª forma: cura ao
  /// novo máximo e ganha 🎚️ `kTransformarAtkBonus`/`kTransformarHpBonus`. 1×.
  transformar,

  // ── Lote 6 (imunidades + utilidades) ──────────────────────────────────────

  /// Imune a Desmoralizar, Suprimir Magia e Silêncio (e a Flash inimigo).
  imunidade,

  /// Imune a Doença, Enredar, Silêncio, Desmoralizar e Suprimir Magia.
  perseveranca,

  /// Imune a Contra-Ataque, Espinhos e Enredar.
  vigilante,

  /// Ataque corpo a corpo atual +(PV máximo − PV atual) — quanto mais ferida,
  /// mais forte o golpe melee.
  furia,

  /// Se já tem armadura (relíquia/Escudo), ganha +🎚️ `kEncantarArmaduraBonus`.
  encantarArmadura,

  /// Ao ser sacrificada, gera +🎚️ `kCristalAdicionalCrystals` cristal extra.
  cristalAdicional,

  // ── Lote 7 (mais defensivas/ofensivas) ────────────────────────────────────

  /// Ao SOFRER dano (qualquer tipo, dano > 0), causa 🎚️ `kEspinhoDeEscudoDamage`
  /// de dano verdadeiro à fonte — salvo se a fonte também tiver Espinho de Escudo.
  espinhoDeEscudo,

  /// Ao sofrer dano, entra em Névoa; o PRÓXIMO dano é prevenido e o estado some.
  nevoa,

  /// Os ataques corpo a corpo/à distância desta criatura ignoram o Voo do alvo,
  /// e causam +🎚️ `kAntiAereoBonus` de dano a quem voa.
  antiAereo,

  /// Alvos COM armadura sofrem +🎚️ `kQuebraArmaduraBonus` de dano físico desta
  /// criatura.
  quebraArmadura,

  /// Dano MÁGICO excedente transborda para a próxima criatura inimiga (espelho
  /// mágico de Pisotear).
  explosaoMagica,

  /// No início do turno do dono, aplica 🎚️ `kNevoaToxicaStacks` acúmulo(s) de
  /// Doença a TODOS os inimigos.
  nevoaToxica,

  // ── Heróis (ADR-0028) ─────────────────────────────────────────────────────

  /// Evasão AMPLA: evade QUALQUER tipo de ataque com 🎚️ `kEsquivaChance` (≠ Voo,
  /// que é por tipo). Não evita DoTs já ativos (Sangramento/Veneno/Doença). O
  /// Assassino concede uma Esquiva temporária de 100% (ver herói).
  esquiva,

  // ── Skills novas (docx do CEO, 2026-06-12) ───────────────────────────────

  /// Volta uma criatura aliada da retaguarda pra mão (reposicionamento). Nas
  /// relíquias (ARCA, Pedra do Regresso) = utilitário de escape; sem runtime
  /// próprio no MVP além de sinalizar a intenção (recuo manual já existe).
  recuo,

  /// Revela criaturas Furtivas e pode mirá-las: ataques desta criatura ignoram
  /// a Furtividade do alvo (foca alvos furtivos).
  percepcao,

  /// Ao acertar um ataque, EXECUTA (destrói) o alvo se o PV atual dele ficar
  /// ≤ 🎚️ `kExecutorThreshold`. Ataques mágicos/verdadeiros também executam.
  executor,
}

/// Magnitude opcional de uma keyword com parâmetro (ex.: "espinhos_3" → 3,
/// "escudo_4" → 4, "roubo_de_pv_2" → 2). Null quando não há número.
int? abilityMagnitude(String raw) {
  final m = RegExp(r'(\d+)$').firstMatch(_fold(raw));
  return m == null ? null : int.parse(m.group(1)!);
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
    case AbilityKeyword.reflexoMagico:
      return 'Reflexo Mágico';
    case AbilityKeyword.inabalavel:
      return 'Inabalável';
    case AbilityKeyword.sangramento:
      return 'Sangramento';
    case AbilityKeyword.veneno:
      return 'Veneno';
    case AbilityKeyword.atordoar:
      return 'Atordoar';
    case AbilityKeyword.enredar:
      return 'Enredar';
    case AbilityKeyword.desmoralizar:
      return 'Desmoralizar';
    case AbilityKeyword.suprimirMagia:
      return 'Suprimir Magia';
    case AbilityKeyword.doenca:
      return 'Doença';
    case AbilityKeyword.surto:
      return 'Surto';
    case AbilityKeyword.andorinha:
      return 'Andorinha';
    case AbilityKeyword.crescimento:
      return 'Crescimento';
    case AbilityKeyword.mimico:
      return 'Mímico';
    case AbilityKeyword.zumbi:
      return 'Carta Zumbi';
    case AbilityKeyword.ressurreicao:
      return 'Ressurreição';
    case AbilityKeyword.transformar:
      return 'Transformar';
    case AbilityKeyword.imunidade:
      return 'Imunidade';
    case AbilityKeyword.perseveranca:
      return 'Perseverança';
    case AbilityKeyword.vigilante:
      return 'Vigilante';
    case AbilityKeyword.furia:
      return 'Fúria';
    case AbilityKeyword.encantarArmadura:
      return 'Encantar Armadura';
    case AbilityKeyword.cristalAdicional:
      return 'Cristal Adicional';
    case AbilityKeyword.espinhoDeEscudo:
      return 'Espinho de Escudo';
    case AbilityKeyword.nevoa:
      return 'Névoa';
    case AbilityKeyword.antiAereo:
      return 'Anti-Aéreo';
    case AbilityKeyword.quebraArmadura:
      return 'Quebra de Armadura';
    case AbilityKeyword.explosaoMagica:
      return 'Explosão Mágica';
    case AbilityKeyword.nevoaToxica:
      return 'Névoa Tóxica';
    case AbilityKeyword.esquiva:
      return 'Esquiva';
    case AbilityKeyword.recuo:
      return 'Recuo';
    case AbilityKeyword.percepcao:
      return 'Percepção';
    case AbilityKeyword.executor:
      return 'Executor';
  }
}

/// Canoniza uma string de habilidade vinda dos dados. Aceita variantes com e
/// sem espaço/acento/caixa ("AtaqueDuplo", "Silencio", "roubo de pv"...).
/// Retorna null se não for uma keyword com runtime.
AbilityKeyword? abilityKeywordFromString(String raw) {
  final folded = _fold(raw);
  final direct = _canonical[folded];
  if (direct != null) return direct;
  // Tira a magnitude no fim ("espinhos2" → "espinhos") e tenta de novo.
  final base = folded.replaceFirst(RegExp(r'\d+$'), '');
  return _canonical[base];
}

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
  'reflexomagico': AbilityKeyword.reflexoMagico,
  'reflexaomagica': AbilityKeyword.reflexoMagico,
  'inabalavel': AbilityKeyword.inabalavel,
  'sangramento': AbilityKeyword.sangramento,
  'veneno': AbilityKeyword.veneno,
  'atordoar': AbilityKeyword.atordoar,
  'enredar': AbilityKeyword.enredar,
  'desmoralizar': AbilityKeyword.desmoralizar,
  'suprimirmagia': AbilityKeyword.suprimirMagia,
  'doenca': AbilityKeyword.doenca,
  'surto': AbilityKeyword.surto,
  'andorinha': AbilityKeyword.andorinha,
  'crescimento': AbilityKeyword.crescimento,
  'mimico': AbilityKeyword.mimico,
  'cartazumbi': AbilityKeyword.zumbi,
  'zumbi': AbilityKeyword.zumbi,
  'ressurreicao': AbilityKeyword.ressurreicao,
  'transformar': AbilityKeyword.transformar,
  'imunidade': AbilityKeyword.imunidade,
  'perseveranca': AbilityKeyword.perseveranca,
  'vigilante': AbilityKeyword.vigilante,
  'furia': AbilityKeyword.furia,
  'encantararmadura': AbilityKeyword.encantarArmadura,
  'cristaladicional': AbilityKeyword.cristalAdicional,
  'espinhodeescudo': AbilityKeyword.espinhoDeEscudo,
  'nevoa': AbilityKeyword.nevoa,
  'antiaereo': AbilityKeyword.antiAereo,
  'quebradearmadura': AbilityKeyword.quebraArmadura,
  'quebraarmadura': AbilityKeyword.quebraArmadura,
  'explosaomagica': AbilityKeyword.explosaoMagica,
  'nevoatoxica': AbilityKeyword.nevoaToxica,
  'esquiva': AbilityKeyword.esquiva,
  // Skills novas (docx 2026-06-12).
  'recuo': AbilityKeyword.recuo,
  'recuar': AbilityKeyword.recuo,
  'percepcao': AbilityKeyword.percepcao,
  'executor': AbilityKeyword.executor,
  // Aliases de grafia que aparecem nos dados crus.
  'defesa': AbilityKeyword.escudo,
  'vampirismo': AbilityKeyword.rouboDePv,
  'reversaodefeitico': AbilityKeyword.reflexoMagico,
  'quebraescudo': AbilityKeyword.quebraArmadura,
  'duploataque': AbilityKeyword.ataqueDuplo,
  'espinho': AbilityKeyword.espinhos,
};
