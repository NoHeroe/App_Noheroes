import '../../core/events/app_event_bus.dart';
import '../../core/events/player_events.dart';
import '../../data/database/daos/player_dao.dart';
import '../entities/player.dart';

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
/// faltam — jogadores que não passaram pela Calibração do Sistema caem
/// nesse caminho até preencherem os dados em /perfil.
///
/// Validação de range é feita aqui antes de delegar pro PlayerDao:
/// - peso: 20–300 kg
/// - altura: 100–250 cm
class BodyMetricsService {
  final PlayerDao _dao;
  final AppEventBus _bus;

  /// `bus` injetado pra publicar [BodyMetricsUpdated] após save bem-sucedido.
  /// `isFirstTime` é detectado lendo player ANTES do save: ambos `weightKg` e
  /// `heightCm` null = primeira calibração.
  BodyMetricsService({required PlayerDao dao, required AppEventBus bus})
      : _dao = dao,
        _bus = bus;

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
  double? bmi(Player player) {
    final w = player.weightKg;
    final h = player.heightCm;
    if (w == null || h == null) return null;
    final heightM = h / 100.0;
    if (heightM <= 0) return null;
    final raw = w / (heightM * heightM);
    return (raw * 10).roundToDouble() / 10;
  }

  /// Categoria OMS. Retorna "Incompleto" quando IMC não pode ser calculado.
  String bmiCategory(Player player) {
    final value = bmi(player);
    if (value == null) return categoryIncomplete;
    if (value < 18.5) return categoryUnderweight;
    if (value < 25.0) return categoryNormal;
    if (value < 30.0) return categoryOverweight;
    return categoryObese;
  }

  /// Água recomendada em ml/dia. Null se peso falta.
  ///
  /// Mais realista com idade + sexo: ml/kg cai com a idade
  /// (<30: 40 / 30–55: 35 / >55: 30) e mulheres têm menor % de água
  /// corporal (fator 0.95). Sem idade/sexo cai no 35 ml/kg padrão.
  int? recommendedWaterMl(Player player) {
    final w = player.weightKg;
    if (w == null) return null;
    final age = player.age;
    final double perKg = age == null
        ? 35
        : age < 30
            ? 40
            : age <= 55
                ? 35
                : 30;
    final sexFactor = player.sex == 'female' ? 0.95 : 1.0;
    return (w * perKg * sexFactor).round();
  }

  /// Proteína recomendada em g/dia (perfil ativo). Null se peso falta.
  /// Idosos (>60) recebem 1.8 g/kg (prevenção de sarcopenia); demais 1.6.
  int? recommendedProteinG(Player player) {
    final w = player.weightKg;
    if (w == null) return null;
    final gPerKg = (player.age ?? 0) > 60 ? 1.8 : 1.6;
    return (w * gPerKg).round();
  }

  /// Persiste peso/altura. Lança ArgumentError se algum valor estiver
  /// fora do range — UI valida antes mas defesa em profundidade.
  ///
  /// Publica [BodyMetricsUpdated] pós-save. `isFirstTime=true` quando ambos
  /// os campos estavam null antes (primeira calibração — onboarding);
  /// `false` em edições.
  static const int minAge = 5;
  static const int maxAge = 120;
  static const String sexMale = 'male';
  static const String sexFemale = 'female';

  bool isValidAge(int years) => years >= minAge && years <= maxAge;
  bool isValidSex(String s) => s == sexMale || s == sexFemale;

  Future<void> save({
    required String playerId,
    int? weightKg,
    int? heightCm,
    String? sex,
    int? age,
  }) async {
    if (weightKg != null && !isValidWeight(weightKg)) {
      throw ArgumentError(
          'weightKg fora do range ($minWeightKg-$maxWeightKg): $weightKg');
    }
    if (heightCm != null && !isValidHeight(heightCm)) {
      throw ArgumentError(
          'heightCm fora do range ($minHeightCm-$maxHeightCm): $heightCm');
    }
    if (sex != null && !isValidSex(sex)) {
      throw ArgumentError("sex inválido (esperado '$sexMale'/'$sexFemale'): $sex");
    }
    if (age != null && !isValidAge(age)) {
      throw ArgumentError('age fora do range ($minAge-$maxAge): $age');
    }
    final before = await _dao.findById(playerId);
    final isFirstTime =
        before != null && before.weightKg == null && before.heightCm == null;

    await _dao.updateBodyMetrics(playerId,
        weightKg: weightKg, heightCm: heightCm, sex: sex, age: age);

    _bus.publish(BodyMetricsUpdated(
      playerId: playerId,
      isFirstTime: isFirstTime,
    ));
  }
}
