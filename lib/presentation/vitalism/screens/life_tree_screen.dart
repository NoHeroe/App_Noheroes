import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';

// Tela dedicada do Vitalismo da Vida. Árvore dinâmica real fica pra sprint
// de conteúdo futura — aqui mostra pontos acumulados e histórico do sourceLog.

class LifeTreeScreen extends ConsumerStatefulWidget {
  const LifeTreeScreen({super.key});

  @override
  ConsumerState<LifeTreeScreen> createState() => _LifeTreeScreenState();
}

class _LifeTreeScreenState extends ConsumerState<LifeTreeScreen> {
  bool _loading = true;
  LifeVitalismPointsTableData? _data;

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
    final isVida = await svc.isVitalistaDaVida(player.id);
    if (!mounted) return;
    if (!isVida) {
      context.go('/vitalism');
      return;
    }

    final data = await svc.lifePointsOf(player.id);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.gold,
          ),
        ),
      );
    }
    final total = _data?.totalPoints ?? 0;
    final log = _parseLog(_data?.sourceLog);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.3,
                colors: [
                  Color(0xFF15122A),
                  Color(0xFF07060E),
                  AppColors.black,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: () => context.go('/vitalism'),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'VITALISMO DA VIDA',
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 13,
                              color: AppColors.gold,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
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
                    fontSize: 64,
                    color: AppColors.gold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'canalizados em ti',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.border, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surface,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ÁRVORE DINÂMICA',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Em desenvolvimento — a árvore da Vida cresce com '
                        'gameplay. Nós serão gerados procedurally em sprint '
                        'futura, quando a engine externa entrar.',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'HISTÓRICO',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: log.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Nenhum registro ainda.',
                            style: GoogleFonts.roboto(
                              fontSize: 12, color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          itemCount: log.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _LogEntry(entry: log[i]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
