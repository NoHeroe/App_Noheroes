import 'package:shared_preferences/shared_preferences.dart';

enum TutorialPhase {
  phase0_onboarding,  // onboarding completo
  phase1_sanctuary,   // nível 1: santuário + primeiro hábito + streak
  phase2_library,     // nível 2: biblioteca + diário + atributos
  phase3_shop,        // nível 3: loja + itens + personagem
  phase4_regions,     // nível 4: regiões
  phase5_class,       // nível 5: classe + missões de classe
  phase6_guild,       // nível 6: guilda
  phase7_faction,     // nível 7: facções
  phase8_shadow,      // nível 10: shadow boss
  phase9_playstyle,   // nível 15: estilo de jogo
  phase10_vitalism,   // nível 25: vitalismo
  phase11_skull,      // nível 99: nível caveira
  phase12_enchanter,  // nível 20: encantamento + grant de RUNE_FIRE_E
  phase13_mission_calibration, // nível 5 + classe: quiz de calibração
  phase14_cardgame,   // nível 2: 1ª partida do Modo Cartas (tutorial guiado)
}

/// Flags de progresso do tutorial. **Por jogador** (a chave inclui o `playerId`)
/// — contas diferentes no mesmo aparelho não se suprimem, e o reset de conta
/// limpa só os flags daquele jogador (ver [resetAll]). Persistido em
/// SharedPreferences (local), não no servidor.
class TutorialService {
  static String _key(String playerId, TutorialPhase phase) =>
      'tutorial_${playerId}_${phase.name}';

  static Future<bool> isDone(String playerId, TutorialPhase phase) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(playerId, phase)) ?? false;
  }

  static Future<void> markDone(String playerId, TutorialPhase phase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(playerId, phase), true);
  }

  static Future<bool> shouldShow(String playerId, TutorialPhase phase) async {
    return !(await isDone(playerId, phase));
  }

  /// Remove o flag de UMA fase (faz ela voltar a disparar). Ex.: reset de
  /// classe/facção no dev re-injeta as telas L5/L7.
  static Future<void> clear(String playerId, TutorialPhase phase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(playerId, phase));
  }

  /// Limpa TODOS os flags de tutorial deste jogador (reset de conta → o fluxo
  /// de onboarding/level-up volta a disparar do zero).
  static Future<void> resetAll(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'tutorial_${playerId}_';
    final keys =
        prefs.getKeys().where((k) => k.startsWith(prefix)).toList(growable: false);
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
