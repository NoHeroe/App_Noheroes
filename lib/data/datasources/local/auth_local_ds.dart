import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/app_database.dart';
import '../../database/daos/player_dao.dart';
import '../../database/tables/players_table.dart';
import 'habit_local_ds.dart';
import 'package:drift/drift.dart';

class AuthLocalDs {
  final AppDatabase _db;
  static const _sessionKey = 'nh_player_id';

  AuthLocalDs(this._db);

  PlayerDao get _dao => PlayerDao(_db);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<PlayersTableData?> register({
    required String email,
    required String password,
  }) async {
    final existing = await _dao.findByEmail(email.toLowerCase().trim());
    if (existing != null) return null;

    final id = await _dao.createPlayer(
      PlayersTableCompanion(
        email: Value(email.toLowerCase().trim()),
        passwordHash: Value(_hashPassword(password)),
      ),
    );

    await _saveSession(id);
    return _dao.findById(id);
  }

  Future<PlayersTableData?> login({
    required String email,
    required String password,
  }) async {
    final player = await _dao.findByEmail(email.toLowerCase().trim());
    if (player == null) return null;
    if (player.passwordHash != _hashPassword(password)) return null;

    // Atualiza streak, Dia em Caelum e último login
    await _dao.touchLastLogin(player.id);
    await _saveSession(player.id);

    // Retorna dados atualizados após touchLastLogin
    return _dao.findById(player.id);
  }

  Future<PlayersTableData?> currentSession() async {
    // guildRank_migration: corrige usuários com rank 'e' que não entraram na guilda
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_sessionKey);
    if (id == null) return null;

    // Também roda touchLastLogin na abertura via sessão
    await _dao.touchLastLogin(id);
    return _dao.findById(id);
  }

  Future<void> _saveSession(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, id);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> completeOnboarding(
      int id, String shadowName, String narrativeMode) {
    return PlayerDao(_db).completeOnboarding(id, shadowName, narrativeMode);
  }

  Future<void> createInitialHabit(
      int playerId, String habitTitle, String category) async {
    final habitDs = HabitLocalDs(_db);
    await habitDs.createSystemHabit(
      playerId: playerId,
      title: habitTitle,
      category: category,
    );
  }
}
