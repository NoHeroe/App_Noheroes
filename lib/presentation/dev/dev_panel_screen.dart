import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' show Value;
import '../../app/providers.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/guild_rank.dart';
import '../../data/database/daos/player_dao.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/players_table.dart';
import '../../domain/enums/source_type.dart';
import '../../domain/models/player_snapshot.dart';
import '../shared/widgets/app_snack.dart';

class DevPanelScreen extends ConsumerStatefulWidget {
  const DevPanelScreen({super.key});
  @override
  ConsumerState<DevPanelScreen> createState() => _DevPanelScreenState();
}

class _DevPanelScreenState extends ConsumerState<DevPanelScreen> {
  final _levelCtrl = TextEditingController();
  final _goldCtrl  = TextEditingController();
  final _xpCtrl    = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _levelCtrl.dispose();
    _goldCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    setState(() => _saving = true);

    final db = ref.read(appDatabaseProvider);
    final dao = PlayerDao(db);

    final newLevel = int.tryParse(_levelCtrl.text) ?? player.level;
    final newGold  = int.tryParse(_goldCtrl.text)  ?? player.gold;
    final newXp    = int.tryParse(_xpCtrl.text)    ?? player.xp;

    await (db.update(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .write(PlayersTableCompanion(
          level: Value(newLevel),
          gold:  Value(newGold),
          xp:    Value(newXp),
        ));

    final updated = await dao.findById(player.id);
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aplicado: Lv$newLevel | ${newGold}g | ${newXp}xp'),
          backgroundColor: AppColors.shadowAscending,
        ),
      );
    }
  }

  Future<void> _resetClass() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .write(PlayersTableCompanion(
          classType:   Value(null),
          factionType: Value(null),
        ));
    final updated = await PlayerDao(db).findById(player.id);
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Classe e facção resetadas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.go('/sanctuary'),
        ),
        title: Text('DEV PANEL',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.hp, fontSize: 14, letterSpacing: 2)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.hp.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hp.withValues(alpha: 0.4)),
            ),
            child: Text('APENAS DEV',
                style: GoogleFonts.roboto(
                    fontSize: 10, color: AppColors.hp, letterSpacing: 1)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status atual
            _section('STATUS ATUAL'),
            _infoRow('Nível',   '${player?.level ?? 0}'),
            _infoRow('XP',      '${player?.xp ?? 0}'),
            _infoRow('Ouro',    '${player?.gold ?? 0}'),
            _infoRow('Classe',  player?.classType ?? 'Nenhuma'),
            _infoRow('Facção',  player?.factionType ?? 'Nenhuma'),
            _infoRow('Sombra',  player?.shadowState ?? '-'),
            _infoRow('Dia',     '${player?.caelumDay ?? 1} em Caelum'),
            const SizedBox(height: 24),

            // Ajuste de valores
            _section('AJUSTAR VALORES'),
            _field(_levelCtrl, 'Novo nível', '${player?.level ?? 1}'),
            const SizedBox(height: 10),
            _field(_goldCtrl,  'Novo ouro',  '${player?.gold ?? 0}'),
            const SizedBox(height: 10),
            _field(_xpCtrl,    'Novo XP',    '${player?.xp ?? 0}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('APLICAR',
                        style: GoogleFonts.cinzelDecorative(
                            color: Colors.white, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 24),

            // Ações rápidas
            _section('AÇÕES RÁPIDAS'),
            _actionBtn('Resetar classe e facção', AppColors.hp, _resetClass),
            const SizedBox(height: 10),
            _actionBtn('Ir para seleção de classe', AppColors.gold,
                () => context.go('/class-selection')),
            const SizedBox(height: 10),
            _actionBtn('Ir para seleção de facção', AppColors.shadowStable,
                () => context.go('/faction-selection')),
            const SizedBox(height: 24),

            // Rank + Inventário (Sprint 2.1 Bloco 6)
            _section('RANK + INVENTÁRIO'),
            _infoRow('Rank atual', player?.guildRank ?? 'none'),
            const SizedBox(height: 10),
            _actionBtn('Setar Rank', AppColors.purple, _pickAndSetRank),
            const SizedBox(height: 10),
            _actionBtn('Equipar Colar da Guilda (debug)', AppColors.gold,
                _giveCollar),
            const SizedBox(height: 10),
            _actionBtn(
                'Resetar inventário completo', AppColors.hp, _resetInventory),
            const SizedBox(height: 24),

            // Quests (Sprint 2.2 Bloco 6 — gate de admissão exige 25 quests)
            _section('QUESTS'),
            _infoRow('Missões completas',
                '${player?.totalQuestsCompleted ?? 0}'),
            const SizedBox(height: 10),
            _actionBtn('Setar quests completas',
                AppColors.purple, _pickAndSetQuestsCompleted),
            const SizedBox(height: 10),
            _actionBtn('Resetar quests completas',
                AppColors.hp, _resetQuestsCompleted),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSetQuestsCompleted() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final value = await showDialog<int?>(
      context: context,
      builder: (_) => _SetQuestsCompletedDialog(
        current: player.totalQuestsCompleted,
      ),
    );
    if (value == null || !mounted) return;

    final db = ref.read(appDatabaseProvider);
    await (db.update(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .write(PlayersTableCompanion(totalQuestsCompleted: Value(value)));
    final updated = await PlayerDao(db).findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    ref.invalidate(playerStreamProvider);
    AppSnack.success(context, 'Contador setado pra $value.');
  }

  Future<void> _resetQuestsCompleted() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Resetar contador de quests?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.hp, fontSize: 14)),
        content: Text(
          'Zera total_quests_completed pra 0. Afeta o gate de admissão '
          'da Guilda (25 missões).',
          style: GoogleFonts.roboto(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.hp),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final db = ref.read(appDatabaseProvider);
    await (db.update(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .write(const PlayersTableCompanion(
            totalQuestsCompleted: Value(0)));
    final updated = await PlayerDao(db).findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    ref.invalidate(playerStreamProvider);
    AppSnack.success(context, 'Contador resetado pra 0.');
  }

  Future<void> _pickAndSetRank() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final chosen = await showDialog<_RankChoice?>(
      context: context,
      builder: (_) => const _RankPickerDialog(),
    );
    if (chosen == null || !mounted) return;

    await ref
        .read(playerRankServiceProvider)
        .setRank(player.id, chosen.rank);

    final updated = await PlayerDao(ref.read(appDatabaseProvider))
        .findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    ref.invalidate(playerStreamProvider);
    if (mounted) {
      AppSnack.success(
        context,
        chosen.rank == null
            ? 'Rank setado pra SEM RANK'
            : 'Rank setado pra ${chosen.rank!.name.toUpperCase()}',
      );
    }
  }

  Future<void> _giveCollar() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final invService = ref.read(playerInventoryServiceProvider);
    final eqService  = ref.read(playerEquipmentServiceProvider);
    final rankService = ref.read(playerRankServiceProvider);

    // Idempotência — não dá Colar duas vezes.
    final current = await invService.listOf(player.id);
    if (current.any((e) => e.spec.key == 'COLLAR_GUILD')) {
      if (mounted) AppSnack.info(context, 'Jogador já tem o Colar.');
      return;
    }

    await rankService.setRank(player.id, GuildRank.e);
    final invId = await invService.addItem(
      playerId:       player.id,
      itemKey:        'COLLAR_GUILD',
      quantity:       1,
      acquiredVia:    SourceType.questReward,
      evolutionStage: 'stage_E',
    );
    if (invId > 0) {
      await eqService.equip(
        playerId:    player.id,
        inventoryId: invId,
        player: PlayerSnapshot(
          level:      player.level,
          rank:       GuildRank.e,
          classKey:   player.classType,
          factionKey: player.factionType,
        ),
      );
    }
    final updated = await PlayerDao(ref.read(appDatabaseProvider))
        .findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    AppSnack.success(context, 'Colar da Guilda entregue e equipado.');
  }

  Future<void> _resetInventory() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Resetar inventário?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.hp, fontSize: 14)),
        content: Text(
          'Apaga TODOS os itens do jogador, incluindo Colar e equipamentos.',
          style: GoogleFonts.roboto(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.hp),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await ref
        .read(playerInventoryServiceProvider)
        .resetInventoryFor(player.id);
    await ref.read(playerRankServiceProvider).setRank(player.id, null);

    final updated = await PlayerDao(ref.read(appDatabaseProvider))
        .findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    AppSnack.success(context, 'Inventário resetado.');
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(label,
            style: GoogleFonts.cinzelDecorative(
                fontSize: 11, color: AppColors.gold, letterSpacing: 2)),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.roboto(
                    fontSize: 13, color: AppColors.textSecondary)),
            Text(value,
                style: GoogleFonts.roboto(
                    fontSize: 13, color: AppColors.textPrimary)),
          ],
        ),
      );

  Widget _field(TextEditingController ctrl, String label, String hint) =>
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: GoogleFonts.roboto(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.roboto(color: AppColors.textMuted),
          hintStyle: GoogleFonts.roboto(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.purple),
          ),
        ),
      );

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(label,
              style: GoogleFonts.roboto(fontSize: 13, color: color)),
        ),
      );
}

