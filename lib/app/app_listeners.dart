import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/events/player_events.dart';
import '../data/database/app_database.dart';
import '../data/database/daos/player_dao.dart';
import 'providers.dart';

/// Sprint 3.4 Etapa A hotfix — sincronização global de `LevelUp` events
/// pra `currentPlayerProvider`.
///
/// ## Motivação (lição da Sprint 3.4 hotfix Etapa A)
///
/// O projeto tem **dois** providers que expõem o player na UI:
///
/// - `currentPlayerProvider` — `StateProvider<PlayersTableData?>`. Setado
///   manualmente via `state = fresh`. Usado em ~20 lugares pela UI.
/// - `playerStreamProvider` — `StreamProvider` (Drift `watchSingleOrNull`).
///   Reativo a mudanças no DB. Usado por `stat_bars_row` (XP bar).
///
/// `PlayerDao.addXp` (chamado por `RewardGrantService.grant`/
/// `grantAchievement` + 3 paths em `daily_mission_progress_service`)
/// escreve `level + xp + xpToNext + ...` no DB e emite `LevelUp` event.
/// `playerStreamProvider` reflete a mudança instantaneamente; mas
/// `currentPlayerProvider` só era atualizado em paths específicos
/// (notifier de `/quests`, telas individuais), deixando outros paths
/// com `currentPlayerProvider` stale. Sintoma: XP bar reseta visualmente
/// (do stream) mas elementos como "NÍVEL X" do `caelum_day_banner`
/// (lendo do StateProvider) ficam mostrando level antigo.
///
/// Solução escolhida: listener global que escuta `LevelUp` no bus, lê
/// fresh do DB via `PlayerDao.findById`, e seta `currentPlayerProvider.
/// state = fresh`. Pattern espelha `AchievementToastListener` (Sprint
/// 3.3 Etapa Final-B): viver enquanto o app vive, registrar subscription
/// na inicialização eager via `ref.watch` em `app.dart`.
///
/// **Não publica novo evento** — apenas atualiza estado. Evita loop
/// (R1 do plan-first do hotfix).
///
/// **Mantém regra ADR-0016:** camada `data` (PlayerDao) continua
/// desacoplada do Riverpod. Esta camada `app` é quem orquestra.
class PlayerStateSyncService {
  final Ref _ref;
  StreamSubscription<LevelUp>? _sub;

  PlayerStateSyncService(this._ref);

  void start() {
    final bus = _ref.read(appEventBusProvider);
    _sub = bus.on<LevelUp>().listen(_onLevelUp);
  }

  Future<void> _onLevelUp(LevelUp evt) async {
    // Época 2 (full-online): refetch do currentPlayer no Supabase pelo seu
    // próprio id (uuid). Ignora evt.playerId (a sync é sempre do jogador da
    // sessão). Idempotência preservada: só seta se level/xp/xpToNext mudaram.
    final current = _ref.read(currentPlayerProvider);
    if (current == null) return;
    final fresh = await _ref.read(playerRepositoryProvider).fetchById(current.id);
    if (fresh == null) return;
    if (current.level == fresh.level &&
        current.xp == fresh.xp &&
        current.xpToNext == fresh.xpToNext) {
      return;
    }
    _ref.read(currentPlayerProvider.notifier).state = fresh;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}

/// Provider eager — instancia o sync e registra o listener.
/// `app.dart` faz `ref.watch(playerStateSyncServiceProvider)` no build
/// pra garantir bootstrap.
final playerStateSyncServiceProvider =
    Provider<PlayerStateSyncService>((ref) {
  final svc = PlayerStateSyncService(ref);
  svc.start();
  ref.onDispose(svc.stop);
  return svc;
});

/// Sprint 3.4 Etapa A hotfix — backfill defensivo do `xpToNext` legacy.
///
/// Players criados antes do fix têm `xpToNext=100` (DB default) mas
/// `XpCalculator.xpToNextLevel(1)=200`. O bug não impede progressão
/// (próximo `addXp` recalcula via XpCalculator quando newLevel é 2+),
/// mas faz a XP bar parecer "max=100" no early game.
///
/// Backfill: pra players com `level=1 AND xpToNext=100`, atualiza pra
/// 200. Idempotente (depois de rodar uma vez, condição não bate mais).
///
/// Documenta como "fix preventivo Sprint 3.4 hotfix" no log pra
/// rastreio futuro caso apareça em postmortem.
Future<void> applyXpToNextBackfill(
    PlayerDao dao, PlayersTableData player) async {
  if (player.level == 1 && player.xpToNext == 100) {
    await dao.setXpToNext(player.id, 200);
    // ignore: avoid_print
    print('[xp-backfill] player=${player.id} xpToNext 100 → 200 '
        '(fix preventivo Sprint 3.4 hotfix Etapa A)');
  }
}
