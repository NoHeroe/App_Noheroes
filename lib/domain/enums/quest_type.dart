enum QuestType {
      daily,    // Missão diária (hábito)
        personal, // Missão individual
          lore,     // Missão de lore/região
            faction,  // Missão de facção
              shadow,   // Shadow Quest
                event,    // Missão de evento
                  class_,   // Missão de classe
                  }

                  extension QuestTypeExt on QuestType {
                    String get label => switch (this) {
                        QuestType.daily    => 'Ritual Diário',
                            QuestType.personal => 'Missão Pessoal',
                                QuestType.lore     => 'Missão de Lore',
                                    QuestType.faction  => 'Missão de Facção',
                                        QuestType.shadow   => 'Shadow Quest',
                                            QuestType.event    => 'Evento',
                                                QuestType.class_   => 'Missão de Classe',
                                                  };
                                                  }
}