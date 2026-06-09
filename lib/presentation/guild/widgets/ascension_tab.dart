import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/guild_rank.dart';
import '../../../data/database/app_database.dart';
import '../../../data/datasources/local/ascension_service.dart';
import '../../../data/datasources/local/guild_ascension_service.dart';
import '../../shared/widgets/milestone_popup.dart';

/// B.4 — GuildAscensionService LOCAL: usado SÓ pra `getMissions` (leitura
/// dos trials). A ascensão em si (gates/pay/janela/ascend) vai pela
/// máquina de estados B.2 (`ascensionStateServiceProvider`).
final ascensionServiceProvider = Provider<GuildAscensionService>((ref) {
  return GuildAscensionService(ref.read(appDatabaseProvider));
});

/// Pacote leve consumido pela tab.
class _AscensionData {
  final AscensionView view;
  final String rankTo;
  final List<GuildAscensionTableData> trials;
  const _AscensionData(this.view, this.rankTo, this.trials);
}

/// B.4 — abertura da tab: `checkDeadline` (flipa active→cooldown se venceu)
/// → `evaluateGates` (view). Se active, avança os autos on-demand e lê os
/// trials. Rank none/S são tratados no `build` (não chegam aqui).
final ascensionViewProvider =
    FutureProvider.autoDispose<_AscensionData?>((ref) async {
  final player = ref.watch(currentPlayerProvider);
  if (player == null) return null;
  final rank = player.guildRank;
  if (rank.isEmpty || rank.toLowerCase() == 'none' || rank.toUpperCase() == 'S') {
    return null;
  }

  final svc = ref.read(ascensionStateServiceProvider);
  await svc.checkDeadline(player.id, rank);
  final view = await svc.evaluateGates(player.id, rank);

  final nextEnum = GuildRankSystem.next(GuildRankSystem.fromString(rank));
  final rankTo = (nextEnum?.name ?? rank).toUpperCase();

  var trials = <GuildAscensionTableData>[];
  if (view.state == AscensionViewState.active) {
    // Avança os trials AUTO satisfeitos dentro da janela (motor A.2/B.3).
    await ref.read(guildAscensionProgressServiceProvider).evaluatePlayer(player.id);
    trials = await ref.read(ascensionServiceProvider).getMissions(player.id, rank);
  }
  return _AscensionData(view, rankTo, trials);
});

class AscensionTab extends ConsumerWidget {
  const AscensionTab({super.key});

  static const _rankColors = {
    'e': AppColors.textMuted,
    'd': Color(0xFF4FA06B),
    'c': Color(0xFF3070B3),
    'b': Color(0xFF8B3DFF),
    'a': Color(0xFFFF8C00),
    's': Color(0xFFFFD700),
  };

  static const _gateLabels = {
    'level': 'Nível',
    'missions': 'Missões',
    'gold_lifetime': 'Ouro acumulado',
    'card_wins': 'Vitórias em cartas',
  };

