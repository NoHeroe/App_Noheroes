import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback (impacto do pouso)
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/tutorial_service.dart';
import '../../../data/services/card_match_reward_service.dart';
import '../card_hero_prefs.dart';
import '../../../domain/card_game/card_catalog.dart';
import '../../../domain/card_game/card_game.dart';
import '../../shared/tutorial_manager.dart';
import '../card_economy.dart';
import '../deck_repository.dart';
import '../pve_match_controller.dart';
import '../widgets/card_back.dart';
import '../widgets/combat_vfx.dart';
import '../widgets/game_card_face.dart';
import '../widgets/match_intro.dart';
import '../widgets/magic_dust_overlay.dart';

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

class _CardMatchScreenState extends ConsumerState<CardMatchScreen>
    with SingleTickerProviderStateMixin {
  _BootStatus _boot = _BootStatus.loading;
  String? _bootError;
  CardLoadout? _playerLoadout;
  CardLoadout? _botLoadout;
  HeroId? _playerHero; // ADR-0028: herói do jogador (prefs) e do bot (aleatório).
  HeroId? _botHero;
  Object? _bonusCard; // ADR-0028 Fase C: carta-bônus do Cartomante (montagem).

  // Recompensa de partida (ponto #1): concedida 1× ao terminar; exibida no
  // overlay de fim. `_rewardRequested` evita conceder de novo no rebuild.
  CardMatchReward? _reward;
  bool _rewardRequested = false;

  // Reposicionamento (SPEC CEO 2026-06-11): criatura própria selecionada pra
  // mover. 1º toque seleciona; tocar outra ATRÁS = troca (2 cristais); tocar a
  // mesma = recuar pra mão. Só pra trás.
  String? _movingCreatureId;

  // Mímico (Lote 5): criatura (aliada OU inimiga) marcada pra copiar ao jogar um
  // Mímico da mão. Toca-se a criatura pra marcar; depois toca-se a lane pra jogar.
  String? _mimicTargetId;

  // Oráculo (ADR-0028 Fase C): guarda de reentrância do diálogo de peek
  // (passiva "espiar/reordenar"), pra não abrir duas vezes na mesma vez.
  bool _peekDialogOpen = false;

  /// A carta selecionada da mão é um Mímico (criatura com a keyword)?
  bool _selectedIsMimic(PveMatchUiState ui) {
    final sel = _selectedPoolCard(ui);
    return sel is CreatureCard &&
        sel.abilities
            .any((a) => abilityKeywordFromString(a) == AbilityKeyword.mimico);
  }

  // Tutorial guiado da 1ª partida (ponto #2): bot fraco + diálogos. Detectado
  // no boot pra montar o bot fácil; o tutorial roda por cima da partida.
  bool _isTutorial = false;

  // Intro cinematográfica (CEO 2026-06-13): nuvens → diálogo IA → moeda → 1º
  // banner. `_introDone` libera a tela. `_turnBannerPlayer` (null = sem banner;
  // true/false = de quem é o turno anunciado) dispara o banner recorrente a cada
  // virada de turno; `_bannerKey` força o re-mount pra re-animar.
  bool _introDone = false;
  bool? _turnBannerPlayer;
  Key _bannerKey = UniqueKey();

  // Tutorial da 1ª partida só abre DEPOIS da intro cinematográfica (senão os
  // diálogos colidem com nuvens/moeda/banner). Guardado no boot, disparado em
  // [_onIntroComplete].
  String? _pendingTutorialPlayerId;

  // Animação da jogada da IA (CEO 2026-06-13): a carta voa da mão da IA, vira
  // (verso→frente) e expande até a lane. `_flying` = a notificação em voo AGORA
  // (estado local de UI). GlobalKeys dão as posições origem (mão da IA) e
  // destino (lane do bot) pra converter coordenadas no Stack do Scaffold.
  final GlobalKey _matchStackKey = GlobalKey();
  final GlobalKey _botHandKey = GlobalKey();
  final GlobalKey _playerHandKey = GlobalKey();
  final Map<int, GlobalKey> _botLaneKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
  };
  final Map<int, GlobalKey> _playerLaneKeys = {
    0: GlobalKey(),
    1: GlobalKey(),
    2: GlobalKey(),
  };
  // Voo em andamento (IA ou jogador): guarda a NOTIFICAÇÃO + a GEOMETRIA capturada
  // no disparo (origem/destino/tamanho), pra animação NÃO depender de lookup de
  // render-box durante o build (era uma das causas do restart no meio do voo).
  _Flight? _flying;
  int _flightSeq = 0; // id monotônico → Key única e estável por voo
  CardPlayNotification? _lastHandledBotNotif; // idempotência do gatilho do bot
  // Pisca o cemitério (vermelho + caveira) a cada carta que entra nele. Incrementa
  // por morte/descarte do MEU lado → vira a Key do efeito one-shot (CEO 2026-06-13).
  int _cemeteryFlashSeq = 0;
  // Criatura recém-pousada de um voo → a carta real surge com fade-in (revela os
  // detalhes que a carta voadora mínima escondia). Limpo logo após o fade.
  String? _justLandedId;
  // Tremor de tela no impacto do pouso da carta (CEO 2026-06-13). Controller
  // leve, próprio; dispara em [_onFlightComplete].
  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _bootMatch();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Pré-carrega as texturas de VFX (Kenney Particle Pack) pra não engasgar no
    // 1º efeito de combate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final path in CombatVfx.all) {
        precacheImage(AssetImage(path), context);
      }
      // Texturas das NUVENS da intro — pré-carregadas pra cobrirem o campo já no
      // 1º frame (sem flash do tabuleiro antes das nuvens, CEO 2026-06-13).
      for (final path in const [
        'assets/vfx/particles/smoke_03.png',
        'assets/vfx/particles/smoke_06.png',
        'assets/vfx/particles/smoke_09.png',
      ]) {
        precacheImage(AssetImage(path), context);
      }
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
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
      // ADR-0028: herói do jogador (prefs) + herói aleatório pro bot.
      _playerHero = await CardHeroPrefs.get();
      _botHero = HeroId.values[math.Random().nextInt(HeroId.values.length)];
      // Cartomante (Fase C): resolve a carta-bônus escolhida na montagem.
      _bonusCard = null;
      if (_playerHero == HeroId.cartomante) {
        final bonusId = await CardHeroPrefs.getBonusCardId();
        if (bonusId != null) {
          Object? found;
          for (final c in catalog.creatures) {
            if (c.id == bonusId) {
              found = c;
              break;
            }
          }
          if (found == null) {
            for (final r in catalog.relics) {
              if (r.id == bonusId) {
                found = r;
                break;
              }
            }
          }
          _bonusCard = found;
        }
      }
      if (!mounted) return;
      // Tutorial (1ª partida) só abre após a intro — guardado aqui.
      _pendingTutorialPlayerId =
          (_isTutorial && playerId != null) ? playerId : null;
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
    // Nova partida: zera o estado de recompensa do round anterior + a intro.
    _reward = null;
    _rewardRequested = false;
    _introDone = false;
    _turnBannerPlayer = null;
    final seed = math.Random().nextInt(0x7fffffff);
    ref.read(pveMatchControllerProvider.notifier).startMatch(
          _playerLoadout!,
          _botLoadout!,
          seed: seed,
          heroA: _playerHero,
          heroB: _botHero,
          bonusCardA: _bonusCard,
          gateOpening: true, // a IA só joga depois da intro (ver playOpening)
        );
  }

  /// Fim da intro cinematográfica: libera a tela e, se a IA começa, roda a 1ª
  /// vez dela (que estava gateada).
  void _onIntroComplete() {
    if (!mounted) return;
    setState(() => _introDone = true);
    ref.read(pveMatchControllerProvider.notifier).playOpening();
    // Tutorial da 1ª partida (se houver) abre agora, sobre a partida já revelada.
    final tid = _pendingTutorialPlayerId;
    if (tid != null) {
      _pendingTutorialPlayerId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) TutorialManager.cardGameIntro(context, playerId: tid);
      });
    }
  }

  /// Dispara o banner de turno recorrente (pós-frame pra não mutar no meio do
  /// build). `_bannerKey` novo re-monta o TurnBanner pra re-animar.
  void _triggerTurnBanner(bool playerTurn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _turnBannerPlayer = playerTurn;
        _bannerKey = UniqueKey();
      });
    });
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

    // Níveis de aprimoramento (SPEC v1): injeta level por carta pra escalar os
    // stats no engine. Sem níveis → tudo nível 1 (sem mudança).
    Map<String, int> levels;
    try {
      levels = await ref.read(cardLevelsProvider.future);
    } catch (_) {
      levels = const {};
    }

    final creatureById = {for (final c in catalog.creatures) c.id: c};
    final relicById = {for (final r in catalog.relics) r.id: r};

    final creatures = <CreatureCard>[];
    for (final id in deck.creatureIds) {
      final c = creatureById[id];
      if (c == null) return null;
      creatures.add(c.withLevel(levels[id] ?? 1));
    }
    final relics = <RelicCard>[];
    for (final id in deck.relicIds) {
      final r = relicById[id];
      if (r == null) return null;
      relics.add(r.withLevel(levels[id] ?? 1));
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

  /// Recuar uma criatura própria pra mão (custo kReturnVoluntaryCost; ENCERRA a
  /// vez — CEO 2026-06-13). Confirma antes; avisa se faltam cristais.
  Future<void> _confirmReturnToHand(CreatureInPlay c) async {
    final board = ref.read(pveMatchControllerProvider).playerBoard;
    final crystals = board?.crystals ?? 0;
    // Cartomante (ADR-0028 Fase C): a ativa concede 1 recuo GRÁTIS (custo 0).
    // Sem teto de mão (correção CEO 2026-06-12) — nunca bloqueia por mão cheia.
    final free = board?.freeRecuoPending ?? false;
    if (!free && crystals < kReturnVoluntaryCost) {
      _toast('Cristais insuficientes para recuar (precisa de '
          '$kReturnVoluntaryCost).');
      return;
    }
    final ok = await _confirmDialog(
      title: free ? 'Recuar de graça?' : 'Recuar pra mão?',
      message: free
          ? '${c.card.nome} volta pra sua mão SEM custo (Cartomante). '
              'Relíquias equipadas são descartadas. Isso ENCERRA seu turno.'
          : '${c.card.nome} volta pra sua mão por $kReturnVoluntaryCost '
              'cristais. Relíquias equipadas são descartadas. Isso ENCERRA seu '
              'turno.',
      confirmLabel: 'Recuar',
      confirmColor: AppColors.mp,
    );
    if (ok == true) {
      ref.read(pveMatchControllerProvider.notifier).returnToHand(c.instanceId);
    }
  }

  /// Toast curto reaproveitável (avisos de ação).
  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(milliseconds: 1600),
      backgroundColor: AppColors.surfaceVeil,
      content: Text(message,
          style: GoogleFonts.roboto(color: AppColors.textPrimary, fontSize: 12)),
    ));
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

    // Oráculo (ADR-0028): quando a passiva arma o peek e é a vez do jogador,
    // abre o diálogo de espiar/reordenar (pós-frame, guard contra reentrância).
    ref.listen<PveMatchUiState>(pveMatchControllerProvider, (prev, next) {
      // IA jogou criatura → anima a carta voando da mão dela até a lane. Dispara
      // pós-frame (as GlobalKeys já layoutaram a criatura na lane destino).
      final notif = next.botPlayNotification;
      if (notif != null && _flying == null && notif != _lastHandledBotNotif) {
        _lastHandledBotNotif = notif; // 1 voo por notificação (anti re-trigger)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _flying != null) return;
          final flight = _computeFlight(notif);
          if (flight != null) _beginFlight(flight);
        });
      }
      // Morte/descarte → entrou carta no MEU cemitério: ele pisca vermelho +
      // caveira (CEO 2026-06-13). Sinal robusto (qualquer causa): cresceu o
      // graveyard do meu lado. (O cemitério da IA não fica na tela.)
      final prevGrave = prev?.playerBoard?.graveyard.length ?? 0;
      final nextGrave = next.playerBoard?.graveyard.length ?? 0;
      if (nextGrave > prevGrave) {
        setState(() => _cemeteryFlashSeq++);
      }
      // Banner de turno a cada VIRADA (depois da intro): "Seu Turno" / "Turno
      // do Oponente". Só na transição PARA playerTurn/botTurn (ignora resolving).
      if (_introDone && !next.isFinished && prev?.phase != next.phase) {
        if (next.phase == PveMatchPhase.playerTurn) {
          _triggerTurnBanner(true);
        } else if (next.phase == PveMatchPhase.botTurn) {
          _triggerTurnBanner(false);
        }
      }
      if (next.phase == PveMatchPhase.playerTurn &&
          next.playerBoard?.heroId == HeroId.oraculo &&
          (next.playerBoard?.oraculoPeekPending ?? false) &&
          !_peekDialogOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _peekDialogOpen) return;
          final pb = ref.read(pveMatchControllerProvider).playerBoard;
          if (pb != null && pb.oraculoPeekPending) _showOraculoPeekDialog(pb);
        });
      }
    });

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
          key: _matchStackKey,
          children: [
            // FUNDO do tabuleiro (CEO 2026-06-12): arte de superfície + leve
            // escurecimento nas bordas pra leitura, e poeira mágica dourada por
            // cima do fundo (atrás do conteúdo).
            Positioned.fill(
              child: Image.asset(
                'assets/images/card_game/card_game_background.png',
                fit: BoxFit.cover,
                // Decodifica num tamanho-tela (não no PNG cheio) → menos memória e
                // banda de GPU no fundo, sem perda visível (CEO 2026-06-13).
                cacheWidth: 1080,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFF120016),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.15),
                    radius: 1.3,
                    colors: [Colors.transparent, Color(0x66060008)],
                    stops: [0.55, 1.0],
                  ),
                ),
              ),
            ),
            // Poeira mágica SEMPRE montada (não recria partículas a cada virada).
            // `active` liga/desliga o controller: nas fases de turno ela tica;
            // no replay de COMBATE ela PARA (sem rebuild 60fps competindo com os
            // VFX de golpe/morte — onde o lag mais incomodava) (CEO 2026-06-13).
            Positioned.fill(
              child: MagicDustOverlay(
                active: ui.phase == PveMatchPhase.playerTurn ||
                    ui.phase == PveMatchPhase.botTurn,
              ),
            ),
            // Véu opaco no BOOT/matchmaking: o campo de batalha NÃO pode piscar
            // antes das nuvens da intro (CEO 2026-06-13). Cobre a janela
            // boot→intro; a intro (com véu próprio, opaco no 1º frame) assume a
            // cobertura assim que monta, então a transição é sem corte. Mesma cor
            // do véu da intro pra emendar perfeito. O spinner do `_body` fica
            // POR CIMA (renderizado depois no Stack).
            if (!_introDone &&
                !(_boot == _BootStatus.ready &&
                    ui.match != null &&
                    !ui.isFinished))
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFF0A0912)),
              ),
            SafeArea(child: _body(ui)),
            // (Os 3 botões agora vivem na BANDA CENTRAL do _matchBody —
            // `_centralButtonBand` —, simétricos e ancorados entre os tabuleiros.)
            // Banner de turno recorrente (trava input enquanto visível).
            if (_boot == _BootStatus.ready &&
                !ui.isFinished &&
                _turnBannerPlayer != null) ...[
              const Positioned.fill(
                child: AbsorbPointer(child: SizedBox.expand()),
              ),
              Positioned.fill(
                child: TurnBanner(
                  key: _bannerKey,
                  playerTurn: _turnBannerPlayer!,
                  onDone: () {
                    if (mounted) setState(() => _turnBannerPlayer = null);
                  },
                ),
              ),
            ],
            // Intro cinematográfica (1× por partida): nuvens → IA → moeda →
            // 1º banner. Trava tudo até terminar.
            if (_boot == _BootStatus.ready &&
                ui.match != null &&
                !ui.isFinished &&
                !_introDone)
              Positioned.fill(
                child: MatchIntroOverlay(
                  playerStarts: ui.phase == PveMatchPhase.playerTurn,
                  onComplete: _onIntroComplete,
                ),
              ),
            // Carta voando da mão → lane (jogada da IA OU do jogador). Widget
            // PRÓPRIO com Key única + AnimationController próprio: imune a
            // rebuilds/troca de índice no Stack (banner de turno etc.), então a
            // animação roda UMA vez só, sem reiniciar no meio (CEO 2026-06-13).
            if (_flying != null)
              _CardFlightOverlay(
                key: ValueKey<int>(_flying!.seq),
                flight: _flying!,
                faceBuilder: (w) => _flyingFace(_flying!.notif.creature, w),
                onComplete: _onFlightComplete,
              ),
            // DARDO à distância (CEO 2026-06-14): viaja NO TOPO (acima das lanes)
            // direto da carta atacante até o alvo — trajetória reta sem oclusão.
            if (_boot == _BootStatus.ready && !ui.isFinished)
              _rangedProjectileOverlay(ui),
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
    final interactive = ui.phase == PveMatchPhase.playerTurn &&
        !ui.playLocked &&
        _flying == null; // voo de carta = ação: trava input até pousar (respiro)

    // Tabuleiro em FOCO. Banda central (entre os dois lados) guarda os botões
    // laterais (sobrepostos no build). Sem log no meio. Mão = baralho aberto.
    final selectedCard = _selectedPoolCard(ui);

    return Column(
      children: [
        _botInfoBar(bot, ui),
        _opponentHandBacks(bot),
        // Tabuleiros AGRUPADOS no centro (mais perto um do outro): a banda
        // central de 60px guarda os botões laterais; o conjunto inteiro fica
        // centralizado verticalmente em vez de espalhado nas bordas.
        Expanded(
          // Tremor de tela no impacto do pouso (CEO 2026-06-13): só o TABULEIRO
          // treme (fundo/HUD/overlays ficam quietos). `child` fixo + RepaintBoundary
          // = o Column é construído uma vez; só o Transform recalcula por frame e o
          // repaint fica contido. Custo zero quando parado (t == 0 → child direto).
          child: AnimatedBuilder(
            animation: _shakeCtrl,
            builder: (_, child) {
              final t = _shakeCtrl.value;
              if (t == 0) return child!;
              final amp = 5.0 * (1.0 - t); // decai até 0
              final dx = math.sin(t * 3 * math.pi) * amp;
              return Transform.translate(
                offset: Offset(dx, dx * 0.6),
                child: child,
              );
            },
            child: RepaintBoundary(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // O tabuleiro do OPONENTE sobe um pouco (CEO), sem mexer no resto:
                  // Transform.translate não afeta o layout/centralização.
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: _lanesRow(ui, bot, isPlayerSide: false),
                  ),
                  // Respiro: nenhuma ação (inclusive encerrar turno) durante o voo
                  // de uma carta — só responde de novo quando a carta pousa.
                  IgnorePointer(
                    ignoring: _flying != null,
                    child: _centralButtonBand(ui),
                  ),
                  // Tabuleiro do JOGADOR desce um pouco (CEO 2026-06-13: "bem pouco").
                  Transform.translate(
                    offset: const Offset(0, 12),
                    child: AbsorbPointer(
                      absorbing: !interactive,
                      child: _lanesRow(ui, player, isPlayerSide: true),
                    ),
                  ),
                ],
              ),
            ),
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

  /// Banda central ENTRE os tabuleiros: os 3 botões redondos SEMPRE simétricos —
  /// voltar+log à esquerda, encerrar-turno à direita. Ancorada ao layout REAL
  /// (altura fixa entre as duas fileiras), nunca a uma fração da tela — acaba
  /// com o ajuste manual de altura (CEO 2026-06-13). Fora de AbsorbPointer, então
  /// voltar/log/encerrar respondem sempre (encerrar segue gateado no próprio botão).
  Widget _centralButtonBand(PveMatchUiState ui) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _sideBackButton(),
            const SizedBox(width: 8),
            _logButton(ui),
            const Spacer(),
            _endTurnButton(ui),
          ],
        ),
      ),
    );
  }

  /// Captura a GEOMETRIA do voo (origem na mão, destino na lane, tamanho do slot)
  /// UMA vez, no instante do disparo. A animação em si roda no `_CardFlightOverlay`
  /// (widget próprio, com Key única e AnimationController próprio), que NÃO faz
  /// lookup de render-box durante o build — assim o voo nunca "pisca" pra
  /// SizedBox nem reinicia quando o Stack rebuilda (CEO 2026-06-13).
  /// Retorna null se o layout ainda não resolveu (→ sem voo; a carta aparece
  /// normal, sem animação — degrada com elegância).
  _Flight? _computeFlight(CardPlayNotification n) {
    final stackBox =
        _matchStackKey.currentContext?.findRenderObject() as RenderBox?;
    final handKey = n.fromBot ? _botHandKey : _playerHandKey;
    final laneKeys = n.fromBot ? _botLaneKeys : _playerLaneKeys;
    final handBox = handKey.currentContext?.findRenderObject() as RenderBox?;
    final laneBox =
        laneKeys[n.toLane]?.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || handBox == null || laneBox == null) {
      assert(() {
        debugPrint('[_computeFlight] render-box nulo → voo ignorado '
            '(fromBot=${n.fromBot}, lane=${n.toLane})');
        return true;
      }());
      return null;
    }
    Offset centerIn(RenderBox b) =>
        stackBox.globalToLocal(b.localToGlobal(b.size.center(Offset.zero)));

    // Tamanho final = encaixe EXATO no slot (deriva da lane, não hard-coded):
    // AspectRatio 142/206 dentro da célula da lane.
    const aspect = 142 / 206; // largura/altura
    double cardH = laneBox.size.height;
    double cardW = cardH * aspect;
    if (cardW > laneBox.size.width) {
      cardW = laneBox.size.width;
      cardH = cardW / aspect;
    }

    return _Flight(
      seq: ++_flightSeq,
      notif: n,
      start: centerIn(handBox),
      end: centerIn(laneBox),
      cardW: cardW,
      cardH: cardH,
    );
  }

  /// Voo terminou (o `_CardFlightOverlay` avisou): revela a criatura real na lane
  /// com fade-in (`_justLandedId`) e encerra o voo.
  void _onFlightComplete() {
    if (!mounted) return;
    final id = _flying?.notif.creature.instanceId;
    final fromBot = _flying?.notif.fromBot ?? false;
    setState(() {
      if (id != null) _justLandedId = id;
      _flying = null;
    });
    if (id != null) _scheduleLandedClear(id);
    // Impacto (tremor de tela + haptic) SÓ na MINHA jogada. A carta do bot só voa
    // e pousa — sem tremer a tela toda a cada ação dele (menos custo por ação e
    // menos ruído visual; era parte do "flick" no turno da IA) (CEO 2026-06-13).
    if (!fromBot) _triggerLandingShake();
  }

  /// Impacto do pouso da MINHA carta: leve tremor de tela + vibração tátil sutil.
  void _triggerLandingShake() {
    HapticFeedback.lightImpact();
    _shakeCtrl.forward(from: 0);
  }

  /// Arma o voo + uma REDE DE SEGURANÇA: se por algum motivo raro o overlay sumir
  /// sem chamar `_onFlightComplete`, libera o input depois de uma folga pra a tela
  /// nunca ficar travada com `_flying` preso (CEO 2026-06-13).
  void _beginFlight(_Flight flight) {
    setState(() => _flying = flight);
    final seq = flight.seq;
    final ms = flight.notif.fromBot ? 1400 : 1000; // > duração do voo + folga
    Future<void>.delayed(Duration(milliseconds: ms), () {
      if (mounted && _flying?.seq == seq) _onFlightComplete();
    });
  }

  /// Face MÍNIMA da carta voadora (sem dano/cristal/relíquia/habilidades): no voo
  /// a carta fica "leve e menos bugada"; os detalhes entram com fade-in suave ao
  /// pousar na lane (CEO 2026-06-13).
  Widget _flyingFace(CreatureInPlay c, double w) => GameCardFace(
        width: w,
        name: c.card.nome,
        cost: c.card.cost,
        concepts: c.card.concepts,
        rarity: c.card.rarity,
        artIcon: damageTypeIcon(c.effectiveDamageType),
        minimal: true,
        footer: const SizedBox.shrink(),
      );

  /// Após o fade-in da carta recém-pousada, esquece o id (evita reanimar em
  /// rebuilds futuros). Guard por id pra não cancelar um pouso mais recente.
  void _scheduleLandedClear(String id) {
    Future<void>.delayed(const Duration(milliseconds: 360), () {
      if (mounted && _justLandedId == id) {
        setState(() => _justLandedId = null);
      }
    });
  }

  /// IDs das criaturas no MEU tabuleiro AGORA (pré-jogada) — base pro diff que
  /// descobre qual carta acabou de ser colocada.
  Set<String> _playerInstanceIds(PveMatchUiState ui) {
    final side = ui.match?.sideOf(ui.playerSide);
    if (side == null) return const <String>{};
    return {
      for (final c in side.lanes)
        if (c != null) c.instanceId,
    };
  }

  /// Dispara o voo da carta do JOGADOR (mão → slot) logo após `playCreature`.
  /// Descobre a criatura recém-colocada pelo diff de instanceIds (robusto ao
  /// empurrão/front-pack). Arma `_flying` SÍNCRONO (não pós-frame): assim a carta
  /// real já entra ESCONDIDA no mesmo rebuild da jogada — sem o flash de "carta
  /// posta e depois reanimada" (CEO 2026-06-13). A lane destino (vazia ou cheia)
  /// já tem GlobalKey e foi layoutada no frame anterior, então o `_computeFlight`
  /// acha a posição de imediato.
  void _triggerPlayerFlight(Set<String> before) {
    if (!mounted || _flying != null) return;
    final ui = ref.read(pveMatchControllerProvider);
    final side = ui.match?.sideOf(ui.playerSide);
    if (side == null) return;
    CreatureInPlay? placed;
    for (final c in side.lanes) {
      if (c != null && !before.contains(c.instanceId)) {
        placed = c;
        break;
      }
    }
    final found = placed;
    if (found == null) return; // nada novo (jogada inválida/relíquia) → sem voo
    final flight = _computeFlight(CardPlayNotification(
      creature: found,
      toLane: found.lane,
      fromBot: false,
    ));
    if (flight != null) _beginFlight(flight);
  }

  /// Indicador de TURNO compacto, ao lado do livro de skills no topo (CEO
  /// 2026-06-13). Mini spinner roxo na vez da IA.
  Widget _turnIndicatorTop(PveMatchUiState ui) {
    final turn = ui.match?.turn ?? 0;
    final botPlaying = ui.phase == PveMatchPhase.botTurn ||
        ui.phase == PveMatchPhase.resolving;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('TURNO ',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 8, color: AppColors.textMuted, letterSpacing: 1)),
        Text('$turn',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        if (botPlaying) ...[
          const SizedBox(width: 4),
          const SizedBox(
            width: 9,
            height: 9,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple)),
          ),
        ],
      ],
    );
  }

  /// HUD inferior COMPACTO e centralizado (sem moldura por ora): monstros ·
  /// cristal facetado (com borda) · itens — todos juntos no centro do rodapé.
  Widget _bottomHud(PveMatchUiState ui, BoardSide player) {
    // ADR-0028: compra EXTRA paga (1 cristal) — habilita quando dá pra comprar.
    // Sem teto de mão (correção CEO 2026-06-12): compra extra só exige deck +
    // cristais.
    final canDraw = ui.isPlayerTurn &&
        !ui.playLocked &&
        player.deck.isNotEmpty &&
        player.crystals >= kExtraDrawCost;
    // Layout (CEO 2026-06-12): CEMITÉRIO (carta-caveira) no canto inferior
    // ESQUERDO (oposto do herói); contadores + cristal ao CENTRO; COMPRAR CARTA
    // (vira carta) + HERÓI à DIREITA.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _cemeteryCard(player),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _hudCounter(Icons.pets, '${player.availableCreatureCount}',
                  svg: 'assets/icons/rpg/bestial-fangs.svg'),
              const SizedBox(width: 12),
              CrystalGem(value: player.crystals, size: 40),
              const SizedBox(width: 12),
              _hudCounter(Icons.auto_awesome, '${player.availableRelicCount}',
                  svg: 'assets/icons/rpg/rune-stone.svg'),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _drawCard(canDraw),
                if (player.heroId != null) ...[
                  const SizedBox(width: 10),
                  _heroCard(ui, player),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carta de COMPRAR CARTA = o DECK (CEO 2026-06-12): a ilustração da CAPA da
  /// carta (CardBack), maior, com o ícone de comprar carta girado 90° em cima.
  /// Paga 1 cristal.
  Widget _drawCard(bool enabled) {
    const h = 80.0;
    const w = h * CardBack.kAspect;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () => ref.read(pveMatchControllerProvider.notifier).drawCard()
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: enabled ? 1 : 0.5,
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const CardBack(height: h, radius: 7),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.black.withValues(alpha: 0.55),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.85)),
                    ),
                    child: const CardGlyph(
                      svg: 'assets/icons/rpg/card-draw.svg',
                      fallback: Icons.add_card,
                    ).build(size: 18, color: AppColors.goldLt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1 ',
                  style: GoogleFonts.robotoMono(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              const CardGlyph(
                svg: 'assets/icons/rpg/cut-diamond.svg',
                fallback: Icons.diamond,
              ).build(size: 11, color: const Color(0xFF7FD8E8)),
            ],
          ),
        ],
      ),
    );
  }

  /// Carta do CEMITÉRIO (CEO 2026-06-12): mesmo tamanho da carta do herói, com
  /// uma caveira; canto inferior ESQUERDO. Toca → peek das cartas mortas.
  Widget _cemeteryCard(BoardSide player) {
    const w = 46.0;
    const h = w * 206 / 142;
    const flashRed = Color(0xFFE5403A);
    final n = player.graveyard.length;
    final seq = _cemeteryFlashSeq;

    final tomb = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241B30), Color(0xFF0E0A16)],
        ),
        border: Border.all(color: AppColors.borderViolet, width: 1.3),
      ),
      child: Center(
        child: const CardGlyph(
          svg: 'assets/icons/rpg/tombstone.svg',
          fallback: Icons.book,
        ).build(size: 26, color: AppColors.borderViolet),
      ),
    );

    // Flash de morte (CEO 2026-06-13): a cada carta que ENTRA no cemitério, ele
    // BRILHA em vermelho + uma CAVEIRA vermelha pulsa por cima — uma vez, keyed
    // por `seq` (replays só quando uma nova carta morre). seq==0 = sem morte ainda.
    // Cemitério LIMPO no repouso; a cada carta que entra (kill/descarte) um FLASH
    // vermelho + CAVEIRA aparece POR CIMA e SOME. O glow vive num OVERLAY próprio
    // (não no túmulo) que esvanece até 0 — nunca deixa brilho preso (bug "glow
    // vermelho constante", CEO 2026-06-13). Keyed por `seq` → replay a cada morte.
    final Widget cell = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        tomb, // SEMPRE limpo
        if (seq > 0)
          IgnorePointer(
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                            color: flashRed.withValues(alpha: 0.85),
                            blurRadius: 16,
                            spreadRadius: 2),
                      ],
                    ),
                  ),
                  const CardGlyph(
                    svg: 'assets/icons/rpg/skull.svg',
                    fallback: Icons.warning_amber_rounded,
                  ).build(size: 30, color: flashRed),
                ],
              ),
            ),
          )
              // PULSAR de ~1s (CEO 2026-06-13): some lento, como um pulsar —
              // swell suave (fadeIn 320 + escala concorrente 360), segura um
              // instante e DECAI longo (fadeOut 520). Total ~1000ms.
              .animate(key: ValueKey<int>(seq))
              .fadeIn(duration: 320.ms)
              .scaleXY(
                  begin: 0.6,
                  end: 1.12,
                  duration: 360.ms,
                  curve: Curves.easeOutBack)
              .then(delay: 120.ms)
              .fadeOut(duration: 520.ms),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showCemetery,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          cell,
          const SizedBox(height: 2),
          Text('$n',
              style: GoogleFonts.robotoMono(
                  fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  /// CARTA do herói no HUD (ADR-0028 / feedback CEO 2026-06-12): substitui a
  /// "próxima" + o antigo botão. Exibe o herói como uma mini-carta; tocar usa a
  /// ATIVA (1×/partida). Acende quando a ativa está disponível; apaga após usar.
  /// Carta do HERÓI. [side]=jogador (tocável na sua vez) ou, com [opponent]=true,
  /// a carta do herói da IA: mesmo tamanho/legenda, NÃO tocável, sempre VISÍVEL
  /// (esmaece só quando a IA já usou a ativa) — pra o jogador ver qual é o herói
  /// do oponente (CEO 2026-06-13).
  Widget _heroCard(PveMatchUiState ui, BoardSide side, {bool opponent = false}) {
    final hero = side.heroId!;
    final used = side.heroActiveUsed;
    final enabled = !opponent && ui.isPlayerTurn && !ui.playLocked && !used;
    final dim = opponent ? used : !enabled;
    final showGlow = opponent ? !used : enabled;
    final accent = used ? AppColors.textMuted : AppColors.gold;
    const w = 46.0;
    const h = w * 206 / 142;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => _onHeroTap(side) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: dim ? 0.6 : 1,
            child: Container(
              width: w,
              height: h,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2C2348), Color(0xFF140D22)],
                ),
                border:
                    Border.all(color: accent.withValues(alpha: 0.85), width: 1.3),
                boxShadow: showGlow
                    ? [
                        BoxShadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 7,
                            spreadRadius: 0.5)
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_heroIcon(hero), size: 17, color: accent),
                  const SizedBox(height: 2),
                  Text(
                    _heroShort(hero),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 6.5, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(used ? 'usada' : 'ATIVA',
              style: GoogleFonts.robotoMono(
                  fontSize: 8,
                  color: used ? AppColors.textMuted : accent,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// Diálogo do cemitério: lista as cartas mortas/descartadas dos dois lados.
  void _showCemetery() {
    final ui = ref.read(pveMatchControllerProvider);
    final me = ui.playerBoard;
    final bot = ui.botBoard;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Cemitério 🪦',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 15, color: AppColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _revealSection('Seu cemitério (${me?.graveyard.length ?? 0})',
                    me?.graveyard ?? const <Object>[]),
                const SizedBox(height: 10),
                _revealSection('Cemitério da IA (${bot?.graveyard.length ?? 0})',
                    bot?.graveyard ?? const <Object>[]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Fechar',
                style: GoogleFonts.roboto(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  /// Ícone temático por herói (mini-carta do HUD).
  IconData _heroIcon(HeroId h) {
    switch (h) {
      case HeroId.trapaceiro:
        return Icons.casino;
      case HeroId.cartomante:
        return Icons.style;
      case HeroId.oraculo:
        return Icons.visibility;
      case HeroId.coringa:
        return Icons.auto_awesome;
      case HeroId.assassino:
        return Icons.gps_fixed;
    }
  }

  /// Nome curto do herói (sem artigo) pra caber na mini-carta.
  String _heroShort(HeroId h) =>
      heroLabel(h).replaceFirst('O ', '').replaceFirst('A ', '');

  /// Despacha a ATIVA do herói por tipo (ADR-0028 Fase C). Oráculo abre o
  /// diálogo de espreita (escolha embaralhar/não); Cartomante usa a ativa e,
  /// se habilitar o recuo grátis, avisa o jogador; os demais usam direto.
  Future<void> _onHeroTap(BoardSide player) async {
    final controller = ref.read(pveMatchControllerProvider.notifier);
    switch (player.heroId!) {
      case HeroId.oraculo:
        await _oraculoRevealDialog(player);
        return;
      case HeroId.cartomante:
        final ok = controller.useHeroActive();
        if (ok) {
          final after = ref.read(pveMatchControllerProvider).playerBoard;
          if (after?.freeRecuoPending ?? false) {
            _toast('Cartomante: toque 2× numa criatura sua para recuá-la de '
                'graça (ou ignore).');
          }
        }
        return;
      case HeroId.trapaceiro:
      case HeroId.assassino:
      case HeroId.coringa:
        controller.useHeroActive();
        return;
    }
  }

  /// ATIVA da Oráculo (ADR-0028): revela mão+baralho do oponente e oferece
  /// embaralhar (+`kOraculoShuffleCrystals`) ou manter (+`kOraculoKeepCrystals`).
  Future<void> _oraculoRevealDialog(BoardSide player) async {
    final opp = ref.read(pveMatchControllerProvider).botBoard;
    if (opp == null) return;
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Oráculo — espreita o oponente',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 15, color: AppColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _revealSection('Mão do oponente (${opp.hand.length})', opp.hand),
                const SizedBox(height: 10),
                _revealSection(
                    'Baralho (${opp.deck.length}) — ordem de compra', opp.deck),
                const SizedBox(height: 10),
                Text(
                  'Embaralhar devolve a mão dele ao deck e ele recompra a mesma '
                  'quantidade.',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: AppColors.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Voltar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Manter (+$kOraculoKeepCrystals 💎)',
                style: GoogleFonts.roboto(
                    color: AppColors.gold, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Embaralhar (+$kOraculoShuffleCrystals 💎)',
                style: GoogleFonts.roboto(
                    color: AppColors.purpleLight, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    ref.read(pveMatchControllerProvider.notifier).useOraculoActive(choice);
  }

  Widget _revealSection(String title, List<Object> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.robotoMono(
                fontSize: 11, color: AppColors.purpleLight)),
        const SizedBox(height: 4),
        if (cards.isEmpty)
          Text('— vazio —',
              style:
                  GoogleFonts.roboto(fontSize: 12, color: AppColors.textMuted))
        else
          ...cards.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text('• ${_objName(c)}',
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.textSecondary)),
              )),
      ],
    );
  }

  /// PASSIVA da Oráculo (ADR-0028): diálogo de espiar as próximas
  /// `kOraculoPeekCount` cartas do próprio deck e mover 1 pra qualquer posição.
  /// 1º toque escolhe a carta; 2º toque escolhe o destino. "Manter ordem" pula.
  Future<void> _showOraculoPeekDialog(BoardSide player) async {
    if (_peekDialogOpen) return;
    _peekDialogOpen = true;
    final deck = player.deck;
    final n = deck.length < kOraculoPeekCount ? deck.length : kOraculoPeekCount;
    final cards = deck.sublist(0, n);
    final controller = ref.read(pveMatchControllerProvider.notifier);
    int? from;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text('Oráculo — próximas $n cartas',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 15, color: AppColors.textPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  from == null
                      ? 'Toque numa carta para movê-la.'
                      : 'Agora toque na posição de destino.',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                ...List.generate(n, (i) {
                  final selected = from == i;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (from == null) {
                        setLocal(() => from = i);
                      } else {
                        final f = from!;
                        Navigator.of(ctx).pop();
                        controller.reorderDeck(f, i);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: selected
                            ? const Color(0xFF3A2E55)
                            : const Color(0xFF221A33),
                        border: Border.all(
                            color:
                                selected ? AppColors.gold : AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text('${i + 1}.',
                              style: GoogleFonts.robotoMono(
                                  fontSize: 12, color: AppColors.purpleLight)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_objName(cards[i]),
                                style: GoogleFonts.roboto(
                                    fontSize: 12.5,
                                    color: AppColors.textPrimary)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.reorderDeck(0, 0); // manter ordem (limpa o peek)
              },
              child: Text('Manter ordem',
                  style: GoogleFonts.roboto(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
    _peekDialogOpen = false;
  }

  /// Nome exibível de uma carta (criatura/relíquia) da mão/deck.
  String _objName(Object o) {
    if (o is CreatureCard) return o.nome;
    if (o is RelicCard) return o.nome;
    return cardId(o);
  }

  /// Contador branco (monstros / itens): ícone EM CIMA, número EMBAIXO.
  Widget _hudCounter(IconData icon, String value,
      {double size = 18, String? svg}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CardGlyph(svg: svg, fallback: icon).build(size: size, color: Colors.white),
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
        // Cresce pra caber a carta do HERÓI da IA no topo-esquerda (CEO 2026-06-13).
        height: bot.heroId != null ? 82 : 38,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Caixa do bot (ícone + 'IA') + carta do HERÓI da IA logo à direita —
            // ENTRE o ícone de IA e os contadores. Mesma carta/legenda da minha,
            // só que do oponente e NÃO-tocável (CEO 2026-06-13).
            Align(
              alignment: Alignment.topLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  if (bot.heroId != null) ...[
                    const SizedBox(width: 8),
                    _heroCard(ui, bot, opponent: true),
                  ],
                ],
              ),
            ),
            // Mini-HUD do bot CENTRALIZADO no topo (mesmo design do rodapé, menor).
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _hudCounter(Icons.pets, '${bot.availableCreatureCount}',
                      size: 14, svg: 'assets/icons/rpg/bestial-fangs.svg'),
                  const SizedBox(width: 12),
                  CrystalGem(value: bot.crystals, size: 26),
                  const SizedBox(width: 12),
                  _hudCounter(Icons.auto_awesome, '${bot.availableRelicCount}',
                      size: 14, svg: 'assets/icons/rpg/rune-stone.svg'),
                ],
                ),
              ),
            ),
            // TURNO (compacto) + livro de LEGENDA — canto direito (CEO 2026-06-13).
            Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _turnIndicatorTop(ui),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.menu_book,
                        size: 18, color: AppColors.textSecondary),
                    tooltip: 'Legenda',
                    onPressed: _showLegend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mão do OPONENTE como COSTAS de carta (ADR-0028 / feedback CEO 2026-06-12):
  /// o jogador vê a QUANTIDADE de cartas na mão do bot sem ver o conteúdo. Leque
  /// compacto e sobreposto; com a mão sem teto, limita o nº de costas visíveis e
  /// mostra o total numérico ao lado.
  Widget _opponentHandBacks(BoardSide bot) {
    final n = bot.hand.length;
    if (n == 0) return const SizedBox(height: 8);
    // Dobrado (CEO 2026-06-12) e em LEQUE espelhado (direção oposta à do jogador).
    const h = 72.0;
    const w = h * CardBack.kAspect;
    const maxShown = 8;
    final shown = n > maxShown ? maxShown : n;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: SizedBox(
        key: _botHandKey, // origem do voo da carta jogada pela IA
        height: h + 16,
        child: LayoutBuilder(
          builder: (context, cons) {
            final width = cons.maxWidth;
            final usable = (width - w).clamp(0.0, double.infinity);
            final step =
                shown > 1 ? (usable / (shown - 1)).clamp(0.0, w * 0.72) : 0.0;
            final span = step * (shown - 1) + w;
            final startX = (width - span) / 2;
            final center = (shown - 1) / 2;
            final maxArc = center * 3.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < shown; i++)
                  Builder(builder: (_) {
                    final offset = i - center;
                    // Espelhado do leque do jogador: tilt invertido e arco que
                    // abre PRA BAIXO (centro mais baixo, bordas mais altas).
                    return Positioned(
                      left: startX + step * i,
                      top: maxArc - offset.abs() * 3.0,
                      child: Transform.rotate(
                        angle: -offset * 0.05,
                        child:
                            const SizedBox(width: w, height: h, child: CardBack(radius: 6)),
                      ),
                    );
                  }),
                Positioned(
                  right: 10,
                  top: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$n',
                        style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Diálogo de LEGENDA: os 5 tipos de dano (com destaque pra vitalismo/cura,
  /// menos óbvios) + os ícones de status transitório do tabuleiro.
  void _showLegend() {
    Widget typeRow(DamageType t, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: damageTypeColor(t).withValues(alpha: 0.28),
                  border: Border.all(color: damageTypeColor(t), width: 1),
                ),
                child: typeGlyph(t, size: 12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.robotoMono(
                        fontSize: 11, color: AppColors.textPrimary)),
              ),
            ],
          ),
        );

    Widget statusRow(IconData icon, Color color, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.robotoMono(
                        fontSize: 10.5, color: AppColors.textSecondary)),
              ),
            ],
          ),
        );

    Widget sectionTitle(String t) => Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(t,
              style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold)),
        );

    Widget abilityRow(AbilityKeyword k) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8C66A), Color(0xFF8A6A2A)],
                  ),
                ),
                child: keywordGlyph(k).build(size: 11, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.robotoMono(
                        fontSize: 10.5, color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                          text: '${abilityKeywordLabel(k)} — ',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700)),
                      TextSpan(text: keywordDescription(k)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    // Habilidades agrupadas pelos lotes (ordem do enum).
    const offensive = [
      AbilityKeyword.provocar,
      AbilityKeyword.ataqueDuplo,
      AbilityKeyword.alcance,
      AbilityKeyword.inspirar,
      AbilityKeyword.pisotear,
      AbilityKeyword.cristalDeDrenagem,
      AbilityKeyword.rouboDePv,
      AbilityKeyword.investida,
      AbilityKeyword.furia,
      AbilityKeyword.cristalAdicional,
      AbilityKeyword.antiAereo,
      AbilityKeyword.quebraArmadura,
      AbilityKeyword.explosaoMagica,
    ];
    const defensive = [
      AbilityKeyword.escudo,
      AbilityKeyword.voo,
      AbilityKeyword.silencio,
      AbilityKeyword.furtividade,
      AbilityKeyword.espinhos,
      AbilityKeyword.escudoEspelhado,
      AbilityKeyword.escudoSagrado,
      AbilityKeyword.contraAtaque,
      AbilityKeyword.reflexoMagico,
      AbilityKeyword.inabalavel,
      AbilityKeyword.imunidade,
      AbilityKeyword.perseveranca,
      AbilityKeyword.vigilante,
      AbilityKeyword.encantarArmadura,
      AbilityKeyword.espinhoDeEscudo,
      AbilityKeyword.nevoa,
      AbilityKeyword.esquiva,
    ];
    const status = [
      AbilityKeyword.sangramento,
      AbilityKeyword.veneno,
      AbilityKeyword.atordoar,
      AbilityKeyword.enredar,
      AbilityKeyword.desmoralizar,
      AbilityKeyword.suprimirMagia,
      AbilityKeyword.doenca,
      AbilityKeyword.surto,
      AbilityKeyword.nevoaToxica,
    ];
    const exotic = [
      AbilityKeyword.andorinha,
      AbilityKeyword.crescimento,
      AbilityKeyword.mimico,
      AbilityKeyword.zumbi,
      AbilityKeyword.ressurreicao,
      AbilityKeyword.transformar,
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1426),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderViolet),
        ),
        title: Text('Legenda',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipos de dano',
                  style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold)),
              const SizedBox(height: 4),
              typeRow(DamageType.corpoACorpo, 'Corpo a corpo — ataca da frente'),
              typeRow(
                  DamageType.aDistancia, 'À distância — ataca da retaguarda'),
              typeRow(DamageType.magico, 'Mágico — mira o menor PV'),
              typeRow(
                  DamageType.vitalismo, 'Vitalismo — dano verdadeiro (sem armadura)'),
              typeRow(DamageType.cura, 'Cura — restaura PV de um aliado'),
              const SizedBox(height: 10),
              Text('Status no tabuleiro',
                  style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold)),
              const SizedBox(height: 4),
              statusRow(Icons.shield, const Color(0xFF9FB4D8),
                  'Armadura — reduz dano físico'),
              statusRow(Icons.auto_awesome, AppColors.conceptMagico,
                  'Armadura mágica — reduz dano mágico'),
              statusRow(Icons.water_drop, AppColors.hp,
                  'Sangramento — dano/turno (nº = acúmulos), some sozinho'),
              statusRow(Icons.science, AppColors.conceptChrysalis,
                  'Veneno — 1 dano/turno permanente (cura remove)'),
              statusRow(Icons.coronavirus, AppColors.purpleLight,
                  'Doença — suprime buffs; alvo do Surto'),
              statusRow(
                  Icons.stars, AppColors.gold, 'Atordoado — pula o próximo ataque'),
              statusRow(Icons.hub, AppColors.conceptVita,
                  'Enredado — sem Voo, pula o próximo ataque'),
              statusRow(Icons.trending_down, const Color(0xFFE08A4A),
                  'Desmoralizado / Suprimido — ataque reduzido'),
              sectionTitle('Habilidades · Ofensivas / utilidade'),
              for (final k in offensive) abilityRow(k),
              sectionTitle('Habilidades · Defensivas'),
              for (final k in defensive) abilityRow(k),
              sectionTitle('Habilidades · Status / controle'),
              for (final k in status) abilityRow(k),
              sectionTitle('Habilidades · Exóticas'),
              for (final k in exotic) abilityRow(k),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Fechar',
                style: GoogleFonts.robotoMono(color: AppColors.purpleLight)),
          ),
        ],
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

    // Destaques de seleção (apenas no lado do jogador). Criatura acende as lanes
    // JOGÁVEIS (CEO 2026-06-14): a FRENTE só com tabuleiro vazio; com carta(s), os
    // slots TRASEIROS — tocar num traseiro OCUPADO empurra o ocupante pra trás (a
    // frente nunca é empurrada por jogada). Tabuleiro cheio não acende nada.
    final highlightLanes = <int>{};
    final highlightTargets = <String>{};
    if (isPlayerSide && ui.isPlayerTurn && selected != null) {
      if (selected is CreatureCard && controller.canPlayCreature(selected)) {
        highlightLanes.addAll(controller.playableLanes(selected));
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

    // Ordem VISUAL das lanes: frente (lane 0) no MEIO; lane 1 à esquerda; lane
    // 2 à direita. Posição calculada (Stack) pra a criatura DESLIZAR entre lanes
    // ao avançar (AnimatedPositioned keyed por instanceId) em vez de teleportar.
    int visualOf(int lane) => lane == 0 ? 1 : (lane == 1 ? 0 : 2);
    const laneDepth = <double>[0, 13, 22]; // stagger em cunha (lane0 na frente)
    final dir = isPlayerSide ? 1.0 : -1.0;

    Widget cell(int lane) => _laneSlot(
          ui,
          side.lanes[lane],
          lane: lane,
          isPlayerSide: isPlayerSide,
          laneHighlighted: highlightLanes.contains(lane),
          targetHighlighted: side.lanes[lane] != null &&
              highlightTargets.contains(side.lanes[lane]!.instanceId),
        );

    // Chaves de lane ÚNICAS. Normalmente 'cre_<cardId>' (instanceId == cardId),
    // mas TOKENS idênticos (ex.: várias "Caixa Coringa" do Coringa) dividem o
    // mesmo cardId → desempata pra não duplicar Key no Stack e crashar o build
    // ("Duplicate keys found", CEO 2026-06-13). A 1ª ocorrência mantém a chave
    // limpa (slide normal das criaturas únicas); duplicatas ganham sufixo.
    final laneKeyOf = <int, String>{};
    final keySeen = <String, int>{};
    for (var lane = 0; lane < kLaneCount; lane++) {
      final c = side.lanes[lane];
      if (c == null) {
        laneKeyOf[lane] = 'empty_${side.id.name}_$lane';
      } else {
        final base = 'cre_${c.instanceId}';
        final n = keySeen[base] ?? 0;
        keySeen[base] = n + 1;
        laneKeyOf[lane] = n == 0 ? base : '$base#$n';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: SizedBox(
        height: 152,
        child: LayoutBuilder(
          builder: (context, cons) {
            const gap = 6.0;
            final slotW = (cons.maxWidth - 2 * gap) / 3;
            double xOf(int lane) => visualOf(lane) * (slotW + gap);
            double yOf(int lane) => laneDepth[lane] * dir;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var lane = 0; lane < kLaneCount; lane++)
                  if (side.lanes[lane] == null)
                    Positioned(
                      key: ValueKey<String>(laneKeyOf[lane]!),
                      left: xOf(lane),
                      top: yOf(lane),
                      width: slotW,
                      height: 152,
                      child: KeyedSubtree(
                        key: (isPlayerSide ? _playerLaneKeys : _botLaneKeys)[
                            lane],
                        child: cell(lane),
                      ),
                    )
                  else
                    AnimatedPositioned(
                      key: ValueKey<String>(laneKeyOf[lane]!),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOut,
                      left: xOf(lane),
                      top: yOf(lane),
                      width: slotW,
                      height: 152,
                      child: KeyedSubtree(
                        key: (isPlayerSide ? _playerLaneKeys : _botLaneKeys)[
                            lane],
                        child: cell(lane),
                      ),
                    ),
                if (orphanTarget) ...[
                  if (h.targetDied && !h.isHeal)
                    Positioned.fill(child: Center(child: _shardBurst(h))),
                  Positioned.fill(
                    child: Center(child: _floatingHighlightText(h)),
                  ),
                ],
              ],
            );
          },
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
          // O número desce JUNTO com o impacto do golpe (CEO 2026-06-14): espera o
          // golpe ENCOSTAR (`_hitContactMs` por tipo: melee 710 / mágico 1000 / à
          // distância 420) em vez de aparecer no início do beat. Cura/habilidade
          // têm contato 0 (aparecem na hora).
          .animate(key: ValueKey<int>(h.seq))
          .fadeIn(delay: _hitContactMs(h.damageType).ms, duration: 90.ms)
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

    // Mímico (Lote 5): com um Mímico selecionado, TODA criatura em jogo (aliada
    // ou inimiga) vira candidata a cópia; a marcada fica dourada.
    final mimicSelecting =
        _selectedIsMimic(ui) && ui.isPlayerTurn && !ui.playLocked;
    final mimicCandidate = mimicSelecting && creature != null;
    final mimicMarked =
        mimicCandidate && _mimicTargetId == creature.instanceId;

    Color? borderOverride;
    if (laneHighlighted) borderOverride = AppColors.purpleLight;
    if (targetHighlighted) borderOverride = AppColors.gold;
    if (mimicCandidate) borderOverride = AppColors.conceptMagico;
    if (mimicMarked) borderOverride = AppColors.gold;

    // Papel desta criatura no evento de combate sendo narrado (replay).
    final h = ui.highlight;
    final cid = creature?.instanceId;
    // Lado DESTA carta. O instanceId já é único por lado (engine), mas casamos o
    // LADO do destaque também — defesa extra contra cruzamento numa partida
    // ESPELHO (CEO 2026-06-13). Null-safe: se o destaque não traz lado, casa só
    // pelo id (comportamento antigo, sem regressão).
    final sideId = isPlayerSide ? ui.playerSide : ui.botSideId;
    final isHlTarget = h != null &&
        cid != null &&
        h.targetCardId == cid &&
        (h.targetSide == null || h.targetSide == sideId);
    final isHlAbility = h != null &&
        cid != null &&
        h.ability != null &&
        h.attackerCardId == cid &&
        (h.attackerSide == null || h.attackerSide == sideId);
    final isHlAttacker = h != null &&
        cid != null &&
        h.ability == null &&
        h.attackerCardId == cid &&
        (h.attackerSide == null || h.attackerSide == sideId) &&
        !isHlTarget;

    // Já estilhaçou numa batida anterior DESTE step (Pisotear/Ataque Duplo) ou
    // no respiro pós-morte: o snapshot pré-ataque ainda contém a carta, mas ela
    // não deve "ressuscitar" enquanto o destaque está noutra ação. Renderiza o
    // slot vazio/transparente até o próximo step compactar o tabuleiro.
    final shattered = creature != null &&
        h != null &&
        cid != null &&
        h.deadIds.contains(cid) &&
        h.targetCardId != cid &&
        (h.targetSide == null || h.targetSide == sideId);
    // Anti-duplicação: esconde a criatura SÓ enquanto ela está de fato VOANDO
    // (`_flying`). A carta da IA está no lado do bot (fromBot); a minha, no meu
    // lado. NÃO usar `botPlayNotification` aqui — o controller a segura ~1500ms
    // (ritmo do bot), MUITO além do voo de 900ms: a carta ficava invisível ~600ms
    // depois de pousar e sumia de vez se o voo nem iniciasse (bug "carta da IA
    // invisível", CEO 2026-06-13). O flash de 1 frame na publicação é imperceptível.
    final flyingHere = creature != null &&
        _flying != null &&
        _flying!.notif.creature.instanceId == creature.instanceId &&
        (isPlayerSide == !_flying!.notif.fromBot);
    if (shattered || flyingHere) {
      return const Center(
        child: AspectRatio(
          aspectRatio: 142 / 206,
          child: SizedBox.expand(),
        ),
      );
    }

    // Conteúdo: card no formato da coleção ou slot vazio. AnimatedSwitcher
    // keyed no instanceId → "frente sai / retaguarda entra" faz cross-fade
    // (a substituição passa a LER visualmente).
    final isMoving = isPlayerSide &&
        creature != null &&
        _movingCreatureId == creature.instanceId;
    Widget content = creature == null
        ? _emptyLane(lane, laneHighlighted)
        : _boardCard(creature,
            isFront: isFront,
            borderOverride: isMoving ? AppColors.gold : borderOverride);
    // Acabou de pousar de um voo (IA/jogador): a carta voadora era MÍNIMA — agora
    // a carta real surge com fade-in + leve assentamento, revelando os detalhes
    // (dano/cristal/relíquia/habilidades) de forma suave (CEO 2026-06-13).
    if (creature != null && creature.instanceId == _justLandedId) {
      content = content
          .animate()
          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
          .scaleXY(begin: 0.93, end: 1, duration: 340.ms, curve: Curves.easeOutBack);
    }
    // MORTE (CEO 2026-06-13): no beat em que esta criatura é o alvo que MORRE, a
    // carta vira P&B (grayscale) + ganha trincas de vidro; o estilhaço cinza voa
    // por cima (ver `_shardBurst` → CombatVfx.deathShatter).
    final isDying = creature != null &&
        h != null &&
        cid != null &&
        isHlTarget &&
        h.targetDied &&
        !h.isHeal;
    if (isDying) {
      // CEO 2026-06-13: IMPACTO → MORTE. A carta VIVA (colorida) toma o tremor de
      // impacto no momento do golpe (`_hitContactMs`); SÓ DEPOIS do impacto ela
      // perde a cor + trinca e estilhaça. Por isso o cinza entra após o impacto.
      final grayDelayMs = _hitContactMs(h.damageType) +
          _impactWindowMs(h.damageType) +
          _kDeathDelayMs;
      content = _DelayedGrayscale(delayMs: grayDelayMs, child: content);
    }

    // O tabuleiro agora DESLIZA as criaturas entre lanes (AnimatedPositioned no
    // _lanesRow, keyed por instanceId) em vez de fazer cross-fade — o cross-fade
    // (AnimatedSwitcher) fazia a carta "teleportar" ao avançar.
    Widget tile = AspectRatio(
      aspectRatio: 142 / 206,
      child: content,
    );

    // Corte de espada do atacante MELEE: wrappa o card ANTES da investida, pra
    // VIAJAR junto e flashear no pico (quando a carta "encosta" no alvo).
    // Só MELEE tem a espada — vitalismo/verdadeiro é à distância (CEO 2026-06-13).
    final showSlash = h != null &&
        isHlAttacker &&
        !h.evaded &&
        h.damageType == DamageType.corpoACorpo;
    if (creature != null && showSlash) {
      tile = Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          Positioned(
            // Bem mais PRA FORA (CEO 2026-06-13): a espada golpeia ADIANTE, rumo
            // ao alvo — destacada da carta atacante.
            top: isPlayerSide ? -58 : null,
            bottom: isPlayerSide ? null : -58,
            left: 0,
            right: 0,
            child: Center(
              child: RepaintBoundary(
                child: _slashFlash(h, isPlayerSide: isPlayerSide),
              ),
            ),
          ),
        ],
      );
    }

    // CANALIZAÇÃO de magia no ATACANTE (CEO 2026-06-13): orbe arcano que surge,
    // cresce girando (parado) e libera — sobre a carta, virado pro inimigo.
    final showChannel = h != null &&
        isHlAttacker &&
        !h.evaded &&
        h.damageType == DamageType.magico;
    if (creature != null && showChannel) {
      tile = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          tile,
          // Canalização por CÓDIGO (CEO 2026-06-13): partículas amareladas se
          // reúnem num ponto formando uma bolinha de luz, no CENTRO da carta.
          Positioned.fill(
            child: Center(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                // A canalização ENCERRA quando o raio dispara (CEO 2026-06-13):
                // some com fade até `_kMagicChannelMs`, não fica visível durante o
                // golpe.
                child: RepaintBoundary(
                  child: CombatVfx.spellChannel()
                      .animate()
                      .fadeOut(
                          delay: (_kMagicChannelMs - 150).ms,
                          duration: 150.ms),
                ),
              ),
            ),
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
            // MELEE: a carta AVANÇA cruzando a banda central até
            // "encostar" no alvo, segura no impacto (golpe de espada) e RETORNA
            // ao slot. A da FRENTE cruza a banda central (56px); uma da
            // RETAGUARDA (Alcance) avança POUCO (24px) — senão parece que "troca
            // de lugar" com a carta da frente (feedback CEO 2026-06-13). O engine
            // NÃO troca posição — Alcance ataca melee da retaguarda sem se mover.
            final lunge = isFront ? 56.0 : 24.0;
            tile = tile
                .animate(key: ValueKey<int>(h.seq))
                .moveY(
                    begin: 0,
                    end: lunge * dir,
                    duration: 240.ms,
                    curve: Curves.easeIn)
                // Segura no alvo enquanto a espada ARMA e VIAJA pra frente até o
                // impacto — só retorna depois (CEO 2026-06-13).
                .then(delay: 470.ms)
                .moveY(
                    begin: 0,
                    end: -lunge * dir,
                    duration: 320.ms,
                    curve: Curves.easeOut);
          case DamageType.vitalismo:
            // VERDADEIRO/VITALISMO funciona À DISTÂNCIA (CEO 2026-06-13): NÃO
            // avança nem usa espada — dá um "pulso" de canalização PARADO e
            // dispara um orbe ROXO (overlay no alvo). Distinto do melee/arqueiro.
            tile = tile
                .animate(key: ValueKey<int>(h.seq))
                .scaleXY(
                    begin: 1, end: 1.06, duration: 220.ms, curve: Curves.easeOut)
                .then()
                .scaleXY(
                    begin: 1, end: 1 / 1.06, duration: 220.ms, curve: Curves.easeIn);
          case DamageType.magico:
            // MAGIA (CEO 2026-06-13): a carta CANALIZA 0.8s (incha, lento) e dá um
            // COICE pra trás ao LIBERAR — então o RAIO atinge o alvo (overlay do
            // alvo). Canalização = 800ms.
            tile = tile
                .animate(key: ValueKey<int>(h.seq))
                .scaleXY(begin: 1, end: 1.07, duration: 800.ms, curve: Curves.easeInOut)
                .then()
                .moveY(begin: 0, end: -16 * dir, duration: 130.ms, curve: Curves.easeOut)
                .scaleXY(begin: 1, end: 1 / 1.07, duration: 130.ms)
                .then()
                .moveY(begin: 0, end: 16 * dir, duration: 240.ms, curve: Curves.easeOut);
          case DamageType.aDistancia:
            // Lança flecha (viaja no overlay do alvo): recuo curto de "saque".
            tile = tile
                .animate(key: ValueKey<int>(h.seq))
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
            tile = tile.animate(key: ValueKey<int>(h.seq)).shimmer(
                duration: 450.ms,
                color: AppColors.conceptChrysalis.withValues(alpha: 0.3));
        }
      } else if (isHlAbility) {
        tile = tile.animate(key: ValueKey<int>(h.seq)).shimmer(
            duration: 550.ms, color: AppColors.gold.withValues(alpha: 0.35));
      } else if (isHlTarget && !h.isHeal && h.targetDied) {
        // CEO 2026-06-13: sempre IMPACTO → MORTE. O alvo (VIVO) TREME no momento
        // do golpe (`_hitContactMs`); só DEPOIS do impacto a carta perde a cor +
        // trinca (cinza via `_DelayedGrayscale`) e ESTILHAÇA (some + estouro).
        final magicHit = h.damageType == DamageType.magico;
        final contact = _hitContactMs(h.damageType);
        tile = tile
            .animate(key: ValueKey<int>(h.seq))
            // 1) IMPACTO (reação ao golpe, carta viva). Na magia, o tremor dura a
            // EXPLOSÃO inteira (`_impactWindowMs`); só DEPOIS vem a morte.
            .shake(
                delay: contact.ms,
                hz: magicHit ? 7 : 8,
                duration: _impactWindowMs(h.damageType).ms,
                rotation: magicHit ? 0.03 : 0.014)
            // 2) MORTE: segura trincada um instante e DESPEDAÇA (some rápido com
            // leve "estouro" pra fora — não encolhe).
            .then(delay: (_kDeathDelayMs + _kDeathCrackHoldMs).ms)
            .fadeOut(duration: 160.ms, curve: Curves.easeOut)
            .scaleXY(
                begin: 1, end: 1.08, duration: 160.ms, curve: Curves.easeOut);
      } else if (isHlTarget && !h.isHeal) {
        // IMPACTO (alvo sobrevive): tremor no momento do golpe (`_hitContactMs`).
        final magicHit = h.damageType == DamageType.magico;
        tile = tile.animate(key: ValueKey<int>(h.seq)).shake(
            delay: _hitContactMs(h.damageType).ms,
            hz: magicHit ? 6 : 7,
            duration: _impactWindowMs(h.damageType).ms,
            rotation: magicHit ? 0.032 : 0.012);
      } else if (isHlTarget && h.isHeal) {
        tile = tile.animate(key: ValueKey<int>(h.seq)).shimmer(
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
            Positioned.fill(
              child: RepaintBoundary(
                  child: _impactOverlay(hh, isPlayerSide, creature.lane)),
            ),
          // Morte: com o replay pré-estado o alvo morto ainda está visível no
          // passo — o shatter estilhaça SOBRE o tile (some no passo seguinte,
          // quando o tabuleiro avança). Antes só existia no caminho "órfão".
          if (isHlTarget && hh.targetDied && !hh.isHeal)
            Positioned.fill(child: Center(child: _shardBurst(hh))),
          Positioned.fill(child: Center(child: _floatingHighlightText(hh))),
        ],
      );
    }

    // (O stagger em CUNHA agora é aplicado via `top` no _lanesRow — ver
    // `_laneStaggerY` — pra deslizar junto com o avanço entre lanes.)
    return Center(
        child: GestureDetector(
          onTap: () {
            // Voo de carta em andamento = ação em curso: ignora toques (respiro).
            if (!ui.isPlayerTurn || ui.playLocked || _flying != null) return;
            // Mímico: tocar QUALQUER criatura (aliada ou inimiga) marca/desmarca
            // como alvo da cópia (antes do guard de lado — alvo pode ser inimigo).
            if (mimicSelecting && creature != null) {
              setState(() => _mimicTargetId =
                  _mimicTargetId == creature.instanceId
                      ? null
                      : creature.instanceId);
              return;
            }
            if (!isPlayerSide) return;
            final selectedId = ui.selectedCardId;
            if (selectedId == null) {
              // Fluxo de REPOSICIONAMENTO (select + click; só pra trás):
              // 1º toque numa criatura própria seleciona; tocar OUTRA atrás =
              // troca (−2 cristais); tocar a MESMA = recuar pra mão.
              if (creature == null) {
                if (_movingCreatureId != null) {
                  setState(() => _movingCreatureId = null);
                }
                return;
              }
              if (_movingCreatureId == null) {
                setState(() => _movingCreatureId = creature.instanceId);
              } else if (_movingCreatureId == creature.instanceId) {
                final c = creature;
                setState(() => _movingCreatureId = null);
                _confirmReturnToHand(c);
              } else {
                final from = _movingCreatureId!;
                setState(() => _movingCreatureId = null);
                controller.swapPosition(from, creature.instanceId);
              }
              return;
            }
            if (_movingCreatureId != null) {
              setState(() => _movingCreatureId = null);
            }
            if (laneHighlighted) {
              // Criatura: joga aqui. Tocar um slot traseiro OCUPADO empurra o
              // ocupante pra trás (ADR-0032); a frente não é destacada com
              // carta(s) em jogo. Tabuleiro cheio não acende lane.
              // Mímico: leva o alvo marcado (ou null → engine auto-escolhe).
              final mimicId = _selectedIsMimic(ui) ? _mimicTargetId : null;
              final before = _playerInstanceIds(ui);
              controller.playCreature(selectedId, lane: lane, mimicTargetId: mimicId);
              if (_mimicTargetId != null) setState(() => _mimicTargetId = null);
              // Anima a MINHA carta voando da mão até o slot (CEO 2026-06-13).
              _triggerPlayerFlight(before);
            } else if (targetHighlighted && creature != null) {
              controller.playRelic(selectedId, creature.instanceId);
            }
          },
          child: tile,
        ),
    );
  }

  /// Overlay de impacto no card do alvo, por tipo de ataque (texturas Kenney,
  /// tingidas por elemento): mágico = orbe arcano que viaja + impacto; à
  /// distância = bolt/streak que viaja + impacto; melee/verdadeiro = impacto
  /// imediato (o corte em si é o `_slashFlash` no atacante).
  /// Direção de ENTRADA do raio mágico: aponta do ALVO para o ATACANTE (ângulo
  /// FIEL à posição de quem atacou), via lane keys. Default vertical se a
  /// geometria não estiver disponível.
  /// Vetor (no espaço do tile do alvo) de onde o ataque VEM, na direção REAL do
  /// atacante. `full=false` (magia): normalizado a 84px — o raio "entra" perto do
  /// alvo. `full=true` (à distância): vetor COMPLETO alvo→atacante — o dardo viaja
  /// a distância TODA, da carta atacante até a carta alvo (CEO 2026-06-14).
  Offset _attackerEntryFrom(
      CombatHighlight h, bool isPlayerSideTarget, int targetLane,
      {bool full = false}) {
    final fallback =
        Offset(0, isPlayerSideTarget ? -1.0 : 1.0) * (full ? 168.0 : 84.0);
    final attId = h.attackerCardId;
    if (attId == null) return fallback;
    final ui = ref.read(pveMatchControllerProvider);
    final attList = (isPlayerSideTarget ? ui.botBoard : ui.playerBoard)
            ?.creaturesInPlay ??
        const <CreatureInPlay>[];
    var attLane = -1;
    for (var i = 0; i < attList.length; i++) {
      if (attList[i].instanceId == attId) {
        attLane = i; // front-packed: índice = lane
        break;
      }
    }
    if (attLane < 0) return fallback;
    final stackBox =
        _matchStackKey.currentContext?.findRenderObject() as RenderBox?;
    final tgtBox =
        (isPlayerSideTarget ? _playerLaneKeys : _botLaneKeys)[targetLane]
            ?.currentContext
            ?.findRenderObject() as RenderBox?;
    final attBox = (isPlayerSideTarget ? _botLaneKeys : _playerLaneKeys)[attLane]
        ?.currentContext
        ?.findRenderObject() as RenderBox?;
    if (stackBox == null || tgtBox == null || attBox == null) return fallback;
    Offset centerIn(RenderBox b) =>
        stackBox.globalToLocal(b.localToGlobal(b.size.center(Offset.zero)));
    final dir = centerIn(attBox) - centerIn(tgtBox); // alvo → atacante
    if (dir.distance < 1) return fallback;
    return full ? dir : dir / dir.distance * 84.0;
  }

  /// DARDO à distância NO TOPO da pilha da partida (CEO 2026-06-14): renderizado
  /// acima das lanes pra a trajetória reta atacante→alvo NÃO ficar atrás de
  /// nenhuma carta (oclusão). Ancorado no CENTRO do alvo (coords do `_matchStack`)
  /// e viaja o vetor completo desde o atacante. O impacto/tremor ficam no tile.
  Widget _rangedProjectileOverlay(PveMatchUiState ui) {
    final h = ui.highlight;
    if (h == null ||
        h.damageType != DamageType.aDistancia ||
        h.isHeal ||
        h.evaded ||
        h.attackerCardId == null ||
        h.targetCardId == null) {
      return const SizedBox.shrink();
    }
    final isPlayerTarget = h.targetSide == ui.playerSide;
    final tgtList =
        (isPlayerTarget ? ui.playerBoard : ui.botBoard)?.creaturesInPlay ??
            const <CreatureInPlay>[];
    final attList =
        (isPlayerTarget ? ui.botBoard : ui.playerBoard)?.creaturesInPlay ??
            const <CreatureInPlay>[];
    final tLane = tgtList.indexWhere((c) => c.instanceId == h.targetCardId);
    final aLane = attList.indexWhere((c) => c.instanceId == h.attackerCardId);
    if (tLane < 0 || aLane < 0) return const SizedBox.shrink();
    final stackBox =
        _matchStackKey.currentContext?.findRenderObject() as RenderBox?;
    final tgtBox = (isPlayerTarget ? _playerLaneKeys : _botLaneKeys)[tLane]
        ?.currentContext
        ?.findRenderObject() as RenderBox?;
    final attBox = (isPlayerTarget ? _botLaneKeys : _playerLaneKeys)[aLane]
        ?.currentContext
        ?.findRenderObject() as RenderBox?;
    if (stackBox == null || tgtBox == null || attBox == null) {
      return const SizedBox.shrink();
    }
    Offset centerIn(RenderBox b) =>
        stackBox.globalToLocal(b.localToGlobal(b.size.center(Offset.zero)));
    final attC = centerIn(attBox);
    final tgtC = centerIn(tgtBox);
    const size = 104.0;
    final contact = _hitContactMs(DamageType.aDistancia);
    return Positioned(
      left: tgtC.dx - size / 2,
      top: tgtC.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: KeyedSubtree(
          key: ValueKey('fxBoltTop_${h.seq}'),
          child: CombatVfx.rangedBolt(
              durationMs: contact, from: attC - tgtC, size: size),
        ),
      ),
    );
  }

  Widget _impactOverlay(
      CombatHighlight h, bool isPlayerSideTarget, int targetLane) {
    final type = h.damageType;
    final isMagic = type == DamageType.magico;
    // Vitalismo/verdadeiro é À DISTÂNCIA (CEO 2026-06-13): orbe que VIAJA até o
    // alvo, como o arqueiro/mágico (não impacto imediato de melee).
    final isProjectile = isMagic ||
        type == DamageType.aDistancia ||
        type == DamageType.vitalismo;

    final Color color;
    switch (type) {
      case DamageType.magico:
        color = AppColors.conceptMagico;
      case DamageType.aDistancia:
        color = AppColors.gold;
      case DamageType.vitalismo:
        color = AppColors.purple; // verdadeiro/vitalismo (à distância)
      case DamageType.corpoACorpo:
      case DamageType.cura:
      case null:
        color = AppColors.hp;
    }

    // O projétil entra pela borda do lado do atacante e VIAJA até o alvo: alvo
    // do jogador (embaixo) leva tiro de cima; alvo do bot (em cima) de baixo.
    final startDy = isPlayerSideTarget ? -66.0 : 66.0;

    // MAGIA (CEO 2026-06-13): o atacante CANALIZA ~0.8s e então o RAIO (sprite
    // dourado/azul) ATINGE o alvo (junta → estoura → dissipa). Sem orbe lento; o
    // raio é instantâneo. `_kMagicChannelMs` = quando a canalização libera.
    if (isMagic) {
      final contact = _hitContactMs(h.damageType);
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // O raio: vem da direção REAL do atacante e crava no alvo.
          Center(
            child: KeyedSubtree(
              key: ValueKey('fxLightning_${h.seq}'),
              child: CombatVfx.lightningStrike(
                delayMs: _kMagicChannelMs,
                from: _attackerEntryFrom(h, isPlayerSideTarget, targetLane),
              ),
            ),
          ),
          // EXPLOSÃO de impacto no CONTATO (junto com o tremor já existente),
          // centralizada na carta atingida (CEO 2026-06-13).
          Center(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: KeyedSubtree(
                key: ValueKey('fxBlast_${h.seq}'),
                child: CombatVfx.impactBlast(
                    delayMs: contact, size: 168, durationMs: _kMagicBlastMs),
              ),
            ),
          ),
        ],
      );
    }

    // À DISTÂNCIA (CEO 2026-06-14): MESMO esquema da magia. O DARDO (gelo) viaja
    // DIRETO da carta atacante até o alvo num overlay NO TOPO
    // (`_rangedProjectileOverlay`) — assim a trajetória reta atravessa o tabuleiro
    // SEM oclusão (não fica atrás de outras cartas). AQUI no tile do alvo fica só
    // o IMPACTO no centro + o tremor já existente, no contato. Tom GELO.
    if (type == DamageType.aDistancia) {
      final contact = _hitContactMs(h.damageType);
      return IgnorePointer(
        child: Center(
          child: KeyedSubtree(
            key: ValueKey('fxImpact_${h.seq}'),
            child: CombatVfx.impactBurst(
                color: const Color(0xFF9BE8FF), delayMs: contact),
          ),
        ),
      );
    }

    const projMs = 250;
    // Impacto no CONTATO do golpe — sincroniza com o tremor do alvo. Projétil
    // chega ~250ms; melee chega no fim da estocada da espada (`_hitContactMs`).
    final impactDelay = _hitContactMs(type);
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isProjectile)
            KeyedSubtree(
              key: ValueKey('fxProj_${h.seq}'),
              child: CombatVfx.projectile(
                travel: Offset(0, startDy),
                color: color,
                arrow: type == DamageType.aDistancia,
                durationMs: projMs,
              ),
            ),
          // MELEE: CORTE vermelho atravessando a carta no impacto (CEO 2026-06-13)
          // — junto com o tremor do alvo.
          if (type == DamageType.corpoACorpo)
            Positioned.fill(child: CombatVfx.slashCut(delayMs: impactDelay)),
          KeyedSubtree(
            key: ValueKey('fxImpact_${h.seq}'),
            child: CombatVfx.impactBurst(color: color, delayMs: impactDelay),
          ),
        ],
      ),
    );
  }

  /// Golpe melee: a ESPADA (PNG tier 3) desce num arco cortando o alvo no pico
  /// da investida do atacante (CEO 2026-06-13). `flip` no lado do bot → golpe
  /// desce rumo ao jogador. (O slash de energia/impacto entra depois.)
  Widget _slashFlash(CombatHighlight h, {bool isPlayerSide = true}) {
    return KeyedSubtree(
      key: ValueKey<int>(h.seq),
      child: CombatVfx.swordStrike(
        delayMs: 240,
        flip: !isPlayerSide,
      ),
    );
  }

  /// Morte de uma carta: flash branco + ESTILHAÇOS de vidro CINZA (formas
  /// irregulares) caindo. Ancorado sobre o tile do alvo (ou centro órfão).
  Widget _shardBurst(CombatHighlight h) {
    // Estilhaça DEPOIS do IMPACTO + hold da carta trincada (sincroniza com o
    // início do fadeOut do tile): contato do golpe + impacto + hold. O controller
    // estende a janela do evento de morte (+500ms) pra esta sequência caber.
    final delayMs = _hitContactMs(h.damageType) +
        _impactWindowMs(h.damageType) +
        _kDeathDelayMs +
        _kDeathCrackHoldMs;
    return KeyedSubtree(
      key: ValueKey<int>(h.seq),
      child: CombatVfx.deathShatter(delayMs: delayMs),
    );
  }

  /// Slot de lane vazio (placeholder no formato/raio do card).
  Widget _emptyLane(int lane, bool highlighted) {
    // CEO 2026-06-13: slot mais ESCURO, SEM texto dentro, e bordas com BLUR
    // leve (halo suave em vez de linha seca).
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? AppColors.purpleLight
              : AppColors.border.withValues(alpha: 0.45),
          width: highlighted ? 1.6 : 1,
        ),
        boxShadow: [
          if (highlighted)
            const BoxShadow(color: AppColors.purpleGlow, blurRadius: 8)
          else
            BoxShadow(
              color: AppColors.border.withValues(alpha: 0.35),
              blurRadius: 5,
              spreadRadius: 0.5,
            ),
        ],
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
  /// rodapé de combate (ATK efetivo, PV atual colorido, keywords). Glow LEVE na
  /// cor do CONCEITO da carta (CEO 2026-06-13).
  Widget _boardCard(CreatureInPlay c,
      {required bool isFront, Color? borderOverride}) {
    // Glow na cor do CONCEITO e SUAVE, feito dentro da GameCardFace
    // (`glowByConcept`) — sem camada extra. Antes era um glow forte na cor do
    // TIPO DE DANO, que o CEO pediu pra trocar pelo conceito e enfraquecer.
    return GameCardFace(
      name: c.card.nome,
      cost: c.card.cost,
      concepts: c.card.concepts,
      rarity: c.card.rarity,
      artIcon: damageTypeIcon(c.effectiveDamageType),
      borderOverride: borderOverride,
      glowByConcept: true,
      cornerBadge: isFront
          ? const Icon(Icons.flag, size: 11, color: AppColors.gold)
          : null,
      showItemSlot: true,
      itemIcon: c.relics.isNotEmpty ? _relicSlotIcon(c.relics.first) : null,
      effects: effectBadgesForCreature(c),
      // CEO 2026-06-13: defesas vão pro rodapé (acima da vida); debuffs viram
      // bolinhas vermelhas no topo-direita (statusOverlay aposentado aqui).
      debuffs: _debuffGlyphs(c),
      footer: _boardFooter(c),
    );
  }

  Widget _boardFooter(CreatureInPlay c) {
    // CEO 2026-06-13: tipos de ataque EMPILHADOS (esquerda) · defesas EM CIMA da
    // vida (direita), com ícones da mesma cor/tamanho da vida.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Multi-ataque: 1 linha (ícone do tipo + valor) por tipo, empilhadas.
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final a in c.attacks)
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    typeGlyph(a.type, size: 11),
                    const SizedBox(width: 2),
                    Text('${a.value}',
                        style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold)),
                  ],
                ),
              ),
          ],
        ),
        const Spacer(),
        // Defesas EM CIMA da vida (mesma cor/tamanho de ícone que a vida).
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (c.armor > 0) _defenseLine(Icons.shield, c.armor),
            if (c.magicArmor > 0) _defenseLine(Icons.auto_awesome, c.magicArmor),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 9, color: Colors.white),
                const SizedBox(width: 2),
                // PV com contagem ANIMADA (CEO 2026-06-13): ao mudar (dano/cura)
                // o número desce/sobe contando, em vez de pular. Sem animação no
                // 1º build (Tween só com end → não conta do zero ao entrar).
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: c.currentHp.toDouble()),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  builder: (ctx, val, _) => Text('${val.round()}',
                      style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _boardHpColor(c))),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Linha de defesa (acima da vida): ícone branco tamanho 9 (igual à vida) +
  /// valor branco.
  Widget _defenseLine(IconData icon, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: Colors.white),
          const SizedBox(width: 2),
          Text('$value',
              style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }

  /// Glifos RPG dos DEBUFFS ativos (viram bolinhas vermelhas no topo-direita).
  List<CardGlyph> _debuffGlyphs(CreatureInPlay c) {
    final out = <CardGlyph>[];
    if (c.bleedStacks > 0) out.add(keywordGlyph(AbilityKeyword.sangramento));
    if (c.poisoned) out.add(keywordGlyph(AbilityKeyword.veneno));
    if (c.diseaseStacks > 0) out.add(keywordGlyph(AbilityKeyword.doenca));
    if (c.stunned) out.add(keywordGlyph(AbilityKeyword.atordoar));
    if (c.entangled) out.add(keywordGlyph(AbilityKeyword.enredar));
    if (c.desmoralizadoMelee > 0) {
      out.add(keywordGlyph(AbilityKeyword.desmoralizar));
    }
    if (c.suprimidoMagico > 0) out.add(keywordGlyph(AbilityKeyword.suprimirMagia));
    return out;
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
    // #60 (CEO 2026-06-12): a "próxima" SAIU do HUD — o rodapé agora tem a carta
    // do herói + comprar carta + cemitério. O leque mostra só a mão.
    final n = cards.length;

    const cardH = 132.0;
    const cardW = cardH * 142 / 206; // ~91
    if (n == 0) {
      return const SizedBox(height: cardH, child: Center(child: Text('')));
    }

    return SizedBox(
      key: _playerHandKey, // origem do voo da carta jogada pelo jogador
      height: cardH + 20,
      child: LayoutBuilder(
        builder: (context, cons) {
          final width = cons.maxWidth;
          final usable = (width - cardW).clamp(0.0, double.infinity);
          // Cartas mais JUNTAS (CEO 2026-06-12): mais sobreposição (clamp menor).
          final step =
              n > 1 ? (usable / (n - 1)).clamp(0.0, cardW * 0.72) : 0.0;
          final span = step * (n - 1) + cardW;
          // Um pouco mais à ESQUERDA do centro (CEO).
          final startX = (width - span) / 2 - 18;
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
                _fanCard(ui, controller, cards, null, i, n,
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
    final rot = isPreview ? 0.0 : offset * 0.075; // leque mais acentuado (CEO)
    final arcDy = offset.abs() * 5.0; // arco mais forte: bordas mais baixas

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
          ? effectGlyphsFromAbilities(creature.abilities)
          : const <EffectBadge>[],
      minimal: minimal,
      // IN-GAME: glow suave na cor do conceito (CEO 2026-06-13).
      glowByConcept: true,
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
    final fg = enabled ? AppColors.goldLt : AppColors.goldLt.withValues(alpha: 0.45);
    // Paleta da CARTA DO HERÓI (CEO 2026-06-13): corpo roxo-escuro + dourado.
    return GestureDetector(
      onTap: enabled ? _onEndTurnPressed : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2C2348), Color(0xFF140D22)],
            ),
            border:
                Border.all(color: AppColors.gold.withValues(alpha: 0.9), width: 1.6),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1)
                  ]
                : null,
          ),
          child: Center(
            child: const CardGlyph(
              svg: 'assets/icons/rpg/crossed-swords.svg',
              fallback: Icons.sports_martial_arts,
            ).build(size: 26, color: fg),
          ),
        ),
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
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C2348), Color(0xFF140D22)],
          ),
          border:
              Border.all(color: AppColors.gold.withValues(alpha: 0.8), width: 1.4),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            size: 16, color: AppColors.goldLt),
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
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C2348), Color(0xFF140D22)],
          ),
          border:
              Border.all(color: AppColors.gold.withValues(alpha: 0.8), width: 1.4),
        ),
        child: const Icon(Icons.receipt_long_outlined,
            size: 18, color: AppColors.goldLt),
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
            onPressed: () => context.push('/card-game/deck-builder'),
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

