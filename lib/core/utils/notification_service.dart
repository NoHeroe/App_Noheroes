import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const int _idMorning   = 1;
  static const int _idAfternoon = 2;
  static const int _idStreak    = 3;
  static const int _idShadow    = 4;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  static Future<void> scheduleDaily() async {
    await _scheduleDailyAt(
      id: _idMorning, hour: 6, minute: 0,
      title: 'Caelum desperta.',
      body: 'Seus rituais aguardam. A sombra observa cada escolha.',
      channelId: 'rituals', channelName: 'Rituais Diários',
    );
    await _scheduleDailyAt(
      id: _idAfternoon, hour: 17, minute: 0,
      title: 'O dia ainda não terminou.',
      body: 'Você ainda tem rituais pendentes em Caelum.',
      channelId: 'rituals', channelName: 'Rituais Diários',
    );
    await _scheduleDailyAt(
      id: _idStreak, hour: 21, minute: 0,
      title: 'Sua sequência está em risco.',
      body: 'Complete pelo menos um ritual antes da meia-noite.',
      channelId: 'streak', channelName: 'Streak',
    );
  }

  static Future<void> notifyShadowState(String state) async {
    final messages = {
      'unstable':  ('Sua sombra está inquieta.',  'Instabilidade detectada. Retome seus rituais.'),
      'chaotic':   ('Sua sombra está caótica.',   'Padrão de falhas detectado. A penalidade se aproxima.'),
      'abyssal':   ('⚠️ Sombra Abissal.',         'Estado crítico. Enfrente-a antes que seja tarde demais.'),
      'ascending': ('Sua sombra ascende.',        'Disciplina recompensada. Bônus de ascensão ativos.'),
    };
    final msg = messages[state];
    if (msg == null) return;
    await _plugin.show(
      id: _idShadow,
      title: msg.$1,
      body: msg.$2,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'shadow', 'Estado da Sombra',
          importance: Importance.high,
          priority: Priority.high,
          color: _shadowColor(state),
        ),
      ),
    );
  }

  static Future<void> cancelStreak() async {
    await _plugin.cancel(id: _idStreak);
  }

  static Future<void> _scheduleDailyAt({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Color _shadowColor(String state) => switch (state) {
    'unstable'  => const Color(0xFFB36B00),
    'chaotic'   => const Color(0xFF8B2020),
    'abyssal'   => const Color(0xFFB33030),
    'ascending' => const Color(0xFF4FA06B),
    _           => const Color(0xFF6B4FA0),
  };
}
