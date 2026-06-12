/// Estado imutável da partida do Card Game "Modo Cartas ACDA".
///
/// Toda mutação é feita via `copyWith` retornando uma nova instância.
/// O `Random` (rng) é mantido por referência (objeto mutável de dart:math),
/// pois é a fonte determinística de aleatoriedade injetada por seed.
library;

import 'dart:math';

import 'abilities.dart';
import 'card_models.dart';
import 'engine_config.dart';
import 'hero.dart';
import 'match_events.dart';

/// Fase atual da partida.
enum MatchPhase { jogo, ataque, fim }

/// Identifica um dos dois lados.
enum SideId { a, b }

/// Uma criatura em jogo: a carta + estado dinâmico (hp, relíquias, lane,
/// buffs temporários de habilidades).
///
/// Buffs temporários (design dos campos):
/// - `inspirarBonus`: aplicado no início do turno do dono (`_beginTurn`),
///   expira no FIM do turno do dono (limpo pelo `endTurn` do dono, após a
///   Fase de Ataque).
/// - `investidaBonus`: aplicado no início do turno do dono, expira no fim do
///   turno do OPONENTE (limpo pelo `endTurn` do oponente) — dura a rodada.
/// Ambos só contam para ataque corpo a corpo (`effectiveAtk`). A expiração é
/// feita por varredura explícita no engine — sem vazamento entre turnos.
/// - `bonusMaxHp`: PERMANENTE (Roubo de PV soma PV atual e máximo).
/// Um ataque de uma criatura na Fase de Ataque: tipo de dano + valor.
/// Multi-ataque (SPEC do CEO 2026-06-11): uma criatura pode ter VÁRIOS ataques
/// (1 por tipo). Bônus de relíquia de outro tipo vira um ataque novo (não soma
/// no tipo base). A fase resolve cada ataque separado, com mira/posição própria.
class CardAttack {
  final DamageType type;
  final int value;
  const CardAttack(this.type, this.value);

  @override
  String toString() => 'CardAttack($type, $value)';
}

class CreatureInPlay {
  const CreatureInPlay({
    required this.card,
    required this.currentHp,
    required this.lane,
    this.relics = const <RelicCard>[],
    this.bonusMaxHp = 0,
    this.inspirarBonus = 0,
    this.investidaBonus = 0,
    this.inabalavelUsed = false,
    this.bleedStacks = 0,
    this.bleedTurns = 0,
    this.poisoned = false,
    this.stunned = false,
    this.entangled = false,
    this.atordoarCooldown = 0,
    this.desmoralizadoMelee = 0,
    this.suprimidoMagico = 0,
    this.diseaseStacks = 0,
    this.permanentAtkBonus = 0,
    this.ressureicaoUsed = false,
    this.transformed = false,
    this.nevoaArmed = false,
  });

  final CreatureCard card;
  final int currentHp;

  /// Lane ocupada (0 = frente).
  final int lane;

  /// Relíquias equipadas (flash NÃO entra aqui — é consumida ao equipar).
  final List<RelicCard> relics;

  /// Bônus PERMANENTE de PV máximo (Roubo de PV).
  final int bonusMaxHp;

  /// Bônus temporário de ataque melee (Inspirar) — expira no fim do turno
  /// do dono.
  final int inspirarBonus;

  /// Bônus temporário de ataque melee (Investida) — expira no fim do turno
  /// do oponente.
  final int investidaBonus;

  /// Inabalável já foi usado nesta partida (revive 1×). Persiste entre golpes.
  final bool inabalavelUsed;

  // ── Lote 3a: status / DoT ───────────────────────────────────────────────
  /// Acúmulos de Sangramento (dano/tick = acúmulos × `kSangramentoPerStack`).
  final int bleedStacks;

  /// Turnos restantes de Sangramento (reseta para `kSangramentoTurns` a cada
  /// novo acerto; decai 1 por tick). 0 = sem sangramento.
  final int bleedTurns;

  /// Envenenada (DoT de `kVenenoPerTurn`/turno, sem duração; removida por cura).
  final bool poisoned;

  /// Atordoada: pula a PRÓXIMA Fase de Ataque dela (limpa ao pular).
  final bool stunned;

  /// Enredada: pula a próxima Fase de Ataque E não pode usar Voo enquanto durar
  /// (limpa ao pular).
  final bool entangled;

