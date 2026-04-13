import 'package:shared_preferences/shared_preferences.dart';

class NpcSession {
  static const _key = 'npc_last_shown_day';

  static Future<bool> shouldShow(int caelumDay) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_key) ?? -1;
    return last != caelumDay;
  }

  static Future<void> markShown(int caelumDay) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, caelumDay);
  }
}
