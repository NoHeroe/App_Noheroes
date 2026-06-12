/// Heróis / representantes do baralho (ADR-0028). Cada herói é um "porta-skill"
/// com 1 passiva fixa + 1 ativa (1×/partida). v1: a 1ª leva (Trapaceiro,
/// Cartomante, Oráculo, Coringa, Assassino). Spec canônica: vault `herois.md`.
library;

/// Os 5 heróis iniciais.
enum HeroId { trapaceiro, cartomante, oraculo, coringa, assassino }

/// Nome exibível do herói.
String heroLabel(HeroId h) {
  switch (h) {
    case HeroId.trapaceiro:
      return 'O Trapaceiro';
    case HeroId.cartomante:
      return 'O Cartomante';
    case HeroId.oraculo:
      return 'A Oráculo';
    case HeroId.coringa:
      return 'O Coringa';
    case HeroId.assassino:
      return 'O Assassino';
  }
}

/// Descrição curta da PASSIVA (fixa).
String heroPassive(HeroId h) {
  switch (h) {
    case HeroId.trapaceiro:
      return 'Ocasionalmente compra 1 carta do baralho.';
    case HeroId.cartomante:
      return '1 carta a mais no deck, adicionada após o turno 4.';
    case HeroId.oraculo:
      return 'Ocasionalmente vê as próximas 5 cartas e reordena 1.';
    case HeroId.coringa:
      return 'Pequena chance de substituir uma carta morta por uma da Caixa Coringa.';
    case HeroId.assassino:
      return 'Ocasionalmente concede Esquiva (100%) a uma carta por 1 turno.';
  }
}

/// Descrição curta da ATIVA (1×/partida).
String heroActive(HeroId h) {
  switch (h) {
    case HeroId.trapaceiro:
      return 'Rouba 2 cristais do oponente.';
    case HeroId.cartomante:
      return 'Puxa 2 cartas e recua 1 carta do tabuleiro sem custo.';
    case HeroId.oraculo:
      return 'Vê o baralho+mão do oponente; embaralha (ou não) por cristais.';
    case HeroId.coringa:
      return 'Põe a carta "Fragmento do Deus Louco" na mão.';
    case HeroId.assassino:
      return 'Mata 1 carta aleatória do deck do oponente (→ cemitério).';
  }
}

/// Canoniza um id cru (do deck builder / JSON) para o enum.
HeroId? heroIdFromString(String? raw) {
  switch (raw) {
    case 'trapaceiro':
      return HeroId.trapaceiro;
    case 'cartomante':
      return HeroId.cartomante;
    case 'oraculo':
      return HeroId.oraculo;
    case 'coringa':
      return HeroId.coringa;
    case 'assassino':
      return HeroId.assassino;
  }
  return null;
}

String heroIdToString(HeroId h) => h.name;
