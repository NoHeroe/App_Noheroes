// Linha de player_inventory vinda do Supabase (Época 2, full-online — ADR-0024).
// Substitui a antiga PlayerInventoryTableData (Drift). PK de linha (id) continua
// int (bigserial); player_id é a uuid do jogador -> String.
//
// Construído via fromMap(Map<String,dynamic>) — a row do PostgREST já vem como
// Map com colunas snake_case.
class PlayerInventoryEntry {
  final int id;
  final String playerId;
  final String itemKey;
  final int quantity;
  final int? durabilityCurrent;
  final int acquiredAt; // ms epoch
  final String acquiredVia;
  final String? evolutionStage;
  final bool isEquipped;
  final String? appliedRuneKey;
  final String? appliedSapKey;
  final int? sapChargesRemaining;

  const PlayerInventoryEntry({
    required this.id,
    required this.playerId,
    required this.itemKey,
    required this.quantity,
    required this.durabilityCurrent,
    required this.acquiredAt,
    required this.acquiredVia,
    required this.evolutionStage,
    required this.isEquipped,
    required this.appliedRuneKey,
    required this.appliedSapKey,
    required this.sapChargesRemaining,
  });

  factory PlayerInventoryEntry.fromMap(Map<String, dynamic> m) {
    return PlayerInventoryEntry(
      id:                  _asInt(m['id'])!,
      playerId:            m['player_id'] as String,
      itemKey:             m['item_key'] as String,
      quantity:            _asInt(m['quantity']) ?? 1,
      durabilityCurrent:   _asInt(m['durability_current']),
      acquiredAt:          _asInt(m['acquired_at']) ?? 0,
      acquiredVia:         m['acquired_via'] as String,
      evolutionStage:      m['evolution_stage'] as String?,
      isEquipped:          m['is_equipped'] as bool? ?? false,
      appliedRuneKey:      m['applied_rune_key'] as String?,
      appliedSapKey:       m['applied_sap_key'] as String?,
      sapChargesRemaining: _asInt(m['sap_charges_remaining']),
    );
  }
}

// PostgREST pode emitir bigint como int ou (raramente) String; tolera ambos.
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
