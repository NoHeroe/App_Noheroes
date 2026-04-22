import '../enums/mission_modality.dart';
import '../enums/mission_tab_origin.dart';
import 'reward_declared.dart';

/// Sprint 3.1 Bloco 3 — payload imutável passado entre
/// `MissionProgressService` e as 4 strategies (Bloco 6).
///
/// Derivado de [MissionProgress] no momento em que um evento ou ação de
/// usuário vai ser processado; as strategies leem este contexto sem tocar
/// diretamente na row Drift. Mantém código isolado de mudanças na
/// persistência (ADR 0016 — Repository Pattern).
///
/// Contém os campos **necessários pra decidir**:
///   - qual strategy cuida do evento (via [modality])
///   - se o evento é relevante pra essa aba específica ([tabOrigin])
///   - qual é a meta pra comparar com o incremento ([targetValue])
///   - o que entrega ao completar ([rewardDeclared])
///
/// [metaJson] carrega estado específico por família (ex: array de progresso
/// por requirement na família mixed). Mantido como string pra evitar
/// acoplamento com estruturas internas de cada strategy.
class MissionContext {
  final int missionProgressId;
  final int playerId;
  final String missionKey;
  final MissionModality modality;
  final MissionTabOrigin tabOrigin;
  final int currentValue;
  final int targetValue;
  final RewardDeclared rewardDeclared;
  final String metaJson;

  const MissionContext({
    required this.missionProgressId,
    required this.playerId,
    required this.missionKey,
    required this.modality,
    required this.tabOrigin,
    required this.currentValue,
    required this.targetValue,
    required this.rewardDeclared,
    required this.metaJson,
  });

  factory MissionContext.fromJson(Map<String, dynamic> json) {
    final mpid = json['mission_progress_id'];
    if (mpid is! int) {
      throw FormatException(
          "MissionContext.mission_progress_id inválido ($mpid)");
    }
    final playerId = json['player_id'];
    if (playerId is! int) {
      throw FormatException(
          "MissionContext.player_id inválido ($playerId) em mpid=$mpid");
    }
    final missionKey = json['mission_key'];
    if (missionKey is! String || missionKey.isEmpty) {
      throw FormatException(
          "MissionContext.mission_key ausente em mpid=$mpid");
    }
    final modalityStr = json['modality'];
    if (modalityStr is! String) {
      throw FormatException(
          "MissionContext.modality ausente em mpid=$mpid");
    }
    final tabStr = json['tab_origin'];
    if (tabStr is! String) {
      throw FormatException(
          "MissionContext.tab_origin ausente em mpid=$mpid");
    }
    final currentValue = json['current_value'];
    if (currentValue is! int) {
      throw FormatException(
          "MissionContext.current_value inválido ($currentValue) em mpid=$mpid");
    }
    final targetValue = json['target_value'];
    if (targetValue is! int) {
      throw FormatException(
          "MissionContext.target_value inválido ($targetValue) em mpid=$mpid");
    }
    final rewardDeclared = json['reward_declared'];
    if (rewardDeclared is! Map<String, dynamic>) {
      throw FormatException(
          "MissionContext.reward_declared ausente em mpid=$mpid");
    }
    return MissionContext(
      missionProgressId: mpid,
      playerId: playerId,
      missionKey: missionKey,
      modality: MissionModalityCodec.fromStorage(modalityStr),
      tabOrigin: MissionTabOriginCodec.fromStorage(tabStr),
      currentValue: currentValue,
      targetValue: targetValue,
      rewardDeclared: RewardDeclared.fromJson(rewardDeclared),
      metaJson: (json['meta_json'] as String?) ?? '{}',
    );
  }

  Map<String, dynamic> toJson() => {
        'mission_progress_id': missionProgressId,
        'player_id': playerId,
        'mission_key': missionKey,
        'modality': modality.storage,
        'tab_origin': tabOrigin.storage,
        'current_value': currentValue,
        'target_value': targetValue,
        'reward_declared': rewardDeclared.toJson(),
        'meta_json': metaJson,
      };
}
