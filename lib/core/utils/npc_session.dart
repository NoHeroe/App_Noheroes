import 'package:shared_preferences/shared_preferences.dart';

class NpcSession {
  static const _keyDay = 'npc_last_shown_day';
  static const _keyShadow = 'npc_last_shadow_state';

  /// Mostra se mudou o dia OU se o estado da sombra mudou
  static Future<bool> shouldShow(int caelumDay, String shadowState) async {
    final prefs = await SharedPreferences.getInstance();
    final lastDay = prefs.getInt(_keyDay) ?? -1;
    final lastShadow = prefs.getString(_keyShadow) ?? '';
    return lastDay != caelumDay || lastShadow != shadowState;
  }

  static Future<void> markShown(int caelumDay, String shadowState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDay, caelumDay);
    await prefs.setString(_keyShadow, shadowState);
  }
}
