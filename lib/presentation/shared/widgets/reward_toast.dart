import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class _ToastJob {
  final String source;
  final int xp, gold, gems;
  final String? achievementTitle;
  _ToastJob({required this.source, required this.xp, required this.gold,
      required this.gems, this.achievementTitle});
}

class RewardToast {
  static final Queue<_ToastJob> _queue = Queue();
  static bool _showing = false;

  static void show(BuildContext context, {
    required String source,
    int xp = 0, int gold = 0, int gems = 0,
    String? achievementTitle,
  }) {
    _queue.add(_ToastJob(source: source, xp: xp, gold: gold,
        gems: gems, achievementTitle: achievementTitle));
    if (!_showing) _next(context);
  }

  static void _next(BuildContext context) {
    if (_queue.isEmpty) { _showing = false; return; }
    _showing = true;
    final job = _queue.removeFirst();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _RewardToastWidget(
        job: job,
        onDismiss: () {
          entry.remove();
          _next(context);
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _RewardToastWidget extends StatefulWidget {
  final _ToastJob job;
  final VoidCallback onDismiss;
  const _RewardToastWidget({required this.job, required this.onDismiss});

  @override
  State<_RewardToastWidget> createState() => _RewardToastWidgetState();
}

class _RewardToastWidgetState extends State<_RewardToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(
            begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 3500), _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16, right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      width: 1.5),
                  boxShadow: [BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (j.achievementTitle != null) ...[
                      Row(children: [
                        const Icon(Icons.emoji_events,
                            color: AppColors.gold, size: 16),
                        const SizedBox(width: 8),
                        Text('CONQUISTA DESBLOQUEADA',
                            style: GoogleFonts.cinzelDecorative(
                                fontSize: 9, color: AppColors.gold,
                                letterSpacing: 1.5)),
                      ]),
                      const SizedBox(height: 4),
                      Text(j.achievementTitle!,
                          style: GoogleFonts.roboto(fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFF2A2A3A), height: 1),
                      const SizedBox(height: 10),
                    ],
                    Text(j.source,
                        style: GoogleFonts.roboto(fontSize: 11,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Row(children: [
                      if (j.xp > 0) ...[
                        _Chip(icon: '✦', value: '+${j.xp}',
                            label: 'XP', color: AppColors.purple),
                        const SizedBox(width: 8),
                      ],
                      if (j.gold > 0) ...[
                        _Chip(icon: '◈', value: '+${j.gold}',
                            label: 'Ouro', color: AppColors.gold),
                        const SizedBox(width: 8),
                      ],
                      if (j.gems > 0)
                        _Chip(icon: '◆', value: '+${j.gems}',
                            label: 'Gemas', color: AppColors.mp),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String icon, value, label;
  final Color color;
  const _Chip({required this.icon, required this.value,
      required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: TextStyle(fontSize: 10, color: color)),
        const SizedBox(width: 4),
        Text('$value $label', style: GoogleFonts.roboto(
            fontSize: 11, color: color,
            fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
