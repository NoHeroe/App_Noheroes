import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/tutorial_service.dart';
import '../../../data/services/card_match_reward_service.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_game.dart';
import '../../shared/tutorial_manager.dart';
import '../deck_repository.dart';
import '../pve_match_controller.dart';
import '../widgets/game_card_face.dart';

/// PARTIDA JOGÁVEL do Modo Cartas (ACDA) — PvE interativo.
///
/// O jogador (lado A, deck ATIVO) joga contra o bot (lado B, preset
/// determinístico do catálogo). Toda a orquestração vive no
/// [PveMatchController]; esta tela só renderiza o `PveMatchUiState` e
/// dispara ações.
///
/// Fluxo de toque: carta do pool → seleciona → criatura: lanes livres
/// acendem (tap joga); relíquia: alvos compatíveis acendem (tap equipa).
/// Carta selecionada também pode ser sacrificada (1×/turno).
class CardMatchScreen extends ConsumerStatefulWidget {
  const CardMatchScreen({super.key, required this.mode});

  final String mode;

  @override
  ConsumerState<CardMatchScreen> createState() => _CardMatchScreenState();
}

enum _BootStatus { loading, noDeck, error, ready }

class _CardMatchScreenState extends ConsumerState<CardMatchScreen> {
  _BootStatus _boot = _BootStatus.loading;
  String? _bootError;
  CardLoadout? _playerLoadout;
  CardLoadout? _botLoadout;

  // Recompensa de partida (ponto #1): concedida 1× ao terminar; exibida no
  // overlay de fim. `_rewardRequested` evita conceder de novo no rebuild.
  CardMatchReward? _reward;
  bool _rewardRequested = false;

  // Tutorial guiado da 1ª partida (ponto #2): bot fraco + diálogos. Detectado
  // no boot pra montar o bot fácil; o tutorial roda por cima da partida.
  bool _isTutorial = false;

  @override
  void initState() {
    super.initState();
    _bootMatch();
  }

  // ---------------------------------------------------------------------------
  // Boot: catálogo + deck ativo do jogador + preset do bot
  // ---------------------------------------------------------------------------

