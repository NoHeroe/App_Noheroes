import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../notifications/notifications_screen.dart';
import '../../../core/utils/npc_session.dart';
import '../../../data/datasources/local/npc_reputation_service.dart';
// Sprint 3.1 Bloco 1 — ShadowQuestService e QuestAdmissionService foram
// .bakados. Reentregues nos Blocos 7 (QuestAdmission refactor) e na Sprint
// Shadow futura. Hooks abaixo ficam como noop até lá.
import '../../shared/widgets/milestone_popup.dart';
import '../../shared/widgets/npc_dialog_overlay.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/tutorial_manager.dart';
import '../widgets/caelum_day_banner.dart';
import '../widgets/shadow_status_card.dart';
import '../widgets/npc_dialogue_card.dart';
import '../../../core/utils/asset_loader.dart';
import '../widgets/sanctuary_drawer.dart';
import '../../shared/widgets/nh_bottom_nav.dart';
// Restyle Santuário (mockup v3) — camada visual extraída em widgets.
import '../widgets/sanctuary_atmosphere.dart';
import '../widgets/sanctuary_header_widgets.dart';
import '../widgets/sanctuary_combat_hex.dart';

class SanctuaryScreen extends ConsumerStatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  ConsumerState<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends ConsumerState<SanctuaryScreen> {
  Timer? _npcTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showNpc = false;
  int _lastLevel = 0;

