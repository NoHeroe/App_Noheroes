import '../enums/daily_unit_type.dart';

/// Sprint 3.2 Etapa 1.1 — uma sub-tarefa do pool de missões diárias.
///
/// Imutável. Carregada via `DailyPoolService.loadAll()` a partir de
/// `assets/data/daily_pool_*.json`. Escala dinâmica (água/proteína)
/// é resolvida em runtime via `BodyMetricsService` quando
/// `requerImc == true` — o mapa `escalaPorRank` fica zerado nesses casos.
class DailySubTaskSpec {
  final String key;
  final String nomeVisivel;
  final String subCategoria;
  final String unidade;
  final DailyUnitType tipoUnidade;
  final Map<String, int> escalaPorRank; // E,D,C,B,A,S
  final bool requerImc;

  const DailySubTaskSpec({
    required this.key,
    required this.nomeVisivel,
    required this.subCategoria,
    required this.unidade,
    required this.tipoUnidade,
    required this.escalaPorRank,
    required this.requerImc,
  });

  factory DailySubTaskSpec.fromJson(Map<String, dynamic> json) {
    final raw = (json['escala_por_rank'] as Map).cast<String, dynamic>();
    return DailySubTaskSpec(
      key: json['key'] as String,
      nomeVisivel: json['nome_visivel'] as String,
      subCategoria: json['sub_categoria'] as String,
      unidade: json['unidade'] as String,
      tipoUnidade:
          DailyUnitTypeCodec.fromStorage(json['tipo_unidade'] as String),
      escalaPorRank: {
        for (final e in raw.entries) e.key: (e.value as num).toInt(),
      },
      requerImc: json['requer_imc'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'nome_visivel': nomeVisivel,
        'sub_categoria': subCategoria,
        'unidade': unidade,
        'tipo_unidade': tipoUnidade.storage,
        'escala_por_rank': escalaPorRank,
        'requer_imc': requerImc,
      };
}
