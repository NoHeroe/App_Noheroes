// Tipo de receita: craft (mesa/workshop) vs forge (bigorna).
// Diferenciação visual e de gate via required_station.
enum RecipeType { craft, forge }

extension RecipeTypeX on RecipeType {
  String get value => name;

  String get label => switch (this) {
        RecipeType.craft => 'Criar',
        RecipeType.forge => 'Forjar',
      };

  static RecipeType? fromString(String? raw) {
    if (raw == null) return null;
    return switch (raw.toLowerCase()) {
      'craft' => RecipeType.craft,
      'forge' => RecipeType.forge,
      _ => null,
    };
  }
}
