import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/faction_quest_service.dart';
import '../../../data/database/app_database.dart';

class FactionQuestCard extends StatefulWidget {
  final FactionQuestsTableData quest;
  final String factionId;

  const FactionQuestCard({
    super.key,
    required this.quest,
    required this.factionId,
  });

  @override
  State<FactionQuestCard> createState() => _FactionQuestCardState();
}

class _FactionQuestCardState extends State<FactionQuestCard> {
  late Timer _timer;
  Duration _remaining = FactionQuestService.timeUntilNextWeek();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _remaining = FactionQuestService.timeUntilNextWeek();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color get _factionColor => switch (widget.factionId) {
        'moon_clan'    => const Color(0xFF3070B3),
        'sun_clan'     => const Color(0xFFC2A05A),
        'black_legion' => const Color(0xFF8B2020),
        'new_order'    => const Color(0xFF6B4FA0),
        'trinity'      => const Color(0xFF4FA06B),
        'renegades'    => const Color(0xFFB36B00),
        'error'        => const Color(0xFF7B2FBE),
        _              => AppColors.gold,
      };

  String _formatTimer(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final color = _factionColor;
    final progress = widget.quest.progress;
    final target = widget.quest.progressTarget;
    final pct = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final done = widget.quest.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? AppColors.shadowAscending.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text('MISSÃO SEMANAL',
                    style: GoogleFonts.roboto(
                        fontSize: 8, color: color, letterSpacing: 1.5)),
              ),
              const Spacer(),
              if (!done)
                Row(children: [
                  Icon(Icons.timer_outlined, color: AppColors.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(_formatTimer(_remaining),
                      style: GoogleFonts.roboto(
                          fontSize: 10, color: AppColors.textMuted)),
                ])
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.shadowAscending.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('COMPLETA',
                      style: GoogleFonts.roboto(
                          fontSize: 8,
                          color: AppColors.shadowAscending,
                          letterSpacing: 1.5)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.quest.title,
              style: GoogleFonts.cinzelDecorative(
                  fontSize: 13,
                  color: done ? AppColors.textMuted : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(widget.quest.description,
              style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.4)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(done
                  ? AppColors.shadowAscending
                  : color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$progress / $target',
                  style: GoogleFonts.roboto(
                      fontSize: 10, color: AppColors.textMuted)),
              Row(children: [
                Icon(Icons.auto_awesome, color: AppColors.xp, size: 11),
                const SizedBox(width: 3),
                Text('+${widget.quest.xpReward} XP',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.xp)),
                const SizedBox(width: 8),
                Icon(Icons.monetization_on_outlined,
                    color: AppColors.gold, size: 11),
                const SizedBox(width: 3),
                Text('+${widget.quest.goldReward}',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.gold)),
                const SizedBox(width: 8),
                const Text('🎁',
                    style: TextStyle(fontSize: 11)),
                Text(' + 5% item',
                    style: GoogleFonts.roboto(
                        fontSize: 10, color: AppColors.textMuted)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}
