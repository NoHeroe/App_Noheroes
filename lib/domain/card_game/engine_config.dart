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
