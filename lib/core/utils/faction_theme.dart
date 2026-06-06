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

  /// Sentinel da Etapa F — `faction_type='lone_wolf'` (Caminho do Lobo
  /// Solitário). NÃO é facção real: dá bônus via catálogo (faction_buffs.json)
  /// mas `hasRealFaction`/`isReal` retornam false (tema anti-facção).
  static const loneWolf = 'lone_wolf';

  static const _names = <String, String>{
    'guild':        'Guilda de Aventureiros',
    'moon_clan':    'Clã da Lua',
    'sun_clan':     'Clã do Sol',
    'black_legion': 'Legião Negra',
    'new_order':    'Nova Ordem',
    'trinity':      'Culto da Trindade',
    'renegades':    'Os Renegados',
    'error':        'Facção ERROR',
    // Etapa F — tema de display (NÃO é facção real; ver hasRealFaction).
    'lone_wolf':    'Lobo Solitário',
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
    // Etapa F — cinza/void (Umbra), soulslike anti-facção.
    'lone_wolf':    Color(0xFF6E6E78),
  };

  /// Cor de fallback (dourado padrão da Guilda) pra ids desconhecidos.
  static const fallbackColor = Color(0xFFC2A05A);

  static String nameOf(String id) => _names[id] ?? id;

  static Color colorOf(String id) => _colors[id] ?? fallbackColor;

  /// `true` se [factionType] é a marca do Lobo Solitário (sentinel).
  static bool isLoneWolf(String? factionType) => factionType == loneWolf;

  /// Sprint 3.4 Etapa F — helper CENTRAL pro sweep. `true` SÓ pras facções
  /// reais de combate/ideológicas (as 7 + Guilda nível 2). Retorna `false`
  /// pra `null`/`''`/`'none'`/`'lone_wolf'`/`'pending:*'`.
  ///
  /// ⚠️ Lobo Solitário é EXCLUÍDO de propósito: tem tema de display
  /// (nameOf/colorOf) mas NÃO é facção real — não recebe missões/reputação
  /// de facção, não é "membro" (não chamar LeaveFactionService), etc.
  static bool hasRealFaction(String? factionType) =>
      factionType != null &&
      factionType.isNotEmpty &&
      factionType != 'none' &&
      factionType != loneWolf &&
      !factionType.startsWith('pending:');

  /// Alias retrocompatível — delega pra [hasRealFaction] (mesma semântica,
  /// já excluindo lone_wolf). Mantido pros call-sites existentes (Etapa E).
  static bool isReal(String? id) => hasRealFaction(id);
}
