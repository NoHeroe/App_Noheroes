import '../../data/database/app_database.dart';
import '../../data/database/daos/player_dao.dart';

/// Sprint 3.2 Etapa 1.0 — IMC + recomendações diárias (água/proteína).
///
/// Fórmulas:
/// - IMC: peso_kg / (altura_m²)
/// - Categorias OMS: <18.5 abaixo / 18.5–24.9 normal / 25–29.9 sobrepeso /
///   >=30 obesidade
/// - Água: 35ml × peso_kg
/// - Proteína: 1.6g × peso_kg (perfil ativo, padrão pra usuários do app)
///
/// Todos os métodos retornam null/`"Incompleto"` quando peso ou altura
/// faltam — jogadores pré-3.2 que não passaram pela Calibração do Sistema
/// caem nesse caminho até preencherem os dados em /perfil.
///
/// Validação de range é feita aqui antes de delegar pro PlayerDao:
/// - peso: 20–300 kg
/// - altura: 100–250 cm
class BodyMetricsService {
  final PlayerDao _dao;

  BodyMetricsService({required PlayerDao dao}) : _dao = dao;

  static const int minWeightKg = 20;
  static const int maxWeightKg = 300;
  static const int minHeightCm = 100;
  static const int maxHeightCm = 250;

  static const String categoryUnderweight = 'Abaixo';
  static const String categoryNormal = 'Normal';
  static const String categoryOverweight = 'Sobrepeso';
  static const String categoryObese = 'Obesidade';
  static const String categoryIncomplete = 'Incompleto';

  bool isValidWeight(int kg) => kg >= minWeightKg && kg <= maxWeightKg;
  bool isValidHeight(int cm) => cm >= minHeightCm && cm <= maxHeightCm;

  /// IMC arredondado pra 1 casa decimal. Null se peso ou altura faltam.
  double? bmi(PlayersTableData player) {
    final w = player.weightKg;
    final h = player.heightCm;
    if (w == null || h == null) return null;
    final heightM = h / 100.0;
    if (heightM <= 0) return null;
    final raw = w / (heightM * heightM);
    return (raw * 10).roundToDouble() / 10;
  }

  /// Categoria OMS. Retorna "Incompleto" quando IMC não pode ser calculado.
  String bmiCategory(PlayersTableData player) {
    final value = bmi(player);
    if (value == null) return categoryIncomplete;
    if (value < 18.5) return categoryUnderweight;
    if (value < 25.0) return categoryNormal;
    if (value < 30.0) return categoryOverweight;
    return categoryObese;
  }

  /// Água recomendada em ml/dia. Null se peso falta.
  int? recommendedWaterMl(PlayersTableData player) {
    final w = player.weightKg;
    if (w == null) return null;
    return w * 35;
  }

  /// Proteína recomendada em g/dia (perfil ativo). Null se peso falta.
  int? recommendedProteinG(PlayersTableData player) {
    final w = player.weightKg;
    if (w == null) return null;
    return (w * 1.6).round();
  }

  /// Persiste peso/altura. Lança ArgumentError se algum valor estiver
  /// fora do range — UI valida antes mas defesa em profundidade.
  Future<void> save({
    required int playerId,
    int? weightKg,
    int? heightCm,
  }) async {
    if (weightKg != null && !isValidWeight(weightKg)) {
      throw ArgumentError(
          'weightKg fora do range ($minWeightKg-$maxWeightKg): $weightKg');
    }
    if (heightCm != null && !isValidHeight(heightCm)) {
      throw ArgumentError(
          'heightCm fora do range ($minHeightCm-$maxHeightCm): $heightCm');
    }
    await _dao.updateBodyMetrics(playerId,
        weightKg: weightKg, heightCm: heightCm);
  }
}
