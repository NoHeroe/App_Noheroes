import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
        onDidReceiveNotificationResponse: _onTap,
      );
      const channel = AndroidNotificationChannel(
        'noheroes_main', 'NoHeroes',
        description: 'Notificações do NoHeroes',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      _initialized = true;
    } catch (_) {}
  }

  static void _onTap(NotificationResponse r) {}

  static Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'noheroes_main', 'NoHeroes',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> sendPatchNote(String version, String notes) =>
      showImmediate(id: 1001, title: 'NoHeroes $version', body: notes, payload: 'patch_notes');

  static Future<void> sendEvent(String name, String desc) =>
      showImmediate(id: 1002, title: 'Evento: $name', body: desc, payload: 'event');

  static Future<void> sendGift(String desc) =>
      showImmediate(id: 1003, title: 'Brinde de Caelum', body: desc, payload: 'gift');

  static Future<void> sendNpcMessage(String npc, String msg) =>
      showImmediate(id: 1004, title: npc, body: msg, payload: 'npc_message');

  static Future<void> sendSystemAlert(String title, String body) =>
      showImmediate(id: 1005, title: title, body: body, payload: 'system');

  static Future<void> sendNpcTimerMessage(String npc, String msg) =>
      showImmediate(id: 2000, title: npc, body: msg, payload: 'npc_timer');

  static Future<void> cancelAll() => _plugin.cancelAll();
  static Future<void> cancel(int id) => _plugin.cancel(id: id);

  static Future<bool> alreadySentToday(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    return prefs.getBool('notif_${type}_${now.year}${now.month}${now.day}') ?? false;
  }

  static Future<void> markSentToday(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setBool('notif_${type}_${now.year}${now.month}${now.day}', true);
  }
}
