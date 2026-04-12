enum ShadowState {
      stable,     // Estável
        tense,      // Tensa
          chaotic,    // Caótica
            ascending,  // Ascendente
              obsessive,  // Obsessiva (overwork)
                apathetic,  // Apática
                  abyssal,    // Abissal (crítico)
                    void_,      // Vazio
                    }

                    extension ShadowStateExt on ShadowState {
                      String get label => switch (this) {
                          ShadowState.stable    => 'Estável',
                              ShadowState.tense     => 'Tensa',
                                  ShadowState.chaotic   => 'Caótica',
                                      ShadowState.ascending => 'Ascendente',
                                          ShadowState.obsessive => 'Obsessiva',
                                              ShadowState.apathetic => 'Apática',
                                                  ShadowState.abyssal   => 'Abissal',
                                                      ShadowState.void_     => 'Vazio',
                                                        };

                                                          String get phrase => switch (this) {
                                                              ShadowState.stable    => 'Sua sombra observa em silêncio.',
                                                                  ShadowState.tense     => 'Algo dentro de você está inquieto.',
                                                                      ShadowState.chaotic   => 'A sombra se agita. Você está perdendo o controle.',
                                                                          ShadowState.ascending => 'Sua sombra recua. Você está ascendendo.',
                                                                              ShadowState.obsessive => 'Cuidado. O excesso também é uma forma de fuga.',
                                                                                  ShadowState.apathetic => 'A sombra cresce no silêncio da inação.',
                                                                                      ShadowState.abyssal   => 'Você está à beira do abismo. Enfrente-a.',
                                                                                          ShadowState.void_     => 'Nada. Nem sombra, nem luz.',
                                                                                            };
                                                                                            }
}