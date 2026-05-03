import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/config/faction_alliances.dart' show kSecretFactionUnlockKey;
import '../../../core/constants/app_colors.dart';
import '../../../core/events/faction_events.dart' show FactionJoined;
import '../../../data/datasources/local/class_bonus_service.dart';
// Sprint 3.1 Bloco 1 — QuestAdmissionService e factionsServiceProvider
// foram .bakados. Este ecrã continua exibindo a escolha (lê JSON direto) e
// marca a facção como `pending:<id>` em players; a criação das missões de
// admissão volta no Bloco 7 via QuestAdmissionService refatorado.
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../../shared/widgets/app_snack.dart';
import '../../../data/datasources/local/npc_reputation_service.dart';
import '../../../core/utils/asset_loader.dart';
import 'package:drift/drift.dart' show Variable, DriftDatabase;

class FactionSelectionScreen extends ConsumerStatefulWidget {
  const FactionSelectionScreen({super.key});
  @override
  ConsumerState<FactionSelectionScreen> createState() => _FactionSelectionScreenState();
}

class _FactionSelectionScreenState extends ConsumerState<FactionSelectionScreen> {
  List<Map<String, dynamic>> _factions = [];
  int _selected = -1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFactions();
  }

  Future<void> _loadFactions() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/factions.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final all = (data['factions'] as List).cast<Map<String, dynamic>>();

      // Sprint 3.4 hotfix P2 — filtra facções secretas cujo gate
      // achievement não está desbloqueado pelo player. Fecha leak
      // histórico (débito do Bloco 7 da Sprint 3.1: comentário antigo
      // reconhecia que `FactionsService com filtro de secretas por
      // achievement` não foi reimplementado). Default conservador:
      // facção `isSecret=true` sem mapeamento em
      // `kSecretFactionUnlockKey` fica escondida pra todo mundo.
      final repo = ref.read(playerAchievementsRepositoryProvider);
      final completed =
          (await repo.listCompletedKeys(player.id)).toSet();
      final filtered = <Map<String, dynamic>>[];
      for (final f in all) {
        // Sprint 3.4 Sub-Etapa B.2 — modelo dual da Guilda. Aparece
        // na lista APENAS se o player já é Aventureiro nível 1
        // (guild_rank in ['e'..'s']). Player rank='none' não vê
        // Guilda; é incentivado a fazer flow especial em /guild
        // (complete 15 missões → recebe COLLAR + rank E) primeiro.
        if (f['id'] == 'guild') {
          if (player.guildRank == 'none' || player.guildRank.isEmpty) {
            continue; // esconde até virar Aventureiro nível 1
          }
          filtered.add(f);
          continue;
        }
        if (f['isSecret'] != true) {
          filtered.add(f);
          continue;
        }
        final unlockKey = kSecretFactionUnlockKey[f['id']];
        if (unlockKey != null && completed.contains(unlockKey)) {
          filtered.add(f);
        }
        // Caso default: secret sem gate mapeado OU gate não
        // desbloqueado → escondida.
      }

      if (!mounted) return;
      setState(() => _factions = filtered);
    } catch (_) {
      if (!mounted) return;
      setState(() => _factions = []);
    }
  }

  Color _color(Map c) => Color(int.parse(c['color'] as String));

  Future<void> _confirm() async {
    if (_selected < 0) return;
    final faction = _factions[_selected];
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Jurar lealdade?',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(faction['name'] as String,
                style: GoogleFonts.cinzelDecorative(
                    color: _color(faction), fontSize: 16)),
            const SizedBox(height: 4),
            Text('"${faction['philosophy']}"',
                style: GoogleFonts.roboto(
                    color: _color(faction),
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Text('Você receberá 3 missões de admissão.\nComplete-as para entrar na facção.\nFalhar resultará em penalidade de reputação.',
                style: GoogleFonts.roboto(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Iniciar admissão',
                style: GoogleFonts.roboto(color: _color(faction))),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    final db = ref.read(appDatabaseProvider);
    final factionId = faction['id'] as String;

    // Sprint 3.4 Sub-Etapa B.2 — modelo dual da Guilda. Player que
    // chega aqui já é Aventureiro nível 1 (filtro em _loadFactions
    // garante guild_rank in ['e'..'s']). Entrada DIRETA, sem admissão
    // eliminatória. Promove faction_type='guild', cria membership
    // row, emite FactionJoined direto.
    if (factionId == 'guild') {
      await _confirmGuildDirect(player.id);
      return;
    }

    // Sprint 3.4 Etapa A — bug histórico corrigido. Antes:
    //   - players.faction_type = 'pending:X' era setado direto via SQL
    //   - QuestAdmissionService NÃO era chamado (foi `.bakado` na 3.1
    //     Bloco 1 e nunca religado)
    //   - Resultado: jogador ficava `pending:X` pra sempre, nunca via
    //     missões de admissão.
    //
    // Agora: setamos `pending:X` E chamamos `startFactionAdmission`
    // que cria N quests em `player_mission_progress` (tabOrigin=
    // admission). Sub-Etapa B.2 popula `metaJson` com sub-tasks
    // automáticas + escala de dificuldade.
    await db.customStatement(
      "UPDATE players SET faction_type = ? WHERE id = ?",
      ['pending:$factionId', player.id],
    );

    final admissionService = ref.read(questAdmissionServiceProvider);
    final created = await admissionService.startFactionAdmission(
        player.id, factionId);

    // +5 reputação com NPC da facção ao iniciar admissão
    try {
      final npcId = AssetLoader.npcIdForFaction(factionId);
      await NpcReputationService(db).addReputation(player.id, npcId, 5);
    } catch (_) {}

    final updated = await db.managers.playersTable
        .filter((f) => f.id(player.id))
        .getSingleOrNull();
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(created.isEmpty
                ? 'Facção marcada como pendente. (Pool de admissão vazio — verifique JSON.)'
                : 'Admissão iniciada — ${created.length} missões criadas.'),
            backgroundColor: AppColors.mp,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/sanctuary');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _factions.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : Stack(
              children: [
                _buildBg(),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(child: _buildList()),
                      _buildLoneWolfOption(),
                      _buildConfirmBtn(),
                    ],
                  ),
                ),
                if (_loading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                        child: CircularProgressIndicator(color: AppColors.gold)),
                  ),
              ],
            ),
    );
  }

  Widget _buildBg() => Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xFF0A1A0A), Color(0xFF0A0010), AppColors.black],
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          children: [
            Text('ESCOLHA DAS FACÇÕES',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 15, color: AppColors.gold, letterSpacing: 3)),
            const SizedBox(height: 8),
            Text(
              'Você atingiu o nível 7.\nCaelum exige que você escolha um lado.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _factions.length,
        itemBuilder: (_, i) => _FactionCard(
          data: _factions[i],
          isSelected: _selected == i,
          onTap: () => setState(() => _selected = i),
        ),
      );

  Widget _buildConfirmBtn() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selected >= 0 ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selected >= 0
                  ? _color(_factions[_selected])
                  : AppColors.border,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _selected >= 0
                  ? 'JURAR LEALDADE À ${(_factions[_selected]['name'] as String).toUpperCase()}'
                  : 'SELECIONE UMA FACÇÃO',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  letterSpacing: 1),
            ),
          ),
        ),
      );

  Widget _buildLoneWolfOption() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GestureDetector(
        onTap: _confirmLoneWolf,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            color: AppColors.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline, color: AppColors.textMuted, size: 24),
              const SizedBox(height: 6),
              Text('Caminho do Lobo Solitario',
                  style: GoogleFonts.cinzelDecorative(
                      fontSize: 12, color: AppColors.textSecondary, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('Seguir sem faccao. Pode mudar depois.',
                  style: GoogleFonts.roboto(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  /// Sprint 3.4 Sub-Etapa B.2 — entrada direta na Facção Guilda
  /// (modelo dual: Aventureiro nível 1 = `guild_rank in ['e'..'s']`,
  /// já garantido pelo filtro de `_loadFactions`; este flow concede
  /// nível 2 = `faction_type='guild'`).
  Future<void> _confirmGuildDirect(int playerId) async {
    final db = ref.read(appDatabaseProvider);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.customStatement(
      "UPDATE players SET faction_type = 'guild' WHERE id = ?",
      [playerId],
    );
    await db.customStatement(
      'INSERT OR IGNORE INTO player_faction_membership '
      '(player_id, faction_id, joined_at, left_at, locked_until, '
      ' debuff_until, admission_attempts) '
      'VALUES (?, ?, ?, NULL, NULL, NULL, 0)',
      [playerId, 'guild', nowMs],
    );
    await db.customStatement(
      'UPDATE player_faction_membership SET joined_at = ?, '
      'left_at = NULL '
      "WHERE player_id = ? AND faction_id = 'guild' "
      'AND joined_at IS NULL',
      [nowMs, playerId],
    );

    // Emite FactionJoined diretamente (cascata pra listeners
    // existentes — achievements `event_faction_joined`, etc).
    ref.read(appEventBusProvider).publish(
        FactionJoined(playerId: playerId, factionId: 'guild'));

    final updated = await db.managers.playersTable
        .filter((f) => f.id(playerId))
        .getSingleOrNull();
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Você é agora membro oficial da Facção Guilda. '
                'Buffs ativos.'),
            backgroundColor: AppColors.shadowAscending,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/guild');
      }
    }
  }

  Future<void> _confirmLoneWolf() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text('Caminho do Lobo Solitario',
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.textPrimary, fontSize: 15)),
        content: Text('Voce pode explorar Caelum sem faccao. Pode mudar essa escolha depois.',
            style: GoogleFonts.roboto(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Voltar', style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirmar', style: GoogleFonts.roboto(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final player = ref.read(currentPlayerProvider);
    if (player != null) {
      final db = ref.read(appDatabaseProvider);
      await db.customUpdate(
        'UPDATE players SET faction_type = ? WHERE id = ?',
        variables: [
          Variable.withString('none'),
          Variable.withInt(player.id),
        ],
        updates: {db.playersTable},
      );
      final updated = await ref.read(authDsProvider).currentSession();
      ref.read(currentPlayerProvider.notifier).state = updated;
    }
    if (!mounted) return;
    context.go('/sanctuary');
  }

}

class _FactionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isSelected;
  final VoidCallback onTap;
  const _FactionCard({required this.data, required this.isSelected, required this.onTap});

  @override
  State<_FactionCard> createState() => _FactionCardState();
}

