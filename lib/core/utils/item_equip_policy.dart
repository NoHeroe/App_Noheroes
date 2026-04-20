import '../../domain/models/inventory_entry_with_spec.dart';
import '../../domain/models/item_spec.dart';
import '../../domain/models/player_snapshot.dart';
import 'guild_rank.dart';

enum RejectReason {
  notEquippable,
  tooLowLevel,
  tooLowRank,
  classRestricted,
  factionRestricted,
  slotOccupied,
}

class EquipResult {
  final bool isOk;
  final RejectReason? reason;

  const EquipResult._(this.isOk, this.reason);

  const EquipResult.ok() : this._(true, null);
  const EquipResult.rejected(RejectReason r) : this._(false, r);
}

// Políticas puras de equipamento — sem IO, sem banco.
// - parseRank: coexiste com GuildRankSystem.fromString legado, mas tem semântica
//   diferente ('none'/vazio/inválido → null, em vez de fallback em E).
//   Ver Sprint_2.1 Bloco 0 reconhecimento.
// - isRankSufficient: null do player ⇒ não equipa nada com gate de rank.
// - canEquipItem: valida em ordem fixa; retorna primeira rejeição.
// - aggregateStatsFromEquipment: soma por chave.
class ItemEquipPolicy {
  ItemEquipPolicy._();

  static GuildRank? parseRank(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw) {
      case 'E': return GuildRank.e;
      case 'D': return GuildRank.d;
      case 'C': return GuildRank.c;
      case 'B': return GuildRank.b;
      case 'A': return GuildRank.a;
      case 'S': return GuildRank.s;
    }
    return null;
  }

  static bool isRankSufficient(GuildRank? playerRank, GuildRank? requiredRank) {
    if (requiredRank == null) return true;
    if (playerRank == null) return false;
    return playerRank.index >= requiredRank.index;
  }

  static EquipResult canEquipItem({
    required ItemSpec item,
    required PlayerSnapshot player,
  }) {
    if (!item.isEquippable) {
      return const EquipResult.rejected(RejectReason.notEquippable);
    }
    if (player.level < item.requiredLevel) {
      return const EquipResult.rejected(RejectReason.tooLowLevel);
    }
    if (!isRankSufficient(player.rank, item.requiredRank)) {
      return const EquipResult.rejected(RejectReason.tooLowRank);
    }
    // Sprint 2.2 pós-teste: Tecelão Sombrio é híbrido universal — ignora
    // allowedClasses em todos os itens.
    if (item.allowedClasses.isNotEmpty &&
        player.classKey != 'shadowWeaver' &&
        (player.classKey == null ||
            !item.allowedClasses.contains(player.classKey))) {
      return const EquipResult.rejected(RejectReason.classRestricted);
    }
    if (item.allowedFactions.isNotEmpty &&
        (player.factionKey == null ||
            !item.allowedFactions.contains(player.factionKey))) {
      return const EquipResult.rejected(RejectReason.factionRestricted);
    }
    return const EquipResult.ok();
  }

  static Map<String, num> aggregateStatsFromEquipment(
    List<ItemSpec> equipped,
  ) {
    final result = <String, num>{};
    for (final item in equipped) {
      item.stats.forEach((k, v) {
        result[k] = (result[k] ?? 0) + v;
      });
    }
    return result;
  }

  // Variante que respeita evolution_stage de items is_evolving. Usada pelo
  // player_equipment_service — pro Colar da Guilda e afins, os stats efetivos
  // vêm de evolution_stages[stage_X], não de spec.stats (que pode ser {}).
  static Map<String, num> aggregateStatsFromEquippedEntries(
    List<InventoryEntryWithSpec> entries,
  ) {
    final result = <String, num>{};
    for (final e in entries) {
      final effective = effectiveStatsFor(e.spec, e.entry.evolutionStage);
      effective.forEach((k, v) {
        result[k] = (result[k] ?? 0) + v;
      });
    }
    return result;
  }

  // Resolve os stats "efetivos" de um item considerando seu estágio de evolução.
  //  - item não-evolving → spec.stats
  //  - item evolving + estágio válido → stage.stats
  //  - item evolving + estágio inválido/null → spec.stats (fallback defensivo)
  static Map<String, num> effectiveStatsFor(
    ItemSpec spec,
    String? evolutionStage,
  ) {
    if (!spec.isEvolving) return spec.stats;
    if (spec.evolutionStages == null || evolutionStage == null) {
      return spec.stats;
    }
    final stage = spec.evolutionStages![evolutionStage];
    return stage?.stats ?? spec.stats;
  }
}
