import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// Popup centralizado para grandes marcos:
/// level up, desbloqueios, conquistas épicas etc.
class MilestonePopup extends StatefulWidget {
  final String title;
  final String subtitle;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onDismiss;

  const MilestonePopup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.message,
    this.icon = Icons.auto_awesome,
    this.color = AppColors.gold,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String message,
    IconData icon = Icons.auto_awesome,
    Color color = AppColors.gold,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) => MilestonePopup(
        title: title,
        subtitle: subtitle,
        message: message,
        icon: icon,
        color: color,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<MilestonePopup> createState() => _MilestonePopupState();
}

class _MilestonePopupState extends State<MilestonePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        widget.onDismiss?.call();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: widget.color.withValues(alpha: 0.6),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone central
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.12),
                        border: Border.all(
                            color: widget.color.withValues(alpha: 0.5),
                            width: 2),
                      ),
                      child: Icon(widget.icon,
                          color: widget.color, size: 36),
                    ),
                    const SizedBox(height: 16),

                    // Subtítulo (ex: "NÍVEL 5")
                    Text(
                      widget.subtitle.toUpperCase(),
                      style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: widget.color,
                          letterSpacing: 3),
                    ),
                    const SizedBox(height: 6),

                    // Título principal
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzelDecorative(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                          height: 1.3),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Container(
                        height: 1,
                        color: widget.color.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),

                    // Mensagem
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    // Hint
                    Text(
                      'Toque para continuar',
                      style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: AppColors.textMuted),
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
