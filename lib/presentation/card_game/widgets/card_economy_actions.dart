import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/card_game/card_game.dart';
import '../card_economy.dart';
import '../card_ownership.dart';

/// Bloco de ações de economia para uma carta (embutido no detalhe da Coleção):
/// **Criar** (se não possui), **Aprimorar** + **Desencantar** (se possui).
/// Carrega o snapshot `cg_card_info` e reflete custo, saldo e affordability.
/// Server-authoritative — o botão só dispara a RPC; o servidor valida.
class CardEconomyActions extends ConsumerStatefulWidget {
  final String cardId;

  /// Stats-base (nível 1) pra mostrar os deltas no aprimorar CR-style.
  final int baseAtk;
  final int baseHp;
  final bool isCreature;

  /// Herói: não tem atk/hp/escala de stat — o preview de nível some.
  final bool isHero;

  /// Conceito primário (não-neutro) da carta — usado no desencante pra chance
  /// de Essência de Facção (cards_catalog não tem conceito no DB). null = neutro.
  final String? concept;

  const CardEconomyActions({
    super.key,
    required this.cardId,
    this.baseAtk = 0,
    this.baseHp = 0,
    this.isCreature = true,
    this.isHero = false,
    this.concept,
  });

  @override
  ConsumerState<CardEconomyActions> createState() => _CardEconomyActionsState();
}

