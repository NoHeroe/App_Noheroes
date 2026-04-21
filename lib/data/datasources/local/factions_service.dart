import 'dart:convert';
import 'package:flutter/services.dart';
import '../../database/app_database.dart';
import '../../database/daos/achievement_dao.dart';

// Carrega facções do JSON e filtra conforme estado do player.
// Regra Sprint 2.3 Bloco 0.A:
//   • isSecret != true             → sempre visível
//   • isSecret == true +
//       requiresAchievement presente + unlocked por player → visível
//       requiresAchievement ausente (ou não desbloqueado)  → invisível
class FactionsService {
  final AppDatabase _db;
  FactionsService(this._db);

  AchievementDao get _achievementDao => AchievementDao(_db);

  Future<List<Map<String, dynamic>>> _loadAll() async {
    final raw = await rootBundle.loadString('assets/data/factions.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    return (data['factions'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> availableForSelection(
      PlayersTableData player) async {
    final all = await _loadAll();
    final result = <Map<String, dynamic>>[];
    for (final f in all) {
      final isSecret = f['isSecret'] == true;
      if (!isSecret) {
        result.add(f);
        continue;
      }
      final req = f['requiresAchievement'] as String?;
      if (req == null || req.isEmpty) continue;
      final unlocked = await _achievementDao.isUnlocked(player.id, req);
      if (unlocked) result.add(f);
    }
    return result;
  }
}
