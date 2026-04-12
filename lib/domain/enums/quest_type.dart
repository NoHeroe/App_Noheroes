enum QuestType {
  daily,
  personal,
  lore,
  faction,
  shadow,
  event,
  class_,
}

extension QuestTypeExt on QuestType {
  String get label => switch (this) {
    QuestType.daily    => 'Ritual Diario',
    QuestType.personal => 'Missao Pessoal',
    QuestType.lore     => 'Missao de Lore',
    QuestType.faction  => 'Missao de Faccao',
    QuestType.shadow   => 'Shadow Quest',
    QuestType.event    => 'Evento',
    QuestType.class_   => 'Missao de Classe',
  };
}
