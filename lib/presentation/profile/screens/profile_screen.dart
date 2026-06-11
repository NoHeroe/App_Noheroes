import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../core/widgets/animated_bg.dart';
import '../../../data/database/daos/player_dao.dart';
import '../../../domain/entities/player.dart';
import '../../../domain/services/body_metrics_service.dart';
import '../../shared/avatar_provider.dart';
import '../../shared/widgets/nh_back_button.dart';
import '../../sanctuary/widgets/sanctuary_header_widgets.dart';

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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // Sem título — voltar + mini-perfil compacto + carteira (entre eles).
    return Row(
      children: [
        NhBackButton(
          key: const ValueKey('profile-back'),
          onTap: () => context.go('/sanctuary'),
        ),
        const SizedBox(width: 10),
        const Expanded(child: SanctuaryMiniProfile()),
        const SizedBox(width: 10),
        const SanctuaryWalletPills(),
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

class _IdentityCard extends ConsumerWidget {
  final Player player;
  const _IdentityCard({required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRank = player.guildRank != 'none';
    final rankLabel = hasRank
        ? GuildRankSystem.label(GuildRankSystem.fromString(player.guildRank))
            .toUpperCase()
        : 'SEM RANK';
    final avatarIdx =
        ref.watch(selectedAvatarProvider).clamp(0, kAvatarPresets.length - 1);
    final preset = kAvatarPresets[avatarIdx];

    return _Card(
      title: 'IDENTIDADE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visualização do avatar selecionado.
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: preset.color.withValues(alpha: 0.25),
                        blurRadius: 14),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF3A2D52), Color(0xFF140E20)],
                    ),
                  ),
                  child: Icon(preset.icon, color: preset.color, size: 34),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.shadowName,
                        style: GoogleFonts.cinzelDecorative(
                            fontSize: 18, color: AppColors.txt)),
                    const SizedBox(height: 6),
                    Text(_classLabel(player.classType),
                        style: GoogleFonts.roboto(
                            fontSize: 13, color: AppColors.txt2)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Pill(label: 'Nível ${player.level}',
                            color: AppColors.gold),
                        const SizedBox(width: 8),
                        _Pill(
                          label: rankLabel,
                          color: hasRank ? AppColors.gold : AppColors.txtMut,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('AVATAR',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 10, color: AppColors.gold, letterSpacing: 2)),
              const SizedBox(width: 8),
              Text('(placeholder — editor 3D em breve)',
                  style: GoogleFonts.roboto(
                      fontSize: 9, color: AppColors.txtMut)),
            ],
          ),
          const SizedBox(height: 10),
          // Seletor de avatar (presets) — visualização atualiza acima e em
          // todos os mini-perfis.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < kAvatarPresets.length; i++)
                GestureDetector(
                  onTap: () =>
                      ref.read(selectedAvatarProvider.notifier).select(i),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kAvatarPresets[i].color.withValues(alpha: 0.12),
                      border: Border.all(
                        color: i == avatarIdx
                            ? AppColors.gold
                            : AppColors.borderViolet,
                        width: i == avatarIdx ? 2 : 1,
                      ),
                    ),
                    child: Icon(kAvatarPresets[i].icon,
                        color: kAvatarPresets[i].color, size: 20),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyMetricsCard extends ConsumerWidget {
  final Player player;
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
            label: 'Sexo',
            value: _sexLabel(player.sex),
            editKey: 'profile-edit-sex',
            onEdit: () => _editSex(context, ref),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Idade',
            value: player.age == null ? '—' : '${player.age} anos',
            editKey: 'profile-edit-age',
            onEdit: () => _editDialog(
              context: context,
              ref: ref,
              field: _Field.age,
              current: player.age,
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
    final (min, max, unit, title) = switch (field) {
      _Field.weight => (
          BodyMetricsService.minWeightKg,
          BodyMetricsService.maxWeightKg,
          'kg',
          'Peso'
        ),
      _Field.height => (
          BodyMetricsService.minHeightCm,
          BodyMetricsService.maxHeightCm,
          'cm',
          'Altura'
        ),
      _Field.age => (
          BodyMetricsService.minAge,
          BodyMetricsService.maxAge,
          'anos',
          'Idade'
        ),
    };
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
      weightKg: field == _Field.weight ? newValue : null,
      heightCm: field == _Field.height ? newValue : null,
      age: field == _Field.age ? newValue : null,
    );
    await _refresh(ref);
  }

  Future<void> _editSex(BuildContext context, WidgetRef ref) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sexo',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.gold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final opt in const [
              (BodyMetricsService.sexMale, 'Masculino'),
              (BodyMetricsService.sexFemale, 'Feminino'),
            ])
              ListTile(
                title: Text(opt.$2,
                    style: GoogleFonts.roboto(color: AppColors.txt)),
                trailing: player.sex == opt.$1
                    ? const Icon(Icons.check, color: AppColors.gold)
                    : null,
                onTap: () => Navigator.pop(ctx, opt.$1),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await service.save(playerId: player.id, sex: chosen);
    await _refresh(ref);
  }

  Future<void> _refresh(WidgetRef ref) async {
    final fresh =
        await PlayerDao(ref.read(supabaseClientProvider)).findById(player.id);
    if (fresh != null) {
      ref.read(currentPlayerProvider.notifier).state = fresh;
    }
  }

  static String _sexLabel(String? s) => switch (s) {
        BodyMetricsService.sexMale => 'Masculino',
        BodyMetricsService.sexFemale => 'Feminino',
        _ => '—',
      };

  Color _categoryColor(String c) => switch (c) {
        BodyMetricsService.categoryNormal => AppColors.rarityUncommon,
        BodyMetricsService.categoryUnderweight => AppColors.shadowObsessive,
        BodyMetricsService.categoryOverweight => AppColors.shadowObsessive,
        BodyMetricsService.categoryObese => AppColors.hp,
        _ => AppColors.textMuted,
      };
}

enum _Field { weight, height, age }

class _RecommendationsCard extends StatelessWidget {
  final Player player;
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
            value: water == null
                ? '—'
                : '${(water / 1000).toStringAsFixed(water % 1000 == 0 ? 0 : 1)} L',
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
  final Player player;
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
        activeThumbColor: AppColors.gold,
        value: player.autoConfirmEnabled,
        onChanged: (value) async {
          final client = ref.read(supabaseClientProvider);
          await PlayerDao(client).setAutoConfirmEnabled(player.id, value);
          // Refresca currentPlayerProvider pra UI reagir.
          final fresh = await PlayerDao(client).findById(player.id);
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
