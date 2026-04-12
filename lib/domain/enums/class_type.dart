enum ClassType {
  warrior,
  colossus,
  monk,
  rogue,
  hunter,
  druid,
  mage,
  shadowWeaver,
}

extension ClassTypeExt on ClassType {
  String get label => switch (this) {
    ClassType.warrior      => 'Guerreiro',
    ClassType.colossus     => 'Colosso',
    ClassType.monk         => 'Monge',
    ClassType.rogue        => 'Ladino',
    ClassType.hunter       => 'Cacador',
    ClassType.druid        => 'Druida',
    ClassType.mage         => 'Mago',
    ClassType.shadowWeaver => 'Tecelao Sombrio',
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
