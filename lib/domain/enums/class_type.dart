enum ClassType {
      warrior,      // Guerreiro
        colossus,     // Colosso
          monk,         // Monge
            rogue,        // Ladino
              hunter,       // Caçador
                druid,        // Druida
                  mage,         // Mago
                    shadowWeaver, // Tecelão Sombrio
                    }

                    extension ClassTypeExt on ClassType {
                      String get label => switch (this) {
                          ClassType.warrior      => 'Guerreiro',
                              ClassType.colossus     => 'Colosso',
                                  ClassType.monk         => 'Monge',
                                      ClassType.rogue        => 'Ladino',
                                          ClassType.hunter       => 'Caçador',
                                              ClassType.druid        => 'Druida',
                                                  ClassType.mage         => 'Mago',
                                                      ClassType.shadowWeaver => 'Tecelão Sombrio',
                                                        };

                                                          String get description => switch (this) {
                                                              ClassType.warrior      => 'Força e equilíbrio. O caminho do enfrentamento.',
                                                                  ClassType.colossus     => 'Força bruta e resistência extrema.',
                                                                      ClassType.monk         => 'Disciplina, espiritualidade e equilíbrio.',
                                                                          ClassType.rogue        => 'Mobilidade, astúcia e precisão.',
                                                                              ClassType.hunter       => 'Foco, observação e sobrevivência.',
                                                                                  ClassType.druid        => 'Conexão natural, cura e transformação.',
                                                                                      ClassType.mage         => 'Intelecto, mana e arcano.',
                                                                                          ClassType.shadowWeaver => 'Híbrido total. Acesso a tudo. Evolução lenta.',
                                                                                            };

                                                                                              bool get hasVitalism => switch (this) {
                                                                                                  ClassType.warrior      => true,
                                                                                                      ClassType.colossus     => true,
                                                                                                          ClassType.rogue        => true,
                                                                                                              ClassType.hunter       => true,
                                                                                                                  ClassType.shadowWeaver => true,
                                                                                                                      _                      => false,
                                                                                                                        };
                                                                                                                        }
}