/// Geometria imutável de UM voo de carta (mão → lane), capturada no disparo. Ter
/// tudo pré-calculado faz o `_CardFlightOverlay` NÃO precisar de lookup de
/// render-box durante o build → animação estável, sem reinício no meio.
class _Flight {
  const _Flight({
    required this.seq,
    required this.notif,
    required this.start,
    required this.end,
    required this.cardW,
    required this.cardH,
  });

  final int seq; // id único do voo → vira a Key do overlay
  final CardPlayNotification notif;
  final Offset start; // centro da origem (mão), no espaço do Stack da partida
  final Offset end; // centro do destino (lane)
  final double cardW;
  final double cardH;
}

/// Overlay que anima UMA carta voando da mão até a lane. Tem ciclo de vida
/// próprio (AnimationController que roda `forward()` UMA vez no initState) e Key
/// única (via `_Flight.seq`): rebuilds do Stack pai e trocas de índice entre os
/// filhos condicionais (banner de turno etc.) não recriam o estado, então a
/// animação NÃO reinicia no meio do voo (bug CEO 2026-06-13).
///
/// Dois sabores:
///  • IA (`fromBot`): verso sai da mão, VIRA por `scaleX` (sem perspectiva 3D) e
///    expande até a lane.
///  • Jogador: a carta (de frente) sobe, cresce e DESCE encaixando com impacto.
/// Em ambos a carta é MÍNIMA; os detalhes entram com fade-in quando a criatura
/// real é revelada na lane (lado do `_CardMatchScreenState`).
class _CardFlightOverlay extends StatefulWidget {
  const _CardFlightOverlay({
    super.key,
    required this.flight,
    required this.faceBuilder,
    required this.onComplete,
  });