  /// Cooldown da habilidade Atordoar DESTA criatura (atacante): >0 = não pode
  /// atordoar ainda. Decai no início do turno do dono.
  final int atordoarCooldown;

  // ── Lote 3b: auras de redução (debuff vindo do inimigo) + Doença ─────────
  /// Redução temporária de ataque MELEE (Desmoralizar inimigo). Expira no fim
  /// do turno desta criatura. Aplicada no início do turno do dono da aura.
  final int desmoralizadoMelee;

  /// Redução temporária de ataque MÁGICO (Suprimir Magia inimigo). Expira no
  /// fim do turno desta criatura.
  final int suprimidoMagico;

  /// Acúmulos de Doença. >0 suprime Inspirar/Desmoralizar desta criatura e
  /// arma o gatilho do Surto. Removida por cura ou ao Surto detonar.
  final int diseaseStacks;

  // ── Lote 5: exóticas ─────────────────────────────────────────────────────
  /// Bônus PERMANENTE somado a TODOS os ataques (Andorinha, Crescimento,
  /// Transformar). Acumula ao longo da partida.
  final int permanentAtkBonus;

  /// Ressurreição já usada (auto-revive com PV reduzido, 1×).
  final bool ressureicaoUsed;

  /// Transformar já disparou (2ª forma ativa). Não dispara de novo.
  final bool transformed;

  /// Névoa (Lote 7) armada: já sofreu dano e o PRÓXIMO golpe será prevenido.
  final bool nevoaArmed;

  /// keyword FUNCIONAL: tem a keyword E não está suprimida por Doença (Doença
  /// desativa Inspirar, Desmoralizar e Reflexo Mágico na criatura doente).
  bool functionalKeyword(AbilityKeyword k) {
    if (!hasKeyword(k)) return false;
    if (diseaseStacks > 0 &&
        (k == AbilityKeyword.inspirar ||
            k == AbilityKeyword.desmoralizar ||
            k == AbilityKeyword.reflexoMagico)) {
      return false;
    }
    return true;
  }

  /// Tem DoT ativo (sangramento ou veneno)?
  bool get hasDot => bleedStacks > 0 || poisoned;

  /// Dano de DoT aplicado por tick (sangramento por acúmulos + veneno fixo).
  int get dotDamage =>
      bleedStacks * kSangramentoPerStack + (poisoned ? kVenenoPerTurn : 0);

  /// Pula a Fase de Ataque dela neste turno (atordoada ou enredada).
  bool get skipsAttack => stunned || entangled;

  /// Pode evadir por Voo? Tem a keyword Voo E não está enredada (Enredar tira
  /// o Voo enquanto dura).
  bool get canFly => hasKeyword(AbilityKeyword.voo) && !entangled;

  String get instanceId => card.id;

  /// PV máximo: HP base da carta + `hpBonus` das relíquias + bônus permanente
  /// (Roubo de PV).
  int get maxHp {
    var total = card.effectiveHp + bonusMaxHp;
    for (final r in relics) {
      total += r.scaledHpBonus;
    }
    return total;
  }

  bool get isAlive => currentHp > 0;

  /// Keywords de habilidade canônicas: inatas da carta + concedidas pelas
  /// relíquias equipadas. Variantes de grafia dos dados são normalizadas
  /// (ver `abilities.dart`); strings desconhecidas são ignoradas.
  Set<AbilityKeyword> get keywords {
    final result = <AbilityKeyword>{};
    for (final a in card.abilities) {
      final k = abilityKeywordFromString(a);
      if (k != null) result.add(k);
    }
    for (final r in relics) {
      for (final a in r.grants.abilities) {
        final k = abilityKeywordFromString(a);
        if (k != null) result.add(k);
      }
    }
    return result;
  }

  bool hasKeyword(AbilityKeyword k) => keywords.contains(k);

