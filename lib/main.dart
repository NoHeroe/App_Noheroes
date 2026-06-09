import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Época 2 — full-online: inicializa o cliente Supabase antes de tudo (ADR-0024).
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  await NotificationService.init();
  await NotificationService.scheduleDaily();
  runApp(
    const ProviderScope(
      child: NoHeroesApp(),
    ),
  );
}
