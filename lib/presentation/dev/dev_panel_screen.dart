import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' show Value, Variable;
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/providers.dart';
import '../../core/config/faction_alliances.dart';
import '../../core/constants/app_colors.dart';
import '../../core/events/app_event.dart';
import '../../core/utils/guild_rank.dart';
import '../../core/utils/requirements_helper.dart';
import '../../data/database/daos/player_dao.dart';
import '../../data/database/app_database.dart';
import '../../data/datasources/local/tutorial_service.dart';
import '../../domain/enums/intensity.dart';
import '../../domain/enums/item_type.dart';
import '../../domain/enums/mission_category.dart';
import '../../domain/enums/source_type.dart';
import '../../domain/models/item_spec.dart';
import '../../domain/models/player_snapshot.dart';
import '../../domain/services/individual_creation_service.dart';
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
  final _gemsCtrl  = TextEditingController();
  bool _saving = false;

  // Sprint 3.1 Bloco 14 — Events inspector. Ring buffer 20 entries FIFO,
  // captura todos eventos do bus via .on<AppEvent>() (base class). State
  // local do widget — não persiste ao sair do Dev Panel (aceitável pra
  // debug).
  static const int _kEventBufferMax = 20;
  final List<_EventLogEntry> _eventBuffer = [];
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    // Assina post-frame pra garantir que ProviderScope está pronto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bus = ref.read(appEventBusProvider);
      _eventSub = bus.on<AppEvent>().listen((e) {
        if (!mounted) return;
        setState(() {
          _eventBuffer.insert(0, _EventLogEntry(
            at: DateTime.now(),
            type: e.runtimeType.toString(),
            repr: e.toString(),
          ));
          if (_eventBuffer.length > _kEventBufferMax) {
            _eventBuffer.removeLast();
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _levelCtrl.dispose();
    _goldCtrl.dispose();
    _xpCtrl.dispose();
    _gemsCtrl.dispose();
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
    final newGems  = int.tryParse(_gemsCtrl.text)  ?? player.gems;

    await (db.update(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .write(PlayersTableCompanion(
          level: Value(newLevel),
          gold:  Value(newGold),
          xp:    Value(newXp),
          gems:  Value(newGems),
        ));

    final updated = await dao.findById(player.id);
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Aplicado: Lv$newLevel | ${newGold}g | ${newXp}xp | $newGems💎'),
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
            const SizedBox(height: 10),
            _field(_gemsCtrl,  'Novas gemas', '${player?.gems ?? 0}'),
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
            const SizedBox(height: 10),
            // Sprint 2.3 dev shortcut — gate level 20 bloqueia acesso normal.
            _actionBtn('Ir para Encantamento (/enchant)',
                AppColors.purpleLight, () => context.go('/enchant')),
            const SizedBox(height: 10),
            // Sprint 2.3 fix round 2 (B+) — destrava testes manuais de todas
            // as 50 runas até drops do loot_world serem implementados.
            _actionBtn('Adicionar runa ao inventário',
                AppColors.purpleLight, _addRuneToInventory),
            const SizedBox(height: 10),
            // Sprint 2.3 Bloco 6 — reseta flag da quest do Encantador +
            // remove RUNE_FIRE_E do inventário. Abrir /enchant dispara de novo.
            _actionBtn('Resetar quest do Encantador',
                AppColors.hp, _resetEnchanterQuest),
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
            const SizedBox(height: 24),

            // ────────────────── Sprint 3.1 Bloco 14 ──────────────────
            _section('MISSÕES (Sprint 3.1)'),
            _actionBtn('Reset daily now (bypass 24h)',
                AppColors.purple, _forceDailyReset),
            const SizedBox(height: 10),
            _actionBtn('Reset weekly now (bypass 7d)',
                AppColors.purple, _forceWeeklyReset),
            const SizedBox(height: 10),
            _actionBtn('Forçar complete primeira missão ativa',
                AppColors.shadowAscending, _forceCompleteFirst),
            const SizedBox(height: 10),
            _actionBtn('Forçar fail primeira missão ativa',
                AppColors.hp, _forceFailFirst),
            const SizedBox(height: 24),

            _section('CALIBRAÇÃO (Bloco 9)'),
            _actionBtn('Reset preferences + phase13 flag',
                AppColors.hp, _resetPreferences),
            const SizedBox(height: 24),

            _section('CURRENCY (recálculo correto)'),
            _actionBtn('+100 gold', AppColors.gold, _addGold100),
            const SizedBox(height: 10),
            _actionBtn('+50 gems', AppColors.purple, _addGems50),
            const SizedBox(height: 10),
            _actionBtn('+200 XP (via addXp — recalcula level/HP)',
                AppColors.shadowAscending, _addXp200),
            const SizedBox(height: 24),

            _section('REPUTAÇÃO FACÇÕES'),
            for (final f in kKnownFactions) _buildFactionRepRow(f),
            const SizedBox(height: 24),

            _section('RANK shortcuts (debug, sem custo)'),
            _actionBtn('Promover +1 rank',
                AppColors.gold, _promoteRank),
            const SizedBox(height: 10),
            _actionBtn('Rebaixar -1 rank',
                AppColors.hp, _demoteRank),
            const SizedBox(height: 24),

            _section('INDIVIDUAIS'),
            _actionBtn('Criar individual random',
                AppColors.purple, _createRandomIndividual),
            const SizedBox(height: 10),
            _actionBtn('Deletar TODAS individuais ativas',
                AppColors.hp, _deleteAllIndividuals),
            const SizedBox(height: 24),

            _section('EVENTS INSPECTOR (últimos $_kEventBufferMax)'),
            _buildEventsList(),
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

  // Sprint 2.3 fix round 2 (B+) — bottom sheet com todas as runas do
  // items_catalog; adiciona 1 unidade da selecionada via PlayerInventoryService.
  // Destrava testes manuais até drops de loot_world serem implementados.
  Future<void> _addRuneToInventory() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    final catalog = ref.read(itemsCatalogServiceProvider);
    final all = await catalog.findAll();
    final runes = all.where((i) => i.type == ItemType.rune).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (!mounted) return;

    final selected = await showModalBottomSheet<ItemSpec>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Escolher runa (${runes.length})',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 14,
                        color: AppColors.purpleLight,
                        letterSpacing: 2)),
              ),
              const Divider(color: AppColors.border, height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: runes.length,
                  itemBuilder: (_, i) {
                    final r = runes[i];
                    return ListTile(
                      leading: const Icon(Icons.auto_awesome,
                          color: AppColors.purpleLight, size: 18),
                      title: Text(r.name,
                          style: GoogleFonts.roboto(
                              color: AppColors.textPrimary, fontSize: 12)),
                      subtitle: Text(
                          '${r.key} · rank ${r.requiredRank?.name.toUpperCase() ?? "?"}',
                          style: GoogleFonts.roboto(
                              color: AppColors.textMuted, fontSize: 10)),
                      onTap: () => Navigator.pop(ctx, r),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || !mounted) return;

    try {
      final svc = ref.read(playerInventoryServiceProvider);
      await svc.addItem(
        playerId:    player.id,
        itemKey:     selected.key,
        quantity:    1,
        acquiredVia: SourceType.lootWorld,
      );
      if (!mounted) return;
      AppSnack.success(context, '${selected.name} adicionada ao inventário.');
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(context, 'Falha ao adicionar: $e');
    }
  }

  // Sprint 2.3 Bloco 6 — reseta flag da quest do Encantador.
  // Remove a flag do SharedPreferences (tutorial_phase12_enchanter) e rebate
  // a RUNE_FIRE_E do inventário se tiver. Tolerante a "não tinha" — se o
  // consumeOne falhar pq o inventário já está vazio, ignora silenciosamente.
  Future<void> _resetEnchanterQuest() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Resetar quest do Encantador?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.hp, fontSize: 14)),
        content: Text(
          'Remove a flag tutorial_phase12_enchanter + remove 1× RUNE_FIRE_E '
          'do inventário (se houver). Na próxima abertura do /enchant ou do '
          'santuário, a quest dispara de novo.',
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

    // Flag persistente — key gerada por TutorialService como
    // 'tutorial_${phase.name}'. Usa o .name do enum pra ficar em sync com
    // qualquer rename futuro.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
        'tutorial_${TutorialPhase.phase12_enchanter.name}');

    final player = ref.read(currentPlayerProvider);
    if (player != null) {
      try {
        // Sprint 2.3 fix — runas no items_catalog. Consome 1 unidade de
        // RUNE_FIRE_E (se houver) via PlayerInventoryService.
        final svc = ref.read(playerInventoryServiceProvider);
        final has = await svc.hasItem(player.id, 'RUNE_FIRE_E');
        if (has) {
          await svc.consumeOneByKey(
              playerId: player.id, itemKey: 'RUNE_FIRE_E');
        }
      } catch (_) {
        // Tolerante — se não tinha, segue.
      }
    }

    if (!mounted) return;
    AppSnack.success(context, 'Quest do Encantador resetada.');
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

  // ────────────── Sprint 3.1 Bloco 14 — handlers ───────────────────

  Future<void> _forceDailyReset() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    // Bypass check 24h: seta last_daily_reset=null.
    await db.customUpdate(
      'UPDATE players SET last_daily_reset = NULL WHERE id = ?',
      variables: [Variable.withInt(player.id)],
      updates: {db.playersTable},
    );
    final result = await ref.read(dailyResetServiceProvider).checkAndApply(player.id);
    if (!mounted) return;
    AppSnack.success(context,
        'Daily reset: ${result.processed} processadas / '
        '${result.reassignedDaily} novas daily / ${result.reassignedClass} novas classe');
  }

  Future<void> _forceWeeklyReset() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.customUpdate(
      'UPDATE players SET last_weekly_reset = NULL WHERE id = ?',
      variables: [Variable.withInt(player.id)],
      updates: {db.playersTable},
    );
    final result = await ref.read(weeklyResetServiceProvider).checkAndApply(player.id);
    if (!mounted) return;
    AppSnack.success(context,
        'Weekly reset: ${result.processed} processadas / reassigned=${result.reassigned}');
  }

  Future<void> _forceCompleteFirst() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(missionRepositoryProvider);
    final active = await repo.findActive(player.id);
    if (active.isEmpty) {
      if (!mounted) return;
      AppSnack.error(context, 'Sem missões ativas');
      return;
    }
    final first = active.first;
    await repo.markCompleted(first.id, at: DateTime.now(), rewardClaimed: true);
    if (!mounted) return;
    AppSnack.success(context, 'Completada: ${first.missionKey}');
  }

  Future<void> _forceFailFirst() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(missionRepositoryProvider);
    final active = await repo.findActive(player.id);
    if (active.isEmpty) {
      if (!mounted) return;
      AppSnack.error(context, 'Sem missões ativas');
      return;
    }
    final first = active.first;
    await repo.markFailed(first.id, at: DateTime.now());
    if (!mounted) return;
    AppSnack.success(context, 'Falhou: ${first.missionKey}');
  }

  Future<void> _resetPreferences() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(missionPreferencesRepositoryProvider);
    await repo.deleteForPlayer(player.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
        'tutorial_${TutorialPhase.phase13_mission_calibration.name}');
    if (!mounted) return;
    AppSnack.success(context, 'Prefs zeradas + phase13 flag resetada');
  }

  Future<void> _addGold100() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    await PlayerDao(db).addGold(player.id, 100);
    if (!mounted) return;
    AppSnack.success(context, '+100 ouro');
  }

  Future<void> _addGems50() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.customUpdate(
      'UPDATE players SET gems = gems + 50 WHERE id = ?',
      variables: [Variable.withInt(player.id)],
      updates: {db.playersTable},
    );
    if (!mounted) return;
    AppSnack.success(context, '+50 gemas');
  }

  Future<void> _addXp200() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    final levelUp = await PlayerDao(db).addXp(player.id, 200);
    if (levelUp != null) {
      ref.read(appEventBusProvider).publish(levelUp);
    }
    if (!mounted) return;
    AppSnack.success(context,
        levelUp == null ? '+200 XP' : '+200 XP → level ${levelUp.newLevel}');
  }

  Future<void> _promoteRank() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final current = GuildRankSystem.fromString(player.guildRank.toLowerCase());
    final order = [GuildRank.e, GuildRank.d, GuildRank.c,
      GuildRank.b, GuildRank.a, GuildRank.s];
    final idx = order.indexOf(current);
    if (idx < 0 || idx == order.length - 1) {
      if (!mounted) return;
      AppSnack.error(context, 'Rank máximo já é S');
      return;
    }
    await _setRank(order[idx + 1]);
  }

  Future<void> _demoteRank() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final current = GuildRankSystem.fromString(player.guildRank.toLowerCase());
    final order = [GuildRank.e, GuildRank.d, GuildRank.c,
      GuildRank.b, GuildRank.a, GuildRank.s];
    final idx = order.indexOf(current);
    if (idx <= 0) {
      if (!mounted) return;
      AppSnack.error(context, 'Rank mínimo já é E');
      return;
    }
    await _setRank(order[idx - 1]);
  }

  Future<void> _setRank(GuildRank newRank) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.playersTable)
          ..where((t) => t.id.equals(player.id)))
        .write(PlayersTableCompanion(guildRank: Value(newRank.name)));
    final updated = await PlayerDao(db).findById(player.id);
    if (!mounted) return;
    ref.read(currentPlayerProvider.notifier).state = updated;
    AppSnack.success(context, 'Rank → ${newRank.name.toUpperCase()}');
  }

  Future<void> _createRandomIndividual() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final service = ref.read(individualCreationServiceProvider);
    final rank = GuildRankSystem.fromString(player.guildRank.toLowerCase());
    try {
      await service.createIndividual(IndividualCreationParams(
        playerId: player.id,
        name: 'Individual DEV ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Missão criada via Dev Panel pra teste.',
        categoria: MissionCategory.fisico,
        intensity: Intensity.medium,
        frequencia: IndividualFrequency.dias,
        requirements: [
          RequirementItem(
            label: 'Flexões',
            target: 10,
            unit: 'reps',
          ),
        ],
        isRepetivel: false,
        rank: rank,
      ));
      if (!mounted) return;
      AppSnack.success(context, 'Individual random criada');
    } on IndividualLimitExceededException catch (_) {
      if (!mounted) return;
      AppSnack.error(context, 'Limite 5 atingido');
    }
  }

  Future<void> _deleteAllIndividuals() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    final repo = ref.read(missionRepositoryProvider);
    final active = await repo.findActive(player.id);
    int deleted = 0;
    for (final m in active) {
      // Individuais têm modality individual. Marca failed diretamente
      // (bypass de custo — Dev Panel é debug).
      if (m.missionKey.startsWith('IND_USER_')) {
        await repo.markFailed(m.id, at: DateTime.now());
        deleted++;
      }
    }
    if (!mounted) return;
    AppSnack.success(context, '$deleted individuais falhadas');
  }

  Widget _buildFactionRepRow(String factionKey) {
    return FutureBuilder<int>(
      future: ref.read(factionReputationServiceProvider).current(
          ref.read(currentPlayerProvider)?.id ?? 0, factionKey),
      builder: (ctx, snap) {
        final rep = snap.data ?? 50;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(factionKey,
                    style: GoogleFonts.roboto(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
              SizedBox(
                width: 40,
                child: Text('$rep',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 13, color: AppColors.gold)),
              ),
              TextButton(
                onPressed: () => _adjustRep(factionKey, 10),
                child: const Text('+10'),
              ),
              TextButton(
                onPressed: () => _adjustRep(factionKey, -10),
                child: const Text('-10'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _adjustRep(String factionKey, int delta) async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    await ref.read(factionReputationServiceProvider).adjustReputation(
        playerId: player.id, factionId: factionKey, delta: delta);
    if (!mounted) return;
    setState(() {}); // rebuild FutureBuilder
    AppSnack.success(context,
        '$factionKey $delta (matrix propaga só se preenchida)');
  }

  Widget _buildEventsList() {
    if (_eventBuffer.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('(sem eventos capturados ainda)',
            style: GoogleFonts.roboto(
                fontSize: 11, color: AppColors.textMuted)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in _eventBuffer)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${entry.at.toIso8601String().substring(11, 19)}  '
              '${entry.type}  ${entry.repr}',
              style: GoogleFonts.robotoMono(
                  fontSize: 10, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

/// Sprint 3.1 Bloco 14 — entry do events inspector ring buffer.
class _EventLogEntry {
  final DateTime at;
  final String type;
  final String repr;
  const _EventLogEntry({
    required this.at,
    required this.type,
    required this.repr,
  });
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
