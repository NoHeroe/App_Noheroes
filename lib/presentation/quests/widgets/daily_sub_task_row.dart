import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/daily_unit_type.dart';
import '../../../domain/models/daily_sub_task_instance.dart';
import 'daily_pilar_visuals.dart';

/// Sprint 3.2 Etapa 1.3.A — uma linha por sub-tarefa dentro do card
/// aberto. 3 dessas por missão.
///
/// Renderiza: nome + "X/Y unidade" + barra de progresso estática + 4
/// botões numéricos (-10/-1/+1/+10) OU 1 botão "MARCAR FEITO"
/// (substituição quando `tipoUnidade == boolean`).
///
/// Cor da barra:
/// - Mono-modalidade: cor do pilar do card (passada em [cardColor]).
/// - Vitalismo: cor canônica do `subPilar` da sub-tarefa (vermelho/
///   azul/dourado por sub-tarefa) — sinaliza visualmente que veio de
///   pilar diferente.
class DailySubTaskRow extends StatelessWidget {
  final DailySubTaskInstance sub;

  /// Cor do card/pilar. Pra Vitalismo a cor da barra desta linha NÃO é
  /// essa — usa `subPilar` via [DailyPilarVisuals.colorForSubPilar].
  final Color cardColor;

  /// Callback chamado quando o usuário tap num botão. `delta` é positivo
  /// (+1, +10) ou negativo (-1, -10). Pra boolean é +1 (marcar feito) ou
  /// -1 (desmarcar).
  final void Function(int delta) onDelta;

  const DailySubTaskRow({
    super.key,
    required this.sub,
    required this.cardColor,
    required this.onDelta,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        DailyPilarVisuals.colorForSubPilar(sub.subPilar, cardColor);
    final isBool = sub.tipoUnidade == DailyUnitType.boolean;
    final progress = sub.escalaAlvo == 0
        ? 0.0
        : (sub.progressoAtual / sub.escalaAlvo).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nome (verde + ✓ quando completed) + X/Y.
          Row(
            children: [
              Flexible(
                child: Text(
                  sub.nomeVisivel,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: sub.completed
                        ? DailyPilarVisuals.completedColor
                        : AppColors.textPrimary,
                    fontWeight:
                        sub.completed ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (sub.completed) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: DailyPilarVisuals.completedColor,
                ),
              ],
              const Spacer(),
              const SizedBox(width: 8),
              Text(
                isBool
                    ? (sub.completed ? 'FEITO' : '— / ${sub.escalaAlvo}')
                    : '${sub.progressoAtual} / ${sub.escalaAlvo} ${sub.unidade}',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: sub.completed
                      ? DailyPilarVisuals.completedColor
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra estática (1.3.B anima). Sempre na cor do pilar — visual
          // de completude vai no nome+ícone, não na barra.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          // Botões: 4 numéricos OU 1 boolean.
          if (isBool) _BoolButton(sub: sub, color: color, onDelta: onDelta)
          else _NumericButtons(
              sub: sub, color: color, onDelta: onDelta),
        ],
      ),
    );
  }
}

class _NumericButtons extends StatelessWidget {
  final DailySubTaskInstance sub;
  final Color color;
  final void Function(int delta) onDelta;
  const _NumericButtons(
      {required this.sub, required this.color, required this.onDelta});

  @override
  Widget build(BuildContext context) {
    // Cap individual: progresso máximo = escalaAlvo × 3 (excedência 300%).
    // (+) bloqueia no cap; (-) bloqueia em 0. Sub completa NÃO desabilita
    // — botões seguem ativos pra permitir excedência ou correção.
    final atCap = sub.escalaAlvo > 0 &&
        sub.progressoAtual >= sub.escalaAlvo * 3;
    final atZero = sub.progressoAtual <= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NumericBtn(
            label: '−10', color: color, disabled: atZero,
            onTap: () => onDelta(-10)),
        const SizedBox(width: 8),
        _NumericBtn(
            label: '−1', color: color, disabled: atZero,
            onTap: () => onDelta(-1)),
        const Spacer(),
        _NumericBtn(
            label: '+1', color: color, disabled: atCap,
            onTap: () => onDelta(1)),
        const SizedBox(width: 8),
        _NumericBtn(
            label: '+10', color: color, disabled: atCap,
            onTap: () => onDelta(10)),
      ],
    );
  }
}

class _NumericBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _NumericBtn({
    required this.label,
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = disabled
        ? AppColors.border
        : color.withValues(alpha: 0.85);
    final textColor =
        disabled ? AppColors.textMuted : AppColors.textPrimary;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 44,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(6),
          color: disabled
              ? AppColors.surface
              : color.withValues(alpha: 0.06),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BoolButton extends StatelessWidget {
  final DailySubTaskInstance sub;
  final Color color;
  final void Function(int delta) onDelta;
  const _BoolButton(
      {required this.sub, required this.color, required this.onDelta});

  @override
  Widget build(BuildContext context) {
    final done = sub.completed;
    final borderColor = done
        ? DailyPilarVisuals.completedColor
        : color.withValues(alpha: 0.85);
    final fillColor = done
        ? DailyPilarVisuals.completedColor.withValues(alpha: 0.12)
        : color.withValues(alpha: 0.06);
    final label = done ? '✓ FEITO' : 'MARCAR FEITO';
    return GestureDetector(
      onTap: () => onDelta(done ? -1 : 1),
      child: Container(
        width: double.infinity,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(6),
          color: fillColor,
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: done
                ? DailyPilarVisuals.completedColor
                : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
