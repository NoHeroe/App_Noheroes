import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../core/widgets/animated_bg.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../../domain/services/body_metrics_service.dart';
import '../../shared/widgets/player_stats_counter.dart';

/// Sprint 3.2 Etapa 1.0 — Perfil do jogador.
///
/// Exibe identidade (nome/classe/level/rank), dados físicos (peso/altura/IMC
/// + faixa OMS) e recomendações diárias (água/proteína baseadas em peso).
/// Edição inline via dialog (lápis ao lado de cada valor).
///
/// Acessível via SanctuaryDrawer (item "Perfil") ou navegação direta /perfil.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    if (player == null) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: Text('Sem jogador.',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    final service = ref.watch(bodyMetricsServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBg(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const _Header(),
                const SizedBox(height: 16),
                _IdentityCard(player: player),
                const SizedBox(height: 16),
                _BodyMetricsCard(player: player, service: service),
                const SizedBox(height: 16),
                _RecommendationsCard(player: player, service: service),
                const SizedBox(height: 16),
                _PreferencesCard(player: player),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    return Row(
      children: [
        GestureDetector(
          key: const ValueKey('profile-back'),
          onTap: () => context.go('/sanctuary'),
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
        Text(
          'PERFIL',
          style: GoogleFonts.cinzelDecorative(
              fontSize: 16, color: AppColors.gold, letterSpacing: 2),
        ),
        const Spacer(),
        PlayerStatsCounter(
          gold: player?.gold ?? 0,
          xp: player?.xp ?? 0,
          gems: player?.gems ?? 0,
        ),
      ],
    );
  }
}

String _classLabel(String? c) => switch (c) {
      'warrior' => 'Guerreiro',
      'colossus' => 'Colosso',
      'monk' => 'Monge',
      'rogue' => 'Ladino',
      'hunter' => 'Caçador',
      'druid' => 'Druida',
      'mage' => 'Mago',
      'shadowWeaver' => 'Tecelão de Sombras',
      _ => 'Sem Classe',
    };

class _IdentityCard extends StatelessWidget {
  final PlayersTableData player;
  const _IdentityCard({required this.player});