  @override
  void dispose() {
    _npcTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    // Timer NPC 15min
    _npcTimer = Timer(const Duration(minutes: 15), _triggerNpcTimer);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final player = ref.read(currentPlayerProvider);
      final currentLevel = player?.level ?? 1;
      // Detecta level up comparando com nível salvo
      final prefs = await SharedPreferences.getInstance();
      final savedLevel = prefs.getInt('last_known_level') ?? currentLevel;
      if (currentLevel > savedLevel && savedLevel > 0) {
        await prefs.setInt('last_known_level', currentLevel);
        _lastLevel = savedLevel;
        if (mounted) await _checkLevelUp(currentLevel);
      } else {
        await prefs.setInt('last_known_level', currentLevel);
        _lastLevel = currentLevel;
      }
      // Daily reset em background (nao bloqueia tutoriais)
      unawaited(_runDailyReset());
      // Aguarda Navigator estabilizar apos rebuilds/invalidacoes
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await _checkLevelTriggers();
      if (!mounted) return;
      await _checkNpcDialog();
    });
  }

  Future<void> _runDailyReset() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    // Sprint 3.1 Bloco 1 — daily reset legacy neutralizado. Novo fluxo vive
    // em DailyResetService (Bloco 14) e será disparado por um provider
    // reativo que substitui este _runDailyReset inteiro no Bloco 10.
    // Check de admissão de facção fica por enquanto como noop também
    // (QuestAdmissionService .bakado — volta no Bloco 7).
    // ignore: unused_local_variable
    final _ = player; // silencia lint até Bloco 10 reconectar.
  }

  Future<void> _checkLevelUp(int newLevel) async {
    if (newLevel > _lastLevel && _lastLevel > 0) {
      _lastLevel = newLevel;
      if (!mounted) return;
      final unlocks = _levelUnlocks(newLevel);
      await MilestonePopup.show(
        context,
        title: 'Nível $newLevel',
        subtitle: 'Subiu de nível',
        message: unlocks.isNotEmpty
            ? 'Você alcançou o Nível $newLevel!\n\n${unlocks.join('\n')}'
            : 'Você alcançou o Nível $newLevel!\nCaelum reconhece seu crescimento.',
        icon: Icons.arrow_circle_up,
        color: AppColors.xp,
      );
    }
  }

  List<String> _levelUnlocks(int level) {
    final unlocks = <String>[];
    if (level == 2) unlocks.add('📚 Biblioteca desbloqueada');
    if (level == 5) unlocks.add('⚔️ Seleção de Classe disponível');
    if (level == 6) unlocks.add('🛡️ Guilda de Aventureiros desbloqueada');
    if (level == 7) unlocks.add('🏴 Facções disponíveis');
    if (level == 10) unlocks.add('🗺️ Regiões médias desbloqueadas');
    if (level == 25) unlocks.add('✨ Vitalismo avançado desbloqueado');
    if (level == 15) unlocks.add('⚔️ Estilo de Jogo disponível');
    if (level == 50) unlocks.add('🌟 Subclasses disponíveis');
    return unlocks;
  }

  // Sprint 3.1 Bloco 1 — `_checkShadowQuests` e `_checkFactionAdmission`
  // neutralizados. ShadowQuestService e QuestAdmissionService estão .bakados;
  // os fluxos correspondentes reentram pelos Blocos 7 (admissão refatorada)
  // e pela Sprint Shadow futura.

  Future<void> _checkNpcDialog() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final show =
        await NpcSession.shouldShow(player.caelumDay, player.shadowState);
    if (show && mounted) {
      setState(() => _showNpc = true);
      await NpcSession.markShown(player.caelumDay, player.shadowState);
      // Ganha +2 rep com NPC da facção ao ver diálogo
      final client = ref.read(supabaseClientProvider);
      final npcId = AssetLoader.npcIdForFaction(player.factionType);
      await NpcReputationService(client).addReputation(player.id, npcId, 2);
    }
  }

  void _triggerNpcTimer() {
    if (!mounted) return;
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final messages = [
      'Você está há bastante tempo aqui. Caelum observa quem persiste.',
      'O tempo que você investe aqui se transforma em algo real. Continue.',
      'Sua sombra ficou inquieta enquanto você estava parado. Aja.',
      'Noryan Gray perguntou por você. Parece que há missões esperando.',
      'O Vazio reconhece presença. Você está construindo algo.',
    ];
    messages.shuffle();
    NpcDialogOverlay.show(
      context,
      npcName: 'Noryan Gray',
      npcTitle: 'Mestre da Guilda',
      message: messages.first,
    );
  }

  Future<void> _checkLevelTriggers() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null || !mounted) return;

    // Época 2 (ADR-0024) — DailyResetService/WeeklyResetService legados
    // removidos. O rollover diário/semanal agora é automático via
    // DailyMissionRolloverService (camada de dados full-online), então o
    // boot-check manual deixou de existir aqui.

    final hasClass = (player.classType?.isNotEmpty ?? false);
    final hasFaction = (player.factionType?.isNotEmpty ?? false) &&
        player.factionType != 'none' &&
        !(player.factionType?.startsWith('pending:') ?? false);
    final hasPlaystyle =
        player.playStyle.isNotEmpty && player.playStyle != 'none';

    // Fase 10 só dispara a cerimônia do Cristal pra vitalistas sem afinidade.
    // Consulta ao banco é feita apenas se o player já atingiu o nível 25.
    var isVitalistWithoutAffinity = false;
    if (player.level >= 25 && player.isVitalist) {
      final owned = await ref
          .read(vitalismUniqueServiceProvider)
          .ownedAffinitiesOf(player.id);
      if (!mounted) return;
      isVitalistWithoutAffinity = owned.isEmpty;
    }

    // Sprint 3.1 Bloco 14.6a — `hasCalibrated` deixa de ser consultado
    // aqui: a calibração agora é feita no `AwakeningScreen` (onboarding),
    // e `TutorialManager.runAll` não dispara mais o quiz via phase13.
    await TutorialManager.runAll(
      context,
      ref: ref,
      playerId: player.id,
      level: player.level,
      hasClass: hasClass,
      hasFaction: hasFaction,
      hasPlaystyle: hasPlaystyle,
      isVitalistWithoutAffinity: isVitalistWithoutAffinity,
    );
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Sair de Caelum?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 15)),
        content: Text('Sua sombra permanecerá aguardando.',
            style: GoogleFonts.roboto(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ficar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sair', style: GoogleFonts.roboto(color: AppColors.hp)),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);

    // Listener REATIVO: usa playerStreamProvider (stream do banco) que
    // emite automaticamente quando o nível muda em qualquer tela.
    //
    // Sprint 3.4 Etapa A hotfix — guard `prevLevel > 0` removida.
    // Antes bloqueava a primeira detecção (quando `prev` era null no
    // mount inicial), criando janelas em que `currentPlayerProvider`
    // ficava stale. Sincronização global agora vive em
    // `playerStateSyncServiceProvider` (app_listeners.dart) — este
    // listener fica responsável apenas pelo popup de level-up
    // (MilestonePopup) + checagem de unlocks, que ainda exigem level
    // diverging strictly upward.
    ref.listen<AsyncValue<dynamic>>(playerStreamProvider, (prev, next) async {
      final prevLevel = prev?.value?.level ?? 0;
      final nextLevel = next.value?.level ?? 0;
      if (nextLevel > prevLevel && mounted) {
        // Sync defensivo (idempotente — sync global já cobre via
        // playerStateSyncServiceProvider, mas garantimos consistência
        // local pra esta tela observar `currentPlayerProvider` rebuild
        // imediato).
        ref.read(currentPlayerProvider.notifier).state = next.value;
        // Popup só dispara se não é a 1ª emissão (prevLevel > 0).
        if (prevLevel > 0) {
          await _checkLevelUp(nextLevel);
          if (mounted) await _checkLevelTriggers();
        }
      }
    });

    final level = player?.level ?? 1;
    final isVitalist = player?.isVitalist ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.blackVeil,
        drawer: const SanctuaryDrawer(),
        body: Stack(
          children: [
            const SanctuaryAtmosphere(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Row 1 — perfil + carteira
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: SanctuaryMiniProfile()),
                          SizedBox(width: 16),
                          SanctuaryWalletPills(),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.06, curve: Curves.easeOut),
                      const SizedBox(height: 16),
                      // Row 2 — utilitários
                      SanctuaryUtilRow(
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                        onInbox: () => AppSnack.warning(
                            context, 'Caixa de entrada em breve.'),
                        onFriends: () =>
                            AppSnack.warning(context, 'Amigos em breve.'),
                        onBell: () =>
                            NotificationsScreen.showPanel(context),
                      ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: 20),
                      const CaelumDayBanner()
                          .animate(delay: 140.ms)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 20),
                      const ShadowStatusCard()
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.08, curve: Curves.easeOut),
                      const SizedBox(height: 24),
                      SanctuaryCombatHex(onTap: () => context.go('/battle'))
                          .animate(delay: 280.ms)
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.1, curve: Curves.easeOut),
                      const SizedBox(height: 28),
                      _buildMedallions(context, level, isVitalist)
                          .animate(delay: 360.ms)
                          .fadeIn(duration: 500.ms),
                      const SizedBox(height: 32),
                      // TEMP DEV — remover no release. Acesso ao Dev Panel
                      // (saiu do topbar no restyle da Fatia 1).
                      Center(child: _devChip(context)),
                      const SizedBox(height: 16),
                      const SizedBox(height: 88), // respiro acima da navbar
                    ],
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: NhBottomNav(currentIndex: 2),
            ),
            if (_showNpc)
              NpcDialogueOverlay(
                shadowState:
                    ref.read(currentPlayerProvider)?.shadowState ?? 'stable',
                caelumDay: ref.read(currentPlayerProvider)?.caelumDay ?? 1,
                factionType: ref.read(currentPlayerProvider)?.factionType,
                onDismiss: () => setState(() => _showNpc = false),
              ),
          ],
        ),
      ),
    );
  }

  // TEMP DEV — remover no release. Chip discreto de acesso ao Dev Panel.
  Widget _devChip(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/dev'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surfaceVeil2,
          border: Border.all(color: AppColors.goldDk),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bug_report, size: 14, color: AppColors.txt2),
            const SizedBox(width: 6),
            Text(
              'DEV',
              style: GoogleFonts.roboto(
                fontSize: 11,
                letterSpacing: 1.5,
                color: AppColors.txt2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Medalhões com alturas alternadas pra dispersão (mockup v3). Gates
  // preservados: Biblioteca lvl 2, Guilda lvl 6, Vitalismo lvl 25.
  Widget _buildMedallions(BuildContext context, int level, bool isVitalist) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: SanctuaryMedallion(
            label: 'Biblioteca',
            icon: Icons.menu_book_outlined,
            locked: level < 2,
            onTap: () {
              if (level >= 2) {
                context.go('/library');
              } else {
                AppSnack.warning(context, 'A Biblioteca abre no Nível 2.');
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SanctuaryMedallion(
            label: 'Guilda',
            icon: Icons.shield_outlined,
            locked: level < 6,
            onTap: () {
              if (level >= 6) {
                context.go('/guild');
              } else {
                AppSnack.warning(
                    context, 'A Guilda de Aventureiros abre no Nível 6.');
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SanctuaryMedallion(
            label: 'Vitalismo',
            icon: isVitalist ? Icons.bolt_outlined : Icons.auto_awesome,
            locked: level < 25,
            onTap: () {
              if (level >= 25) {
                context.go(isVitalist ? '/vitalism' : '/magic');
              } else {
                AppSnack.warning(context, 'Desbloqueado no Nível 25.');
              }
            },
          ),
        ),
      ],
    );
  }
}
