enum AffinityTier {
  common,
  rare,
  special,
}

extension AffinityTierExt on AffinityTier {
  // Placeholders v0.27.0 — substituídos por ADR 0008 (balanceamento) no futuro.
  int get lifeRitualPoints => switch (this) {
    AffinityTier.common  => 10,
    AffinityTier.rare    => 50,
    AffinityTier.special => 0, // Vida não se converte em pontos
  };

  String get dbValue => name;
}

AffinityTier? parseAffinityTier(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return AffinityTier.values.asNameMap()[raw];
}
