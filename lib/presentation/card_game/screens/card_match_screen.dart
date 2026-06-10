import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_game.dart';
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

  /// Bandeja de mão expandida (minimizável — foco no tabuleiro).
  bool _handExpanded = true;

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
      _playerLoadout = player;
      _botLoadout = _buildBotLoadout(catalog);
      setState(() => _boot = _BootStatus.ready);
      _startMatch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _boot = _BootStatus.error;
        _bootError = e.toString();
      });
    }
  }

  void _startMatch() {
    final seed = math.Random().nextInt(0x7fffffff);
    ref.read(pveMatchControllerProvider.notifier).startMatch(
          _playerLoadout!,
          _botLoadout!,
          seed: seed,
        );
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
            SafeArea(
              child: Column(
                children: [
                  _header(ui),
                  Expanded(child: _body(ui)),
                ],
              ),
            ),
            // Botão redondo de encerrar turno, fixo no centro-direita.
            if (_boot == _BootStatus.ready && ui.match != null && !ui.isFinished)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(child: _endTurnButton(ui)),
              ),
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
  // Header
  // ---------------------------------------------------------------------------

  Widget _header(PveMatchUiState ui) {
    final turnText = switch (ui.phase) {
      PveMatchPhase.playerTurn => 'Turno ${ui.match?.turn ?? '-'} · sua vez',
      PveMatchPhase.resolving => 'Resolvendo ataque…',
      PveMatchPhase.botTurn => 'Vez da IA…',
      PveMatchPhase.finished => 'Partida encerrada',
      PveMatchPhase.idle => 'Preparando…',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onBackPressed,
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
                Text('PARTIDA — MODO CARTAS',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 13,
                        color: AppColors.purpleLight,
                        letterSpacing: 2)),
                Text(turnText,
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (ui.phase == PveMatchPhase.botTurn ||
              ui.phase == PveMatchPhase.resolving)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Corpo da partida
  // ---------------------------------------------------------------------------

  Widget _matchBody(PveMatchUiState ui) {
    final bot = ui.botBoard!;
    final player = ui.playerBoard!;
    final interactive = ui.phase == PveMatchPhase.playerTurn;

    // Tabuleiro em FOCO: as lanes ocupam o centro (espaçadas), e a mão fica
    // numa bandeja minimizável no rodapé — não come a tela.
    return Column(
      children: [
        _botInfoBar(bot),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _lanesRow(ui, bot, isPlayerSide: false),
              _miniLog(ui),
              AbsorbPointer(
                absorbing: !interactive,
                child: _lanesRow(ui, player, isPlayerSide: true),
              ),
            ],
          ),
        ),
        AbsorbPointer(
          absorbing: !interactive,
          child: Opacity(
            opacity: interactive ? 1 : 0.55,
            child: _handTray(ui, player),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: AbsorbPointer(
            absorbing: !interactive,
            child: Opacity(
                opacity: interactive ? 1 : 0.55, child: _actionRow(ui)),
          ),
        ),
      ],
    );
  }

  Widget _botInfoBar(BoardSide bot) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceVeil,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined,
              color: AppColors.conceptCorrompido, size: 16),
          const SizedBox(width: 8),
          Text('IA',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 12, color: AppColors.textPrimary, letterSpacing: 1)),
          const Spacer(),
          _statChip(Icons.diamond_outlined, '${bot.crystals}', AppColors.mp),
          const SizedBox(width: 10),
          _statChip(Icons.pets_outlined, '${bot.remainingCreatureCount}/9',
              AppColors.conceptCorrompido),
          const SizedBox(width: 10),
          _statChip(Icons.style_outlined,
              '${bot.hand.length + bot.deck.length}', AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: GoogleFonts.robotoMono(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: SizedBox(
        height: 152,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var lane = 0; lane < side.lanes.length; lane++) ...[
                  if (lane > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _laneSlot(
                      ui,
                      side.lanes[lane],
                      lane: lane,
                      isPlayerSide: isPlayerSide,
                      laneHighlighted: highlightLanes.contains(lane),
                      targetHighlighted: side.lanes[lane] != null &&
                          highlightTargets
                              .contains(side.lanes[lane]!.instanceId),
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
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey<String>(creature?.instanceId ?? 'empty$lane'),
          child: content,
        ),
      ),
    );

    // Animações do replay por TIPO de ataque (flutter_animate; key = evento).
    if (creature != null && h != null) {
      if (isHlAttacker) {
        final dir = isPlayerSide ? -1.0 : 1.0; // -y = rumo ao inimigo (jogador)
        switch (h.damageType) {
          case DamageType.corpoACorpo:
          case DamageType.vitalismo:
            // Físico/verdadeiro: AVANÇA até o inimigo e volta (golpe).
            tile = tile
                .animate(key: ObjectKey(h))
                .moveY(
                    begin: 0,
                    end: 16 * dir,
                    duration: 150.ms,
                    curve: Curves.easeOut)
                .then(delay: 40.ms)
                .moveY(
                    begin: 0,
                    end: -16 * dir,
                    duration: 190.ms,
                    curve: Curves.easeIn);
          case DamageType.magico:
          case DamageType.aDistancia:
            // Lança projétil/flecha: pulso de "conjuração/saque" (recuo curto).
            tile = tile
                .animate(key: ObjectKey(h))
                .scaleXY(
                    begin: 1, end: 1.08, duration: 130.ms, curve: Curves.easeOut)
                .then()
                .scaleXY(begin: 1, end: 1 / 1.08, duration: 170.ms);
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

    // Overlays no card do alvo: impacto por tipo (projétil + burst) + número.
    if (creature != null && (isHlTarget || isHlAbility)) {
      final hh = h;
      tile = Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          if (isHlTarget && !hh.isHeal && !hh.evaded)
            Positioned.fill(child: _impactOverlay(hh, isPlayerSide)),
          Positioned.fill(child: Center(child: _floatingHighlightText(hh))),
        ],
      );
    }

    // Stagger: frente (lane 0) no centro; 2 e 3 recuados (3 mais que 2). O
    // recuo é pra LONGE da linha central (jogador desce, bot sobe).
    final staggerDy = (lane * 8.0) * (isPlayerSide ? 1 : -1);

    return Transform.translate(
      offset: Offset(0, staggerDy),
      child: Center(
        child: GestureDetector(
          onTap: () {
            if (!isPlayerSide || !ui.isPlayerTurn) return;
            final selectedId = ui.selectedCardId;
            if (selectedId == null) return;
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

    // O projétil entra pela borda do lado do atacante: alvo do jogador (em
    // baixo) leva tiro de cima; alvo do bot (em cima) leva tiro de baixo.
    final startDy = isPlayerSideTarget ? -30.0 : 30.0;

    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isProjectile)
            Icon(Icons.circle, size: 9, color: color)
                .animate(key: ObjectKey(h))
                .moveY(
                    begin: startDy,
                    end: 0,
                    duration: 200.ms,
                    curve: Curves.easeIn)
                .fadeOut(delay: 180.ms, duration: 60.ms),
          Icon(impactIcon, size: 26, color: color)
              .animate(key: ObjectKey(h))
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

  /// Card de criatura no tabuleiro: `GameCardFace` (formato da coleção) com
  /// rodapé de combate (ATK efetivo, PV atual/máx + barra, keywords).
  Widget _boardCard(CreatureInPlay c,
      {required bool isFront, Color? borderOverride}) {
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
      footer: _boardFooter(c),
    );
  }

  Widget _boardFooter(CreatureInPlay c) {
    final hpRatio =
        c.maxHp <= 0 ? 0.0 : (c.currentHp / c.maxHp).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${c.effectiveAtk}',
                style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold)),
            Text(' ATK',
                style: GoogleFonts.roboto(
                    fontSize: 6,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold.withValues(alpha: 0.7))),
            const Spacer(),
            if (c.armor > 0) ...[
              const Icon(Icons.shield, size: 8, color: AppColors.textSecondary),
              Text('${c.armor} ',
                  style: GoogleFonts.robotoMono(
                      fontSize: 8, color: AppColors.textSecondary)),
            ],
            Text('${c.currentHp}/${c.maxHp}',
                style: GoogleFonts.robotoMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.conceptChrysalis)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 4,
            child: Stack(
              children: [
                Container(color: AppColors.surface),
                FractionallySizedBox(
                  widthFactor: hpRatio,
                  child: Container(
                    color: hpRatio > 0.5
                        ? AppColors.conceptChrysalis
                        : (hpRatio > 0.25 ? AppColors.gold : AppColors.hp),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (c.keywords.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            c.keywords.map(abilityKeywordLabel).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                color: AppColors.gold.withValues(alpha: 0.85)),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mini-log
  // ---------------------------------------------------------------------------

  /// Faixa central slim: turno/fase + últimas 2 linhas de log (toca → log full).
  Widget _miniLog(PveMatchUiState ui) {
    final recent =
        ui.log.length <= 2 ? ui.log : ui.log.sublist(ui.log.length - 2);
    return GestureDetector(
      onTap: () => _showFullLog(ui.log),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderViolet),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in recent)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.5),
                      child: _logLine(entry),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.unfold_more,
                size: 13, color: AppColors.purpleLight),
          ],
        ),
      ),
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

  /// Bandeja de mão MINIMIZÁVEL: alça (cristais + contagem + chevron) que
  /// expande/colapsa o baralho único. Colapsada, o tabuleiro ganha a tela.
  Widget _handTray(PveMatchUiState ui, BoardSide player) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVeil,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _handExpanded = !_handExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mp.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.mp.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.diamond_outlined,
                            size: 14, color: AppColors.mp),
                        const SizedBox(width: 5),
                        Text('${player.crystals}',
                            style: GoogleFonts.robotoMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _statChip(Icons.pets_outlined,
                      '${player.remainingCreatureCount}/9',
                      AppColors.purpleLight),
                  const Spacer(),
                  Text('MÃO ${player.hand.length} · DECK ${player.deck.length}',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted)),
                  const SizedBox(width: 4),
                  Icon(
                      _handExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      size: 18,
                      color: AppColors.purpleLight),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _handExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: SizedBox(height: 150, child: _handStrip(ui, player)),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _handStrip(PveMatchUiState ui, BoardSide player) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    // MÃO: as ≤5 cartas visíveis, em ordem de compra (embaralhada — sem
    // reordenar). A última posição mostra a MINIATURA da próxima a comprar.
    final cards = player.hand;
    final next = player.nextCard;
    if (cards.isEmpty && next == null) return _emptyPoolText('Mão vazia.');
    final itemCount = cards.length + (next != null ? 1 : 0);
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      separatorBuilder: (_, i) =>
          SizedBox(width: i == cards.length - 1 ? 12 : 7),
      itemBuilder: (_, i) {
        if (i >= cards.length) return _previewCard(next!);
        final card = cards[i];
        if (card is CreatureCard) {
          return _handCard(
            card,
            selected: ui.selectedCardId == card.id,
            playable: controller.canPlayCreature(card),
          );
        }
        final relic = card as RelicCard;
        return _handCard(
          relic,
          selected: ui.selectedCardId == relic.id,
          playable: controller.canPlayRelic(relic),
        );
      },
    );
  }

  /// Miniatura (menor, não-interativa) da PRÓXIMA carta que será comprada.
  Widget _previewCard(Object card) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Opacity(
        opacity: 0.6,
        child: AspectRatio(
          aspectRatio: 142 / 206,
          child: Stack(
            children: [
              IgnorePointer(child: _gameFaceFor(card)),
              Positioned(
                top: 2,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyPoolText(String text) {
    return Center(
      child: Text(text,
          style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textMuted)),
    );
  }

  /// Carta da mão no formato da coleção (`GameCardFace`), ~10% maior que a
  /// referência. Tocar seleciona (mesmo não-jogável: ainda dá pra SACRIFICAR).
  Widget _handCard(Object card, {required bool selected, required bool playable}) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    return GestureDetector(
      onTap: () => controller.selectCard(cardId(card)),
      child: AspectRatio(
        aspectRatio: 142 / 206,
        child: _gameFaceFor(card, selected: selected, dimmed: !playable),
      ),
    );
  }

  /// Constrói a `GameCardFace` de uma carta (criatura ou relíquia) — usada pela
  /// mão e pela miniatura de preview.
  Widget _gameFaceFor(Object card, {bool selected = false, bool dimmed = false}) {
    final creature = card is CreatureCard ? card : null;
    final relic = card is RelicCard ? card : null;
    final concepts = creature?.concepts ?? relic!.concepts;
    final concept = conceptColor(concepts);

    final Widget footer = creature != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${creature.atk}',
                  style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold)),
              Text(' ATK',
                  style: GoogleFonts.roboto(
                      fontSize: 6,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold.withValues(alpha: 0.7))),
              const Spacer(),
              Text('${creature.hp}',
                  style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.conceptChrysalis)),
              Text(' PV',
                  style: GoogleFonts.roboto(
                      fontSize: 6,
                      fontWeight: FontWeight.w700,
                      color: AppColors.conceptChrysalis.withValues(alpha: 0.7))),
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
      footer: footer,
      cornerBadge: badge,
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

  /// Linha de ação: aparece só com uma carta selecionada (cancelar +
  /// sacrificar). O ENCERRAR TURNO virou o botão redondo da direita.
  Widget _actionRow(PveMatchUiState ui) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    final selected = _selectedPoolCard(ui);
    if (selected == null) return const SizedBox.shrink();

    return Row(
      children: [
        GestureDetector(
          onTap: () => controller.selectCard(null),
          child: Container(
            width: 38,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.close,
                size: 16, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: controller.canSacrifice
              ? OutlinedButton.icon(
                  onPressed: () => controller.sacrifice(selected is CreatureCard
                      ? selected.id
                      : (selected as RelicCard).id),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.hp.withValues(alpha: 0.6)),
                    foregroundColor: AppColors.hp,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.local_fire_department_outlined,
                      size: 15),
                  label: Text(
                    selected is CreatureCard
                        ? 'Sacrificar (+$kSacrificeCreatureCrystals)'
                        : 'Sacrificar (+$kSacrificeRelicCrystals)',
                    style: GoogleFonts.roboto(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                )
              : Center(
                  child: Text('Toque numa lane para posicionar',
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: AppColors.textMuted)),
                ),
        ),
      ],
    );
  }

  /// Botão REDONDO de encerrar turno, fixo no centro-direita (estilo Card
  /// Monsters). Só ativo na vez do jogador.
  Widget _endTurnButton(PveMatchUiState ui) {
    final enabled = ui.phase == PveMatchPhase.playerTurn;
    return GestureDetector(
      onTap: enabled ? _onEndTurnPressed : null,
      child: Container(
        width: 54,
        height: 54,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fast_forward_rounded,
                size: 22,
                color: enabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5)),
            Text('FIM',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 7,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5))),
          ],
        ),
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
