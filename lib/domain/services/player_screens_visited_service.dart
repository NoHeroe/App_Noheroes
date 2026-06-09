import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/events/app_event_bus.dart';
import '../../core/events/navigation_events.dart';
import '../../data/database/daos/player_dao.dart';

/// Sprint 3.3 Etapa 2.1c-γ — tracking de telas visitadas pelo jogador.
///
/// Single writer de `players.screens_visited_keys` (CSV de paths).
/// Chamado pelo router listener (`routerProvider`) em cada navegação.
/// Reads via `hasVisited` / `visitedCount` consumidos pelo
/// `AchievementsService` no trigger `event_screen_visited`.
///
/// ## Race condition
///
/// `recordVisit` é read-modify-write em string CSV. Full-online: a
/// atomicidade (SELECT ... FOR UPDATE + append) vive na RPC
/// `record_screen_visit`, que também faz a normalização e a exclusão de
/// paths. Ela retorna `boolean` = isFirstVisit. NÃO reimplementamos a
/// transação no cliente.
class PlayerScreensVisitedService {
  final SupabaseClient _client;
  final PlayerDao _playerDao;
  final AppEventBus _bus;

  PlayerScreensVisitedService({
    required SupabaseClient client,
    required PlayerDao playerDao,
    required AppEventBus bus,
  })  : _client = client,
        _playerDao = playerDao,
        _bus = bus;

  /// Paths excluídos do tracking. Splash + auth boilerplate não
  /// representam "visitas conscientes" pra fins de conquista.
  /// (Mantido em sincronia com a lista hard-coded na RPC `record_screen_visit`.)
  static const Set<String> excludedFromTracking = {
    '/',
    '/login',
    '/register',
  };

  /// Registra visita à [screenKey] via RPC `record_screen_visit` (atômica:
  /// normaliza, exclui paths boilerplate, append idempotente). A RPC retorna
  /// `isFirstVisit`; publicamos `ScreenVisited` com esse flag mesmo em
  /// visitas repetidas (pra alimentar listeners de navegações repetidas).
  ///
  /// Path malformado/excluído resulta em `isFirstVisit=false` (a RPC já trata
  /// esses casos como no-op). Path vazio é noop silencioso sem emit, igual ao
  /// comportamento original.
  Future<void> recordVisit(String playerId, String screenKey) async {
    final normalized = _normalize(screenKey);
    if (normalized.isEmpty) return;
    if (excludedFromTracking.contains(normalized)) return;

    final res = await _client.rpc('record_screen_visit', params: {
      'p_player': playerId,
      'p_screen_key': screenKey,
    });
    final isFirst = res == true;

    _bus.publish(ScreenVisited(
      playerId: playerId,
      screenKey: normalized,
      isFirstVisit: isFirst,
    ));
  }

  /// `true` se [screenKey] já está no CSV do jogador.
  Future<bool> hasVisited(String playerId, String screenKey) async {
    final normalized = _normalize(screenKey);
    if (normalized.isEmpty) return false;
    final visited = await _fetchVisited(playerId);
    return visited.contains(normalized);
  }

  /// Quantidade de telas distintas visitadas pelo jogador.
  Future<int> visitedCount(String playerId) async {
    return (await _fetchVisited(playerId)).length;
  }

  /// Lista bruta dos paths visitados — útil pra debug/testes/UI futura.
  Future<List<String>> listVisited(String playerId) async {
    return _fetchVisited(playerId);
  }

  /// Lê o CSV `screens_visited_keys` da própria row e parseia.
  Future<List<String>> _fetchVisited(String playerId) async {
    final player = await _playerDao.findById(playerId);
    if (player == null) return const [];
    return parseCSV(player.screensVisitedKeys);
  }

  /// Parse tolerante de CSV: split por vírgula, trim, descarta vazias.
  static List<String> parseCSV(String raw) {
    if (raw.isEmpty) return [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Normaliza path: trim + remove query (`?...`) + remove fragment
  /// (`#...`). Mantém leading slash.
  static String _normalize(String raw) {
    var s = raw.trim();
    final qIdx = s.indexOf('?');
    if (qIdx >= 0) s = s.substring(0, qIdx);
    final fIdx = s.indexOf('#');
    if (fIdx >= 0) s = s.substring(0, fIdx);
    return s;
  }
}
