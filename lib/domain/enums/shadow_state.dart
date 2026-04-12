enum ShadowState {
  stable,
  tense,
  chaotic,
  ascending,
  obsessive,
  apathetic,
  abyssal,
  void_,
}

extension ShadowStateExt on ShadowState {
  String get label => switch (this) {
    ShadowState.stable    => 'Estavel',
    ShadowState.tense     => 'Tensa',
    ShadowState.chaotic   => 'Caotica',
    ShadowState.ascending => 'Ascendente',
    ShadowState.obsessive => 'Obsessiva',
    ShadowState.apathetic => 'Apatica',
    ShadowState.abyssal   => 'Abissal',
    ShadowState.void_     => 'Vazio',
  };

  String get phrase => switch (this) {
    ShadowState.stable    => 'Sua sombra observa em silencio.',
    ShadowState.tense     => 'Algo dentro de voce esta inquieto.',
    ShadowState.chaotic   => 'A sombra se agita. Voce esta perdendo o controle.',
    ShadowState.ascending => 'Sua sombra recua. Voce esta ascendendo.',
    ShadowState.obsessive => 'Cuidado. O excesso tambem e uma forma de fuga.',
    ShadowState.apathetic => 'A sombra cresce no silencio da inacao.',
    ShadowState.abyssal   => 'Voce esta a beira do abismo. Enfrente-a.',
    ShadowState.void_     => 'Nada. Nem sombra, nem luz.',
  };
}