  /// Imunidade (Lote 6) a um efeito: Imunidade / Perseverança / Vigilante cobrem
  /// conjuntos diferentes. "imune a X" = X não a afeta (para Espinhos/Contra-
  /// Ataque o afetado é o ATACANTE; para os demais, o alvo/portador).
  bool immuneTo(AbilityKeyword effect) {
    if (hasKeyword(AbilityKeyword.imunidade) &&
        (effect == AbilityKeyword.desmoralizar ||
            effect == AbilityKeyword.suprimirMagia ||
            effect == AbilityKeyword.silencio)) {
      return true;
    }
    if (hasKeyword(AbilityKeyword.perseveranca) &&
        (effect == AbilityKeyword.doenca ||
            effect == AbilityKeyword.enredar ||
            effect == AbilityKeyword.silencio ||
            effect == AbilityKeyword.desmoralizar ||
            effect == AbilityKeyword.suprimirMagia)) {
      return true;
    }
    if (hasKeyword(AbilityKeyword.vigilante) &&
        (effect == AbilityKeyword.contraAtaque ||
            effect == AbilityKeyword.espinhos ||
            effect == AbilityKeyword.enredar)) {
      return true;
    }
    return false;
  }

  /// Armadura derivada: soma das `armor` das relíquias equipadas + armadura
  /// inata de Escudo (🎚️ `kEscudoArmor`).
  int get armor {
    var total = 0;
    for (final r in relics) {
      total += r.scaledArmor;
    }
    if (hasKeyword(AbilityKeyword.escudo)) total += kEscudoArmor;
    if (hasKeyword(AbilityKeyword.escudoSagrado)) total += kEscudoSagradoArmor;
    // Encantar Armadura (Lote 6): só dá bônus se JÁ existe armadura.
    if (total > 0 && hasKeyword(AbilityKeyword.encantarArmadura)) {
      total += kEncantarArmaduraBonus;
    }
    return total;
  }

  /// Armadura MÁGICA (reduz dano mágico): Escudo Espelhado + Escudo Sagrado.
  int get magicArmor {
    var total = 0;
    if (hasKeyword(AbilityKeyword.escudoEspelhado)) {
      total += kEscudoEspelhadoArmor;
    }
    if (hasKeyword(AbilityKeyword.escudoSagrado)) total += kEscudoSagradoArmor;
    return total;
  }

  /// MULTI-ATAQUE (SPEC do CEO 2026-06-11) — lista de ataques desta criatura na
  /// Fase de Ataque, 1 por tipo de dano:
  /// - **Base:** `(card.damageType, card.effectiveAtk)` (escala por nível).
  /// - **Relíquia com `atkBonus`:** o bônus é do tipo `attackType` da relíquia,
  ///   ou do tipo BASE se a relíquia não especifica. Mesmo tipo → soma; tipo
  ///   diferente → ataque NOVO. Bônus genérico (sem `attackType`) só vale se o
  ///   tipo base for FÍSICO (regra antiga do CEO 2026-06-10).
  /// - **Buffs temporários** (Inspirar/Investida) só no ataque corpo a corpo.
  ///
  /// Relíquias NÃO sobrescrevem mais o tipo da criatura (corrige o bug do +2 à
  /// distância numa criatura melee virar 6 à distância — agora vira 4 melee + 2
  /// à distância). Ordem determinística (ordem do enum); valores 0 são omitidos.
  List<CardAttack> get attacks {
    final base = card.damageType;
    final byType = <DamageType, int>{base: card.effectiveAtk};
    for (final r in relics) {
      final bonus = r.scaledAtkBonus;
      if (bonus <= 0) continue;
      final t = r.grants.attackType;
      if (t == null) {
        // Bônus genérico: só soma se o tipo BASE for físico.
        if (base == DamageType.corpoACorpo || base == DamageType.aDistancia) {
          byType[base] = (byType[base] ?? 0) + bonus;
        }
      } else {
        // Tipado: soma no ataque daquele tipo (cria se não existe).
        byType[t] = (byType[t] ?? 0) + bonus;
      }
    }
    // Buffs temporários (Inspirar/Investida) só no ataque corpo a corpo.
    final meleeBuff = inspirarBonus + investidaBonus;
    if (meleeBuff > 0 && byType.containsKey(DamageType.corpoACorpo)) {
      byType[DamageType.corpoACorpo] =
          byType[DamageType.corpoACorpo]! + meleeBuff;
    }
    // Fúria (Lote 6): +ataque melee = PV máximo − PV atual (quanto mais ferida,
    // mais forte). Dinâmico, recalculado a cada leitura.
    if (hasKeyword(AbilityKeyword.furia) &&
        byType.containsKey(DamageType.corpoACorpo)) {
      final missing = maxHp - currentHp;
      if (missing > 0) {
        byType[DamageType.corpoACorpo] =
            byType[DamageType.corpoACorpo]! + missing;
      }
    }
    // Debuffs de aura (Lote 3b): Desmoralizar reduz melee; Suprimir Magia reduz
    // mágico. Clampa em 0 (não vira ataque negativo).
    if (desmoralizadoMelee > 0 && byType.containsKey(DamageType.corpoACorpo)) {
      final m = byType[DamageType.corpoACorpo]! - desmoralizadoMelee;
      byType[DamageType.corpoACorpo] = m < 0 ? 0 : m;
    }
    if (suprimidoMagico > 0 && byType.containsKey(DamageType.magico)) {
      final m = byType[DamageType.magico]! - suprimidoMagico;
      byType[DamageType.magico] = m < 0 ? 0 : m;
    }
    // Bônus PERMANENTE (Andorinha/Crescimento/Transformar) em TODOS os ataques.
    if (permanentAtkBonus > 0) {
      for (final k in byType.keys.toList()) {
        byType[k] = byType[k]! + permanentAtkBonus;
      }
    }
    final out = <CardAttack>[];
    for (final dt in DamageType.values) {
      final v = byType[dt];
      if (v != null && v > 0) out.add(CardAttack(dt, v));
    }
    return out;
  }

