/// Constantes tunáveis do Card Game "Modo Cartas ACDA".
///
/// Centralizadas aqui (não espalhadas na lógica). 🎚️ = ajustável sem
/// reescrever o engine.
library;

/// Número de lanes por lado (0 = frente).
const int kLaneCount = 3;

/// Cristais ganhos no início do turno. 🎚️
const int kCrystalsPerTurn = 3;

/// Cristais acumulam entre turnos? 🎚️ (não — zera no início do turno).
const bool kCrystalsCarryOver = false;

/// Cristal ganho ao sacrificar uma relíquia. 🎚️
const int kSacrificeRelicCrystals = 1;

/// Cristal ganho ao sacrificar uma criatura. 🎚️
const int kSacrificeCreatureCrystals = 2;

/// Máximo de sacrifícios por turno. 🎚️
const int kMaxSacrificesPerTurn = 1;

/// Limite de turno (trava anti-stall): turn >= este valor encerra. 🎚️
const int kStallTurnLimit = 40;

/// Quantas cartas o lado perde ao terminar o turno sem criaturas em jogo. 🎚️
const int kNoCreaturePenaltyCards = 1;

/// Tamanho da MÃO (cartas visíveis/jogáveis). O resto fica no deck (compra). 🎚️
/// Modelo Card Monsters: deck embaralhado, mão de 5, compra automática ao jogar.
const int kHandSize = 5;

/// Custo em cristais da jogada especial "tabuleiro cheio → carta empurrada
/// volta pra mão" (bloqueia o resto das ações do turno). 🎚️
const int kReturnToHandCost = 3;

/// Custo em cristais da ação VOLUNTÁRIA de recuar uma criatura própria em jogo
/// de volta pra mão (não encerra a vez). 🎚️
const int kReturnVoluntaryCost = 2;

// ---------------------------------------------------------------------------
// Combate posicional — padrões de alvo por tipo (fiel a `tipos_de_dano.md`)
// ---------------------------------------------------------------------------

/// Padrão de seleção de alvo de um tipo de ataque. 🎚️ tunável por tipo.
enum TargetPattern {
  /// Criatura inimiga da frente (menor lane ocupada).
  front,

  /// Lane oposta (mesmo índice do atacante); se vazia, a frente inimiga.
  oppositeThenFront,

  /// Inimigo de menor PV atual (desempate: menor lane).
  lowestHp,
}

/// Alvo de `corpoACorpo`: frente inimiga (regra cravada, não tunável de fato,
/// mas centralizada aqui por consistência).
const TargetPattern kMeleeTargeting = TargetPattern.front;

/// Alvo de `aDistancia`: lane oposta; senão a frente. 🎚️
const TargetPattern kRangedTargeting = TargetPattern.oppositeThenFront;

/// Alvo de `magico`: inimigo de menor PV atual. 🎚️
const TargetPattern kMagicoTargeting = TargetPattern.lowestHp;

/// Alvo de `vitalismo`: frente inimiga (dano verdadeiro). 🎚️
const TargetPattern kVitalismoTargeting = TargetPattern.front;

/// `vitalismo` pode atacar de qualquer posição? 🎚️ (vault: sim).
const bool kVitalismoAttacksAnywhere = true;

// ---------------------------------------------------------------------------
// Habilidades runtime — valores tunáveis 🎚️
// ---------------------------------------------------------------------------

/// Armadura inata concedida pela habilidade Escudo (soma com a de relíquia). 🎚️
const int kEscudoArmor = 1;

// ── Lote 2 (defensivas) — magnitudes 🎚️ calibráveis ──────────────────────────

/// Dano verdadeiro que Espinhos causa ao atacante melee. 🎚️
const int kEspinhosDamage = 1;

/// Redução de dano MÁGICO de Escudo Espelhado (armadura mágica). 🎚️
const int kEscudoEspelhadoArmor = 1;

/// Redução de dano FÍSICO e MÁGICO de Escudo Sagrado. 🎚️
const int kEscudoSagradoArmor = 1;

/// Chance de Contra-Ataque ao ser atingida por melee (0..1). 🎚️
const double kContraAtaqueChance = 0.5;

/// Reflexo Mágico: SEMPRE (100%) ignora o dano mágico e o devolve ao atacante
/// (decisão do CEO 2026-06-11). Se o atacante TAMBÉM tiver Reflexo, vira loop:
/// quica entre os dois, +`kReflexoLoopGain` de dano por loop, e após
/// `kReflexoLoopLimit` loops é lançado ALEATORIAMENTE em um dos dois. 🎚️
const int kReflexoLoopLimit = 4;

