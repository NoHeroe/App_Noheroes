import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// Widget padrão de diálogo NPC — mesmo design do NpcDialogueOverlay.
/// Avatar à esquerda, balão de fala, toque na tela para fechar.
/// Usado por TODOS os NPCs do app.
class NpcDialogOverlay extends StatefulWidget {
  final String npcName;
  final String npcTitle;
  final String message;
  final VoidCallback onDismiss;

  const NpcDialogOverlay({
    super.key,
    required this.npcName,
    required this.npcTitle,
    required this.message,
    required this.onDismiss,
  });

  /// Mostra o overlay sobre a tela atual via Navigator
  static Future<void> show(BuildContext context, {
    required String npcName,
    required String npcTitle,
    required String message,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        pageBuilder: (ctx, _, __) => NpcDialogOverlay(
          npcName: npcName,
          npcTitle: npcTitle,
          message: message,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<NpcDialogOverlay> createState() => _NpcDialogOverlayState();
}

class _NpcDialogOverlayState extends State<NpcDialogOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 0, 16,
                    MediaQuery.of(context).padding.bottom + 100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar NPC
                    Builder(builder: (_) {
                      final isVoid = widget.npcName == 'O Vazio';
                      final npcColor = isVoid ? AppColors.purple : AppColors.gold;
                      final npcIcon = isVoid ? Icons.blur_on : Icons.person_outline;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.shadowVoid,
                              border: Border.all(
                                  color: npcColor.withValues(alpha: 0.7),
                                  width: 2),
                              boxShadow: [BoxShadow(
                                  color: npcColor.withValues(alpha: 0.3),
                                  blurRadius: 14, spreadRadius: 2)],
                            ),
                            child: Icon(npcIcon,
                                color: npcColor, size: 32),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.npcName.length > 10
                                ? '${widget.npcName.substring(0, 8)}...'
                                : widget.npcName,
                            style: GoogleFonts.cinzelDecorative(
                                fontSize: 8, color: npcColor,
                                letterSpacing: 1),
                          ),
                        ],
                      );
                    }),
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
                              color: AppColors.gold.withValues(alpha: 0.35)),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.npcTitle.toUpperCase(),
                                style: GoogleFonts.roboto(
                                    fontSize: 8, color: AppColors.gold,
                                    letterSpacing: 2)),
                            const SizedBox(height: 6),
                            Text('"${widget.message}"',
                                style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    fontStyle: FontStyle.italic,
                                    height: 1.5)),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text('Toque para fechar',
                                  style: GoogleFonts.roboto(
                                      fontSize: 9,
                                      color: AppColors.textMuted)),
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
      ),
    );
  }
}
