import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_game.dart';
import '../deck_repository.dart';
import '../pve_match_controller.dart';

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

  /// Aba do pool no rodapé: 0 = criaturas, 1 = relíquias.
  int _poolTab = 0;

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

    return Column(
      children: [
        _botInfoBar(bot),
        const SizedBox(height: 4),
        _lanesRow(ui, bot, isPlayerSide: false),
        _miniLog(ui),
        AbsorbPointer(
          absorbing: !interactive,
          child: _lanesRow(ui, player, isPlayerSide: true),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: AbsorbPointer(
            absorbing: !interactive,
            child: Opacity(
              opacity: interactive ? 1 : 0.55,
              child: _footer(ui, player),
            ),
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
              '${bot.poolCreatures.length + bot.poolRelics.length}',
              AppColors.textSecondary),
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

    // Destaques de seleção (apenas no lado do jogador).
    final highlightLanes = <int>{};
    final highlightTargets = <String>{};
    if (isPlayerSide && ui.isPlayerTurn && selected != null) {
      if (selected is CreatureCard && controller.canAfford(selected)) {
        highlightLanes.addAll(controller.freeLanes());
      } else if (selected is RelicCard && controller.canAffordRelic(selected)) {
        highlightTargets.addAll(
            controller.compatibleTargets(selected).map((c) => c.instanceId));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          for (var lane = 0; lane < side.lanes.length; lane++) ...[
            if (lane > 0) const SizedBox(width: 8),
            Expanded(
              child: _laneSlot(
                ui,
                side.lanes[lane],
                lane: lane,
                isPlayerSide: isPlayerSide,
                laneHighlighted: highlightLanes.contains(lane),
                targetHighlighted: side.lanes[lane] != null &&
                    highlightTargets.contains(side.lanes[lane]!.instanceId),
              ),
            ),
          ],
        ],
      ),
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

    Color borderColor = AppColors.border;
    if (laneHighlighted) borderColor = AppColors.purpleLight;
    if (targetHighlighted) borderColor = AppColors.gold;

    final isFront = lane == 0;

    return GestureDetector(
      onTap: () {
        if (!isPlayerSide || !ui.isPlayerTurn) return;
        final selectedId = ui.selectedCardId;
        if (selectedId == null) return;
        if (laneHighlighted && creature == null) {
          controller.playCreature(selectedId, lane: lane);
        } else if (targetHighlighted && creature != null) {
          controller.playRelic(selectedId, creature.instanceId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 86,
        decoration: BoxDecoration(
          color: creature == null
              ? AppColors.surface.withValues(alpha: 0.55)
              : AppColors.surfaceVeil2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: (laneHighlighted || targetHighlighted) ? 1.6 : 1,
          ),
          boxShadow: (laneHighlighted || targetHighlighted)
              ? [
                  BoxShadow(
                      color: borderColor.withValues(alpha: 0.35),
                      blurRadius: 8)
                ]
              : null,
        ),
        child: creature == null
            ? Center(
                child: Text(
                  isFront ? 'FRENTE' : 'LINHA ${lane + 1}',
                  style: GoogleFonts.roboto(
                      fontSize: 9,
                      color: laneHighlighted
                          ? AppColors.purpleLight
                          : AppColors.textMuted,
                      letterSpacing: 1.5),
                ),
              )
            : _creatureTile(creature, isFront: isFront),
      ),
    );
  }

  Widget _creatureTile(CreatureInPlay c, {required bool isFront}) {
    final concept = _conceptColor(c.card.concepts.first);
    final hpRatio =
        c.maxHp <= 0 ? 0.0 : (c.currentHp / c.maxHp).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.card.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: concept,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (isFront)
                const Icon(Icons.flag_outlined,
                    size: 10, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 3),
          Text('ATK ${c.atk} · PV ${c.currentHp}/${c.maxHp}'
              '${c.armor > 0 ? ' · ARM ${c.armor}' : ''}',
              style: GoogleFonts.robotoMono(
                  fontSize: 9, color: AppColors.textSecondary)),
          const SizedBox(height: 5),
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
          const Spacer(),
          Row(
            children: [
              for (final r in c.relics)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(Icons.auto_awesome,
                      size: 10, color: _conceptColor(r.concepts.first)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mini-log
  // ---------------------------------------------------------------------------

  Widget _miniLog(PveMatchUiState ui) {
    final recent = ui.log.length <= 4
        ? ui.log
        : ui.log.sublist(ui.log.length - 4);
    return GestureDetector(
      onTap: () => _showFullLog(ui.log),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderViolet),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: _logLine(entry),
              ),
            if (ui.log.length > 4)
              Align(
                alignment: Alignment.centerRight,
                child: Text('ver tudo ›',
                    style: GoogleFonts.roboto(
                        fontSize: 9, color: AppColors.purpleLight)),
              ),
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

  Widget _footer(PveMatchUiState ui, BoardSide player) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVeil,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Cristais — destaque.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.mp.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.mp.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.diamond_outlined,
                        size: 15, color: AppColors.mp),
                    const SizedBox(width: 5),
                    Text('${player.crystals}',
                        style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _statChip(Icons.pets_outlined,
                  '${player.remainingCreatureCount}/9', AppColors.purpleLight),
              const Spacer(),
              _poolTabButton('CRIATURAS', 0, player.poolCreatures.length),
              const SizedBox(width: 6),
              _poolTabButton('RELÍQUIAS', 1, player.poolRelics.length),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _poolList(ui, player)),
          const SizedBox(height: 8),
          _actionRow(ui),
        ],
      ),
    );
  }

  Widget _poolTabButton(String label, int tab, int count) {
    final active = _poolTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _poolTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.purple.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? AppColors.purple : AppColors.border),
        ),
        child: Text('$label ($count)',
            style: GoogleFonts.roboto(
                fontSize: 9,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
                color:
                    active ? AppColors.purpleLight : AppColors.textMuted)),
      ),
    );
  }

  Widget _poolList(PveMatchUiState ui, BoardSide player) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    if (_poolTab == 0) {
      if (player.poolCreatures.isEmpty) {
        return _emptyPoolText('Sem criaturas no pool.');
      }
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: player.poolCreatures.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final card = player.poolCreatures[i];
          return _creaturePoolCard(
            card,
            selected: ui.selectedCardId == card.id,
            playable: controller.canPlayCreature(card),
          );
        },
      );
    }
    if (player.poolRelics.isEmpty) {
      return _emptyPoolText('Sem relíquias no pool.');
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: player.poolRelics.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final card = player.poolRelics[i];
        return _relicPoolCard(
          card,
          selected: ui.selectedCardId == card.id,
          playable: controller.canPlayRelic(card),
        );
      },
    );
  }

  Widget _emptyPoolText(String text) {
    return Center(
      child: Text(text,
          style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textMuted)),
    );
  }

  Widget _creaturePoolCard(CreatureCard card,
      {required bool selected, required bool playable}) {
    final concept = _conceptColor(card.concepts.first);
    return _poolCardShell(
      cardId: card.id,
      selected: selected,
      playable: playable,
      accent: concept,
      rarity: card.rarity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.mp.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('${card.cost}',
                    style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mp)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(card.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                        fontSize: 9.5,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: concept)),
              ),
            ],
          ),
          const Spacer(),
          Text('ATK ${card.atk} · PV ${card.hp}',
              style: GoogleFonts.robotoMono(
                  fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _relicPoolCard(RelicCard card,
      {required bool selected, required bool playable}) {
    final concept = _conceptColor(card.concepts.first);
    return _poolCardShell(
      cardId: card.id,
      selected: selected,
      playable: playable,
      accent: concept,
      rarity: card.rarity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.mp.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('${card.cost}',
                    style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mp)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(card.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                        fontSize: 9.5,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: concept)),
              ),
              if (card.isFlash)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('FLASH',
                      style: GoogleFonts.roboto(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold)),
                ),
            ],
          ),
          const Spacer(),
          Text(_relicSummary(card),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.robotoMono(
                  fontSize: 8.5, height: 1.2, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _poolCardShell({
    required String cardId,
    required bool selected,
    required bool playable,
    required Color accent,
    required Rarity rarity,
    required Widget child,
  }) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    return GestureDetector(
      // Carta não-jogável continua selecionável: ainda pode ser SACRIFICADA.
      onTap: () => controller.selectCard(cardId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 104,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple.withValues(alpha: 0.14)
              : AppColors.surfaceVeil2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.purpleLight : _rarityColor(rarity),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                      color: AppColors.purpleGlow,
                      blurRadius: 8,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: Opacity(opacity: playable ? 1 : 0.38, child: child),
      ),
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

  Widget _actionRow(PveMatchUiState ui) {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    final selected = _selectedPoolCard(ui);
    final canEndTurn = ui.phase == PveMatchPhase.playerTurn;

    return Row(
      children: [
        if (selected != null) ...[
          // Cancelar seleção.
          GestureDetector(
            onTap: () => controller.selectCard(null),
            child: Container(
              width: 38,
              height: 42,
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
          if (controller.canSacrifice)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => controller.sacrifice(selected is CreatureCard
                    ? selected.id
                    : (selected as RelicCard).id),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppColors.hp.withValues(alpha: 0.6)),
                  foregroundColor: AppColors.hp,
                  padding: const EdgeInsets.symmetric(vertical: 11),
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
              ),
            ),
          if (controller.canSacrifice) const SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: canEndTurn ? _onEndTurnPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.purple,
              disabledBackgroundColor:
                  AppColors.purple.withValues(alpha: 0.25),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.bolt, size: 15),
            label: Text('ENCERRAR TURNO',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  /// Resolve a carta selecionada (criatura OU relíquia) do pool do jogador.
  Object? _selectedPoolCard(PveMatchUiState ui) {
    final id = ui.selectedCardId;
    final board = ui.playerBoard;
    if (id == null || board == null) return null;
    for (final c in board.poolCreatures) {
      if (c.id == id) return c;
    }
    for (final r in board.poolRelics) {
      if (r.id == id) return r;
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

  // ---------------------------------------------------------------------------
  // Cores
  // ---------------------------------------------------------------------------

  Color _conceptColor(CardConcept c) {
    switch (c) {
      case CardConcept.vitalismo:
        return AppColors.conceptVita;
      case CardConcept.neutro:
        return AppColors.conceptNeutro;
      case CardConcept.chrysalis:
        return AppColors.conceptChrysalis;
      case CardConcept.celestial:
        return AppColors.conceptCelestial;
      case CardConcept.magico:
        return AppColors.conceptMagico;
      case CardConcept.corrompido:
        return AppColors.conceptCorrompido;
    }
  }

  Color _rarityColor(Rarity r) {
    switch (r) {
      case Rarity.comum:
        return AppColors.cardComum;
      case Rarity.rara:
        return AppColors.cardRara;
      case Rarity.epica:
        return AppColors.cardEpica;
      case Rarity.lendaria:
        return AppColors.cardLendaria;
      case Rarity.elite:
        return AppColors.cardElite;
    }
  }
}
