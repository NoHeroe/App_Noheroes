import 'package:flutter/material.dart';

/// Sprint 3.1 Bloco 9 — tile de opção do quiz. UI mínima funcional —
/// Bloco 10 substitui estética (dark fantasy, partículas, NPC overlay
/// polido). O suficiente pra testar fim-a-fim.
///
/// Modo `radio` = escolha única, `checkbox` = múltipla até [maxChecked].
class QuizOptionTile extends StatelessWidget {
  final String label;
  final String? description;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  final bool checkboxMode;

  const QuizOptionTile({
    super.key,
    required this.label,
    required this.selected,
    this.description,
    this.disabled = false,
    this.onTap,
    this.checkboxMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = checkboxMode
        ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
        : (selected ? Icons.radio_button_checked : Icons.radio_button_off);
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: description == null ? null : Text(description!),
        onTap: disabled ? null : onTap,
        selected: selected,
      ),
    );
  }
}
