import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/vitalism_calculator.dart';
import '../../../domain/enums/class_type.dart';

/// Aplica bônus de atributos por classe / escolha de facção (Época 2 —
/// Supabase). `applyClassBonus` é um read-modify-write single-table (lê
/// o nível atual, deriva HP/MP/vitalismo, escreve a row) — não há RPC
/// dedicada e a escrita é numa só tabela (`players`), então persiste
/// direto via PostgREST. RLS (`auth.uid() = id`) protege cross-player.
class ClassBonusService {
  final SupabaseClient _client;
  ClassBonusService(this._client);

  static const _bonuses = {
    'warrior':      {'strength': 4, 'constitution': 3, 'dexterity': 2, 'intelligence': 1, 'spirit': 1, 'charisma': 1},
    'colossus':     {'strength': 5, 'constitution': 4, 'dexterity': 1, 'intelligence': 1, 'spirit': 1, 'charisma': 0},
    'monk':         {'strength': 2, 'constitution': 2, 'dexterity': 3, 'intelligence': 2, 'spirit': 4, 'charisma': 1},
    'rogue':        {'strength': 2, 'constitution': 1, 'dexterity': 5, 'intelligence': 3, 'spirit': 1, 'charisma': 2},
    'hunter':       {'strength': 2, 'constitution': 2, 'dexterity': 4, 'intelligence': 3, 'spirit': 2, 'charisma': 1},
    'druid':        {'strength': 1, 'constitution': 2, 'dexterity': 2, 'intelligence': 3, 'spirit': 5, 'charisma': 1},
    'mage':         {'strength': 1, 'constitution': 1, 'dexterity': 2, 'intelligence': 5, 'spirit': 3, 'charisma': 2},
    'shadowWeaver': {'strength': 2, 'constitution': 2, 'dexterity': 2, 'intelligence': 2, 'spirit': 2, 'charisma': 2},
  };

  Future<void> applyClassBonus(String playerId, String classId) async {
    final row = await _client
        .from('players')
        .select('level')
        .eq('id', playerId)
        .maybeSingle();
    if (row == null) return;
    final level = (row['level'] as num?)?.toInt() ?? 1;

    final bonus = _bonuses[classId];
    if (bonus == null) return;

    final maxHp = 100 + (bonus['constitution']! * 10) + (level * 5);
    final maxMp = (maxHp * 0.9).round();

    final parsedClass = ClassType.values.asNameMap()[classId];
    final maxVitalism = parsedClass != null
        ? VitalismCalculator.calculateMaxVitalism(
            hp: maxHp,
            classType: parsedClass,
            level: level,
          )
        : 0;

    await _client.from('players').update({
      'class_type': classId,
      'strength': bonus['strength']!,
      'constitution': bonus['constitution']!,
      'dexterity': bonus['dexterity']!,
      'intelligence': bonus['intelligence']!,
      'spirit': bonus['spirit']!,
      'charisma': bonus['charisma']!,
      'max_hp': maxHp,
      'hp': maxHp,
      'max_mp': maxMp,
      'mp': maxMp,
      'current_vitalism': maxVitalism,
    }).eq('id', playerId);
  }

  Future<void> applyFactionChoice(String playerId, String factionId) async {
    await _client
        .from('players')
        .update({'faction_type': factionId}).eq('id', playerId);
  }
}