class _RankChoice {
  final GuildRank? rank;
  const _RankChoice(this.rank);
}

class _SetQuestsCompletedDialog extends StatefulWidget {
  final int current;
  const _SetQuestsCompletedDialog({required this.current});

  @override
  State<_SetQuestsCompletedDialog> createState() =>
      _SetQuestsCompletedDialogState();
}

class _SetQuestsCompletedDialogState
    extends State<_SetQuestsCompletedDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.current}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Setar quests completas',
          style: GoogleFonts.cinzelDecorative(
              color: AppColors.purple, fontSize: 14)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        style: GoogleFonts.roboto(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: 'Valor (0-999)',
          labelStyle: GoogleFonts.roboto(color: AppColors.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final n = int.tryParse(_ctrl.text.trim());
            if (n == null) return;
            final clamped = n.clamp(0, 999);
            Navigator.pop(context, clamped);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.purple),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class _RankPickerDialog extends StatelessWidget {
  const _RankPickerDialog();

  @override
  Widget build(BuildContext context) {
    const options = <_RankChoice>[
      _RankChoice(null),
      _RankChoice(GuildRank.e),
      _RankChoice(GuildRank.d),
      _RankChoice(GuildRank.c),
      _RankChoice(GuildRank.b),
      _RankChoice(GuildRank.a),
      _RankChoice(GuildRank.s),
    ];
    return SimpleDialog(
      backgroundColor: AppColors.surface,
      title: Text('Setar rank',
          style: GoogleFonts.cinzelDecorative(
              color: AppColors.purple, fontSize: 14)),
      children: [
        for (final o in options)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, o),
            child: Text(
              o.rank == null ? 'SEM RANK (none)' : o.rank!.name.toUpperCase(),
              style: GoogleFonts.roboto(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