  Future<void> _bootMatch() async {
    setState(() {
      _boot = _BootStatus.loading;
      _bootError = null;
    });
    try {
      final catalog = await CardCatalog.load();
      final player = await _resolvePlayerLoadout(catalog);
      if (!mounted) return;
      if (player == null) {
        setState(() => _boot = _BootStatus.noDeck);
        return;
      }

      // Tutorial guiado da 1ª partida (1× por jogador): bot FRACO + diálogos.
      final playerId = ref.read(currentPlayerProvider)?.id;
      _isTutorial = playerId != null &&
          await TutorialService.shouldShow(
              playerId, TutorialPhase.phase14_cardgame);
      if (!mounted) return;

      _playerLoadout = player;
      _botLoadout = _isTutorial
          ? _buildEasyBotLoadout(catalog)
          : _buildBotLoadout(catalog);
      setState(() => _boot = _BootStatus.ready);
      _startMatch();

      if (_isTutorial && playerId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            TutorialManager.cardGameIntro(context, playerId: playerId);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _boot = _BootStatus.error;
        _bootError = e.toString();
      });
    }
  }

  void _startMatch() {
    // Nova partida: zera o estado de recompensa do round anterior.
    _reward = null;
    _rewardRequested = false;
    final seed = math.Random().nextInt(0x7fffffff);
    ref.read(pveMatchControllerProvider.notifier).startMatch(
          _playerLoadout!,
          _botLoadout!,
          seed: seed,
        );
  }

  /// Concede a recompensa de partida (1×) quando termina. Server-authoritative:
  /// só informa win/loss; a RPC decide os valores. Depois refaz o fetch do
  /// player pra XP/gold/level refletirem na HUD.
  Future<void> _grantReward(bool won) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    try {
      final reward = await ref
          .read(cardMatchRewardServiceProvider)
          .grant(playerId: player.id, won: won);
      if (!mounted) return;
      setState(() => _reward = reward);
      // Refresh do player (XP/gold mudam mesmo sem level-up — o listener de
      // LevelUp só cobre subida de nível).
      final fresh = await ref.read(playerRepositoryProvider).fetchById(player.id);
      if (fresh != null && mounted) {
        ref.read(currentPlayerProvider.notifier).state = fresh;
      }
    } catch (_) {
      // Recompensa é best-effort: falha de rede não trava a tela de fim.
    }
  }

  /// Resolve o DECK ATIVO do jogador num [CardLoadout]. null = sem deck
  /// válido (sem login, sem deck, deck incompleto ou id órfão) — a tela
  /// mostra o convite pro Construtor de Deck.
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
      if (c == null) return null;
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

  /// Deck do BOT: preset determinístico montado do catálogo (mesma montagem
  /// da prévia: 9 criaturas a partir do offset 9 + relíquias compatíveis).
  CardLoadout _buildBotLoadout(CardCatalog catalog, {int offset = 9}) {
    final creatures = <CreatureCard>[];
    for (var i = 0; i < 9; i++) {
      creatures.add(catalog.creatures[(offset + i) % catalog.creatures.length]);
    }

    final relics = <RelicCard>[];
    final used = <String>{};
    bool fitsAny(RelicCard r) => creatures.any((c) => r.isCompatibleWith(c));

    for (final r in catalog.relics) {
      if (relics.length >= 9) break;
      if (used.contains(r.id)) continue;
      if (fitsAny(r)) {
        relics.add(r);
        used.add(r.id);
      }
    }
    for (final r in catalog.relics) {
      if (relics.length >= 9) break;
      if (used.contains(r.id)) continue;
      relics.add(r);
      used.add(r.id);
    }

    return CardLoadout(creatures: creatures, relics: relics.take(9).toList());
  }

  /// Bot do TUTORIAL (1ª partida): as 9 criaturas mais FRACAS do catálogo
  /// (menor atk+hp) + relíquias compatíveis. Partida fácil pra primeira
  /// experiência guiada.
  CardLoadout _buildEasyBotLoadout(CardCatalog catalog) {
    final creatures = List<CreatureCard>.from(catalog.creatures)
      ..sort((a, b) => (a.atk + a.hp).compareTo(b.atk + b.hp));
    final weakest = creatures.take(9).toList();

    final relics = <RelicCard>[];
    final used = <String>{};
    bool fitsAny(RelicCard r) => weakest.any((c) => r.isCompatibleWith(c));
    for (final r in catalog.relics) {
      if (relics.length >= 9) break;
      if (used.contains(r.id)) continue;
      if (fitsAny(r)) {
        relics.add(r);
        used.add(r.id);
      }
    }
    for (final r in catalog.relics) {
      if (relics.length >= 9) break;
      if (used.contains(r.id)) continue;
      relics.add(r);
      used.add(r.id);
    }
    return CardLoadout(creatures: weakest, relics: relics.take(9).toList());
  }

  // ---------------------------------------------------------------------------
  // Navegação / diálogos
  // ---------------------------------------------------------------------------

  Future<void> _onBackPressed() async {
    final ui = ref.read(pveMatchControllerProvider);
    final inProgress = ui.match != null &&
        ui.phase != PveMatchPhase.idle &&
        ui.phase != PveMatchPhase.finished;
    if (!inProgress) {
      if (mounted) context.go('/battle');
      return;
    }
    final quit = await _confirmDialog(
      title: 'Desistir da partida?',
      message: 'Sair agora conta como derrota.',
      confirmLabel: 'Desistir',
      confirmColor: AppColors.hp,
    );
    if (quit == true && mounted) {
      ref.read(pveMatchControllerProvider.notifier).forfeit();
      context.go('/battle');
    }
  }

  Future<void> _onEndTurnPressed() async {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    final ui = ref.read(pveMatchControllerProvider);
    if (ui.phase != PveMatchPhase.playerTurn) return;

    final hasCreature = ui.playerBoard?.hasCreatureInPlay ?? false;
    if (!hasCreature) {
      final go = await _confirmDialog(
        title: 'Encerrar sem criaturas?',
        message: 'Você terminará o turno sem criaturas no tabuleiro e '
            'perderá 1 carta aleatória. Continuar?',
        confirmLabel: 'Continuar',
        confirmColor: AppColors.gold,
      );
      if (go != true) return;
    }
    controller.endPlayerTurn();
  }

  /// Recuar uma criatura própria pra mão (custo kReturnVoluntaryCost; não
  /// encerra a vez). Confirma antes; avisa se faltam cristais.
  Future<void> _confirmReturnToHand(CreatureInPlay c) async {
    final crystals =
        ref.read(pveMatchControllerProvider).playerBoard?.crystals ?? 0;
    if (crystals < kReturnVoluntaryCost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(milliseconds: 1400),
          backgroundColor: AppColors.surfaceVeil,
          content: Text(
            'Cristais insuficientes para recuar (precisa de $kReturnVoluntaryCost).',
            style: GoogleFonts.roboto(color: AppColors.textPrimary, fontSize: 12),
          ),
        ));
      }
      return;
    }
    final ok = await _confirmDialog(
      title: 'Recuar pra mão?',
      message: '${c.card.nome} volta pra sua mão por $kReturnVoluntaryCost '
          'cristais. Relíquias equipadas são descartadas.',
      confirmLabel: 'Recuar',
      confirmColor: AppColors.mp,
    );
    if (ok == true) {
      ref.read(pveMatchControllerProvider.notifier).returnToHand(c.instanceId);
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(title,
            style: GoogleFonts.cinzelDecorative(
                fontSize: 15, color: AppColors.textPrimary)),
        content: Text(message,
            style: GoogleFonts.roboto(
                fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: GoogleFonts.roboto(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel,
                style: GoogleFonts.roboto(
                    color: confirmColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showFullLog(List<MatchLogEntry> log) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceVeil,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REGISTRO DA PARTIDA',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 13,
                      color: AppColors.purpleLight,
                      letterSpacing: 2)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  reverse: true,
                  shrinkWrap: true,
                  itemCount: log.length,
                  itemBuilder: (_, i) {
                    final entry = log[log.length - 1 - i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: _logLine(entry),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(pveMatchControllerProvider);

    // Concede a recompensa 1× quando a partida termina (pós-frame pra não
    // mutar provider durante o build).
    if (ui.isFinished && _boot == _BootStatus.ready && !_rewardRequested) {
      _rewardRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _grantReward(ui.playerWon == true);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.4,
                  colors: [
                    Color(0xFF1A0020),
                    Color(0xFF0A000A),
                    AppColors.black,
                  ],
                ),
              ),
            ),
            SafeArea(child: _body(ui)),
            // Botões laterais no MEIO (banda entre os dois tabuleiros): voltar à
            // esquerda, encerrar jogada (espadas cruzadas) à direita.
            if (_boot == _BootStatus.ready && ui.match != null && !ui.isFinished)
              ...[
              Align(
                alignment: const Alignment(-1, -0.16),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sideBackButton(),
                      const SizedBox(width: 8),
                      _logButton(ui),
                    ],
                  ),
                ),
              ),
              // Turno no MEIO, entre desistir (esq) e encerrar (dir).
              Align(
                alignment: const Alignment(0, -0.16),
                child: _turnIndicator(ui),
              ),
              Align(
                alignment: const Alignment(1, -0.16),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _endTurnButton(ui),
                ),
              ),
            ],
            if (ui.isFinished && _boot == _BootStatus.ready)
              _matchOverOverlay(ui),
          ],
        ),
      ),
    );
  }

  Widget _body(PveMatchUiState ui) {
    switch (_boot) {
      case _BootStatus.loading:
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
          ),
        );
      case _BootStatus.noDeck:
        return _noDeckBody();
      case _BootStatus.error:
        return _errorBody(_bootError ?? 'Erro desconhecido');
      case _BootStatus.ready:
        if (ui.match == null) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
            ),
          );
        }
        return _matchBody(ui);
    }
  }

  // ---------------------------------------------------------------------------
  // Corpo da partida
  // ---------------------------------------------------------------------------

  Widget _matchBody(PveMatchUiState ui) {
    final bot = ui.botBoard!;
    final player = ui.playerBoard!;
    // Bloqueado durante o replay/bot E quando playLocked (troca com tabuleiro
    // cheio → só resta encerrar o turno). O botão de encerrar fica ativo à parte.
    final interactive =
        ui.phase == PveMatchPhase.playerTurn && !ui.playLocked;

    // Tabuleiro em FOCO. Banda central (entre os dois lados) guarda os botões
    // laterais (sobrepostos no build). Sem log no meio. Mão = baralho aberto.
    final selectedCard = _selectedPoolCard(ui);

    return Column(
      children: [
        _botInfoBar(bot, ui),
        // Tabuleiros AGRUPADOS no centro (mais perto um do outro): a banda
        // central de 60px guarda os botões laterais; o conjunto inteiro fica
        // centralizado verticalmente em vez de espalhado nas bordas.
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // O tabuleiro do OPONENTE sobe um pouco (CEO), sem mexer no resto:
              // Transform.translate não afeta o layout/centralização.
              Transform.translate(
                offset: const Offset(0, -18),
                child: _lanesRow(ui, bot, isPlayerSide: false),
              ),
              const SizedBox(height: 60), // banda central (botões voltar/encerrar)
              // O tabuleiro do JOGADOR desce um pouco (CEO) sem mexer no do bot:
              // Transform.translate não afeta o layout/centralização.
              Transform.translate(
                offset: const Offset(0, 20),
                child: AbsorbPointer(
                  absorbing: !interactive,
                  child: _lanesRow(ui, player, isPlayerSide: true),
                ),
              ),
            ],
          ),
        ),
        // Mão sobe e desloca levemente pra direita (CEO) + menu de ação
        // sobreposto (flutua sobre o topo do leque sem empurrar o HUD).
        Transform.translate(
          offset: const Offset(16, -24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AbsorbPointer(
                absorbing: !interactive,
                child: Opacity(
                  opacity: interactive ? 1 : 0.55,
                  child: _handFan(ui, player),
                ),
              ),
              if (interactive && selectedCard != null)
                Positioned(
                  top: -10,
                  left: 0,
                  right: 0,
                  child: Center(child: _actionOverlay(ui, selectedCard)),
                ),
            ],
          ),
        ),
        // HUD inferior ornamentado (moldura): monstros (esq) · cristal (centro)
        // · itens (dir). Centralizado no rodapé da página.
        _bottomHud(ui, player),
      ],
    );
  }

  /// Indicador de TURNO no centro da banda (entre desistir e encerrar). Na vez
  /// da IA, mostra um spinner.
  Widget _turnIndicator(PveMatchUiState ui) {
    final turn = ui.match?.turn ?? 0;
    final botPlaying = ui.phase == PveMatchPhase.botTurn ||
        ui.phase == PveMatchPhase.resolving;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('TURNO',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 8, color: AppColors.textMuted, letterSpacing: 2)),
        Text('$turn',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        if (botPlaying)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 9,
                  height: 9,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.purple)),
                ),
                const SizedBox(width: 4),
                Text('IA',
                    style: GoogleFonts.roboto(
                        fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ),
      ],
    );
  }

  /// HUD inferior COMPACTO e centralizado (sem moldura por ora): monstros ·
  /// cristal facetado (com borda) · itens — todos juntos no centro do rodapé.
  Widget _bottomHud(PveMatchUiState ui, BoardSide player) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 10),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _hudCounter(Icons.pets, '${player.availableCreatureCount}'),
            const SizedBox(width: 14),
            CrystalGem(value: player.crystals, size: 42),
            const SizedBox(width: 14),
            _hudCounter(Icons.auto_awesome, '${player.availableRelicCount}'),
          ],
        ),
      ),
    );
  }

  /// Contador branco (monstros / itens): ícone EM CIMA, número EMBAIXO.
  Widget _hudCounter(IconData icon, String value, {double size = 18}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size, color: Colors.white),
        Text(value,
            style: GoogleFonts.cinzelDecorative(
                fontSize: size * 0.85,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ],
    );
  }

  Widget _botInfoBar(BoardSide bot, PveMatchUiState ui) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: SizedBox(
        height: 38,
        child: Stack(
          children: [
            // Caixinha ISOLADA do bot: ícone + título IA (fica à esquerda).
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVeil,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderViolet),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.smart_toy_outlined,
                        color: AppColors.conceptCorrompido, size: 16),
                    const SizedBox(width: 6),
                    Text('IA',
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            // Mini-HUD do bot CENTRALIZADO (mesmo design do rodapé, menor).
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _hudCounter(Icons.pets, '${bot.availableCreatureCount}',
                      size: 14),
                  const SizedBox(width: 12),
                  CrystalGem(value: bot.crystals, size: 26),
                  const SizedBox(width: 12),
                  _hudCounter(Icons.auto_awesome, '${bot.availableRelicCount}',
                      size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lanes
  // ---------------------------------------------------------------------------

  Widget _lanesRow(PveMatchUiState ui, BoardSide side,
      {required bool isPlayerSide}) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    final selected = _selectedPoolCard(ui);

    // Destaques de seleção (apenas no lado do jogador). Criatura jogável acende
    // TODAS as lanes próprias (empurrão: pode-se pôr em slot ocupado).
    final highlightLanes = <int>{};
    final highlightTargets = <String>{};
    if (isPlayerSide && ui.isPlayerTurn && selected != null) {
      if (selected is CreatureCard && controller.canPlayCreature(selected)) {
        highlightLanes.addAll([for (var i = 0; i < kLaneCount; i++) i]);
      } else if (selected is RelicCard && controller.canAffordRelic(selected)) {
        highlightTargets.addAll(
            controller.compatibleTargets(selected).map((c) => c.instanceId));
      }
    }

    // Alvo "órfão": o evento narrado mira uma criatura que JÁ saiu do
    // tabuleiro (morreu; lanes compactaram). O número flutua no centro da
    // fileira do lado defensor.
    final h = ui.highlight;
    final sideId = isPlayerSide ? ui.playerSide : ui.botSideId;
    final orphanTarget = h != null &&
        h.targetSide == sideId &&
        h.targetCardId != null &&
        !side.lanes
            .any((c) => c != null && c.instanceId == h.targetCardId);

    // Ordem VISUAL das lanes: frente (lane 0) no MEIO; slot 2 (lane 1) à
    // esquerda; slot 3 (lane 2) à direita.
    const visualOrder = <int>[1, 0, 2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: SizedBox(
        height: 152, // slots maiores (CEO) — sem mudar a posição relativa
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < visualOrder.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _laneSlot(
                      ui,
                      side.lanes[visualOrder[i]],
                      lane: visualOrder[i],
                      isPlayerSide: isPlayerSide,
                      laneHighlighted:
                          highlightLanes.contains(visualOrder[i]),
                      targetHighlighted: side.lanes[visualOrder[i]] != null &&
                          highlightTargets.contains(
                              side.lanes[visualOrder[i]]!.instanceId),
                    ),
                  ),
                ],
              ],
            ),
            if (orphanTarget) ...[
              if (h.targetDied && !h.isHeal)
                Positioned.fill(child: Center(child: _shardBurst(h))),
              Positioned.fill(
                child: Center(child: _floatingHighlightText(h)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Texto flutuante do evento destacado: dano/cura/evasão/habilidade.
  Widget _floatingHighlightText(CombatHighlight h) {
    final String text;
    final Color color;
    if (h.evaded) {
      text = 'EVADIU';
      color = AppColors.textSecondary;
    } else if (h.isHeal) {
      text = '+${h.amount ?? 0}';
      color = AppColors.conceptChrysalis;
    } else if (h.ability != null) {
      text = h.ability!.toUpperCase();
      color = AppColors.gold;
    } else {
      text = h.targetDied ? '-${h.amount ?? 0} †' : '-${h.amount ?? 0}';
      color = AppColors.hp;
    }
    return IgnorePointer(
      child: Text(
        text,
        style: GoogleFonts.cinzelDecorative(
          fontSize: h.ability != null ? 9 : 15,
          fontWeight: FontWeight.w700,
          color: color,
          shadows: const [Shadow(color: AppColors.black, blurRadius: 8)],
        ),
      )
          .animate(key: ObjectKey(h))
          .fadeIn(duration: 90.ms)
          .moveY(begin: 8, end: -16, duration: 620.ms, curve: Curves.easeOut)
          .fadeOut(delay: 400.ms, duration: 220.ms),
    );
  }

  Widget _laneSlot(
    PveMatchUiState ui,
    CreatureInPlay? creature, {
    required int lane,
    required bool isPlayerSide,
    required bool laneHighlighted,
    required bool targetHighlighted,
  }) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    final isFront = lane == 0;

    Color? borderOverride;
    if (laneHighlighted) borderOverride = AppColors.purpleLight;
    if (targetHighlighted) borderOverride = AppColors.gold;

    // Papel desta criatura no evento de combate sendo narrado (replay).
    final h = ui.highlight;
    final cid = creature?.instanceId;
    final isHlTarget = h != null && cid != null && h.targetCardId == cid;
    final isHlAbility = h != null &&
        cid != null &&
        h.ability != null &&
        h.attackerCardId == cid;
    final isHlAttacker = h != null &&
        cid != null &&
        h.ability == null &&
        h.attackerCardId == cid &&
        !isHlTarget;

    // Conteúdo: card no formato da coleção ou slot vazio. AnimatedSwitcher
    // keyed no instanceId → "frente sai / retaguarda entra" faz cross-fade
    // (a substituição passa a LER visualmente).
    final Widget content = creature == null
        ? _emptyLane(lane, laneHighlighted)
        : _boardCard(creature, isFront: isFront, borderOverride: borderOverride);

    Widget tile = AspectRatio(
      aspectRatio: 142 / 206,
      child: AnimatedSwitcher(
        // Mais lento/suave pra reduzir o "flicker" quando o tabuleiro avança
        // (morte + compactação) entre os passos do replay.
        duration: const Duration(milliseconds: 380),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey<String>(creature?.instanceId ?? 'empty$lane'),
          child: content,
        ),
      ),
    );

    // Corte de espada do atacante MELEE: wrappa o card ANTES da investida, pra
    // VIAJAR junto e flashear no pico (quando a carta "encosta" no alvo).
    final showSlash = h != null &&
        isHlAttacker &&
        !h.evaded &&
        (h.damageType == DamageType.corpoACorpo ||
            h.damageType == DamageType.vitalismo);
    if (creature != null && showSlash) {
      tile = Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          Positioned(
            top: isPlayerSide ? -16 : null,
            bottom: isPlayerSide ? null : -16,
            left: 0,
            right: 0,
            child: Center(child: _slashFlash(h)),
          ),
        ],
      );
    }

    // Animações do replay por TIPO de ataque (flutter_animate; key = evento).
    if (creature != null && h != null) {
      if (isHlAttacker) {
        final dir = isPlayerSide ? -1.0 : 1.0; // -y = rumo ao inimigo (jogador)
        switch (h.damageType) {
          case DamageType.corpoACorpo:
          case DamageType.vitalismo:
            // Físico/verdadeiro: a carta AVANÇA cruzando a banda central até
            // "encostar" no alvo, segura no impacto (golpe de espada) e RETORNA
            // ao slot. Lunge grande (56px) pra ser nítido — antes era 16px e
            // ficava "invisível". Com Clip.none nos Stacks ancestrais não corta.
            tile = tile
                .animate(key: ObjectKey(h))
                .moveY(
                    begin: 0,
                    end: 56 * dir,
                    duration: 260.ms,
                    curve: Curves.easeIn)
                .then(delay: 150.ms) // segura no impacto (golpe legível)
                .moveY(
                    begin: 0,
                    end: -56 * dir,
                    duration: 320.ms,
                    curve: Curves.easeOut);
          case DamageType.magico:
          case DamageType.aDistancia:
            // Lança projétil/flecha (viaja no overlay do alvo): recuo curto de
            // "conjuração/saque" + leve crescimento.
            tile = tile
                .animate(key: ObjectKey(h))
                .moveY(
                    begin: 0,
                    end: -10 * dir,
                    duration: 140.ms,
                    curve: Curves.easeOut)
                .scaleXY(begin: 1, end: 1.06, duration: 140.ms)
                .then()
                .moveY(begin: 0, end: 10 * dir, duration: 200.ms)
                .scaleXY(begin: 1, end: 1 / 1.06, duration: 200.ms);
          case DamageType.cura:
          case null:
            tile = tile.animate(key: ObjectKey(h)).shimmer(
                duration: 450.ms,
                color: AppColors.conceptChrysalis.withValues(alpha: 0.3));
        }
      } else if (isHlAbility) {
        tile = tile.animate(key: ObjectKey(h)).shimmer(
            duration: 550.ms, color: AppColors.gold.withValues(alpha: 0.35));
      } else if (isHlTarget && !h.isHeal) {
        tile = tile
            .animate(key: ObjectKey(h))
            .shake(hz: 7, duration: 340.ms, rotation: 0.012);
      } else if (isHlTarget && h.isHeal) {
        tile = tile.animate(key: ObjectKey(h)).shimmer(
            duration: 550.ms,
            color: AppColors.conceptChrysalis.withValues(alpha: 0.3));
      }
    }

    // Overlays do ALVO: impacto por tipo (projétil + burst) + número + morte.
    if (creature != null && h != null && (isHlTarget || isHlAbility)) {
      final hh = h;
      tile = Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          if (isHlTarget && !hh.isHeal && !hh.evaded)
            Positioned.fill(child: _impactOverlay(hh, isPlayerSide)),
          // Morte: com o replay pré-estado o alvo morto ainda está visível no
          // passo — o shatter estilhaça SOBRE o tile (some no passo seguinte,
          // quando o tabuleiro avança). Antes só existia no caminho "órfão".
          if (isHlTarget && hh.targetDied && !hh.isHeal)
            Positioned.fill(child: Center(child: _shardBurst(hh))),
          Positioned.fill(child: Center(child: _floatingHighlightText(hh))),
        ],
      );
    }

    // Stagger em CUNHA: frente (lane 0) avançada na direção do inimigo; slot 2
    // e 3 recuados pra longe da linha central (3 mais que 2). Jogador recua pra
    // baixo; bot pra cima.
    const laneDepth = <double>[0, 13, 22]; // lane0 frente, lane1, lane2
    final staggerDy = laneDepth[lane] * (isPlayerSide ? 1 : -1);

    return Transform.translate(
      offset: Offset(0, staggerDy),
      child: Center(
        child: GestureDetector(
          onTap: () {
            if (!isPlayerSide || !ui.isPlayerTurn || ui.playLocked) return;
            final selectedId = ui.selectedCardId;
            if (selectedId == null) {
              // Nada selecionado + toque na PRÓPRIA criatura → recuar pra mão
              // (custo kReturnVoluntaryCost; não encerra a vez).
              if (creature != null) _confirmReturnToHand(creature);
              return;
            }
            if (laneHighlighted) {
              // Criatura: joga aqui (empurra se o slot estiver ocupado; a
              // engine decide normal vs cheio→volta-pra-mão).
              controller.playCreature(selectedId, lane: lane);
            } else if (targetHighlighted && creature != null) {
              controller.playRelic(selectedId, creature.instanceId);
            }
          },
          child: tile,
        ),
      ),
    );
  }

  /// Overlay de impacto no card do alvo, por tipo de ataque: projétil/flecha
  /// que entra do lado do atacante (mágico/à distância) + burst de impacto.
  Widget _impactOverlay(CombatHighlight h, bool isPlayerSideTarget) {
    final type = h.damageType;
    final isProjectile =
        type == DamageType.magico || type == DamageType.aDistancia;

    final IconData impactIcon;
    final Color color;
    switch (type) {
      case DamageType.magico:
        impactIcon = Icons.blur_on;
        color = AppColors.conceptMagico;
      case DamageType.aDistancia:
        impactIcon = Icons.close;
        color = AppColors.gold;
      case DamageType.corpoACorpo:
      case DamageType.vitalismo:
      case DamageType.cura:
      case null:
        impactIcon = Icons.flare;
        color = AppColors.hp;
    }

    // O projétil entra pela borda do lado do atacante e VIAJA até o alvo: alvo
    // do jogador (embaixo) leva tiro de cima; alvo do bot (em cima) leva tiro
    // de baixo. Distância maior (60px) pra cruzar visivelmente a banda central.
    final startDy = isPlayerSideTarget ? -60.0 : 60.0;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isProjectile)
            Icon(type == DamageType.aDistancia ? Icons.navigation : Icons.circle,
                    size: type == DamageType.aDistancia ? 14 : 11, color: color)
                // Keys DISTINTAS por filho (projétil vs burst): senão os dois
                // ficam com a mesma key no mesmo Stack → "Duplicate keys".
                // Estável por evento (identityHashCode de h) pra reiniciar a
                // animação a cada highlight novo.
                .animate(key: ValueKey('fxProj_${identityHashCode(h)}'))
                .moveY(
                    begin: startDy,
                    end: 0,
                    duration: 240.ms,
                    curve: Curves.easeIn)
                .fadeOut(delay: 210.ms, duration: 60.ms),
          Icon(impactIcon, size: 26, color: color)
              .animate(key: ValueKey('fxImpact_${identityHashCode(h)}'))
              .scaleXY(
                  begin: 0.3,
                  end: 1.2,
                  delay: isProjectile ? 200.ms : 60.ms,
                  duration: 160.ms,
                  curve: Curves.easeOut)
              .fadeIn(delay: isProjectile ? 200.ms : 60.ms, duration: 80.ms)
              .then()
              .fadeOut(duration: 180.ms),
        ],
      ),
    );
  }

  /// Corte de espada (flash) do golpe melee: risco curvo brilhante que cresce
  /// e some no pico da investida do atacante (quando "encosta" no alvo).
  Widget _slashFlash(CombatHighlight h) {
    return IgnorePointer(
      child: SizedBox(
        width: 50,
        height: 50,
        child: CustomPaint(painter: _SlashPainter(AppColors.gold)),
      )
          .animate(key: ObjectKey(h))
          .fadeIn(delay: 250.ms, duration: 60.ms)
          .scaleXY(
              begin: 0.45,
              end: 1.35,
              delay: 250.ms,
              duration: 160.ms,
              curve: Curves.easeOut)
          .then()
          .fadeOut(duration: 170.ms),
    );
  }

  /// Burst de cacos (morte de uma carta) — ancorado onde o número da morte
  /// flutua. 8 fragmentos voam pra fora e somem.
  Widget _shardBurst(CombatHighlight h) {
    return IgnorePointer(
      child: KeyedSubtree(
        key: ObjectKey(h),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Stack(alignment: Alignment.center, children: [
            for (var i = 0; i < 8; i++) _shard(i),
          ]),
        ),
      ),
    );
  }

  Widget _shard(int i) {
    final angle = (i / 8) * 2 * math.pi;
    final dx = math.cos(angle) * 26;
    final dy = math.sin(angle) * 26;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: AppColors.hp.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(1),
      ),
    )
        .animate()
        .move(
            begin: Offset.zero,
            end: Offset(dx, dy),
            duration: 420.ms,
            curve: Curves.easeOut)
        .rotate(begin: 0, end: 0.6, duration: 420.ms)
        .fadeOut(delay: 200.ms, duration: 220.ms);
  }

  /// Slot de lane vazio (placeholder no formato/raio do card).
  Widget _emptyLane(int lane, bool highlighted) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? AppColors.purpleLight : AppColors.border,
          width: highlighted ? 1.6 : 1,
        ),
        boxShadow: highlighted
            ? const [BoxShadow(color: AppColors.purpleGlow, blurRadius: 8)]
            : null,
      ),
      child: Center(
        child: Text(
          lane == 0 ? 'FRENTE' : 'LINHA ${lane + 1}',
          style: GoogleFonts.roboto(
              fontSize: 8,
              letterSpacing: 1.2,
              color:
                  highlighted ? AppColors.purpleLight : AppColors.textMuted),
        ),
      ),
    );
  }

  /// Ícone do item equipado (pra o pentágono inferior), derivado do efeito.
  IconData _relicSlotIcon(RelicCard r) {
    final g = r.grants;
    if (g.attackType != null) return damageTypeIcon(g.attackType!);
    if (g.armor != null) return Icons.shield;
    if (g.heal != null) return Icons.healing;
    if (g.hpBonus != null) return Icons.favorite;
    if (g.atkBonus != null) return Icons.colorize;
    return Icons.auto_awesome;
  }

  /// Cor do PV no tabuleiro: branco = vida cheia (no original); vermelho =
  /// abaixo do total; verde = acima da vida original (buffada).
  Color _boardHpColor(CreatureInPlay c) {
    if (c.currentHp > c.card.hp) return AppColors.conceptChrysalis; // acima
    if (c.currentHp >= c.maxHp) return Colors.white; // cheia
    return AppColors.hp; // abaixo do total
  }

  /// Card de criatura no tabuleiro: `GameCardFace` (formato da coleção) com
  /// rodapé de combate (ATK efetivo, PV atual colorido, keywords). Ganha um
  /// glow pulse LEVE na cor do conceito (carta "viva" no tabuleiro).
  Widget _boardCard(CreatureInPlay c,
      {required bool isFront, Color? borderOverride}) {
    final glow = conceptColor(c.card.concepts);
    return GameCardFace(
      name: c.card.nome,
      cost: c.card.cost,
      concepts: c.card.concepts,
      rarity: c.card.rarity,
      artIcon: damageTypeIcon(c.effectiveDamageType),
      borderOverride: borderOverride,
      cornerBadge: isFront
          ? const Icon(Icons.flag, size: 11, color: AppColors.gold)
          : null,
      showItemSlot: true,
      itemIcon: c.relics.isNotEmpty ? _relicSlotIcon(c.relics.first) : null,
      effects: c.keywords.map(keywordIcon).toList(),
      footer: _boardFooter(c),
    )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .boxShadow(
          duration: 1400.ms,
          curve: Curves.easeInOut,
          borderRadius: BorderRadius.circular(10),
          begin: BoxShadow(
              color: glow.withValues(alpha: 0.0),
              blurRadius: 3,
              spreadRadius: 0),
          end: BoxShadow(
              color: glow.withValues(alpha: 0.45),
              blurRadius: 12,
              spreadRadius: 1),
        );
  }

  Widget _boardFooter(CreatureInPlay c) {
    // Barra de vida REMOVIDA (CEO); as keywords viraram brasões na borda
    // esquerda (ver GameCardFace.effectCrests). Aqui fica só a linha de stats.
    return Row(
      children: [
        // Ícone BRANCO do tipo (físico = espada); diferencia pela forma.
        typeGlyph(c.effectiveDamageType, size: 12),
        const SizedBox(width: 3),
        Text('${c.effectiveAtk}',
            style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.gold)),
        const Spacer(),
        if (c.armor > 0) ...[
          const Icon(Icons.shield, size: 8, color: AppColors.textSecondary),
          Text('${c.armor} ',
              style: GoogleFonts.robotoMono(
                  fontSize: 8, color: AppColors.textSecondary)),
        ],
        // Só a vida ATUAL, colorida: branco = cheia (no original); vermelho =
        // abaixo do total; verde = acima da vida original. Coraçãozinho branco.
        const Icon(Icons.favorite, size: 9, color: Colors.white),
        const SizedBox(width: 2),
        Text('${c.currentHp}',
            style: GoogleFonts.robotoMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _boardHpColor(c))),
      ],
    );
  }

  Widget _logLine(MatchLogEntry entry) {
    final color = switch (entry.kind) {
      MatchLogKind.system => AppColors.textMuted,
      MatchLogKind.player => AppColors.purpleLight,
      MatchLogKind.bot => AppColors.conceptCorrompido,
      MatchLogKind.combat => AppColors.gold,
    };
    return Text(
      'T${entry.turn} · ${entry.text}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.robotoMono(fontSize: 9.5, height: 1.3, color: color),
    );
  }

  // ---------------------------------------------------------------------------
  // Rodapé: cristais + pool + ações
  // ---------------------------------------------------------------------------

  /// MÃO como BARALHO ABERTO (leque), não rolável: as ≤5 cartas espalhadas em
  /// arco + a miniatura da PRÓXIMA carta no fim. A carta selecionada sobe e
  /// vai pra frente.
  Widget _handFan(PveMatchUiState ui, BoardSide player) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    final cards = player.hand;
    final next = player.nextCard;
    final n = cards.length + (next != null ? 1 : 0);

    const cardH = 132.0;
    const cardW = cardH * 142 / 206; // ~91
    if (n == 0) {
      return const SizedBox(height: cardH, child: Center(child: Text('')));
    }

    return SizedBox(
      height: cardH + 20,
      child: LayoutBuilder(
        builder: (context, cons) {
          final width = cons.maxWidth;
          final usable = (width - cardW).clamp(0.0, double.infinity);
          // Passo entre cartas: cabe todas sem rolar (sobrepõe se faltar espaço).
          final step =
              n > 1 ? (usable / (n - 1)).clamp(0.0, cardW * 0.94) : 0.0;
          final span = step * (n - 1) + cardW;
          final startX = (width - span) / 2;
          final center = (n - 1) / 2;

          // Ordem de pintura: selecionada por último (fica na frente).
          final order = [for (var i = 0; i < n; i++) i]..sort((a, b) {
              final sa = _isFanSelected(ui, cards, a) ? 1 : 0;
              final sb = _isFanSelected(ui, cards, b) ? 1 : 0;
              return sa - sb;
            });

          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final i in order)
                _fanCard(ui, controller, cards, next, i, n,
                    left: startX + step * i,
                    cardW: cardW,
                    cardH: cardH,
                    center: center),
            ],
          );
        },
      ),
    );
  }

  bool _isFanSelected(PveMatchUiState ui, List<Object> cards, int i) =>
      i < cards.length && ui.selectedCardId == cardId(cards[i]);

  Widget _fanCard(
    PveMatchUiState ui,
    PveMatchController controller,
    List<Object> cards,
    Object? next,
    int i,
    int n, {
    required double left,
    required double cardW,
    required double cardH,
    required double center,
  }) {
    final isPreview = i >= cards.length;
    final card = isPreview ? next! : cards[i];
    final offset = i - center;
    final rot = isPreview ? 0.0 : offset * 0.045; // leque
    final arcDy = offset.abs() * 3.0; // bordas levemente mais baixas

    if (isPreview) {
      // Preview da próxima carta: um pouco mais pra ESQUERDA e ainda mais pra
      // BAIXO (CEO) — desce até quase encostar no contador de cristais.
      return Positioned(
        left: left + 6,
        bottom: -56 - arcDy,
        child: Transform.rotate(
          angle: rot,
          child: Opacity(
            opacity: 0.55,
            child: SizedBox(
              width: cardW * 0.6,
              height: cardH * 0.6,
              child: Stack(children: [
                IgnorePointer(child: _gameFaceFor(card, minimal: true)),
                Positioned(
                  top: 2,
                  left: 0,
                  right: 0,
                  child: Center(child: _previewBadge()),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    final selected = ui.selectedCardId == cardId(card);
    final playable = card is CreatureCard
        ? controller.canPlayCreature(card)
        : controller.canPlayRelic(card as RelicCard);

    return Positioned(
      left: left,
      bottom: (selected ? 20 : 4) - arcDy,
      child: Transform.rotate(
        angle: selected ? 0 : rot,
        child: GestureDetector(
          onTap: () => controller.selectCard(cardId(card)),
          child: SizedBox(
            width: cardW,
            height: cardH,
            child: _gameFaceFor(card, selected: selected, dimmed: !playable),
          ),
        ),
      ),
    );
  }

  Widget _previewBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('PRÓXIMA',
            style: GoogleFonts.roboto(
                fontSize: 6,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
      );

  /// Constrói a `GameCardFace` de uma carta (criatura ou relíquia) — usada pela
  /// mão e pela miniatura de preview.
  Widget _gameFaceFor(Object card,
      {bool selected = false, bool dimmed = false, bool minimal = false}) {
    final creature = card is CreatureCard ? card : null;
    final relic = card is RelicCard ? card : null;
    final concepts = creature?.concepts ?? relic!.concepts;
    final concept = conceptColor(concepts);

    final Widget footer = creature != null
        ? Row(
            children: [
              // Ícone BRANCO do tipo (físico = espada).
              typeGlyph(creature.damageType, size: 12),
              const SizedBox(width: 3),
              Text('${creature.atk}',
                  style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold)),
              const Spacer(),
              const Icon(Icons.favorite, size: 9, color: Colors.white),
              const SizedBox(width: 2),
              Text('${creature.hp}',
                  style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.conceptChrysalis)),
            ],
          )
        : Text(_relicSummary(relic!),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.robotoMono(
                fontSize: 7, height: 1.15, color: AppColors.textSecondary));

    final Widget badge = (relic?.isFlash ?? false)
        ? const Icon(Icons.bolt, size: 12, color: AppColors.gold)
        : Icon(
            creature != null
                ? damageTypeIcon(creature.damageType)
                : Icons.auto_awesome,
            size: 11,
            color: concept);

    return GameCardFace(
      name: creature?.nome ?? relic!.nome,
      cost: creature?.cost ?? relic!.cost,
      concepts: concepts,
      rarity: creature?.rarity ?? relic!.rarity,
      artIcon: creature != null
          ? damageTypeIcon(creature.damageType)
          : (relic!.isFlash ? Icons.bolt : Icons.auto_awesome),
      // Criaturas na mão mostram o slot de item (vazio) + efeitos inatos.
      // Preview (minimal): nada disso — só arte + nome.
      showItemSlot: creature != null && !minimal,
      effects: (creature != null && !minimal)
          ? effectIconsFromAbilities(creature.abilities)
          : const [],
      minimal: minimal,
      footer: minimal ? const SizedBox.shrink() : footer,
      cornerBadge: minimal ? null : badge,
      selected: selected,
      dimmed: dimmed,
    );
  }

  String _relicSummary(RelicCard card) {
    final g = card.grants;
    final parts = <String>[
      if (g.atkBonus != null) '+${g.atkBonus} ATK',
      if (g.hpBonus != null) '+${g.hpBonus} PV',
      if (g.armor != null) '+${g.armor} ARM',
      if (g.heal != null) 'Cura ${g.heal}',
      if (g.attackType != null) 'Tipo: ${damageTypeToString(g.attackType!)}',
    ];
    if (parts.isEmpty) {
      return g.rawEffect.isEmpty ? 'Sem efeito mapeado' : g.rawEffect;
    }
    return parts.join(' · ');
  }

  /// Menu de ação SUTIL: pílula flutuante que aparece com uma carta
  /// selecionada (cancelar + sacrificar). Sobreposta ao topo do leque — não
  /// empurra o HUD. O ENCERRAR TURNO é o botão redondo da direita.
  Widget _actionOverlay(PveMatchUiState ui, Object selected) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    final canSac = controller.canSacrifice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVeil.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.black, blurRadius: 10, spreadRadius: -2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => controller.selectCard(null),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
            ),
          ),
          Container(width: 1, height: 18, color: AppColors.border),
          if (canSac)
            GestureDetector(
              onTap: () => controller.sacrifice(selected is CreatureCard
                  ? selected.id
                  : (selected as RelicCard).id),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_outlined,
                        size: 14, color: AppColors.hp),
                    const SizedBox(width: 5),
                    Text(
                      'Sacrificar +${selected is CreatureCard ? kSacrificeCreatureCrystals : kSacrificeRelicCrystals}',
                      style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.hp),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text('Toque numa lane',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textMuted)),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 130.ms)
        .slideY(begin: 0.5, end: 0, duration: 150.ms, curve: Curves.easeOut);
  }

  /// Botão REDONDO de encerrar jogada (espadas cruzadas), no centro-direita.
  /// Só ativo na vez do jogador.
  Widget _endTurnButton(PveMatchUiState ui) {
    final enabled = ui.phase == PveMatchPhase.playerTurn;
    final fg = enabled ? Colors.white : Colors.white.withValues(alpha: 0.5);
    return GestureDetector(
      onTap: enabled ? _onEndTurnPressed : null,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.purple
              : AppColors.purple.withValues(alpha: 0.22),
          border: Border.all(
              color: enabled ? AppColors.purpleLight : AppColors.border,
              width: 1.5),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                      color: AppColors.purpleGlow,
                      blurRadius: 12,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: Center(child: _CrossedSwords(color: fg, size: 26)),
      ),
    );
  }

  /// Botão REDONDO de voltar, no centro-esquerda (oposto ao encerrar jogada).
  Widget _sideBackButton() {
    return GestureDetector(
      onTap: _onBackPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 1.4),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            size: 16, color: AppColors.textSecondary),
      ),
    );
  }

  /// Botão REDONDO de REGISTRO (log), à direita do botão de desistir. Mesma
  /// aparência do botão de voltar.
  Widget _logButton(PveMatchUiState ui) {
    return GestureDetector(
      onTap: () => _showFullLog(ui.log),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 1.4),
        ),
        child: const Icon(Icons.receipt_long_outlined,
            size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  /// Resolve a carta selecionada (criatura OU relíquia) na MÃO do jogador.
  Object? _selectedPoolCard(PveMatchUiState ui) {
    final id = ui.selectedCardId;
    final board = ui.playerBoard;
    if (id == null || board == null) return null;
    for (final c in board.hand) {
      if (cardId(c) == id) return c;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Overlay de fim de partida
  // ---------------------------------------------------------------------------

  /// Seção de RECOMPENSAS no overlay de fim (ponto #1). Enquanto o RPC não
  /// volta, mostra um spinner discreto; depois, os chips de XP/gold/pacote +
  /// bônus de 1ª vitória e level-up.
  Widget _rewardSection() {
    final r = _reward;
    if (r == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple)),
        ),
      );
    }

    final chips = <Widget>[
      if (r.xp > 0) _rewardChip(Icons.auto_graph, '+${r.xp} XP', AppColors.xp),
      if (r.gold > 0)
        _rewardChip(Icons.monetization_on, '+${r.gold}', AppColors.gold),
      if (r.packs > 0)
        _rewardChip(Icons.style,
            '+${r.packs} pacote${r.packs > 1 ? 's' : ''}', AppColors.purpleLight),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),
        Text('RECOMPENSAS',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
        const SizedBox(height: 8),
        if (chips.isEmpty)
          Text('—',
              style: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.textMuted))
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        if (r.isFirstWinOfDay) ...[
          const SizedBox(height: 8),
          Text('Bônus de 1ª vitória do dia!',
              style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.gold)),
        ],
        if (r.levelUp != null) ...[
          const SizedBox(height: 6),
          Text('Subiu para o nível ${r.levelUp!.newLevel}!',
              style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purpleLight)),
        ],
      ],
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _rewardChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(text,
              style: GoogleFonts.robotoMono(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _matchOverOverlay(PveMatchUiState ui) {
    final won = ui.playerWon == true;
    final color = won ? AppColors.gold : AppColors.hp;
    final turns = ui.match?.turn ?? 0;

    return Positioned.fill(
      child: Container(
        color: AppColors.black.withValues(alpha: 0.78),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVeil,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.18), blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    won
                        ? Icons.emoji_events_outlined
                        : Icons.heart_broken_outlined,
                    size: 44,
                    color: color),
                const SizedBox(height: 12),
                Text(won ? 'VITÓRIA' : 'DERROTA',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 24,
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3)),
                const SizedBox(height: 6),
                Text('$turns turnos',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.textSecondary)),
                _rewardSection(),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go('/battle'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      child: const Text('Voltar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _startMatch,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      child: const Text('Jogar novamente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Estados de boot
  // ---------------------------------------------------------------------------

  Widget _noDeckBody() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.style_outlined,
              size: 48, color: AppColors.purpleLight),
          const SizedBox(height: 16),
          Text('Nenhum deck ativo',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            'Você precisa de um deck válido (9 criaturas + 9 relíquias) '
            'para entrar numa partida.',
            style:
                GoogleFonts.roboto(fontSize: 12, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/card-game/deck-builder'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.purple,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            ),
            icon: const Icon(Icons.construction_outlined, size: 16),
            label: const Text('Montar deck'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/battle'),
            child: Text('Voltar',
                style: GoogleFonts.roboto(color: AppColors.textSecondary)),
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
              style: GoogleFonts.robotoMono(
                  fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _bootMatch,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.purple.withValues(alpha: 0.6)),
              foregroundColor: AppColors.purpleLight,
            ),
            child: const Text('Tentar de novo'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/battle'),
            child: Text('Voltar',
                style: GoogleFonts.roboto(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// Ícone de ESPADAS CRUZADAS (botão de encerrar jogada). Desenhado via
/// CustomPaint pra não depender de glyph/emoji (renderiza igual em qualquer
/// device).
class _CrossedSwords extends StatelessWidget {
  const _CrossedSwords({required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _SwordsPainter(color));
}

class _SwordsPainter extends CustomPainter {
  _SwordsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    // Desenha DUAS espadas reais cruzadas em X: cada uma com lâmina
    // afilada (ponta), guarda (cross-guard), punho e pomo. Renderizadas
    // por transform (espada vertical) rotacionada ±40°.
    _drawSword(canvas, s, 0.7); // \ (ponta sup-esq)
    _drawSword(canvas, s, -0.7); // / (ponta sup-dir)
  }

  void _drawSword(Canvas canvas, Size s, double angle) {
    final w = s.width;
    final h = s.height;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(angle);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = color
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final guardY = h * 0.12; // altura da guarda
    final bladeHalf = w * 0.05; // meia-largura da lâmina

    // Lâmina: ponta afilada no topo, alargando até a guarda.
    final blade = Path()
      ..moveTo(0, -h * 0.46) // ponta
      ..lineTo(-bladeHalf, -h * 0.34)
      ..lineTo(-bladeHalf, guardY)
      ..lineTo(bladeHalf, guardY)
      ..lineTo(bladeHalf, -h * 0.34)
      ..close();
    canvas.drawPath(blade, fill);

    // Guarda (cross-guard) perpendicular logo abaixo da lâmina.
    canvas.drawLine(
        Offset(-w * 0.17, guardY), Offset(w * 0.17, guardY), line);
    // Punho.
    canvas.drawLine(Offset(0, guardY), Offset(0, h * 0.32), line);
    // Pomo (esfera no fim do punho).
    canvas.drawCircle(Offset(0, h * 0.36), w * 0.05, fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SwordsPainter old) => old.color != color;
}

/// Risco de CORTE de espada (golpe melee): arco curvo grosso na cor do golpe +
/// um realce branco fino sobreposto (brilho da lâmina). Desenhado via
/// CustomPaint pra renderizar igual em qualquer device.
class _SlashPainter extends CustomPainter {
  _SlashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()
      ..moveTo(s.width * 0.10, s.height * 0.80)
      ..quadraticBezierTo(s.width * 0.52, s.height * 0.06,
          s.width * 0.92, s.height * 0.38);

    final stroke = Paint()
      ..color = color
      ..strokeWidth = s.width * 0.13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, stroke);

    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = s.width * 0.045
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, shine);
  }

  @override
  bool shouldRepaint(covariant _SlashPainter old) => old.color != color;
}
