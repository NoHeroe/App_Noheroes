import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../data/datasources/local/vitalism_unique_service.dart';
import '../../../domain/enums/affinity_tier.dart';
import '../../shared/widgets/app_snack.dart';
import '../widgets/crystal_obsidian_widget.dart';

const _lifeAffinityId = 'life';

class VitalismHubScreen extends ConsumerStatefulWidget {
  const VitalismHubScreen({super.key});

  @override
  ConsumerState<VitalismHubScreen> createState() => _VitalismHubScreenState();
}

class _VitalismHubScreenState extends ConsumerState<VitalismHubScreen> {
  bool _loading = true;
  List<OwnedAffinity> _active = const [];
  List<OwnedAffinity> _dormant = const [];
  bool _isVida = false;
  LifeVitalismPointsTableData? _lifePoints;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      if (mounted) context.go('/login');
      return;
    }

    final svc = ref.read(vitalismUniqueServiceProvider);
    final active = await svc.ownedAffinitiesOf(player.id);
    final isVida = active.any((a) => a.id == _lifeAffinityId);
    final dormant = await svc.dormantAffinitiesOf(player.id);
    final lifePts = isVida ? await svc.lifePointsOf(player.id) : null;

    if (!mounted) return;
    setState(() {
      _active = active;
      _dormant = dormant;
      _isVida = isVida;
      _lifePoints = lifePts;
      _loading = false;
    });
  }

  void _onCrystalTap() {
    if (_active.isEmpty) {
      // Segurança — o guard da cerimônia já cobre, mas a porta fica aberta.
      context.go('/vitalism/crystal-ceremony');
      return;
    }
    AppSnack.info(
      context,
      'Sacrifício de recursos em desenvolvimento (sprint futura).',
    );
  }

  void _openTree(String vitalismId) {
    if (vitalismId == _lifeAffinityId) {
      context.go('/vitalism/life-tree');
      return;
    }
    context.go('/vitalism/tree/$vitalismId');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.purple,
          ),
        ),
      );
    }
    final tabCount = _isVida ? 3 : 2;
    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _HubBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  _HubHeader(onBack: () => context.go('/sanctuary')),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _onCrystalTap,
                    child: const CrystalObsidianWidget(
                      height: 160,
                      // onTap é controlado pelo wrapper externo pra customizar
                      // snackbar/navegação conforme estado do jogador.
                    ),
                  ),
                  const SizedBox(height: 20),
                  _HubTabs(includeLifeTab: _isVida),
                  Expanded(
                    child: TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _ActiveTab(
                          affinities: _active,
                          onOpen: _openTree,
                          isVida: _isVida,
                        ),
                        _DormantTab(affinities: _dormant, onOpen: _openTree),
                        if (_isVida) _LifePointsTab(data: _lifePoints),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Backdrop / Header / Tabs ────────────────────────────────────────────────

class _HubBackdrop extends StatelessWidget {
  const _HubBackdrop();
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.3,
          colors: [
            Color(0xFF15122A),
            Color(0xFF07060E),
            AppColors.black,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _HubHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textSecondary, size: 20),
            onPressed: onBack,
          ),
          Expanded(
            child: Center(
              child: Text(
                'VITALISMO',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 15,
                  color: AppColors.purpleLight,
                  letterSpacing: 6,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40), // balanço visual pro back
        ],
      ),
    );
  }
}

class _HubTabs extends StatelessWidget {
  final bool includeLifeTab;
  const _HubTabs({required this.includeLifeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: TabBar(
        indicatorColor: AppColors.purpleLight,
        indicatorWeight: 2,
        labelColor: AppColors.purpleLight,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: GoogleFonts.cinzelDecorative(
            fontSize: 11, letterSpacing: 2),
        unselectedLabelStyle: GoogleFonts.cinzelDecorative(
            fontSize: 11, letterSpacing: 2),
        tabs: [
          const Tab(text: 'ATIVAS'),
          const Tab(text: 'HISTÓRICO'),
          if (includeLifeTab) const Tab(text: 'VIDA'),
        ],
      ),
    );
  }
}

// ── Tabs ────────────────────────────────────────────────────────────────────

class _ActiveTab extends StatelessWidget {
  final List<OwnedAffinity> affinities;
  final bool isVida;
  final void Function(String id) onOpen;
  const _ActiveTab({
    required this.affinities,
    required this.isVida,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (affinities.isEmpty) {
      return const _EmptyState(
        icon: Icons.light_mode_outlined,
        title: 'Nenhuma afinidade ativa',
        subtitle:
            'O Cristal aguarda o teu toque.\nOu toma a tua afinidade em PvP.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      itemCount: affinities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final a = affinities[i];
        return _AffinityCard(
          affinity: a,
          dormant: false,
          highlight: isVida && a.id == _lifeAffinityId,
          onTap: () => onOpen(a.id),
        );
      },
    );
  }
}

class _DormantTab extends StatelessWidget {
  final List<OwnedAffinity> affinities;
  final void Function(String id) onOpen;
  const _DormantTab({required this.affinities, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (affinities.isEmpty) {
      return const _EmptyState(
        icon: Icons.ac_unit_outlined,
        title: 'Nenhuma afinidade dormente',
        subtitle:
            'Tuas árvores perdidas ficam guardadas aqui.\n'
            'Se tomares de volta a afinidade, teu progresso volta contigo.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      itemCount: affinities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final a = affinities[i];
        return _AffinityCard(
          affinity: a,
          dormant: true,
          highlight: false,
          onTap: () => onOpen(a.id),
        );
      },
    );
  }
}

class _LifePointsTab extends StatelessWidget {
  final LifeVitalismPointsTableData? data;
  const _LifePointsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data?.totalPoints ?? 0;
    final logEntries = _parseLog(data?.sourceLog);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.06),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                'PONTOS DA VIDA',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 11,
                  color: AppColors.gold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$total',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 44,
                  color: AppColors.gold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'canalizados em ti',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'HISTÓRICO',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 10),
        if (logEntries.isEmpty)
          Text(
            'Nenhum registro ainda.',
            style: GoogleFonts.roboto(
              fontSize: 12, color: AppColors.textMuted,
            ),
          )
        else
          for (final e in logEntries) ...[
            _LogEntry(entry: e),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  List<Map<String, dynamic>> _parseLog(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }
}

// ── Subwidgets ──────────────────────────────────────────────────────────────

class _AffinityCard extends StatelessWidget {
  final OwnedAffinity affinity;
  final bool dormant;
  final bool highlight;
  final VoidCallback onTap;

  const _AffinityCard({
    required this.affinity,
    required this.dormant,
    required this.highlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = highlight
        ? AppColors.gold
        : (dormant ? AppColors.textMuted : AppColors.purpleLight);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dormant ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(_tierIcon(affinity.tier), color: accent, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      affinity.name,
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      affinity.carrierName,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: accent.withValues(alpha: 0.9),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      affinity.themeDescription,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: accent.withValues(alpha: 0.7), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  IconData _tierIcon(AffinityTier tier) => switch (tier) {
        AffinityTier.common  => Icons.auto_awesome_outlined,
        AffinityTier.rare    => Icons.diamond_outlined,
        AffinityTier.special => Icons.favorite_border,
      };
}

class _LogEntry extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _LogEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final source = entry['source']?.toString() ?? '';
    final delta = entry['delta'];
    final label = switch (source) {
      'life_ritual' => 'Ritual do Vazio',
      'pvp_destroy' => 'Destruição em PvP',
      _ => source,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            '+$delta',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 13,
              color: AppColors.gold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 40),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 13,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