  /// Tipo de dano PRIMÁRIO (base). Relíquias não sobrescrevem mais — ver [attacks].
  DamageType get effectiveDamageType => card.damageType;

  /// Valor do ataque do tipo BASE (display/cura/ordenação). Inclui buffs se for
  /// melee. Pro combate real, use [attacks].
  int get atk {
    for (final a in attacks) {
      if (a.type == card.damageType) return a.value;
    }
    return 0;
  }

  /// Compat: o multi-ataque substituiu o "ataque único". Mantido = [atk].
  int get effectiveAtk => atk;

  CreatureInPlay copyWith({
    CreatureCard? card,
    int? currentHp,
    int? lane,
    List<RelicCard>? relics,
    int? bonusMaxHp,
    int? inspirarBonus,
    int? investidaBonus,
    bool? inabalavelUsed,
    int? bleedStacks,
    int? bleedTurns,
    bool? poisoned,
    bool? stunned,
    bool? entangled,
    int? atordoarCooldown,
    int? desmoralizadoMelee,
    int? suprimidoMagico,
    int? diseaseStacks,
    int? permanentAtkBonus,
    bool? ressureicaoUsed,
    bool? transformed,
    bool? nevoaArmed,
  }) {
    return CreatureInPlay(
      card: card ?? this.card,
      currentHp: currentHp ?? this.currentHp,
      lane: lane ?? this.lane,
      relics: relics ?? this.relics,
      bonusMaxHp: bonusMaxHp ?? this.bonusMaxHp,
      inspirarBonus: inspirarBonus ?? this.inspirarBonus,
      investidaBonus: investidaBonus ?? this.investidaBonus,
      inabalavelUsed: inabalavelUsed ?? this.inabalavelUsed,
      bleedStacks: bleedStacks ?? this.bleedStacks,
      bleedTurns: bleedTurns ?? this.bleedTurns,
      poisoned: poisoned ?? this.poisoned,
      stunned: stunned ?? this.stunned,
      entangled: entangled ?? this.entangled,
      atordoarCooldown: atordoarCooldown ?? this.atordoarCooldown,
      desmoralizadoMelee: desmoralizadoMelee ?? this.desmoralizadoMelee,
      suprimidoMagico: suprimidoMagico ?? this.suprimidoMagico,
      diseaseStacks: diseaseStacks ?? this.diseaseStacks,
      permanentAtkBonus: permanentAtkBonus ?? this.permanentAtkBonus,
      ressureicaoUsed: ressureicaoUsed ?? this.ressureicaoUsed,
      transformed: transformed ?? this.transformed,
      nevoaArmed: nevoaArmed ?? this.nevoaArmed,
    );
  }
}

