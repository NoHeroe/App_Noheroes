import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/caelum_day_banner.dart';
import '../widgets/shadow_status_card.dart';
import '../widgets/stat_bars_row.dart';
import '../widgets/daily_missions_card.dart';
import '../widgets/sanctuary_drawer.dart';
import '../../shared/widgets/nh_bottom_nav.dart';

class SanctuaryScreen extends ConsumerStatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  ConsumerState<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends ConsumerState<SanctuaryScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDailyReset());
  }

  Future<void> _runDailyReset() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    await ref.read(habitDsProvider).applyDailyReset(player.id);
    ref.invalidate(habitsProvider);
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
                  _buildTopBar(context, player?.gold ?? 0),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 8),
                          StatBarsRow(),
                          SizedBox(height: 12),
                          CaelumDayBanner(),
                          SizedBox(height: 16),
                          ShadowStatusCard(),
                          SizedBox(height: 20),
                          DailyMissionsCard(),
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

  Widget _buildTopBar(BuildContext context, int gold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: _btn(Icons.menu),
          ),
          const Expanded(
            child: Center(
              child: Text('SANTUÁRIO',
                  style: TextStyle(
                    fontFamily: 'CinzelDecorative',
                    fontSize: 13,
                    color: AppColors.gold,
                    letterSpacing: 3,
                  )),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.surface,
            ),
            child: Row(children: [
              const Text('🪙', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$gold',
                  style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600)),
            ]),
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
