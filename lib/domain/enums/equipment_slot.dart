// 12 slots canônicos. JSON usa snake_case (`main_hand`), enum usa camelCase.
enum EquipmentSlot {
  mainHand,
  offHand,
  head,
  chest,
  legs,
  feet,
  hands,
  shoulders,
  waist,
  ring,
  necklace,
  relic,
}

extension EquipmentSlotExt on EquipmentSlot {
  String get label => switch (this) {
    EquipmentSlot.mainHand  => 'Mão Principal',
    EquipmentSlot.offHand   => 'Mão Secundária',
    EquipmentSlot.head      => 'Cabeça',
    EquipmentSlot.chest     => 'Peito',
    EquipmentSlot.legs      => 'Pernas',
    EquipmentSlot.feet      => 'Pés',
    EquipmentSlot.hands     => 'Mãos',
    EquipmentSlot.shoulders => 'Ombros',
    EquipmentSlot.waist     => 'Cintura',
    EquipmentSlot.ring      => 'Anel',
    EquipmentSlot.necklace  => 'Colar',
    EquipmentSlot.relic     => 'Relíquia',
  };

  String get dbValue => switch (this) {
    EquipmentSlot.mainHand  => 'main_hand',
    EquipmentSlot.offHand   => 'off_hand',
    EquipmentSlot.head      => 'head',
    EquipmentSlot.chest     => 'chest',
    EquipmentSlot.legs      => 'legs',
    EquipmentSlot.feet      => 'feet',
    EquipmentSlot.hands     => 'hands',
    EquipmentSlot.shoulders => 'shoulders',
    EquipmentSlot.waist     => 'waist',
    EquipmentSlot.ring      => 'ring',
    EquipmentSlot.necklace  => 'necklace',
    EquipmentSlot.relic     => 'relic',
  };
}

class EquipmentSlotParser {
  EquipmentSlotParser._();

  static const Map<String, EquipmentSlot> _byString = {
    'main_hand': EquipmentSlot.mainHand,
    'mainHand':  EquipmentSlot.mainHand,
    'off_hand':  EquipmentSlot.offHand,
    'offHand':   EquipmentSlot.offHand,
    'head':      EquipmentSlot.head,
    'chest':     EquipmentSlot.chest,
    'legs':      EquipmentSlot.legs,
    'feet':      EquipmentSlot.feet,
    'hands':     EquipmentSlot.hands,
    'shoulders': EquipmentSlot.shoulders,
    'waist':     EquipmentSlot.waist,
    'ring':      EquipmentSlot.ring,
    'necklace':  EquipmentSlot.necklace,
    'relic':     EquipmentSlot.relic,
  };

  static EquipmentSlot? fromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return _byString[raw.toLowerCase()];
  }
}