/// Estado de um lado do tabuleiro.
///
/// Modelo de MÃO (Card Monsters): o loadout de 18 cartas vira um [deck]
/// embaralhado; a [hand] são as ≤ `kHandSize` cartas visíveis/jogáveis; jogar
/// uma carta COMPRA a próxima do topo do deck repondo a mão. Cartas na mão/deck
/// são `CreatureCard` ou `RelicCard` misturadas (mesmo padrão `Object`+`is` da
/// UI) — use os helpers `cardId`/`cardCost` de `card_models.dart`.
class BoardSide {
  const BoardSide({
    required this.id,
    required this.lanes,
    required this.crystals,
    required this.hand,
    required this.deck,
    required this.sacrificedThisTurn,
    this.pendingCrystals = 0,
    this.graveyard = const <Object>[],
    this.heroId,
    this.heroActiveUsed = false,
  });

  final SideId id;

  /// 3 lanes (0=frente). null = vazia.
  final List<CreatureInPlay?> lanes;

  final int crystals;

  /// MÃO: cartas visíveis/jogáveis (≤ `kHandSize`), criaturas e relíquias
  /// misturadas, em ordem de compra.
  final List<Object> hand;

  /// DECK: pilha de compra restante (índice 0 = topo = próxima a comprar).
  final List<Object> deck;

  /// Se já usou o sacrifício do turno (máx 1/turno).
  final bool sacrificedThisTurn;

  /// Cristais pendentes (Cristal de Drenagem): ganhos durante a Fase de
  /// Ataque, creditados no início do PRÓXIMO turno deste lado (cristais não
  /// fazem carry-over, então o crédito imediato seria perdido no reset).
  final int pendingCrystals;

  /// CEMITÉRIO (ADR-0028): cartas que MORRERAM em combate ou foram DESCARTADAS
  /// (sacrifício, penalidade, etc.). Fonte para efeitos (reanimação, Assassino).
  final List<Object> graveyard;

  /// HERÓI representante deste lado (ADR-0028). null = sem herói (compat).
  final HeroId? heroId;

  /// A ativa do herói (1×/partida) já foi usada?
  final bool heroActiveUsed;

  /// Criaturas vivas no tabuleiro, em ordem de lane (frente→retaguarda).
  List<CreatureInPlay> get creaturesInPlay {
    final result = <CreatureInPlay>[];
    for (final c in lanes) {
      if (c != null && c.isAlive) result.add(c);
    }
    result.sort((a, b) => a.lane.compareTo(b.lane));
    return result;
  }

  bool get hasCreatureInPlay => creaturesInPlay.isNotEmpty;

  /// Criaturas na MÃO (subconjunto jogável agora).
  List<CreatureCard> get handCreatures =>
      hand.whereType<CreatureCard>().toList(growable: false);

  /// Relíquias na MÃO.
  List<RelicCard> get handRelics =>
      hand.whereType<RelicCard>().toList(growable: false);

  /// Próxima carta a comprar (preview); null se o deck acabou.
  Object? get nextCard => deck.isEmpty ? null : deck.first;

  /// Quantas das 9 criaturas ainda existem (em jogo, na mão OU no deck). Conta
  /// IDs distintos: cada carta é única no loadout MVP.
  int get remainingCreatureCount {
    final ids = <String>{};
    for (final c in hand.whereType<CreatureCard>()) {
      ids.add(c.id);
    }
    for (final c in deck.whereType<CreatureCard>()) {
      ids.add(c.id);
    }
    for (final c in creaturesInPlay) {
      ids.add(c.card.id);
    }
    return ids.length;
  }

  int get totalHpInPlay {
    var total = 0;
    for (final c in creaturesInPlay) {
      total += c.currentHp;
    }
    return total;
  }

  /// Monstros ainda disponíveis para jogar (mão + deck) — exibido no HUD.
  int get availableCreatureCount =>
      hand.whereType<CreatureCard>().length +
      deck.whereType<CreatureCard>().length;

  /// Itens (relíquias) ainda disponíveis para usar (mão + deck) — exibido no
  /// HUD.
  int get availableRelicCount =>
      hand.whereType<RelicCard>().length +
      deck.whereType<RelicCard>().length;

  BoardSide copyWith({
    List<CreatureInPlay?>? lanes,
    int? crystals,
    List<Object>? hand,
    List<Object>? deck,
    bool? sacrificedThisTurn,
    int? pendingCrystals,
    List<Object>? graveyard,
    HeroId? heroId,
    bool? heroActiveUsed,
  }) {
    return BoardSide(
      id: id,
      lanes: lanes ?? this.lanes,
      crystals: crystals ?? this.crystals,
      hand: hand ?? this.hand,
      deck: deck ?? this.deck,
      sacrificedThisTurn: sacrificedThisTurn ?? this.sacrificedThisTurn,
      pendingCrystals: pendingCrystals ?? this.pendingCrystals,
      graveyard: graveyard ?? this.graveyard,
      heroId: heroId ?? this.heroId,
      heroActiveUsed: heroActiveUsed ?? this.heroActiveUsed,
    );
  }