class _CardEconomyActionsState extends ConsumerState<CardEconomyActions> {
  Map<String, dynamic>? _info;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      setState(() {
        _loading = false;
        _error = 'Sessão expirada.';
      });
      return;
    }
    try {
      final info = await ref
          .read(cardEconomyServiceProvider)
          .cardInfo(player.id, widget.cardId, concept: widget.concept);
      if (!mounted) return;
      setState(() {
        _info = info['ok'] == true ? info : null;
        _error = info['ok'] == true ? null : 'Carta indisponível.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erro ao carregar economia.';
      });
    }
  }

  Future<void> _refreshAfterAction() async {
    // Posse/cópias mudaram → invalida a Coleção; ouro pode ter mudado.
    ref.invalidate(cardOwnershipProvider);
    try {
      final updated = await ref.read(authDsProvider).currentSession();
      if (mounted && updated != null) {
        ref.read(currentPlayerProvider.notifier).state = updated;
      }
    } catch (_) {}
    await _load();
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.roboto(color: AppColors.txt)),
        backgroundColor: ok ? const Color(0xFF14331E) : const Color(0xFF1A1326),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181221),
        title: Text(title,
            style: GoogleFonts.cinzelDecorative(
                color: AppColors.goldLt, fontSize: 16)),
        content: Text(body,
            style: GoogleFonts.roboto(color: AppColors.txt2, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.roboto(color: AppColors.txtMut)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action,
                style: GoogleFonts.roboto(
                    color: AppColors.purpleLt, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _run(Future<CgResult> Function() op, String okMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final r = await op();
      if (r.ok) {
        _snack(okMsg, ok: true);
        await _refreshAfterAction();
      } else {
        _snack(cgReasonLabel(r.reason));
      }
    } catch (_) {
      _snack('Erro de rede. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                color: AppColors.purpleLt, strokeWidth: 2.2),
          ),
        ),
      );
    }
    final info = _info;
    if (info == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(_error ?? 'Economia indisponível.',
            style: GoogleFonts.roboto(color: AppColors.txtMut, fontSize: 12)),
      );
    }

    final player = ref.read(currentPlayerProvider);
    final isRelic = info['kind'] == 'relic';
    final owned = info['owned'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        Text('PROGRESSÃO',
            style: GoogleFonts.roboto(
                fontSize: 10, letterSpacing: 1.5, color: AppColors.txtMut)),
        const SizedBox(height: 8),
        _resourceStrip(info),
        const SizedBox(height: 12),
        if (owned) ...[
          _ownedBlock(info, isRelic),
          // Criar também aparece pra carta possuída → gera +1 cópia (combustível
          // de evolução). Antes só aparecia pra carta não-possuída.
          if (info['craft'] != null) ...[
            const SizedBox(height: 8),
            _craftBlock(info, asCopy: true),
          ],
        ] else
          // CEO 2026-06-12: carta BLOQUEADA (não-possuída) não pode ser criada
          // do zero — só obtendo em pacote/recompensa.
          _lockedCardNote(),
        if (player != null && (info['player_level'] as num? ?? 1) < 3)
          _lockNote('Criação e desencante abrem no Nível 3 · Aprimorar no Nível 5'),
      ],
    );
  }

  // ── Saldo de recursos relevantes ────────────────────────────────────
  Widget _resourceStrip(Map<String, dynamic> info) {
    int n(String k) => (info[k] as num?)?.toInt() ?? 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _resChip(Icons.blur_on, 'Poeira', n('have_dust')),
        _resChip(Icons.diamond_outlined, 'Cristal', n('have_crystal')),
        _resChip(Icons.military_tech_outlined, 'Emblema', n('have_mat')),
        _resChip(Icons.auto_awesome, 'Essência', n('have_soul')),
      ],
    );
  }

  Widget _resChip(IconData icon, String label, int amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0x33100C15),
        border: Border.all(color: AppColors.borderViolet),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.purpleLt),
          const SizedBox(width: 5),
          Text('$label ',
              style: GoogleFonts.roboto(fontSize: 11, color: AppColors.txtMut)),
          Text('$amount',
              style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLt)),
        ],
      ),
    );
  }

  // ── Criar carta (não-possuída) ou Criar cópia (possuída → +1 cópia) ──
  Widget _craftBlock(Map<String, dynamic> info, {bool asCopy = false}) {
    final craft = info['craft'] as Map?;
    if (craft == null) {
      return _infoLine('Esta carta não pode ser criada.');
    }
    final dust = (craft['dust'] as num).toInt();
    final crystal = (craft['crystal'] as num).toInt();
    final soul = (craft['soul'] as num? ?? 2).toInt();
    final faccao = (craft['faccao'] as num? ?? 0).toInt();
    final can = craft['can'] == true;
    final faccaoStr = faccao > 0 ? ' · $faccao Ess. Facção' : '';
    return _actionButton(
      label: asCopy ? 'CRIAR CÓPIA' : 'CRIAR',
      icon: Icons.auto_fix_high,
      cost: 'Poeira $dust · Cristal $crystal · $soul Essência$faccaoStr',
      enabled: can && !_busy,
      onTap: () async {
        if (!await _confirm(asCopy ? 'Criar cópia' : 'Criar carta',
            'Gastar Poeira $dust + Cristal $crystal + $soul Essência'
                '${faccao > 0 ? ' + $faccao Essência de Facção' : ''} '
                '${asCopy ? 'para gerar +1 cópia desta carta?' : 'para criar esta carta no Nível 1?'}',
            asCopy ? 'Criar cópia' : 'Criar')) {
          return;
        }
        final p = ref.read(currentPlayerProvider)!;
        await _run(
            () => ref
                .read(cardEconomyServiceProvider)
                .create(p.id, widget.cardId, concept: widget.concept),
            asCopy ? '+1 cópia criada!' : 'Carta criada!');
      },
    );
  }

  // ── Carta possuída → Nível + Aprimorar + Desencantar ─────────────────
  Widget _ownedBlock(Map<String, dynamic> info, bool isRelic) {
    final level = (info['level'] as num).toInt();
    final maxLevel = (info['max_level'] as num).toInt();
    final copies = (info['copies'] as num).toInt();
    final upgrade = info['upgrade'] as Map?;
    final dis = info['disenchant'] as Map?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _badge('Nível $level/$maxLevel', AppColors.gold),
            const SizedBox(width: 8),
            _badge('Cópias $copies', AppColors.purpleLt),
          ],
        ),
        const SizedBox(height: 12),
        if (level >= maxLevel)
          _infoLine('Nível máximo atingido.')
        else if (upgrade != null)
          _upgradePanel(info, level, copies, upgrade),
        const SizedBox(height: 8),
        if (dis != null)
          _actionButton(
            label: 'DESENCANTAR',
            icon: Icons.recycling,
            danger: true,
            cost: '+Poeira ${(dis['dust'] as num).toInt()} '
                '+Lasca ${(dis['lasca'] as num? ?? 0).toInt()} '
                '+Essência 1 · chance: Cristal/Facção',
            enabled: dis['can'] == true && !_busy,
            onTap: () async {
              if (!await _confirm('Desencantar carta',
                  'Destruir 1 cópia desta carta em troca de materiais? '
                      'Não recupera o que foi gasto em melhorias.',
                  'Desencantar')) {
                return;
              }
              final p = ref.read(currentPlayerProvider)!;
              await _run(
                  () => ref
                      .read(cardEconomyServiceProvider)
                      .disenchant(p.id, widget.cardId, concept: widget.concept),
                  'Carta desencantada.');
            },
          ),
      ],
    );
  }

  // ── Aprimorar (CR-style: carta atual → próxima, deltas, custos) ──────
  Widget _upgradePanel(Map<String, dynamic> info, int level, int copies, Map up) {
    final player = ref.read(currentPlayerProvider);
    final gold = player?.gold ?? 0;
    final goldCost = (up['gold'] as num).toInt();
    final poeira = (up['poeira'] as num? ?? 0).toInt();
    final embNeed = (up['emblema_needed'] as num? ?? 0).toInt();
    final soul = (up['soul'] as num).toInt();
    final copiesNeed = (up['copies_needed'] as num).toInt();
    final haveEmb = (up['have_emblema'] as num? ?? 0).toInt();
    final haveSoul = (up['have_soul'] as num? ?? 0).toInt();
    final haveDust = (up['have_dust'] as num? ?? 0).toInt();
    final can = up['can'] == true;

    final atkNow = cgScaleStat(widget.baseAtk, level);
    final atkNext = cgScaleStat(widget.baseAtk, level + 1);
    final hpNow = cgScaleStat(widget.baseHp, level);
    final hpNext = cgScaleStat(widget.baseHp, level + 1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x22100C15),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: _miniLevel('Nível $level', atkNow, hpNow,
                      AppColors.txtMut, null, null)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: AppColors.gold),
              ),
              Expanded(
                  child: _miniLevel('Nível ${level + 1}', atkNext, hpNext,
                      AppColors.gold, atkNext - atkNow, hpNext - hpNow)),
            ],
          ),
          const SizedBox(height: 10),
          _copiesBar(copies, copiesNeed),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _costChip(Icons.monetization_on, goldCost, gold >= goldCost),
              _costChip(Icons.blur_on, poeira, haveDust >= poeira),
              _costChip(Icons.military_tech_outlined, embNeed, haveEmb >= embNeed),
              _costChip(Icons.auto_awesome, soul, haveSoul >= soul),
            ],
          ),
          const SizedBox(height: 10),
          _upgradeButton(can && copies > copiesNeed, level + 1, copiesNeed),
        ],
      ),
    );
  }

  Widget _miniLevel(String title, int atk, int hp, Color accent, int? dAtk,
      int? dHp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x33100C15),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.roboto(
                  fontSize: 10, letterSpacing: 0.5, color: accent)),
          if (!widget.isHero) const SizedBox(height: 4),
          if (widget.isHero)
            const SizedBox.shrink()
          else if (widget.isCreature)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, size: 12, color: AppColors.gold),
                Text('$atk',
                    style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.txt)),
                if (dAtk != null && dAtk > 0)
                  Text(' +$dAtk',
                      style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.shadowAscending)),
                const SizedBox(width: 8),
                const Icon(Icons.favorite, size: 11, color: Colors.white),
                Text('$hp',
                    style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.txt)),
                if (dHp != null && dHp > 0)
                  Text(' +$dHp',
                      style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.shadowAscending)),
              ],
            )
          else
            Text('+10% bônus',
                style: GoogleFonts.roboto(fontSize: 11, color: AppColors.txt2)),
        ],
      ),
    );
  }

  Widget _copiesBar(int have, int need) {
    final ratio = need <= 0 ? 1.0 : (have / need).clamp(0.0, 1.0);
    final ok = have > need;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Cópias',
                style: GoogleFonts.roboto(fontSize: 10, color: AppColors.txtMut)),
            const Spacer(),
            Text('$have / ${need + 1}',
                style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ok ? AppColors.shadowAscending : AppColors.txt2)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(
                ok ? AppColors.shadowAscending : AppColors.purpleLt),
          ),
        ),
      ],
    );
  }

  Widget _costChip(IconData icon, int amount, bool ok) {
    final color = ok ? AppColors.goldLt : AppColors.hp;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text('$amount',
            style: GoogleFonts.robotoMono(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        if (!ok)
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Icon(Icons.close, size: 11, color: AppColors.hp),
          ),
      ],
    );
  }

  Widget _upgradeButton(bool can, int nextLevel, int copiesNeed) {
    return Opacity(
      opacity: can && !_busy ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: can && !_busy
            ? () async {
                if (!await _confirm('Aprimorar carta',
                    'Subir para o Nível $nextLevel? Consome ouro, Poeira, '
                        'Emblemas, Essência e $copiesNeed cópia(s).',
                    'Aprimorar')) {
                  return;
                }
                final p = ref.read(currentPlayerProvider)!;
                await _run(
                    () => ref
                        .read(cardEconomyServiceProvider)
                        .upgrade(p.id, widget.cardId),
                    'Carta aprimorada!');
              }
            : null,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: can
                ? const LinearGradient(
                    colors: [Color(0xFFE8C15A), Color(0xFFB8932E)])
                : null,
            color: can ? null : const Color(0x33100C15),
            border: Border.all(
                color: can
                    ? AppColors.gold
                    : AppColors.borderViolet),
          ),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2))
              : Text(can ? 'APRIMORAR' : 'Recursos insuficientes',
                  style: GoogleFonts.roboto(
                      fontSize: 13,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: can ? Colors.black : AppColors.txtMut)),
        ),
      ),
    );
  }

  // ── Widgets auxiliares ───────────────────────────────────────────────
  Widget _actionButton({
    required String label,
    required IconData icon,
    required String cost,
    required bool enabled,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final base = danger ? AppColors.conceptCorrompido : AppColors.purple;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [
              base.withValues(alpha: 0.32),
              base.withValues(alpha: 0.12),
            ]),
            border: Border.all(color: base.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.txt),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.roboto(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.txt)),
                    const SizedBox(height: 2),
                    Text(cost,
                        style: GoogleFonts.roboto(
                            fontSize: 10.5, color: AppColors.txt2)),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: AppColors.txt, strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(text,
          style: GoogleFonts.roboto(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _infoLine(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text,
            style: GoogleFonts.roboto(fontSize: 12, color: AppColors.txtMut)),
      );

  /// Carta bloqueada (não-possuída): não pode ser criada do zero.
  Widget _lockedCardNote() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0x22D8323F),
          border: Border.all(
              color: AppColors.conceptCorrompido.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline,
                size: 18, color: AppColors.conceptCorrompido),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Carta bloqueada — obtenha em pacotes ou recompensas. '
                'Cartas que você ainda não tem não podem ser criadas do zero.',
                style: GoogleFonts.roboto(
                    fontSize: 11.5, height: 1.35, color: AppColors.txt2),
              ),
            ),
          ],
        ),
      );

  Widget _lockNote(String text) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 13, color: AppColors.txtMut),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.roboto(
                      fontSize: 10.5, color: AppColors.txtMut)),
            ),
          ],
        ),
      );
}
