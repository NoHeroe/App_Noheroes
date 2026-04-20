import '../../data/database/app_database.dart';
import 'item_spec.dart';

// Junção lógica: linha do player_inventory + spec do catálogo.
// Usada pelas telas de inventário e equipamento pra evitar buscas repetidas.
class InventoryEntryWithSpec {
  final PlayerInventoryTableData entry;
  final ItemSpec spec;

  const InventoryEntryWithSpec({required this.entry, required this.spec});
}
