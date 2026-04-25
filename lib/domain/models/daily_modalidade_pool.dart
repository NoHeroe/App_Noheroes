import 'daily_sub_task_spec.dart';

/// Sprint 3.2 Etapa 1.1 — pool de uma modalidade (Físico/Mental/Espiritual).
///
/// Vitalismo NÃO usa este model — tem [VitalismoPool] separado por não
/// ter `sub_tarefas` próprias.
class DailyModalidadePool {
  /// Storage: 'fisico' | 'mental' | 'espiritual'.
  final String modalidade;

  /// Hex `#RRGGBB`. Usado no card e barra de progresso da Etapa 1.3.
  final String corCanonica;

  /// Pesos das 4 sub-categorias do pilar. Soma = 1.0.
  /// Ex Físico: treino 0.35 / recuperacao 0.25 / nutricao 0.25 / descanso 0.15
  final Map<String, double> pesosSubcategoria;

  /// 60 sub-tarefas (15 por sub-categoria).
  final List<DailySubTaskSpec> subTarefas;

  /// 32 títulos (8 por sub-categoria). Chave = sub-categoria.
  final Map<String, List<String>> titulosPorSubcategoria;

  /// 20 quotes do pilar.
  final List<String> quotes;

  const DailyModalidadePool({
    required this.modalidade,
    required this.corCanonica,
    required this.pesosSubcategoria,
    required this.subTarefas,
    required this.titulosPorSubcategoria,
    required this.quotes,
  });

  factory DailyModalidadePool.fromJson(Map<String, dynamic> json) {
    final pesos = (json['pesos_subcategoria'] as Map).cast<String, dynamic>();
    final titulos =
        (json['titulos_por_subcategoria'] as Map).cast<String, dynamic>();
    return DailyModalidadePool(
      modalidade: json['modalidade'] as String,
      corCanonica: json['cor_canonica'] as String,
      pesosSubcategoria: {
        for (final e in pesos.entries) e.key: (e.value as num).toDouble(),
      },
      subTarefas: (json['sub_tarefas'] as List)
          .cast<Map<String, dynamic>>()
          .map(DailySubTaskSpec.fromJson)
          .toList(growable: false),
      titulosPorSubcategoria: {
        for (final e in titulos.entries)
          e.key: (e.value as List).cast<String>(),
      },
      quotes: (json['quotes'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'modalidade': modalidade,
        'cor_canonica': corCanonica,
        'pesos_subcategoria': pesosSubcategoria,
        'sub_tarefas': subTarefas.map((s) => s.toJson()).toList(),
        'titulos_por_subcategoria': titulosPorSubcategoria,
        'quotes': quotes,
      };
}
