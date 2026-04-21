// Representa 1 efeito de um encantamento (ex: damage_fire: 10).
// Mapa raw vindo do JSON → classe tipada leve pro domínio.
class EnchantEffect {
  final String key;   // 'damage_fire', 'lifesteal_percent', 'defense_flat'
  final num value;    // int ou double

  const EnchantEffect({required this.key, required this.value});

  static List<EnchantEffect> fromMap(Map<String, dynamic> raw) {
    final result = <EnchantEffect>[];
    raw.forEach((k, v) {
      if (v is num) result.add(EnchantEffect(key: k, value: v));
    });
    return result;
  }
}
