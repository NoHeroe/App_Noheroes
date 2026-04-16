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
}

class TutorialService {
  static Future<bool> isDone(TutorialPhase phase) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_${phase.name}') ?? false;
  }

  static Future<void> markDone(TutorialPhase phase) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_${phase.name}', true);
  }

  static Future<bool> shouldShow(TutorialPhase phase) async {
    return !(await isDone(phase));
  }
}
