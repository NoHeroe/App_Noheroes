import 'dart:async';

import 'package:drift/drift.dart' show Variable;

import '../../../core/events/app_event.dart';
import '../../../core/events/app_event_bus.dart';
import '../../../core/events/daily_mission_events.dart';
import '../../../core/events/diary_events.dart';
import '../../../core/events/mission_events.dart';
import '../../../core/events/reward_events.dart';
import '../../database/app_database.dart';
import 'guild_ascension_service.dart';

/// A.2 — ignição event-driven do motor de ascensão da Guilda.
///
/// Espelha a ESTRUTURA do `WeeklyFactionProgressService`: escuta eventos
/// terminais de gameplay e re-avalia o progresso dos steps do ciclo de
/// ascensão do player contra DADOS VIVOS (via `GuildAscensionService`).
///
/// Diferenças vs weekly:
/// - **NÃO ascende**: o `ascend()` continua MANUAL no botão da
///   `AscensionTab`. Este service só avança `progress`/`completed` dos
///   steps — quando o ciclo fica todo completo, o botão "ASCENDER"
///   aparece, e o jogador decide.
/// - Sem reward/grant aqui (o reward de ascensão é xp/gold do step, fora
///   do escopo da ignição).
///
/// ## Eventos consumidos
/// `DailyMissionCompleted`/`DailyMissionFailed`, `MissionCompleted`,
/// `DiaryEntryCreated`, `RewardGranted`, `AchievementUnlocked`.
///
/// ## Serialização
/// Fila serial `_tail` — garante read-modify-write atômico das rows
/// `guild_ascension_progress` entre eventos concorrentes (igual à weekly).
class GuildAscensionProgressService {
  final AppDatabase _db;
  final AppEventBus _bus;
  final GuildAscensionService _ascension;

  final List<StreamSubscription> _subs = [];
  Future<void> _tail = Future<void>.value();

  GuildAscensionProgressService({
    required AppDatabase db,
    required AppEventBus bus,
    required GuildAscensionService ascension,
  })  : _db = db,
        _bus = bus,
        _ascension = ascension;

  void start() {
    _subs.add(_bus.on<DailyMissionCompleted>().listen(_onEvent));
    _subs.add(_bus.on<DailyMissionFailed>().listen(_onEvent));
    _subs.add(_bus.on<MissionCompleted>().listen(_onEvent));
    _subs.add(_bus.on<DiaryEntryCreated>().listen(_onEvent));
    _subs.add(_bus.on<RewardGranted>().listen(_onEvent));
    _subs.add(_bus.on<AchievementUnlocked>().listen(_onEvent));
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  void _onEvent(AppEvent evt) {
    final playerId = evt.playerId;
    if (playerId == null) return;
    _enqueue(() => _evaluatePlayer(playerId));
  }

  /// Enfileira [task] no encadeamento serial. Erros logados sem quebrar
  /// a fila (próximo task ainda roda).
  Future<void> _enqueue(Future<void> Function() task) {
    final next = _tail.then((_) => task());
    _tail = next.catchError((Object e, StackTrace st) {
      // ignore: avoid_print
      print('[ascension-progress] task falhou: $e\n$st');
    });
    return next;
  }

  /// Re-avaliação on-demand (ex: `AscensionTab.build`). Mesma fila serial.
  Future<void> evaluatePlayer(int playerId) =>
      _enqueue(() => _evaluatePlayer(playerId));

  /// Future que resolve quando a fila atual esvazia (testes).
  Future<void> settle() => _tail;

  Future<void> _evaluatePlayer(int playerId) async {
    final rows = await _db.customSelect(
      'SELECT guild_rank FROM players WHERE id = ? LIMIT 1',
      variables: [Variable.withInt(playerId)],
    ).get();
    if (rows.isEmpty) return;
    final rank = (rows.first.data['guild_rank'] as String?) ?? 'none';
    // Sem rank (não é membro) ou já no topo → nada a avançar.
    if (rank.isEmpty || rank.toLowerCase() == 'none' || rank.toUpperCase() == 'S') {
      return;
    }

    await _ascension.initCycle(playerId, rank);
    // Avança quantos steps estiverem satisfeitos pelos contadores
    // lifetime (ex: player veterano entra num ciclo e completa vários de
    // uma vez). Cap = nº de steps + 1 → evita loop infinito.
    final missions = await _ascension.getMissions(playerId, rank);
    var guard = missions.length + 1;
    while (guard-- > 0) {
      final completed = await _ascension.checkCurrentMission(playerId, rank);
      if (!completed) break;
    }
  }
}
