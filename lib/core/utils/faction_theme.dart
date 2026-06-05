import 'package:flutter/material.dart';

/// Sprint 3.4 Etapa E — tema (nome + cor) por facção, compartilhado entre
/// `/guild` (card D1) e `/faction/<id>` (ficha de membro).
///
/// Espelha `assets/data/factions.json` (`name` + `color`) e o
/// `character_screen._factionName`. Mantido como `static const` inline
/// (cores estáveis em runtime) pra evitar I/O async em cards de destaque.
/// Extraído dos maps privados que viviam no `GuildScreen` na Etapa D pra
/// eliminar duplicação ao reusar na `FactionScreen`.
class FactionTheme {
  FactionTheme._();

  static const _names = <String, String>{
    'guild':        'Guilda de Aventureiros',
    'moon_clan':    'Clã da Lua',
    'sun_clan':     'Clã do Sol',
    'black_legion': 'Legião Negra',
    'new_order':    'Nova Ordem',
    'trinity':      'Culto da Trindade',
    'renegades':    'Os Renegados',
    'error':        'Facção ERROR',
  };

  static const _colors = <String, Color>{
    'guild':        Color(0xFFC2A05A),
    'moon_clan':    Color(0xFF3070B3),
    'sun_clan':     Color(0xFFC2A05A),
    'black_legion': Color(0xFF8B2020),
    'new_order':    Color(0xFF6B4FA0),
    'trinity':      Color(0xFF4FA06B),
    'renegades':    Color(0xFFB36B00),
    'error':        Color(0xFF7B2FBE),
  };

  /// Cor de fallback (dourado padrão da Guilda) pra ids desconhecidos.
  static const fallbackColor = Color(0xFFC2A05A);

  static String nameOf(String id) => _names[id] ?? id;

  static Color colorOf(String id) => _colors[id] ?? fallbackColor;

  /// `true` se [id] é uma facção real (membro de fato) — exclui `null`,
  /// vazio, `'none'` e `'pending:*'` (admissão em curso, sem buff/ficha).
  static bool isReal(String? id) =>
      id != null &&
      id.isNotEmpty &&
      id != 'none' &&
      !id.startsWith('pending:');
}
