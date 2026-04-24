import 'package:flutter/material.dart';

import 'section_header.dart';

/// Sprint 3.1 Bloco 14.6c — wrapper de seção da `/quests` com
/// sanfona (expand/collapse).
///
/// ## Default
/// Seção sempre **expandida** no primeiro build de cada sessão. O
/// jogador colapsa manualmente se quiser.
///
/// ## Persistência
/// Estado vive **em memória local** deste widget via `StatefulWidget`.
/// Sai de tela / hot reload / logout reseta pro default (expandido).
/// Decisão pragmática: persistir em `SharedPreferences` por seção +
/// jogador seria churn pra pouco ganho — sessão do Santuário é curta
/// e o default expandido é o que o jogador quer 90% do tempo.
class SectionAccordion extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final List<Widget> children;

  const SectionAccordion({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.color,
    this.subtitle,
  });

  @override
  State<SectionAccordion> createState() => _SectionAccordionState();
}

class _SectionAccordionState extends State<SectionAccordion> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: widget.title,
          icon: widget.icon,
          color: widget.color,
          subtitle: widget.subtitle,
          expanded: _expanded,
          onToggle: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}