  final _Flight flight;
  final Widget Function(double width) faceBuilder;
  final VoidCallback onComplete;

  @override
  State<_CardFlightOverlay> createState() => _CardFlightOverlayState();
}

class _CardFlightOverlayState extends State<_CardFlightOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final ms = widget.flight.notif.fromBot ? 900 : 600;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    _ctrl.addStatusListener((status) {
      // mounted guard: se a tela sair no meio do voo, não chama de volta.
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.flight;
    final n = f.notif;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, _) {
            final t = _ctrl.value;
            late final double dx;
            late final double dy;
            late final double scale;
            late final Widget faceChild;
            if (n.fromBot) {
              final ease = Curves.easeOut.transform(t);
              dx = f.start.dx + (f.end.dx - f.start.dx) * ease;
              final arc = math.sin(t * math.pi) * 28; // pequeno arco pra cima
              dy = f.start.dy + (f.end.dy - f.start.dy) * ease - arc;
              scale = 0.72 + 0.28 * t; // expande
              // Flip por scaleX (1→0→1): borda some no meio, sem esticão.
              final flipT = ((t - 0.28) / 0.34).clamp(0.0, 1.0);
              final flipScaleX =
                  math.cos(flipT * math.pi).abs().clamp(0.05, 1.0);
              final showBack = flipT < 0.5;
              faceChild = Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(flipScaleX, 1, 1),
                child: showBack
                    ? CardBack(height: f.cardH, radius: 10)
                    : widget.faceBuilder(f.cardW),
              );
            } else {
              // Jogador: sobe + cresce, depois desce e encaixa com impacto.
              final ease = Curves.easeInOut.transform(t);
              dx = f.start.dx + (f.end.dx - f.start.dx) * ease;
              final lift = math.sin(t * math.pi) * 42; // pico acima do destino
              dy = f.start.dy + (f.end.dy - f.start.dy) * ease - lift;
              final grow = t < 0.6
                  ? 0.82 + (1.28 - 0.82) * (t / 0.6)
                  : 1.28 +
                      (1.0 - 1.28) *
                          Curves.easeOutBack.transform((t - 0.6) / 0.4);
              scale = grow.clamp(0.7, 1.4); // overshoot < 1 = squash de impacto
              faceChild = widget.faceBuilder(f.cardW);
            }
            // SEM `Positioned`: o IgnorePointer (um RenderObject) fica entre este
            // widget e o Stack, então `Positioned` seria rejeitado e a carta
            // cairia em constraints de tela cheia (esticão). `Transform.translate`
            // + `Align` posicionam sem depender de pai-Stack.
            return Transform.translate(
              offset: Offset(dx - f.cardW / 2, dy - f.cardH / 2),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: f.cardW,
                  height: f.cardH,
                  child: Transform.scale(scale: scale, child: faceChild),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Reação de IMPACTO ao golpe (CEO 2026-06-13): o alvo TREME quando o golpe
// "encosta" (ver `_hitContactMs`). Regra geral: SEMPRE impacto → depois morte.
const int _kImpactMs = 300;
// Sequência de morte: IMPACTO (carta viva treme) → P&B + trinca (segura
// `_kDeathCrackHoldMs`) → ESTILHAÇA + esvanece.
const int _kDeathCrackHoldMs = 180;
// Respiro entre o FIM do impacto e o INÍCIO da morte (P&B + estilhaço) — CEO
// 2026-06-14: a morte é um evento; pede um respiro após o impacto. A carta
// segura colorida por este tempo, então perde a cor, trinca (hold) e estilhaça.
const int _kDeathDelayMs = 200;
// Quando a ESPADA melee "encosta" no alvo (ms desde o início do beat): avanço da
// carta + mini-recuo + estocada. Sincroniza o impacto/morte com o fim do golpe.
const int _kMeleeContactMs = 710;
// MÁGICO: a carta CANALIZA 0.8s e então o RAIO atinge o alvo (CEO 2026-06-13).
const int _kMagicChannelMs = 800;
// À DISTÂNCIA: tempo de voo do dardo (gelo) da carta atacante até o alvo (CEO
// 2026-06-14). Mais longo que a flecha antiga (250ms) pra o trajeto reto ler.
const int _kRangedFlightMs = 420;
// EXPLOSÃO mágica de impacto (sprite explosion.png) — dura mais que o tremor melee
// pra a animação inteira ser percebida. A MORTE só dispara DEPOIS disso (regra do
// CEO 2026-06-13: morte sempre após as animações de ataque encerrarem).
const int _kMagicBlastMs = 620;

/// Momento (ms desde o início do beat) em que o golpe ENCOSTA no alvo, por tipo —
/// sincroniza o tremor de IMPACTO (e a MORTE, que vem depois) com a chegada do
/// golpe/projétil. CEO 2026-06-13: sempre IMPACTO antes da MORTE.
int _hitContactMs(DamageType? type) {
  switch (type) {
    case DamageType.magico:
      // Canalização (0.8s) + chegada/estouro do raio (~200ms).
      return _kMagicChannelMs + 200;
    case DamageType.corpoACorpo:
      return _kMeleeContactMs; // avanço + recuo + estocada da espada
    case DamageType.aDistancia:
      return _kRangedFlightMs; // voo do dardo de gelo até o alvo (CEO 2026-06-14)
    case DamageType.vitalismo:
      return 250; // chegada do orbe
    case DamageType.cura:
    case null:
      return 0;
  }
}

/// Janela de IMPACTO por tipo (ms): quanto tempo o alvo treme E quanto a MORTE
/// espera ANTES de estilhaçar. A magia espera a EXPLOSÃO inteira (`_kMagicBlastMs`)
/// — assim a morte só dispara após a animação de ataque (CEO 2026-06-13); os
/// demais tipos usam o tremor padrão (`_kImpactMs`).
int _impactWindowMs(DamageType? type) =>
    type == DamageType.magico ? _kMagicBlastMs : _kImpactMs;

/// Filtro de luminância (P&B) reutilizado — `const` pra não recriar por frame.
const ColorFilter _kGrayscaleFilter = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

/// Aplica P&B + trincas de vidro sobre a carta APÓS `delayMs` (0 = imediato).
/// Self-contained: tem o próprio estado/timer, então quando o tile da carta morta
/// é removido (fim do beat) o widget é descartado — e numa eventual ressurreição
/// a carta nasce sem cinza (estado novo). Resolve o "cadáver cinza" antecipado das
/// mortes mágicas (golpe chega ~1120ms depois). (CEO 2026-06-13)
class _DelayedGrayscale extends StatefulWidget {
  const _DelayedGrayscale({required this.delayMs, required this.child});
  final int delayMs;
  final Widget child;

  @override
  State<_DelayedGrayscale> createState() => _DelayedGrayscaleState();
}

class _DelayedGrayscaleState extends State<_DelayedGrayscale> {
  bool _gray = false;

  @override
  void initState() {
    super.initState();
    if (widget.delayMs <= 0) {
      _gray = true;
    } else {
      Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) setState(() => _gray = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_gray) return widget.child;
    return ColorFiltered(
      colorFilter: _kGrayscaleFilter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned.fill(child: CombatVfx.glassCrack()),
        ],
      ),
    );
  }
}


