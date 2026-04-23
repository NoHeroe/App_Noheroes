import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/npc_session.dart';
import '../../../data/datasources/local/npc_reputation_service.dart';
// Sprint 3.1 Bloco 1 — ShadowQuestService e QuestAdmissionService foram
// .bakados. Reentregues nos Blocos 7 (QuestAdmission refactor) e na Sprint
// Shadow futura. Hooks abaixo ficam como noop até lá.
import '../../shared/widgets/milestone_popup.dart';
import '../../shared/widgets/npc_dialog_overlay.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/tutorial_manager.dart';
import '../../../data/datasources/local/tutorial_service.dart';
import '../../../data/database/tables/players_table_ext.dart';
import '../widgets/caelum_day_banner.dart';
import '../widgets/shadow_status_card.dart';
import '../widgets/npc_dialogue_card.dart';
import '../../../core/utils/asset_loader.dart';
import '../widgets/stat_bars_row.dart';
import '../widgets/sanctuary_drawer.dart';
import '../../shared/widgets/nh_bottom_nav.dart';
import '../../guild/screens/guild_screen.dart';

class SanctuaryScreen extends ConsumerStatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  ConsumerState<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends ConsumerState<SanctuaryScreen> {
  static bool _guildUnlockShownThisSession = false;
  Timer? _npcTimer;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showNpc = false;
  int _lastLevel = 0;

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
    if (level == 2)  unlocks.add('📚 Biblioteca desbloqueada');
    if (level == 5)  unlocks.add('⚔️ Seleção de Classe disponível');
    if (level == 6)  unlocks.add('🛡️ Guilda de Aventureiros desbloqueada');
    if (level == 7)  unlocks.add('🏴 Facções disponíveis');
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
    final show = await NpcSession.shouldShow(
        player.caelumDay, player.shadowState);
    if (show && mounted) {
      setState(() => _showNpc = true);
      await NpcSession.markShown(player.caelumDay, player.shadowState);
      // Ganha +2 rep com NPC da facção ao ver diálogo
      final db = ref.read(appDatabaseProvider);
      final npcId = AssetLoader.npcIdForFaction(player.factionType);
      await NpcReputationService(db)
          .addReputation(player.id, npcId, 2);
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

  Future<void> _showGuildUnlockOnce() async {
    if (_SanctuaryScreenState._guildUnlockShownThisSession) return;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('guild_unlock_shown') ?? false;
    if (shown || !mounted) return;
    _SanctuaryScreenState._guildUnlockShownThisSession = true;
    await prefs.setBool('guild_unlock_shown', true);
    if (!mounted) return;
    NpcDialogOverlay.show(
      context,
      npcName: 'Noryan Gray',
      npcTitle: 'Mestre da Guilda',
      message: 'Aventureiro. A Guilda de Aventureiros agora esta acessivel para voce. Venha quando estiver pronto — o Colar te aguarda.',
    );
  }

  Future<void> _checkLevelTriggers() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null || !mounted) return;

    // Sprint 3.1 Bloco 13b — boot-check de daily/weekly reset.
    // Silencioso (erros logados no service, não propagados). Fire-and-forget
    // pra não bloquear UI. Reset services retornam DailyResetResult/
    // WeeklyResetResult — ignoramos o retorno aqui.
    unawaited(
      ref.read(dailyResetServiceProvider).checkAndApply(player.id),
    );
    unawaited(
      ref.read(weeklyResetServiceProvider).checkAndApply(player.id),
    );