  Color _rankColor(String r) =>
      _rankColors[r.toLowerCase()] ?? AppColors.gold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);
    final rank = player?.guildRank ?? 'none';

    if (rank.toLowerCase() == 'none' || rank.isEmpty) {
      return Center(
        child: Text('Entre na Guilda primeiro.',
            style: GoogleFonts.roboto(color: AppColors.textMuted)),
      );
    }
    if (rank.toUpperCase() == 'S') {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star, color: Color(0xFFFFD700), size: 48),
          const SizedBox(height: 12),
          Text('Rank S — Lenda de Caelum',
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 14, color: const Color(0xFFFFD700))),
          const SizedBox(height: 8),
          Text('Você chegou ao topo.',
              style: GoogleFonts.roboto(color: AppColors.textMuted)),
        ]),
      );
    }

    final async = ref.watch(ascensionViewProvider);
    return async.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => Center(
          child: Text('Erro: $e',
              style: const TextStyle(color: AppColors.textMuted))),
      data: (d) {
        if (d == null) {
          return const SizedBox.shrink();
        }
        final view = d.view;
        final nextColor = _rankColor(d.rankTo);

        final body = <Widget>[
          _header(rank, d.rankTo, player!.gold),
          const SizedBox(height: 16),
        ];

        switch (view.state) {
          case AscensionViewState.locked:
            body.addAll(_locked(d, nextColor));
            break;
          case AscensionViewState.payable:
            body.addAll(_payable(context, ref, player.id, rank, view, nextColor));
            break;
          case AscensionViewState.active:
            body.addAll(_active(context, ref, player.id, rank, d, nextColor));
            break;
          case AscensionViewState.cooldown:
            body.addAll(_cooldown(ref, view, nextColor));
            break;
          case AscensionViewState.done:
            // Transitório — o rank já subiu; força reavaliação pro próximo
            // ciclo.
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => ref.invalidate(ascensionViewProvider));
            body.add(Center(
              child: Text('Ascensão concluída.',
                  style: GoogleFonts.roboto(color: AppColors.textMuted)),
            ));
            break;
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: body,
        );
      },
    );
  }

  // ─── header ────────────────────────────────────────────────────────
  Widget _header(String rank, String rankTo, int gold) {
    final rankColor = _rankColor(rank);
    final nextColor = _rankColor(rankTo);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: nextColor.withValues(alpha: 0.4)),
        gradient: LinearGradient(colors: [
          nextColor.withValues(alpha: 0.06),
          AppColors.surface,
        ]),
      ),
      child: Row(children: [
        _rankChip(rank.toUpperCase(), rankColor),
        const SizedBox(width: 12),
        const Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        _rankChip(rankTo, nextColor),
        const Spacer(),
        const Icon(Icons.monetization_on_outlined,
            color: AppColors.gold, size: 14),
        const SizedBox(width: 4),
        Text('$gold',
            style: GoogleFonts.roboto(fontSize: 12, color: AppColors.gold)),
      ]),
    );
  }

  Widget _rankChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: GoogleFonts.cinzelDecorative(fontSize: 20, color: color)),
      );

  // ─── locked ────────────────────────────────────────────────────────
  List<Widget> _locked(_AscensionData d, Color color) {
    return [
      Text('Requisitos pra desbloquear o teste de ${d.rankTo}',
          style: GoogleFonts.cinzelDecorative(
              fontSize: 12, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      ...d.view.gates.map((g) => _gateRow(g)),
    ];
  }

  Widget _gateRow(AscensionGate g) {
    final label = _gateLabels[g.key] ?? g.key;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: g.met
                ? AppColors.shadowAscending.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      child: Row(children: [
        Icon(g.met ? Icons.check_circle : Icons.lock_outline,
            size: 16,
            color: g.met ? AppColors.shadowAscending : AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.textPrimary)),
        ),
        Text('${g.current}/${g.target}',
            style: GoogleFonts.roboto(
                fontSize: 12,
                color: g.met ? AppColors.shadowAscending : AppColors.textMuted)),
      ]),
    );
  }

  // ─── payable ───────────────────────────────────────────────────────
  List<Widget> _payable(BuildContext context, WidgetRef ref, int playerId,
      String rank, AscensionView view, Color color) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Custo do teste',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.monetization_on_outlined,
                color: AppColors.gold, size: 18),
            const SizedBox(width: 6),
            Text('${view.currentCost}',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 20, color: AppColors.gold)),
          ]),
          if (view.failures > 0) ...[
            const SizedBox(height: 6),
            Text('Taxa inflada (+10% × ${view.failures} ${view.failures == 1 ? "falha" : "falhas"})',
                style: GoogleFonts.roboto(
                    fontSize: 10, color: const Color(0xFFFF8C00))),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      _bigButton(
        label: 'PAGAR E INICIAR',
        icon: Icons.play_circle_outline,
        color: color,
        onTap: () => _pay(context, ref, playerId, rank, view.currentCost),
      ),
    ];
  }

  // ─── active ────────────────────────────────────────────────────────
  List<Widget> _active(BuildContext context, WidgetRef ref, int playerId,
      String rank, _AscensionData d, Color color) {
    final view = d.view;
    final trials = d.trials;
    final canAscend = trials.isNotEmpty && trials.every((t) => t.completed);
    final doneCount = trials.where((t) => t.completed).length;

    final widgets = <Widget>[
      // Countdown da janela.
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          const Icon(Icons.timer_outlined,
              color: AppColors.textMuted, size: 16),
          const SizedBox(width: 8),
          Text('Prazo: ',
              style: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.textMuted)),
          if (view.deadlineMs != null)
            _Countdown(
              endMs: view.deadlineMs!,
              style: GoogleFonts.roboto(
                  fontSize: 12, color: AppColors.textPrimary),
              onExpire: () => ref.invalidate(ascensionViewProvider),
            ),
          const Spacer(),
          Text('$doneCount/${trials.length}',
              style: GoogleFonts.cinzelDecorative(fontSize: 12, color: color)),
        ]),
      ),
      const SizedBox(height: 6),
      if (view.failures > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('Tentativa ${view.failures + 1}',
              style: GoogleFonts.roboto(
                  fontSize: 10, color: AppColors.textMuted)),
        ),
      const SizedBox(height: 10),
    ];

    if (canAscend) {
      widgets.add(_bigButton(
        label: 'ASCENDER PARA RANK ${d.rankTo}',
        icon: Icons.arrow_circle_up,
        color: color,
        onTap: () => _ascend(context, ref, playerId, rank),
      ));
      widgets.add(const SizedBox(height: 16));
    }

    for (final t in trials) {
      widgets.add(_trialCard(ref, playerId, rank, t, color));
    }
    return widgets;
  }

  Widget _trialCard(WidgetRef ref, int playerId, String rank,
      GuildAscensionTableData t, Color color) {
    final kind = _trialKind(t.checkType);
    final pct = t.progressTarget > 0
        ? (t.progress / t.progressTarget).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: t.completed
                ? AppColors.shadowAscending.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(t.title,
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 12,
                    color: t.completed
                        ? AppColors.textMuted
                        : AppColors.textPrimary)),
          ),
          if (t.completed)
            const Icon(Icons.check_circle,
                color: AppColors.shadowAscending, size: 18),
        ]),
        // auto → barra de progresso.
        if (kind == 'auto' && !t.completed) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Text('${t.progress} / ${t.progressTarget}',
              style: GoogleFonts.roboto(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
        // manual → botão de marcação.
        if (kind == 'manual' && !t.completed) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () =>
                _confirmManual(ref, playerId, rank, t.questKey),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.6)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.task_alt, color: color, size: 16),
                const SizedBox(width: 8),
                Text('MARCAR CONCLUÍDO',
                    style: GoogleFonts.cinzelDecorative(
                        fontSize: 10, color: color, letterSpacing: 1)),
              ]),
            ),
          ),
        ],
        // mock → nota (auto-satisfeito).
        if (kind == 'mock' && t.completed) ...[
          const SizedBox(height: 6),
          Text('Prova especial — concedida automaticamente (em breve).',
              style: GoogleFonts.roboto(
                  fontSize: 10, color: AppColors.textMuted)),
        ],
      ]),
    );
  }

  // ─── cooldown ──────────────────────────────────────────────────────
  List<Widget> _cooldown(WidgetRef ref, AscensionView view, Color color) {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.hourglass_bottom,
                color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Text('Teste falhou',
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 13, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 10),
          if (view.cooldownUntilMs != null)
            Row(children: [
              Text('Reabre em: ',
                  style: GoogleFonts.roboto(
                      fontSize: 12, color: AppColors.textMuted)),
              _Countdown(
                endMs: view.cooldownUntilMs!,
                style: GoogleFonts.roboto(
                    fontSize: 12, color: AppColors.textPrimary),
                onExpire: () => ref.invalidate(ascensionViewProvider),
              ),
            ]),
          const SizedBox(height: 8),
          Text('Falhas: ${view.failures}  ·  Próximo custo: ${view.currentCost} ouro',
              style: GoogleFonts.roboto(
                  fontSize: 11, color: AppColors.textMuted)),
        ]),
      ),
    ];
  }

  // ─── botão grande ──────────────────────────────────────────────────
  Widget _bigButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
            gradient: LinearGradient(colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ]),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.cinzelDecorative(
                    fontSize: 11, color: color, letterSpacing: 1)),
          ]),
        ),
      );

  // ─── ações ─────────────────────────────────────────────────────────
  String _trialKind(String checkType) {
    if (checkType == 'manual_proof') return 'manual';
    if (checkType == 'card_wins' || checkType == 'boss_win') return 'mock';
    return 'auto';
  }

  Future<void> _refresh(WidgetRef ref) async {
    final updated = await ref.read(authDsProvider).currentSession();
    if (updated != null) {
      ref.read(currentPlayerProvider.notifier).state = updated;
    }
    ref.invalidate(ascensionViewProvider);
  }

  Future<void> _pay(BuildContext context, WidgetRef ref, int playerId,
      String rank, int cost) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Iniciar Teste de Ascensão',
            style: GoogleFonts.cinzelDecorative(
                fontSize: 14, color: AppColors.gold)),
        content: Text(
            'Custa $cost de ouro e abre uma janela com prazo. Se o prazo '
            'vencer sem completar as provas, o teste falha (cooldown + taxa +10%).',
            style: GoogleFonts.roboto(
                fontSize: 12, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.roboto(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Pagar $cost',
                style: GoogleFonts.roboto(color: AppColors.gold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await ref.read(ascensionStateServiceProvider).pay(playerId, rank);
    if (res.ok) {
      await _refresh(ref);
    } else if (context.mounted) {
      final msg = res.reason == 'insufficient_gold'
          ? 'Ouro insuficiente.'
          : 'Não foi possível iniciar o teste.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _confirmManual(WidgetRef ref, int playerId, String rank,
      String trialKey) async {
    final ok = await ref
        .read(ascensionStateServiceProvider)
        .confirmManualTrial(playerId, rank, trialKey);
    if (ok) await _refresh(ref);
  }

  Future<void> _ascend(BuildContext context, WidgetRef ref, int playerId,
      String rank) async {
    final res = await ref.read(ascensionStateServiceProvider).ascend(playerId, rank);
    if (res.ok && res.newRank != null) {
      await _refresh(ref);
      if (context.mounted) {
        MilestonePopup.show(
          context,
          title: 'Rank ${res.newRank}',
          subtitle: 'Ascensão da Guilda',
          message:
              'Seu Colar da Guilda evoluiu. Você agora é Rank ${res.newRank} — '
              'um dos poucos que chegaram aqui.',
          icon: Icons.arrow_circle_up,
          color: const Color(0xFFFFD700),
        );
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível ascender.')));
    }
  }
}

/// B.4 — countdown que tica a cada 60s; ao zerar chama [onExpire] (uma vez).
class _Countdown extends StatefulWidget {
  final int endMs;
  final TextStyle style;
  final VoidCallback onExpire;
  const _Countdown(
      {required this.endMs, required this.style, required this.onExpire});

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _ticker;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      if (_remaining() <= 0) {
        _expire();
      } else {
        setState(() {});
      }
    });
  }

  int _remaining() => widget.endMs - DateTime.now().millisecondsSinceEpoch;

  void _expire() {
    if (_fired) return;
    _fired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onExpire());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ms = _remaining();
    if (ms <= 0) {
      _expire();
      return Text('—', style: widget.style);
    }
    final d = ms ~/ 86400000;
    final h = (ms ~/ 3600000) % 24;
    final m = (ms ~/ 60000) % 60;
    final txt = d > 0 ? '${d}d ${h}h ${m}m' : (h > 0 ? '${h}h ${m}m' : '${m}m');
    return Text(txt, style: widget.style);
  }
}
