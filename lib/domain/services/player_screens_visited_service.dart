import '../../core/events/app_event_bus.dart';
import '../../core/events/navigation_events.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/player_dao.dart';

/// Sprint 3.3 Etapa 2.1c-γ — tracking de telas visitadas pelo jogador.
///
/// Single writer de `players.screens_visited_keys` (CSV de paths).
/// Chamado pelo router listener (`routerProvider`) em cada navegação.
/// Reads via `hasVisited` / `visitedCount` consumidos pelo
/// `AchievementsService` no trigger `event_screen_visited`.
///
/// ## Decisão arquitetural — CSV em TEXT vs bitmask em INT
///
/// Escolhido CSV pelos motivos:
///   - Set de telas é pequeno (~30 paths) — performance é irrelevante
///   - Self-describing: ler diretamente em backup/dev panel/SQL
///   - Bitmask exigiria mapeamento estático key→bit que rasga ao
///     adicionar tela nova (frágil)
///   - Operações dominantes (`contains`, count) são triviais em CSV
///
/// ## Race condition
///
/// `recordVisit` faz read-modify-write em string CSV. Sem proteção,
/// 2 navegações rapid-fire podem ler antes do primeiro persistir →
/// uma das visitas se perde. Solução: transação Drift atômica.
///
/// ## Sem cache em-memória
///
/// Evita risco de inconsistência entre cache e DB. Performance de
/// transação por navegação é negligível (1 SQL read + 1 write quando
/// é primeira visita; só 1 read em duplicatas).
class PlayerScreensVisitedService {
  final AppDatabase _db;
  final PlayerDao _playerDao;
  final AppEventBus _bus;

  PlayerScreensVisitedService({
    required AppDatabase db,
    required PlayerDao playerDao,
    required AppEventBus bus,
  })  : _db = db,
        _playerDao = playerDao,
        _bus = bus;

  /// Paths excluídos do tracking. Splash + auth boilerplate não
  /// representam "visitas conscientes" pra fins de conquista.
  /// Extensível: adicionar mais paths aqui se necessário.
  static const Set<String> excludedFromTracking = {
    '/',
    '/login',
    '/register',
  };

  /// Registra visita à [screenKey]. Idempotente: visita já registrada
  /// não duplica row, mas ainda publica `ScreenVisited(isFirstVisit:false)`
  /// pra alimentar listeners que precisam reagir a navegações repetidas
  /// (ex: conquistas adicionadas após 1ª visita).
  ///
  /// Path malformado (vazio, só whitespace) é noop silencioso. Path em
  /// [excludedFromTracking] é noop sem emit.
  Future<void> recordVisit(int playerId, String screenKey) async {
    final normalized = _normalize(screenKey);
    if (normalized.isEmpty) return;
    if (excludedFromTracking.contains(normalized)) return;

    bool isFirst = false;
    await _db.transaction(() async {
      final player = await _playerDao.findById(playerId);
      if (player == null) return;
      final visited = parseCSV(player.screensVisitedKeys);
      if (visited.contains(normalized)) {
        isFirst = false;
        return;
      }
      visited.add(normalized);
      await _playerDao.setScreensVisitedKeys(playerId, visited.join(','));
      isFirst = true;
    });

    _bus.publish(ScreenVisited(
      playerId: playerId,
      screenKey: normalized,
      isFirstVisit: isFirst,
    ));
  }

  /// `true` se [screenKey] já está no CSV do jogador.
  Future<bool> hasVisited(int playerId, String screenKey) async {
    final normalized = _normalize(screenKey);
    if (normalized.isEmpty) return false;
    final player = await _playerDao.findById(playerId);
    if (player == null) return false;
    return parseCSV(player.screensVisitedKeys).contains(normalized);
  }

  /// Quantidade de telas distintas visitadas pelo jogador.
  Future<int> visitedCount(int playerId) async {
    final player = await _playerDao.findById(playerId);
    if (player == null) return 0;
    return parseCSV(player.screensVisitedKeys).length;
  }

  /// Lista bruta dos paths visitados — útil pra debug/testes/UI futura.
  Future<List<String>> listVisited(int playerId) async {
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
