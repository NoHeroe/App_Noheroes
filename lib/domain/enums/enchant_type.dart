// Sprint 2.3 — encantamentos têm 2 naturezas:
//   rune: permanente no item até substituição
//   sap:  temporário, consome cargas em combate (Sprint 2.4 ativa)
enum EnchantType { rune, sap }

class EnchantTypeParser {
  EnchantTypeParser._();

  static EnchantType? tryParse(String? s) {
    if (s == null) return null;
    for (final t in EnchantType.values) {
      if (t.name == s) return t;
    }
    return null;
  }
}
