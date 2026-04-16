import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/local/notification_service.dart';

class _NotifItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime date;
  final bool read;

  const _NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
    required this.read,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'body': body,
    'type': type, 'date': date.toIso8601String(), 'read': read,
  };

  factory _NotifItem.fromJson(Map<String, dynamic> j) => _NotifItem(
    id: j['id'], title: j['title'], body: j['body'],
    type: j['type'], date: DateTime.parse(j['date']), read: j['read'],
  );

  _NotifItem copyWith({bool? read}) => _NotifItem(
    id: id, title: title, body: body, type: type, date: date,
    read: read ?? this.read,
  );
}

// Notificações de exemplo para mostrar funcionamento
final _seedNotifications = [
  _NotifItem(
    id: 'welcome',
    title: 'Bem-vindo ao NoHeroes',
    body: 'Sua jornada em Caelum começou. Explore o Santuário e complete suas primeiras missões.',
    type: 'system',
    date: DateTime.now().subtract(const Duration(days: 1)),
    read: false,
  ),
  _NotifItem(
    id: 'v022_patch',
    title: 'NoHeroes v0.22 — Patch Notes',
    body: 'Missões de classe diárias, Missões de facção semanais, Aba personagem com equipamentos, Teste de Ascensão da Guilda, Caminho do Lobo Solitário e mais.',
    type: 'patch',
    date: DateTime.now().subtract(const Duration(hours: 2)),
    read: false,
  ),
];

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<_NotifItem> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_notifications');
    List<_NotifItem> items = [];

    if (raw != null) {
      final list = jsonDecode(raw) as List;
      items = list.map((j) => _NotifItem.fromJson(j)).toList();
    }

    // Adiciona seeds se não existirem
    for (final seed in _seedNotifications) {
      if (!items.any((n) => n.id == seed.id)) {
        items.insert(0, seed);
      }
    }

    // Salva
    await prefs.setString('app_notifications',
        jsonEncode(items.map((n) => n.toJson()).toList()));

    // Solicita permissão se necessário
    await NotificationService.init();

    setState(() {
      _notifications = items..sort((a, b) => b.date.compareTo(a.date));
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final updated = _notifications.map((n) => n.copyWith(read: true)).toList();
    await prefs.setString('app_notifications',
        jsonEncode(updated.map((n) => n.toJson()).toList()));
    setState(() => _notifications = updated);
  }

  Future<void> _markRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = _notifications
        .map((n) => n.id == id ? n.copyWith(read: true) : n)
        .toList();
    await prefs.setString('app_notifications',
        jsonEncode(updated.map((n) => n.toJson()).toList()));
    setState(() => _notifications = updated);
  }

  // Adiciona notificação nova (chamado de fora)
  static Future<void> addNotification({
    required String id,
    required String title,
    required String body,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_notifications');
    final items = raw != null
        ? (jsonDecode(raw) as List).map((j) => _NotifItem.fromJson(j)).toList()
        : <_NotifItem>[];

    if (items.any((n) => n.id == id)) return;

    items.insert(0, _NotifItem(
      id: id, title: title, body: body,
      type: type, date: DateTime.now(), read: false,
    ));

    await prefs.setString('app_notifications',
        jsonEncode(items.map((n) => n.toJson()).toList()));
  }

  IconData _typeIcon(String type) => switch (type) {
        'patch'   => Icons.system_update_outlined,
        'event'   => Icons.celebration_outlined,
        'gift'    => Icons.card_giftcard_outlined,
        'npc'     => Icons.person_outline,
        'system'  => Icons.info_outline,
        'warning' => Icons.warning_amber_outlined,
        _         => Icons.notifications_outlined,
      };

  Color _typeColor(String type) => switch (type) {
        'patch'   => AppColors.purple,
        'event'   => AppColors.gold,
        'gift'    => AppColors.shadowAscending,
        'npc'     => AppColors.mp,
        'system'  => AppColors.textSecondary,
        'warning' => AppColors.hp,
        _         => AppColors.textMuted,
      };

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Text('NOTIFICAÇÕES',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 15, color: AppColors.gold, letterSpacing: 2)),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.hp.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.hp.withValues(alpha: 0.4)),
                      ),
                      child: Text('$unread',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: AppColors.hp)),
                    ),
                  ],
                  const Spacer(),
                  if (unread > 0)
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Text('Marcar todas lidas',
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: AppColors.textMuted)),
                    ),
                ],
              ),
            ),

            // Lista
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold))
                  : _notifications.isEmpty
                      ? Center(
                          child: Text('Nenhuma notificação.',
                              style: GoogleFonts.roboto(
                                  color: AppColors.textMuted)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                          itemCount: _notifications.length,
                          itemBuilder: (ctx, i) {
                            final n = _notifications[i];
                            final color = _typeColor(n.type);
                            return GestureDetector(
                              onTap: () => _markRead(n.id),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: n.read
                                      ? AppColors.surface
                                      : color.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: n.read
                                        ? AppColors.border
                                        : color.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color.withValues(alpha: 0.1),
                                        border: Border.all(
                                            color: color.withValues(alpha: 0.3)),
                                      ),
                                      child: Icon(_typeIcon(n.type),
                                          color: color, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                              child: Text(n.title,
                                                  style: GoogleFonts.cinzelDecorative(
                                                      fontSize: 11,
                                                      color: n.read
                                                          ? AppColors.textSecondary
                                                          : AppColors.textPrimary)),
                                            ),
                                            Text(_timeAgo(n.date),
                                                style: GoogleFonts.roboto(
                                                    fontSize: 9,
                                                    color: AppColors.textMuted)),
                                          ]),
                                          const SizedBox(height: 4),
                                          Text(n.body,
                                              style: GoogleFonts.roboto(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary,
                                                  height: 1.4),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    if (!n.read) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8, height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
