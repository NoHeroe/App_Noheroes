import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/providers.dart';
import '../../../core/config/faction_alliances.dart' show kSecretFactionUnlockKey;
import '../../../core/constants/app_colors.dart';
import '../../shared/widgets/nh_back_button.dart';
import '../../../core/events/faction_events.dart' show FactionJoined;
import '../../../core/events/reward_events.dart' show AchievementUnlocked;
// Sprint 3.1 Bloco 1 — QuestAdmissionService e factionsServiceProvider
// foram .bakados. Este ecrã continua exibindo a escolha (lê JSON direto) e
// marca a facção como `pending:<id>` em players; a criação das missões de
// admissão volta no Bloco 7 via QuestAdmissionService refatorado.
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../../shared/widgets/app_snack.dart';
import '../../../data/datasources/local/npc_reputation_service.dart';
import '../../../data/datasources/local/class_bonus_service.dart';
import '../../../core/utils/asset_loader.dart';
import '../../../core/utils/guild_rank.dart';
import '../faction_selection_gate.dart';

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

      // Sprint 3.4 Etapa C hotfix #1 — anexa labels dinâmicos de buffs
      // lidos do FactionBuffService (catálogo único de fonte canônica).
      // Substitui strings hardcoded em `data['buffs']` que estavam
      // desatualizadas pós-recalibragem hotfix #2 da Sub-Etapa B.
      final buffSvc = ref.read(factionBuffServiceProvider);
      for (final f in filtered) {
        try {
          final preview = await buffSvc.previewLabelsForFaction(f['id'] as String);
          f['buffs_applied'] = preview.applied;
          f['buffs_pending'] = preview.pending;
        } catch (_) {
          f['buffs_applied'] = const <String>[];
          f['buffs_pending'] = const <String>[];
        }
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

    final factionId = faction['id'] as String;

    // Hotfix pós-validação 3.4 (BUG 2) — gate de nível. Facções
    // ideológicas exigem nível 7 (mesmo unlock anunciado no Santuário).
    // A Facção Guilda nível 2 (id='guild') é gated por guild_rank
    // (Aventureiro, desbloqueado no nível 6), não por este gate.
    if (!FactionSelectionGate.canSelect(
        factionId: factionId, level: player.level)) {
      AppSnack.warning(
        context,
        'Facções exigem nível 7. Continue evoluindo para escolher um lado.',
      );
      return;
    }

    // Sprint 3.4 Etapa F (D20) — enforça o lock de 7 dias pós-saída.
    // Bloqueia ENTRAR em facção real (inclui Facção Guilda nível 2, tratada
    // abaixo). Virar Lobo Solitário é LIVRE (o gate NÃO existe em
    // _confirmLoneWolf). customSelect per ADR-0019.
    final lockedUntil = await _readActiveFactionLock(player.id);
    if (lockedUntil != null) {
      if (!mounted) return;
      AppSnack.warning(
        context,
        'Bloqueado até ${_fmtLockDate(lockedUntil)} — você saiu de uma '
        'facção recentemente.',
      );
      return;
    }

    // Sprint 3.4 Etapa G.2 (D14) — ERROR (facção extrema) exige rank B+
    // pra ENTRAR. Gate de RANK, independente do gate de visibilidade da
    // Etapa F (achievement). ERROR continua visível na lista; só o confirm
    // bloqueia. Ordem de rank: e<d<c<b<a<s.
    if (faction['id'] == 'error' &&
        !GuildRankSystem.meetsMinimum(
            GuildRankSystem.fromString(player.guildRank), GuildRank.b)) {
      if (!mounted) return;
      AppSnack.warning(
        context,
        'A facção ERROR exige rank B ou superior na Guilda. Continue subindo.',
      );
      return;
    }
    if (!mounted) return;

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
            // Sprint 3.4 Etapa C hotfix #1 — texto genérico (sem
            // quantidade exata de missões). O sistema de admissão
            // gera N missões dinamicamente por facção/tier.
            Text('Missões de admissão serão geradas para avaliar sua aptidão.\nFalhar resultará em penalidade de reputação.',
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
    final client = ref.read(supabaseClientProvider);

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
    await client
        .from('players')
        .update({'faction_type': 'pending:$factionId'}).eq('id', player.id);

    final admissionService = ref.read(questAdmissionServiceProvider);
    final created = await admissionService.startFactionAdmission(
        player.id, factionId);

    // +5 reputação com NPC da facção ao iniciar admissão
    try {
      final npcId = AssetLoader.npcIdForFaction(factionId);
      await NpcReputationService(client).addReputation(player.id, npcId, 5);
    } catch (_) {}

    final updated = await ref.read(authDsProvider).currentSession();
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

  Widget _buildHeader() {
    final level = ref.read(currentPlayerProvider)?.level ?? 7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ITEM 3 — botão voltar (pop se houver pilha, senão /sanctuary).
          NhBackButton(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/sanctuary'),
          ),
          Expanded(
            child: Column(
              children: [
                Text('ESCOLHA DAS FACÇÕES',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 15,
                        color: AppColors.gold,
                        letterSpacing: 3)),
                const SizedBox(height: 8),
                Text(
                  // ITEM 4 — subtítulo neutro (sem "nível 7").
                  FactionSelectionGate.headerSubtitle(level),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          // Espelho do botão voltar pra manter o título centralizado.
          const SizedBox(width: 40),
        ],
      ),
    );
  }

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
    // ITEM 1 — bloqueado (cinza + cadeado) até o nível 7, igual às facções.
    final level = ref.read(currentPlayerProvider)?.level ?? 1;
    final locked = !FactionSelectionGate.canSelectLoneWolf(level);
    final fg = locked ? AppColors.textMuted : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Opacity(
        opacity: locked ? 0.55 : 1.0,
        child: GestureDetector(
          onTap: () {
            if (locked) {
              AppSnack.warning(
                  context, 'O Caminho do Lobo Solitário abre no nível 7.');
            } else {
              _confirmLoneWolf();
            }
          },
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
                Icon(locked ? Icons.lock_outline : Icons.person_outline,
                    color: AppColors.textMuted, size: 24),
                const SizedBox(height: 6),
                Text('Caminho do Lobo Solitario',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 12, color: fg, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                    locked
                        ? 'Disponivel no nivel 7.'
                        : 'Seguir sem faccao. Pode mudar depois.',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sprint 3.4 Sub-Etapa B.2 — entrada direta na Facção Guilda
  /// (modelo dual: Aventureiro nível 1 = `guild_rank in ['e'..'s']`,
  /// já garantido pelo filtro de `_loadFactions`; este flow concede
  /// nível 2 = `faction_type='guild'`).
  Future<void> _confirmGuildDirect(String playerId) async {
    final client = ref.read(supabaseClientProvider);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Época 2 (ADR-0024) — escrita single-table via PostgREST.
    await client
        .from('players')
        .update({'faction_type': 'guild'}).eq('id', playerId);
    // TODO dev (Época 2): bônus de boas-vindas de 100 Insígnias (Etapa H)
    // dependia de UPDATE incremental Drift cru. Sem RPC atômica de
    // incremento equivalente ainda — religar quando `add_insignias` existir.
    // upsert da membership (idempotente por PK composta player_id+faction_id).
    await client.from('player_faction_membership').upsert({
      'player_id': playerId,
      'faction_id': 'guild',
      'joined_at': nowMs,
      'left_at': null,
      'locked_until': null,
      'debuff_until': null,
      'admission_attempts': 0,
    });

    // Emite FactionJoined diretamente (cascata pra listeners
    // existentes — achievements `event_faction_joined`, etc).
    ref.read(appEventBusProvider).publish(
        FactionJoined(playerId: playerId, factionId: 'guild'));

    final updated = await ref.read(authDsProvider).currentSession();
    if (mounted) {
      ref.read(currentPlayerProvider.notifier).state = updated;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Você é agora membro oficial da Facção Guilda. '
                'Buffs ativos.'),
            backgroundColor: AppColors.shadowAscending,
            duration: Duration(seconds: 4),
          ),
        );
        context.go('/guild');
      }
    }
  }

  Future<void> _confirmLoneWolf() async {
    // ITEM 1 — Lobo Solitário também é uma escolha do lvl 7. Gate igual às
    // ideológicas (FactionSelectionGate.canSelectLoneWolf).
    final gatePlayer = ref.read(currentPlayerProvider);
    if (gatePlayer != null &&
        !FactionSelectionGate.canSelectLoneWolf(gatePlayer.level)) {
      AppSnack.warning(
        context,
        'O Caminho do Lobo Solitário abre no nível 7.',
      );
      return;
    }
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
      // Sprint 3.4 Etapa F — opt-in seta o sentinel 'lone_wolf' (antes era
      // 'none'). Ativa os bônus +5% XP/ouro/gemas via FactionBuffService
      // (catalog['lone_wolf']). NÃO passa pelo lock 7d (virar Lobo é livre).
      await ClassBonusService(ref.read(supabaseClientProvider))
          .applyFactionChoice(player.id, 'lone_wolf');

      // ERROR unlock: concede SECRET_LOBO_SOLITARIO SÓ se o player nunca
      // fez uma escolha de facção do lvl 7 (facção ideológica OU Facção
      // Guilda nível 2). Aventureiro nível 1 (guild_rank) NÃO conta —
      // distinguido por: guild row com left_at é ex-Facção-Guilda nível 2
      // (Aventureiro puro nunca consegue leaveFaction('guild')).
      await _grantLoneWolfAchievementIfFirstChoice(player.id);

      final updated = await ref.read(authDsProvider).currentSession();
      ref.read(currentPlayerProvider.notifier).state = updated;
      ref.invalidate(factionBuffSnapshotProvider);
    }
    if (!mounted) return;
    context.go('/sanctuary');
  }

  /// Sprint 3.4 Etapa F — gate da ERROR (decisão CEO): conquista concedida
  /// só na PRIMEIRA escolha de facção do lvl 7 sendo Lobo. Conta como "já
  /// escolheu": qualquer membership de facção ideológica (faction_id !=
  /// 'guild') OU guild row que foi abandonada (left_at != null = ex-Facção
  /// Guilda nível 2). NÃO conta: Aventureiro nível 1 (guild row sem left_at).
  Future<void> _grantLoneWolfAchievementIfFirstChoice(String playerId) async {
    final client = ref.read(supabaseClientProvider);
    // Memberships com joined_at != null; "já escolheu" = qualquer facção
    // ideológica OU guild abandonada (left_at != null). Filtro do faction_id
    // == 'guild' com left_at null é aplicado client-side.
    final rows = await client
        .from('player_faction_membership')
        .select('faction_id, left_at')
        .eq('player_id', playerId)
        .not('joined_at', 'is', null);
    final everChoseFaction = rows.any((r) =>
        r['faction_id'] != 'guild' || r['left_at'] != null);
    if (everChoseFaction) return;

    const key = 'SECRET_LOBO_SOLITARIO';
    final repo = ref.read(playerAchievementsRepositoryProvider);
    if (await repo.isCompleted(playerId, key)) return;
    await repo.markCompleted(playerId, key, at: DateTime.now());
    // Mesmo pipeline do dev panel: publica AchievementUnlocked (popup +
    // cascata metaLike). Reward (xp/gold/gems/baú) é coleta MANUAL na tela
    // de conquistas (ADR-0020) — disponível porque a conquista virou
    // disabled:false.
    ref.read(appEventBusProvider).publish(
        AchievementUnlocked(playerId: playerId, achievementKey: key));
  }

  /// D20 — lê o `locked_until` ativo (> now) da membership mais recente.
  /// Retorna a data se ainda bloqueado, senão null.
  Future<DateTime?> _readActiveFactionLock(String playerId) async {
    final client = ref.read(supabaseClientProvider);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final row = await client
        .from('player_faction_membership')
        .select('locked_until')
        .eq('player_id', playerId)
        .not('locked_until', 'is', null)
        .order('locked_until', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    final ms = (row['locked_until'] as num?)?.toInt();
    if (ms == null || ms <= nowMs) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  String _fmtLockDate(DateTime at) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(at.day)}/${p(at.month)} ${p(at.hour)}:${p(at.minute)}';
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
    // Sprint 3.4 Etapa C hotfix #1 — labels dinâmicos do FactionBuffService.
    // Fallback pra `data['buffs']` (legacy factions.json) só se preview
    // não foi populado (sem catálogo). Pending separado em cinza.
    final appliedRaw = data['buffs_applied'];
    final pendingRaw = data['buffs_pending'];
    final List<String> applied = appliedRaw is List
        ? appliedRaw.cast<String>()
        : (data['buffs'] as List).cast<String>();
    final List<String> pending =
        pendingRaw is List ? pendingRaw.cast<String>() : const [];

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
            // Sprint 3.4 Etapa C hotfix #1 — Wrap com applied (cor da
            // facção) + pending (cinza). Sem `take(3)` quando expandido —
            // mostra tudo só no estado expandido pra evitar overflow no
            // collapsed.
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...(_expanded ? applied : applied.take(3)).map(
                  (b) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(b,
                        style: GoogleFonts.roboto(
                            fontSize: 10, color: color)),
                  ),
                ),
                if (_expanded)
                  ...pending.map(
                    (b) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.textMuted.withValues(alpha: 0.3)),
                      ),
                      child: Text('$b · FUTURO',
                          style: GoogleFonts.roboto(
                              fontSize: 10, color: AppColors.textMuted)),
                    ),
                  ),
              ],
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
