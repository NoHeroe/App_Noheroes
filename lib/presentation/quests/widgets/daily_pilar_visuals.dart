import 'package:flutter/material.dart';

import '../../../domain/enums/mission_category.dart';

/// Sprint 3.2 Etapa 1.3.A — visuais canônicos por pilar (cor + ícone).
///
/// Cores fechadas com o CEO na Etapa 1.1 (mesmas do JSON `cor_canonica`):
/// - Físico → vermelho `#A32D2D`
/// - Mental → azul `#185FA5`
/// - Espiritual → dourado `#854F0B`
/// - Vitalismo → roxo `#534AB7`
///
/// Vitalismo: card usa cor própria (#534AB7), mas barras de cada
/// sub-tarefa usam a cor do pilar de origem (`subPilar`) — esse helper
/// expõe `colorForSubPilar` pra resolver isso na UI.
class DailyPilarVisuals {
  DailyPilarVisuals._();

  static const Color fisicoColor = Color(0xFFA32D2D);
  static const Color mentalColor = Color(0xFF185FA5);
  static const Color espiritualColor = Color(0xFF854F0B);
  static const Color vitalismoColor = Color(0xFF534AB7);

  /// Verde da missão concluída (border + check).
  static const Color completedColor = Color(0xFF2D8B3D);

  static Color colorOf(MissionCategory category) => switch (category) {
        MissionCategory.fisico => fisicoColor,
        MissionCategory.mental => mentalColor,
        MissionCategory.espiritual => espiritualColor,
        MissionCategory.vitalismo => vitalismoColor,
      };

  static IconData iconOf(MissionCategory category) => switch (category) {
        MissionCategory.fisico => Icons.fitness_center,
        MissionCategory.mental => Icons.psychology_outlined,
        MissionCategory.espiritual => Icons.self_improvement,
        MissionCategory.vitalismo => Icons.auto_awesome,
      };

  /// Cor da sub-tarefa quando faz parte de missão Vitalismo (subPilar
  /// preenchido). Fallback: cor do card.
  static Color colorForSubPilar(String? subPilar, Color cardColor) {
    if (subPilar == null) return cardColor;
    return switch (subPilar) {
      'fisico' => fisicoColor,
      'mental' => mentalColor,
      'espiritual' => espiritualColor,
      _ => cardColor,
    };
  }
}
