import 'dart:async';

import 'package:drift/drift.dart' show Variable;

import '../../core/events/app_event_bus.dart';
import '../../core/events/player_events.dart';
import '../../data/database/app_database.dart';

/// Sprint 3.3 Etapa 2.1c-α — agregador de gasto de moedas all-time.
///
/// **Single writer** de `players.total_gems_spent`. Listener de
/// `GemsSpent` (publicado por 4 sinks: shop, enchant, recalibration,
/// individual_delete) e atualiza o contador atomicamente.
///
/// Após commit, publica [CurrencyStatsUpdated] — `AchievementsService`
/// escuta esse evento (não o `GemsSpent` cru) pra resolver o trigger
/// `event_gems_spent_total` sem race condition. Mesmo padrão do
/// `DailyMissionStatsService` da Etapa 2.1a/b.
///
/// MVP escope: só gems. Gold spent pode entrar em sprint futura
/// reusando esta classe (adicionar coluna + segundo listener).
class PlayerCurrencyStatsService {
  final AppDatabase _db;
  final AppEventBus _bus;

  StreamSubscription<GemsSpent>? _gemsSub;
  bool _started = false;

  PlayerCurrencyStatsService({
    required AppDatabase db,
    required AppEventBus bus,
  })  : _db = db,
        _bus = bus;

  /// Subscreve `GemsSpent`. Idempotente — `start()` 2× vira noop.
  void start() {
    if (_started) return;
    _started = true;
    _gemsSub = _bus.on<GemsSpent>().listen(_onGemsSpent);
  }

  /// Cancela subscription. Idempotente.
  Future<void> dispose() async {
    await _gemsSub?.cancel();
    _gemsSub = null;
    _started = false;
  }

  Future<void> _onGemsSpent(GemsSpent evt) async {
    try {
      await _db.customUpdate(
        'UPDATE players SET total_gems_spent = total_gems_spent + ? '
        'WHERE id = ?',
        variables: [
          Variable.withInt(evt.amount),
          Variable.withInt(evt.playerId),
        ],
        updates: {_db.playersTable},
      );
      _bus.publish(CurrencyStatsUpdated(
        playerId: evt.playerId,
        currencyKind: 'gems_spent',
      ));
    } catch (e) {
      // ignore: avoid_print
      print('[currency-stats] _onGemsSpent falhou pra '
          'player=${evt.playerId}: $e');
    }
  }
}
