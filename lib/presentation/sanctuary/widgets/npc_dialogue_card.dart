import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/asset_loader.dart';
import '../../../data/datasources/local/npc_reputation_service.dart';

class NpcDialogueOverlay extends StatefulWidget {
  final String shadowState;
  final int caelumDay;
  final String? factionType;
  final VoidCallback onDismiss;

  const NpcDialogueOverlay({
    super.key,
    required this.shadowState,
    required this.caelumDay,
    this.factionType,
    required this.onDismiss,
  });

  @override
  State<NpcDialogueOverlay> createState() => _NpcDialogueOverlayState();
}

class _NpcDialogueOverlayState extends State<NpcDialogueOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  String _dialogue = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    _loadAndShow();
  }

  String _npcName = '???';
  String _npcTitle = '';

  Future<void> _loadAndShow() async {
    final data = await AssetLoader.getNpcForPlayer(
      factionType: widget.factionType,
      shadowState: widget.shadowState,
      caelumDay: widget.caelumDay,
    );
    if (mounted) {
      setState(() {
        _dialogue = data['dialogue'] ?? '';
        _npcName = data['name'] ?? '???';
        _npcTitle = data['title'] ?? '';
      });
      _ctrl.forward();
    }
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dialogue.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar NPC
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.shadowVoid,
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.gold,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _npcName.length > 8 ? '${_npcName.substring(0, 7)}...' : _npcName,
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 8,
                          color: AppColors.gold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // Balão de fala
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _npcTitle.toUpperCase(),
                            style: GoogleFonts.roboto(
                              fontSize: 8,
                              color: AppColors.gold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '"$_dialogue"',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              'Toque para fechar',
                              style: GoogleFonts.roboto(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
