import 'package:supabase_flutter/supabase_flutter.dart';

// Ponto único de cura de HP. A regra de regen proporcional de vitalismo
// (ADR 0002) — read-modify-write multi-campo sobre o jogador — é atômica e
// portanto vive inteira na RPC `apply_hp_heal` (porte fiel de
// computeHealResult + VitalismCalculator.calculateMaxVitalism). O cliente só
// dispara a RPC.
//
// `computeHealResult`/`HealResult` ficam mantidos como utilitários PUROS
// (testáveis client-side, sem IO), espelhando a lógica que a RPC replica.
class PlayerHealService {
  final SupabaseClient _client;
  PlayerHealService(this._client);

  Future<void> applyHpHealWithVitalismRegen({
    required String playerId,
    required int hpGained,
  }) async {
    if (hpGained <= 0) return;
    await _client.rpc('apply_hp_heal', params: {
      'p_player': playerId,
      'p_hp_gained': hpGained,
    });
  }
}

class HealResult {
  final int newHp;
  final int newCurrentVitalism;
  const HealResult({required this.newHp, required this.newCurrentVitalism});
}

HealResult computeHealResult({
  required int currentHp,
  required int currentVitalism,
  required int hpGained,
  required int hpMax,
  required int vitalismMax,
}) {
  final newHp = (currentHp + hpGained).clamp(0, hpMax);
  final hpGainedReal = newHp - currentHp;

  if (vitalismMax <= 0 || hpMax <= 0 || hpGainedReal <= 0) {
    return HealResult(newHp: newHp, newCurrentVitalism: currentVitalism);
  }

  final percGanho = hpGainedReal / hpMax;
  final vitalismoGanho = (vitalismMax * percGanho).round();
  final newCurrentVitalism =
      (currentVitalism + vitalismoGanho).clamp(0, vitalismMax);

  return HealResult(
    newHp: newHp,
    newCurrentVitalism: newCurrentVitalism,
  );
}