  /// Monta o lado inicial (ADR-0028): deck = 18 cartas embaralhadas; mão = 4
  /// cartas, **garantindo `kInitialHandCreatures` criaturas** + o resto
  /// aleatório. Com [rng] embaralha determinístico por seed; sem rng mantém a
  /// ordem do loadout (testes controlados).
  static BoardSide initial(SideId id, CardLoadout loadout,
      [Random? rng, HeroId? heroId]) {
    final pile = <Object>[...loadout.creatures, ...loadout.relics];
    if (rng != null) pile.shuffle(rng);

    final hand = <Object>[];
    final deck = List<Object>.from(pile);
    // 1) puxa as primeiras `kInitialHandCreatures` CRIATURAS pra mão.
    var creaturesNeeded = kInitialHandCreatures;
    for (var i = 0; i < deck.length && creaturesNeeded > 0; ) {
      if (deck[i] is CreatureCard) {
        hand.add(deck.removeAt(i));
        creaturesNeeded--;
      } else {
        i++;
      }
    }
    // 2) completa a mão até kHandSize com o que vier do topo (qualquer tipo).
    while (hand.length < kHandSize && deck.isNotEmpty) {
      hand.add(deck.removeAt(0));
    }
    return BoardSide(
      id: id,
      lanes: List<CreatureInPlay?>.filled(kLaneCount, null),
      crystals: 0,
      hand: hand,
      deck: deck,
      sacrificedThisTurn: false,
      heroId: heroId,
    );
  }
}

/// Estado completo e imutável da partida.
class MatchState {
  const MatchState({
    required this.sideA,
    required this.sideB,
    required this.activeSide,
    required this.turn,
    required this.phase,
    required this.rng,
    this.winner,
    this.lastTurnEvents = const <MatchEvent>[],
  });

  final BoardSide sideA;
  final BoardSide sideB;
  final SideId activeSide;
  final int turn;
  final MatchPhase phase;
  final SideId? winner;

  /// Eventos gerados pelo ÚLTIMO `endTurn`. Semântica (documentada — a UI
  /// narra a partir daqui): cobre TUDO entre o fim da Fase de Jogo do lado
  /// que chamou `endTurn` e o início do turno seguinte, nesta ordem:
  /// Fase de Ataque (ataques/evasões/curas/procs de habilidade), penalidade
  /// sem criaturas, stall, e os procs de INÍCIO do turno seguinte
  /// (Inspirar/Investida do novo lado ativo). Substituído (não acumulado) a
  /// cada `endTurn`. Ações da Fase de Jogo (apply) não geram eventos.
  final List<MatchEvent> lastTurnEvents;

  /// Fonte determinística de aleatoriedade (injetada por seed).
  final Random rng;

  bool get isOver => phase == MatchPhase.fim;

  BoardSide get active => activeSide == SideId.a ? sideA : sideB;
  BoardSide get opponent => activeSide == SideId.a ? sideB : sideA;

  BoardSide sideOf(SideId id) => id == SideId.a ? sideA : sideB;

  MatchState copyWith({
    BoardSide? sideA,
    BoardSide? sideB,
    SideId? activeSide,
    int? turn,
    MatchPhase? phase,
    SideId? winner,
    bool clearWinner = false,
    List<MatchEvent>? lastTurnEvents,
  }) {
    return MatchState(
      sideA: sideA ?? this.sideA,
      sideB: sideB ?? this.sideB,
      activeSide: activeSide ?? this.activeSide,
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      winner: clearWinner ? null : (winner ?? this.winner),
      lastTurnEvents: lastTurnEvents ?? this.lastTurnEvents,
      rng: rng,
    );
  }

  /// Retorna novo estado substituindo o lado `id`.
  MatchState withSide(SideId id, BoardSide side) {
    if (id == SideId.a) return copyWith(sideA: side);
    return copyWith(sideB: side);
  }
}
