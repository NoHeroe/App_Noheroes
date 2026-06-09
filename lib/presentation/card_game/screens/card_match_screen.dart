import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_game.dart';
import '../deck_repository.dart';

/// Prévia funcional da partida do Modo Cartas (ACDA).
///
/// Carrega o catálogo + o DECK ATIVO do jogador (lado A). O lado B é um deck
/// de BOT (preset determinístico montado do catálogo). Roda o engine até o fim
/// (bot joga os dois lados por ora), coletando um log turno a turno. A partida
/// jogável interativa (com tabuleiro Flame) vem depois.
class CardMatchScreen extends ConsumerStatefulWidget {
  const CardMatchScreen({super.key, required this.mode});

  final String mode;

  @override
  ConsumerState<CardMatchScreen> createState() => _CardMatchScreenState();
}

class _CardMatchScreenState extends ConsumerState<CardMatchScreen> {
  late Future<_SimResult> _future;
  int _seed = 0;

  @override
  void initState() {
    super.initState();
    _future = _runMatch(_seed);
  }

  void _newMatch() {
    setState(() {
      _seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
      _future = _runMatch(_seed);
    });
  }

  Future<_SimResult> _runMatch(int seed) async {
    final catalog = await CardCatalog.load();

    // Lado A = deck ATIVO do jogador (resolvido do catálogo). Sem deck válido
    // (acesso direto / sem login) → fallback pro preset de bot, sem crashar.
    final loadoutA = await _resolvePlayerLoadout(catalog) ??
        _buildLoadout(catalog, offset: 0);
    // Lado B = deck de BOT (preset determinístico).
    final loadoutB = _buildLoadout(catalog, offset: 9);

    const engine = CardBattleEngine();
    var state = engine.start(loadoutA, loadoutB, seed: seed);

    final log = <String>[];
    log.add('Partida iniciada (seed $seed). '
        'Lado ${_sideLabel(state.activeSide)} começa.');

    var guard = 0;
    while (!state.isOver && guard++ < 200) {
      final actor = state.activeSide;
      final actions = engine.botActions(state);
      for (final action in actions) {
        state = engine.apply(state, action);
      }
      state = engine.endTurn(state);
      log.add(_turnLine(state, actor));
    }

    if (state.isOver && state.winner != null) {
      log.add('— Fim — Vencedor: Lado ${_sideLabel(state.winner!)}.');
    } else {
      log.add('— Encerrado por limite de segurança (sem vencedor definido).');
    }

    return _SimResult(
      log: log,
      winner: state.winner,
      turns: state.turn,
    );
  }

  /// Resolve o DECK ATIVO do jogador num [CardLoadout]. Devolve null se não
  /// houver deck válido (sem login, sem deck, deck incompleto, ou algum id que
  /// não existe mais no catálogo) — o caller faz fallback pro preset de bot.
  Future<CardLoadout?> _resolvePlayerLoadout(CardCatalog catalog) async {
    PlayerDeck? deck;
    try {
      deck = await ref.read(activeDeckProvider.future);
    } catch (_) {
      deck = null;
    }
    if (deck == null || !deck.isValid) return null;

    final creatureById = {for (final c in catalog.creatures) c.id: c};
    final relicById = {for (final r in catalog.relics) r.id: r};

    final creatures = <CreatureCard>[];
    for (final id in deck.creatureIds) {
      final c = creatureById[id];
      if (c == null) return null; // id órfão → fallback seguro.
      creatures.add(c);
    }
    final relics = <RelicCard>[];
    for (final id in deck.relicIds) {
      final r = relicById[id];
      if (r == null) return null;
      relics.add(r);
    }

    if (creatures.length != 9 || relics.length != 9) return null;
    return CardLoadout(creatures: creatures, relics: relics);
  }

  /// Monta um loadout válido: pega 9 criaturas (a partir de [offset]) e 9
  /// relíquias compatíveis com alguma dessas criaturas (ou universais),
  /// completando com quaisquer outras se faltar.
  CardLoadout _buildLoadout(CardCatalog catalog, {required int offset}) {
    final creatures = <CreatureCard>[];
    for (var i = 0; i < 9; i++) {
      creatures.add(catalog.creatures[(offset + i) % catalog.creatures.length]);
    }

    final relics = <RelicCard>[];
    final used = <String>{};

    bool fitsAny(RelicCard r) => creatures.any((c) => r.isCompatibleWith(c));

    // 1ª passada: relíquias compatíveis com o time (ou universais).
    for (final r in catalog.relics) {
      if (relics.length >= 9) break;
      if (used.contains(r.id)) continue;
      if (fitsAny(r)) {
        relics.add(r);
        used.add(r.id);
      }
    }
    // 2ª passada: completa com quaisquer relíquias restantes.
    for (final r in catalog.relics) {
      if (relics.length >= 9) break;
      if (used.contains(r.id)) continue;
      relics.add(r);
      used.add(r.id);
    }

    return CardLoadout(
      creatures: creatures,
      relics: relics.take(9).toList(),
    );
  }

  String _sideLabel(SideId id) => id == SideId.a ? 'A' : 'B';

  String _turnLine(MatchState s, SideId actor) {
    final a = s.sideA;
    final b = s.sideB;
    return 'Turno ${s.turn} — jogou ${_sideLabel(actor)} · '
        'A: ${a.creaturesInPlay.length} em jogo/${a.remainingCreatureCount} vivas · '
        'B: ${b.creaturesInPlay.length} em jogo/${b.remainingCreatureCount} vivas';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [Color(0xFF1A0020), Color(0xFF0A000A), AppColors.black],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                _banner(),
                Expanded(
                  child: FutureBuilder<_SimResult>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.purple),
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return _errorBody(snap.error.toString());
                      }
                      return _resultBody(snap.data!);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/battle'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.surface,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRÉVIA DA PARTIDA',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: AppColors.purpleLight,
                        letterSpacing: 2)),
                Text('UI completa em construção',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _banner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined,
              color: AppColors.purpleLight, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Lado A = seu deck · Lado B = bot. Espectador (IA joga ambos). A partida jogável vem depois.',
              style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.purpleLight,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBody(_SimResult result) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: result.log.length,
            itemBuilder: (context, i) {
              final line = result.log[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  line,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
        _winnerBar(result),
        _actionsBar(context),
      ],
    );
  }

  Widget _winnerBar(_SimResult result) {
    final hasWinner = result.winner != null;
    final color = hasWinner ? AppColors.gold : AppColors.textMuted;
    final label = hasWinner
        ? 'Vencedor: Lado ${_sideLabel(result.winner!)} · ${result.turns} turnos'
        : 'Sem vencedor definido · ${result.turns} turnos';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(hasWinner ? Icons.emoji_events_outlined : Icons.info_outline,
              color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 12, color: color, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _actionsBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/battle'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Voltar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _newMatch,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.purple.withValues(alpha: 0.6)),
                foregroundColor: AppColors.purpleLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Nova partida'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBody(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.hp),
          const SizedBox(height: 16),
          Text('Falha ao carregar a partida',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 14, color: AppColors.hp, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(message,
              style:
                  GoogleFonts.robotoMono(fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.go('/battle'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }
}

class _SimResult {
  const _SimResult({
    required this.log,
    required this.winner,
    required this.turns,
  });

  final List<String> log;
  final SideId? winner;
  final int turns;
}
