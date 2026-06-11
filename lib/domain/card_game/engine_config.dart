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
