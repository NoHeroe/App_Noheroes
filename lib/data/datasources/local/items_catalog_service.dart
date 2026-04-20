import '../../../core/utils/guild_rank.dart';
import '../../../core/utils/item_equip_policy.dart';
import '../../../core/utils/item_source_policy.dart';
import '../../../domain/enums/item_type.dart';
import '../../../domain/models/item_spec.dart';
import '../../../domain/models/player_snapshot.dart';
import '../../database/app_database.dart';

// Leitura do items_catalog. Catálogo é imutável após seed → cache em memória
// na primeira chamada. Pattern: guarda o Future pra evitar double-load em boot
// concorrente (idempotente mesmo se rodar 2x).
class ItemsCatalogService {
  final AppDatabase _db;
  Future<List<ItemSpec>>? _cacheFuture;

  ItemsCatalogService(this._db);

  Future<List<ItemSpec>> findAll() => _cacheFuture ??= _loadAll();

  Future<List<ItemSpec>> _loadAll() async {
    final rows = await _db.select(_db.itemsCatalogTable).get();
    return List<ItemSpec>.unmodifiable(rows.map(ItemSpec.fromRow));
  }

  Future<ItemSpec?> findByKey(String key) async {
    final all = await findAll();
    for (final s in all) {
      if (s.key == key) return s;
    }
    return null;
  }

  Future<List<ItemSpec>> findByType(ItemType type) async {
    final all = await findAll();
    return all.where((s) => s.type == type).toList(growable: false);
  }

  Future<List<ItemSpec>> findByRank(GuildRank rank) async {
    final all = await findAll();
    return all.where((s) => s.rank == rank).toList(growable: false);
  }

  // Itens disponíveis em loja pro jogador: defense-in-depth via canAppearInShop
  // + gates de acesso (level/rank/classe/facção) sem exigir isEquippable
  // (consumível/material também podem estar em loja).
  Future<List<ItemSpec>> findAvailableInShop({
    required PlayerSnapshot player,
  }) async {
    final all = await findAll();
    return all.where((s) {
      if (!ItemSourcePolicy.canAppearInShop(s)) return false;
      if (s.requiredLevel > player.level) return false;
      if (!ItemEquipPolicy.isRankSufficient(player.rank, s.requiredRank)) {
        return false;
      }
      if (s.allowedClasses.isNotEmpty &&
          (player.classKey == null ||
              !s.allowedClasses.contains(player.classKey))) {
        return false;
      }
      if (s.allowedFactions.isNotEmpty &&
          (player.factionKey == null ||
              !s.allowedFactions.contains(player.factionKey))) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }
}
