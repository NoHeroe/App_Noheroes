import 'app_event.dart';

/// Sprint 3.3 Etapa 2.1c-γ — eventos de navegação.
///
/// Emitido pelo `PlayerScreensVisitedService.recordVisit` após persistir
/// (ou detectar duplicata em) `players.screens_visited_keys`. Disparado
/// pelo router listener (`routerProvider`) que escuta
/// `routerDelegate.currentConfiguration.uri.path`.
///
/// Consumidor canônico: `AchievementsService` pra trigger
/// `event_screen_visited`. Outros listeners podem se subscrever sem
/// refactor.
class ScreenVisited extends AppEvent {
  @override
  final int playerId;

  /// Path normalizado da rota visitada — leading slash, sem query
  /// params, sem fragment. Ex: `/perfil`, `/shops`, `/shop/blacksmith`.
  final String screenKey;

  /// `true` na primeira visita registrada do path (não estava no CSV
  /// ainda). `false` em visitas subsequentes.
  ///
  /// Listeners de conquista podem checar `screenKey` específico **ou**
  /// `visitedCount` total — ambos os casos disparam mesmo com
  /// `isFirstVisit=false`, porque conquistas adicionadas após 1ª
  /// visita ainda devem unlock no próximo evento.
  final bool isFirstVisit;

  ScreenVisited({
    required this.playerId,
    required this.screenKey,
    required this.isFirstVisit,
    super.at,
  });

  @override
  String toString() =>
      'ScreenVisited(player=$playerId, key=$screenKey, '
      'first=$isFirstVisit)';
}
