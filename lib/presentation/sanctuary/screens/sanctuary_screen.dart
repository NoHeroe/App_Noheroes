import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/npc_session.dart';
import '../../../data/datasources/local/quest_admission_service.dart';
import '../widgets/caelum_day_banner.dart';
import '../widgets/shadow_status_card.dart';
import '../widgets/npc_dialogue_card.dart';
import '../widgets/stat_bars_row.dart';
import '../widgets/sanctuary_drawer.dart';
import '../../shared/widgets/nh_bottom_nav.dart';

class SanctuaryScreen extends ConsumerStatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  ConsumerState<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends ConsumerState<SanctuaryScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showNpc = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _runDailyReset();
      _checkLevelTriggers();
      await _checkNpcDialog();
    });
  }

  Future<void> _runDailyReset() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    await ref.read(habitDsProvider).applyDailyReset(player.id);
    ref.invalidate(habitsProvider);
    await _checkFactionAdmission();
  }

  Future<void> _checkFactionAdmission() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final faction = player.factionType ?? '';

    final factionId = faction.replaceFirst('pending:', '');
    final db = ref.read(appDatabaseProvider);
    final service = QuestAdmissionService(db);
    final passed = await service.checkFactionAdmission(player.id, factionId);

    if (passed && mounted) {
      await service.confirmFaction(player.id, factionId);
      final updated = await db.managers.playersTable
          .filter((f) => f.id(player.id))
          .getSingleOrNull();
      ref.read(currentPlayerProvider.notifier).state = updated;
      ref.invalidate(habitsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admissão aprovada! Bem-vindo à facção.'),
            backgroundColor: AppColors.shadowAscending,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _checkNpcDialog() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final show = await NpcSession.shouldShow(player.caelumDay);
    if (show && mounted) {
      setState(() => _showNpc = true);
      await NpcSession.markShown(player.caelumDay);
    }
  }

  void _checkLevelTriggers() {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    if (player.level >= 5 && (player.classType == null || player.classType!.isEmpty)) {
      context.go('/class-selection');
      return;
    }
    if (player.level >= 7 && (player.factionType == null || player.factionType!.isEmpty)) {
      context.go('/faction-selection');
    }
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
          Stack(children: [
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

class _SecondaryButtons extends StatelessWidget {
  const _SecondaryButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {}, // TODO: rota biblioteca
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFC2A05A).withValues(alpha: 0.5)),
                color: const Color(0xFFC2A05A).withValues(alpha: 0.06),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_outlined,
                      color: Color(0xFFC2A05A), size: 18),
                  const SizedBox(width: 8),
                  Text('Biblioteca',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 11,
                          color: const Color(0xFFC2A05A),
                          letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {}, // TODO: rota vitalismo
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF8B3DFF).withValues(alpha: 0.5)),
                color: const Color(0xFF8B3DFF).withValues(alpha: 0.06),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_outlined,
                      color: Color(0xFF8B3DFF), size: 18),
                  const SizedBox(width: 8),
                  Text('Vitalismo',
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 11,
                          color: const Color(0xFF8B3DFF),
                          letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