/// Dano extra por loop de Reflexo (anti-loop infinito quando dois refletem). 🎚️
const int kReflexoLoopGain = 1;

// ── Lote 3a (status / DoT) — magnitudes 🎚️ calibráveis ───────────────────────

/// Dano verdadeiro por ACÚMULO de Sangramento, por tick. 🎚️
/// (3 acúmulos → 3 de dano/turno.)
const int kSangramentoPerStack = 1;

/// Duração (em turnos do dono) para a qual o Sangramento RESETA a cada novo
/// acerto. Sem novo acerto, decai 1 turno por tick até expirar. 🎚️
const int kSangramentoTurns = 2;

/// Dano verdadeiro por turno do Veneno (sem duração-limite; não escala). 🎚️
const int kVenenoPerTurn = 1;

/// Cooldown (em turnos) da habilidade Atordoar: após atordoar, não atordoa de
/// novo por este nº de turnos do dono. 🎚️
const int kAtordoarCooldownTurns = 1;

/// Chance de Enredar ao acertar um alvo com Voo (0..1). 🎚️
const double kEnredarChance = 0.5;

// ── Lote 3b (auras de redução + combo Doença/Surto) — magnitudes 🎚️ ──────────

/// Redução de ataque MELEE que Desmoralizar aplica aos inimigos (só o maior). 🎚️
const int kDesmoralizarReduction = 1;

/// Redução de ataque MÁGICO que Suprimir Magia aplica aos inimigos (só o
/// maior). 🎚️
const int kSuprimirReduction = 1;

/// Redução de PV MÁXIMO por acúmulo de Doença quando o Surto detona (permanente
/// — o PV atual encolhe junto). 🎚️
const int kSurtoMaxHpPerStack = 1;

// ── Lote 5 (exóticas) — magnitudes 🎚️ calibráveis ────────────────────────────

/// Ganho PERMANENTE (todos os ataques + PV máximo) de Andorinha por abate. 🎚️
const int kAndorinhaGain = 1;

/// Ganho PERMANENTE (todos os ataques + PV máximo) de Crescimento por cura. 🎚️
const int kCrescimentoGain = 1;

/// Penalidade de ATK da Carta Zumbi ao voltar pra mão enfraquecida. 🎚️
const int kZumbiAtkPenalty = 1;

/// Penalidade de PV da Carta Zumbi ao voltar pra mão enfraquecida. 🎚️
const int kZumbiHpPenalty = 1;

/// Fração do PV máximo com que a Ressurreição revive (0..1). 🎚️
const double kRessurreicaoPercent = 0.5;

/// Limiar de PV (fração do máximo) que dispara a 2ª forma de Transformar. 🎚️
const double kTransformarTrigger = 0.5;

/// Bônus de ATK (todos os ataques) ao transformar. 🎚️
const int kTransformarAtkBonus = 2;

/// Bônus de PV máximo ao transformar (cura ao novo máximo). 🎚️
const int kTransformarHpBonus = 2;

// ── Lote 6 (imunidades + utilidades) — magnitudes 🎚️ ─────────────────────────

/// Armadura extra de Encantar Armadura (só se já houver armadura). 🎚️
const int kEncantarArmaduraBonus = 1;

/// Cristal extra gerado por Cristal Adicional ao sacrificar a criatura. 🎚️
const int kCristalAdicionalCrystals = 1;

/// Bônus de ataque corpo a corpo de Inspirar (aliados, até o fim do turno). 🎚️
const int kInspirarBonus = 1;

/// Bônus de ataque corpo a corpo de Investida (até o fim do turno do
/// oponente — a rodada inteira). 🎚️
const int kInvestidaBonus = 1;

/// Quanto Roubo de PV soma ao PV atual E máximo ao acertar (dano > 0). 🎚️
const int kRouboDePvAmount = 1;

/// Cristais ganhos por Cristal de Drenagem ao destruir uma criatura inimiga.
/// Creditados via `pendingCrystals` no início do PRÓXIMO turno do dono
/// (cristais não fazem carry-over — ganhar na Fase de Ataque seria inútil). 🎚️
const int kCristalDeDrenagemCrystals = 1;

/// Chance de Voo evadir um ataque corpo a corpo (incl. o hit extra de
/// Ataque Duplo), quando o atacante NÃO tem Voo. 🎚️
const double kVooMeleeEvadeChance = 0.5;

/// Chance de Voo evadir um ataque à distância (atacante sem Voo). 🎚️
const double kVooRangedEvadeChance = 0.25;
