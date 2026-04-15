import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' show Value;
import '../../app/providers.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/daos/player_dao.dart';
import '../../data/database/app_database.dart';
import '../../data/database/tables/players_table.dart';
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
          ],
        ),
      ),
    );
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
