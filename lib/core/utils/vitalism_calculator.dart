import '../../domain/enums/class_type.dart';

class VitalismCalculator {
  static const Map<ClassType, double> _baseByClass = {
    ClassType.hunter:       1.90,
    ClassType.rogue:        2.10,
    ClassType.warrior:      2.20,
    ClassType.colossus:     2.80,
    ClassType.shadowWeaver: 3.00,
  };

  // Placeholder v0.26.0 — curva final entra via ADR de balanceamento futura.
  static int calculateMaxVitalism({
    required int hp,
    required ClassType classType,
    required int level,
    double multiplier = 1.0,
  }) {
    final base = _baseByClass[classType];
    if (base == null) return 0;
    final percentual = base + (level > 5 ? (level - 5) * 0.02 : 0.0);
    return (hp * percentual * multiplier).round();
  }
}
