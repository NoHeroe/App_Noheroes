/// Heróis / representantes do baralho (ADR-0028). Cada herói é um "porta-skill"
/// com 1 passiva fixa + 1 ativa (1×/partida). v1: a 1ª leva (Trapaceiro,
/// Cartomante, Oráculo, Coringa, Assassino). Spec canônica: vault `herois.md`.
library;

import 'card_models.dart';

/// Os 5 heróis iniciais.
enum HeroId { trapaceiro, cartomante, oraculo, coringa, assassino }

/// Carta da CAIXA CORINGA (passiva do Coringa, ADR-0028): NÃO-colecionável (não
/// vai no deck). 1 PV, 1 ATK mágico, Escudo Sagrado.
CreatureCard caixaCoringaCard() => CreatureCard(
      id: 'caixa_coringa',
      nome: 'Caixa Coringa',
      concepts: const [CardConcept.neutro],
      cost: 0,
      atk: 1,
      hp: 1,
      damageType: DamageType.magico,
      rarity: Rarity.comum,
      abilities: const ['Escudo Sagrado'],
    );

/// FRAGMENTO DO DEUS LOUCO (ativa do Coringa, ADR-0028): épica, 4 PV, 2 físico +
/// 2 mágico + 2 à distância (ataques nativos), habilidade Alcance. Existe também
/// no `creatures.json` (colecionável); este é o objeto usado pela ativa.
CreatureCard fragmentoDoDeusLoucoCard() => CreatureCard(
      id: 'fragmento_deus_louco',
      nome: 'Fragmento do Deus Louco',
      concepts: const [CardConcept.corrompido],
      cost: 4,
      atk: 2,
      hp: 4,
      damageType: DamageType.corpoACorpo,
      rarity: Rarity.epica,
      abilities: const ['Alcance'],
      extraAttacks: const {DamageType.magico: 2, DamageType.aDistancia: 2},
    );

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