  @override
  Widget build(BuildContext context) {
    final hasRank = player.guildRank != 'none';
    final rankLabel = hasRank
        ? GuildRankSystem.label(GuildRankSystem.fromString(player.guildRank))
            .toUpperCase()
        : 'SEM RANK';

    return _Card(
      title: 'IDENTIDADE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(player.shadowName,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 20, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(_classLabel(player.classType),
              style: GoogleFonts.roboto(
                  fontSize: 14, color: AppColors.purpleLight)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Pill(
                label: 'Nível ${player.level}',
                color: AppColors.purple,
              ),
              const SizedBox(width: 8),
              _Pill(
                label: rankLabel,
                color: hasRank ? AppColors.gold : AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyMetricsCard extends ConsumerWidget {
  final PlayersTableData player;
  final BodyMetricsService service;
  const _BodyMetricsCard({required this.player, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bmi = service.bmi(player);
    final category = service.bmiCategory(player);

    return _Card(
      title: 'DADOS FÍSICOS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            label: 'Peso',
            value: player.weightKg == null ? '—' : '${player.weightKg} kg',
            editKey: 'profile-edit-weight',
            onEdit: () => _editDialog(
              context: context,
              ref: ref,
              field: _Field.weight,
              current: player.weightKg,
            ),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Altura',
            value: player.heightCm == null ? '—' : '${player.heightCm} cm',
            editKey: 'profile-edit-height',
            onEdit: () => _editDialog(
              context: context,
              ref: ref,
              field: _Field.height,
              current: player.heightCm,
            ),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'IMC',
            value: bmi == null ? '—' : bmi.toStringAsFixed(1),
            editKey: null,
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Faixa',
            value: category,
            editKey: null,
            valueColor: _categoryColor(category),
          ),
        ],
      ),
    );
  }

  Future<void> _editDialog({
    required BuildContext context,
    required WidgetRef ref,
    required _Field field,
    required int? current,
  }) async {
    final isWeight = field == _Field.weight;
    final min = isWeight
        ? BodyMetricsService.minWeightKg
        : BodyMetricsService.minHeightCm;
    final max = isWeight
        ? BodyMetricsService.maxWeightKg
        : BodyMetricsService.maxHeightCm;
    final unit = isWeight ? 'kg' : 'cm';
    final title = isWeight ? 'Peso' : 'Altura';
    final ctrl = TextEditingController(text: current?.toString() ?? '');

    final newValue = await showDialog<int>(
      context: context,
      builder: (ctx) => _NumberInputDialog(
        title: title,
        unit: unit,
        controller: ctrl,
        min: min,
        max: max,
      ),
    );
    if (newValue == null) return;

    await service.save(
      playerId: player.id,
      weightKg: isWeight ? newValue : null,
      heightCm: isWeight ? null : newValue,
    );
    final db = ref.read(appDatabaseProvider);
    final fresh = await (db.select(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .getSingle();
    ref.read(currentPlayerProvider.notifier).state = fresh;
  }

  Color _categoryColor(String c) => switch (c) {
        BodyMetricsService.categoryNormal => AppColors.rarityUncommon,
        BodyMetricsService.categoryUnderweight => AppColors.shadowObsessive,
        BodyMetricsService.categoryOverweight => AppColors.shadowObsessive,
        BodyMetricsService.categoryObese => AppColors.hp,
        _ => AppColors.textMuted,
      };
}

enum _Field { weight, height }

class _RecommendationsCard extends StatelessWidget {
  final PlayersTableData player;
  final BodyMetricsService service;
  const _RecommendationsCard({required this.player, required this.service});

  @override
  Widget build(BuildContext context) {
    final water = service.recommendedWaterMl(player);
    final protein = service.recommendedProteinG(player);
    return _Card(
      title: 'RECOMENDAÇÕES DIÁRIAS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            label: 'Água',
            value: water == null ? '—' : '$water ml',
            editKey: null,
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Proteína',
            value: protein == null ? '—' : '$protein g',
            editKey: null,
          ),
          if (water == null || protein == null) ...[
            const SizedBox(height: 12),
            Text(
              'Preenche peso pra calcular as recomendações.',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sprint 3.3 Etapa 2.1c-β — toggle de modo automático de daily missions.
///
/// Quando ativo, missões com 100% em todas as sub-tarefas são
/// auto-completadas no rollover diário (sem exigir clique manual no ✓).
/// Default: false. Persistência via [PlayerDao.setAutoConfirmEnabled].
class _PreferencesCard extends ConsumerWidget {
  final PlayersTableData player;
  const _PreferencesCard({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      title: 'PREFERÊNCIAS',
      child: SwitchListTile(
        key: const ValueKey('profile-toggle-auto-confirm'),
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Modo automático de missões diárias',
          style: GoogleFonts.roboto(
              fontSize: 13, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          'Missões com 100% em todas as sub-tarefas serão completadas '
          'automaticamente no rollover.',
          style: GoogleFonts.roboto(
              fontSize: 11, color: AppColors.textMuted, height: 1.4),
        ),
        activeColor: AppColors.gold,
        value: player.autoConfirmEnabled,
        onChanged: (value) async {
          final db = ref.read(appDatabaseProvider);
          await PlayerDao(db).setAutoConfirmEnabled(player.id, value);
          // Refresca currentPlayerProvider pra UI reagir.
          final fresh = await PlayerDao(db).findById(player.id);
          if (fresh != null) {
            ref.read(currentPlayerProvider.notifier).state = fresh;
          }
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cinzelDecorative(
                fontSize: 12, color: AppColors.gold, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String? editKey;
  final VoidCallback? onEdit;
  final Color? valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.editKey,
    this.onEdit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: valueColor ?? AppColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (editKey != null)
          IconButton(
            key: ValueKey(editKey),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined,
                size: 16, color: AppColors.textMuted),
            visualDensity: VisualDensity.compact,
          )
        else
          const SizedBox(width: 40),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cinzelDecorative(
            fontSize: 10, color: color, letterSpacing: 1),
      ),
    );
  }
}

class _NumberInputDialog extends StatefulWidget {
  final String title;
  final String unit;
  final TextEditingController controller;
  final int min;
  final int max;
  const _NumberInputDialog({
    required this.title,
    required this.unit,
    required this.controller,
    required this.min,
    required this.max,
  });

  @override
  State<_NumberInputDialog> createState() => _NumberInputDialogState();
}

class _NumberInputDialogState extends State<_NumberInputDialog> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(
        widget.title,
        style: GoogleFonts.cinzelDecorative(
            fontSize: 14, color: AppColors.gold, letterSpacing: 2),
      ),
      content: TextField(
        key: const ValueKey('profile-edit-input'),
        controller: widget.controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autofocus: true,
        style: GoogleFonts.roboto(color: AppColors.textPrimary),
        decoration: InputDecoration(
          suffixText: widget.unit,
          suffixStyle: GoogleFonts.roboto(color: AppColors.textMuted),
          errorText: _error,
          hintText: '${widget.min}–${widget.max}',
          hintStyle: GoogleFonts.roboto(color: AppColors.textMuted),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar',
              style: GoogleFonts.roboto(color: AppColors.textMuted)),
        ),
        TextButton(
          key: const ValueKey('profile-edit-confirm'),
          onPressed: () {
            final raw = widget.controller.text.trim();
            final parsed = int.tryParse(raw);
            if (parsed == null ||
                parsed < widget.min ||
                parsed > widget.max) {
              setState(() => _error =
                  'Use um valor entre ${widget.min} e ${widget.max}');
              return;
            }
            Navigator.pop(context, parsed);
          },
          child: Text('Salvar',
              style: GoogleFonts.roboto(color: AppColors.gold)),
        ),
      ],
    );
  }
}