class _FactionCardState extends State<_FactionCard> {
  bool _expanded = false;

  Color get color => Color(int.parse(widget.data['color'] as String));
  Map<String, dynamic> get data => widget.data;

  @override
  Widget build(BuildContext context) {
    final isSecret = data['isSecret'] == true;
    final isRecommended = data['recommended'] == true;
    final buffs = (data['buffs'] as List).cast<String>();

    return GestureDetector(
      onTap: () {
        widget.onTap();
        setState(() => _expanded = !_expanded);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: data['id'] == 'error'
                ? AppColors.purple.withValues(alpha: widget.isSelected ? 0.8 : 0.4)
                : (widget.isSelected ? color : AppColors.border),
            width: widget.isSelected ? 1.5 : 1,
          ),
          boxShadow: data['id'] == 'error' ? [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sprint 3.4 Sub-Etapa B.2 hotfix — Wrap em vez
                      // de Row pra evitar overflow horizontal quando
                      // múltiplos badges acumulam (Guilda tinha
                      // RECOMENDADA + ENTRADA DIRETA, estourava 60px).
                      // Filtro: RECOMENDADA escondida quando há badge
                      // mais específico (guild=ENTRADA DIRETA,
                      // secret=SECRETA).
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment:
                                  WrapCrossAlignment.center,
                              children: [
                                Text(data['name'] as String,
                                    style: GoogleFonts.cinzelDecorative(
                                        fontSize: 13,
                                        color: AppColors.textPrimary)),
                                if (isRecommended &&
                                    data['id'] != 'guild' &&
                                    !isSecret)
                                  _badge('RECOMENDADA', AppColors.gold),
                                if (isSecret)
                                  _badge('SECRETA', AppColors.hp),
                                if (data['id'] == 'guild')
                                  _badge('ENTRADA DIRETA',
                                      AppColors.shadowAscending)
                                else if (data['id'] != 'error')
                                  _badge('ADMISSÃO ELIMINATÓRIA',
                                      AppColors.shadowObsessive),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('"${data['philosophy']}"',
                          style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: color,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(data['difficulty'] as String,
                        style: GoogleFonts.roboto(
                            fontSize: 10, color: AppColors.textMuted)),
                    if (widget.isSelected)
                      Icon(Icons.check_circle, color: color, size: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(data['description'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4)),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['description'] as String,
                      style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text('Líder: ${data['leader']}',
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: AppColors.textMuted)),
                  Text('Dificuldade: ${data['difficulty']}',
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: color)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: buffs
                  .take(3)
                  .map((b) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(b,
                            style: GoogleFonts.roboto(
                                fontSize: 10, color: color)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: GoogleFonts.roboto(
                fontSize: 8, color: color, letterSpacing: 1)),
      );
}
