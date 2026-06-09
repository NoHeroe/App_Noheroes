import 'item_spec.dart';
import 'player_inventory_entry.dart';

// Junção lógica: linha do player_inventory + spec do catálogo.
// Usada pelas telas de inventário e equipamento pra evitar buscas repetidas.
class InventoryEntryWithSpec {
  final PlayerInventoryEntry entry;
  final ItemSpec spec;

  const InventoryEntryWithSpec({required this.entry, required this.spec});
}
