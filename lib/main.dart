import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fontes empacotadas como asset (assets/fonts/) — o google_fonts resolve
  // cada família/variante do bundle LOCAL antes de tentar a rede, então o app
  // não pisca nem falha as fontes offline. Variantes empacotadas: Roboto
  // Regular/Italic/Medium/SemiBold/Bold, CinzelDecorative Regular/Bold,
  // RobotoMono Regular (cobrem 100% do que a UI usa). O fetch em runtime fica
  // LIGADO de propósito como degradação graciosa: se algum dia surgir uma
  // variante não empacotada (ex.: peso do textTheme default), ela busca/cai
  // pro fallback em vez de crashar. Não desligar sem cobrir todas as variantes.
  GoogleFonts.config.allowRuntimeFetching = true;
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