    final hasClass = (player.classType?.isNotEmpty ?? false);
    final hasFaction = (player.factionType?.isNotEmpty ?? false)
        && player.factionType != 'none'
        && !(player.factionType?.startsWith('pending:') ?? false);
    final hasPlaystyle = player.playStyle.isNotEmpty && player.playStyle != 'none';

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
            child: Text('Sair',
                style: GoogleFonts.roboto(color: AppColors.hp)),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);

    // Listener REATIVO: usa playerStreamProvider (stream do banco) que emite
    // automaticamente quando o nivel muda em qualquer tela (igual v0.22.1).
    ref.listen<AsyncValue<dynamic>>(playerStreamProvider, (prev, next) async {
      final prevLevel = prev?.value?.level ?? 0;
      final nextLevel = next.value?.level ?? 0;
      if (nextLevel > prevLevel && prevLevel > 0 && mounted) {
        // Atualiza o currentPlayerProvider tambem para manter consistencia
        ref.read(currentPlayerProvider.notifier).state = next.value;
        await _checkLevelUp(nextLevel);
        if (mounted) await _checkLevelTriggers();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.black,
        drawer: const SanctuaryDrawer(),
        body: Stack(
          children: [
            _buildAtmosphere(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, player?.gold ?? 0, player?.gems ?? 0),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          StatBarsRow(),
                          SizedBox(height: 12),
                          CaelumDayBanner(),
                          SizedBox(height: 16),
                          ShadowStatusCard(),
                          SizedBox(height: 20),
                          _PlayButton(),
                          SizedBox(height: 10),
                          _SecondaryButtons(),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: NhBottomNav(currentIndex: 0),
            ),
            if (_showNpc)
              NpcDialogueOverlay(
                shadowState: ref.read(currentPlayerProvider)?.shadowState ?? 'stable',
                caelumDay: ref.read(currentPlayerProvider)?.caelumDay ?? 1,
                factionType: ref.read(currentPlayerProvider)?.factionType,
                onDismiss: () => setState(() => _showNpc = false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtmosphere() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.5),
          radius: 1.2,
          colors: [Color(0xFF1A0A2E), Color(0xFF0A0010), AppColors.black],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, int gold, int gems) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: _btn(Icons.menu),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => context.go('/dev'),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hp.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.hp.withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.bug_report, color: AppColors.hp, size: 16),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('SANTUÁRIO',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 13,
                    color: AppColors.gold,
                    letterSpacing: 3,
                  )),
            ),
          ),
          Row(
            children: [
              _currencyChip('🪙', '$gold', AppColors.gold),
              const SizedBox(width: 6),
              _currencyChip('💎', '$gems', AppColors.purple),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go('/notifications'),
            child: Stack(children: [
              _btn(Icons.notifications_none),
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.purple,
                      shape: BoxShape.circle),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _currencyChip(String emoji, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(value,
              style: GoogleFonts.roboto(
                  fontSize: 12, color: color,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _btn(IconData icon) => Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
          color: AppColors.surface,
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      );
}
class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/battle'),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFB33030).withValues(alpha: 0.6),
              width: 1.5),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B2020).withValues(alpha: 0.8),
              const Color(0xFF3A0000).withValues(alpha: 0.6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB33030).withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_martial_arts,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'ENTRAR EM COMBATE',
              style: GoogleFonts.cinzelDecorative(
                fontSize: 13,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButtons extends ConsumerWidget {
  const _SecondaryButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final level = player?.level ?? 1;
    final guildUnlocked = level >= 6;
    final hubUnlocked = level >= 25;
    final isVitalist = player?.isVitalist ?? false;

    return Column(
      children: [
        // Linha 1: Biblioteca + Vitalismo
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
              final p = ref.read(currentPlayerProvider);
              if ((p?.level ?? 1) >= 2) {
                context.go('/library');
              } else {
                AppSnack.warning(context, 'A Biblioteca abre no Nível 2.');
              }
            },
                child: _SecBtn(
                  icon: Icons.menu_book_outlined,
                  label: 'Biblioteca',
                  color: const Color(0xFFC2A05A),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!hubUnlocked) {
                    AppSnack.warning(context, 'Desbloqueado no nível 25.');
                    return;
                  }
                  context.go(isVitalist ? '/vitalism' : '/magic');
                },
                child: _SecBtn(
                  icon: !hubUnlocked
                      ? Icons.lock_outline
                      : (isVitalist ? Icons.bolt_outlined : Icons.auto_awesome),
                  label: !hubUnlocked
                      ? '???'
                      : (isVitalist ? 'Vitalismo' : 'Magia'),
                  color: !hubUnlocked
                      ? AppColors.textMuted
                      : (isVitalist
                          ? const Color(0xFF8B3DFF)
                          : AppColors.mp),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Linha 2: Guilda (largura total)
        GestureDetector(
          onTap: () {
            if (guildUnlocked) {
              context.go('/guild');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  'A Guilda de Aventureiros abre no Nível 6.',
                  style: GoogleFonts.roboto(color: Colors.white),
                ),
                backgroundColor: AppColors.surface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                duration: const Duration(seconds: 2),
              ));
            }
          },
          child: Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: guildUnlocked
                      ? AppColors.gold.withValues(alpha: 0.5)
                      : AppColors.border),
              color: guildUnlocked
                  ? AppColors.gold.withValues(alpha: 0.06)
                  : AppColors.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  guildUnlocked ? Icons.shield_outlined : Icons.lock_outline,
                  color: guildUnlocked ? AppColors.gold : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  guildUnlocked ? 'Guilda de Aventureiros' : 'Guilda  (Nível 6)',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 11,
                      color: guildUnlocked
                          ? AppColors.gold
                          : AppColors.textMuted,
                      letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SecBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SecBtn({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11, color: color, letterSpacing: 1)),
        ],
      ),
    );
  }
}
