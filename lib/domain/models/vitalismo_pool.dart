/// Sprint 3.2 Etapa 1.1 — pool especial do Vitalismo.
///
/// Diferente de [DailyModalidadePool], NÃO tem `sub_tarefas` próprias:
/// quando o sistema gera 1 missão Vitalismo (Etapa 1.2), ele sorteia
/// 1 sub-tarefa de cada pilar (Físico + Mental + Espiritual) usando os
/// `pesos_subcategoria_por_pilar` deste pool — que diferem dos pesos
/// nativos de cada pilar (Vitalismo prioriza treino/foco/proposito).
class VitalismoPool {
  /// Sempre `'vitalismo'`.
  final String modalidade;

  /// Hex `#534AB7` — roxo canônico.
  final String corCanonica;

  /// Pesos por pilar pra sorteio dentro de cada um. 3 mapas (fisico,
  /// mental, espiritual), cada um com soma = 1.0.
  final Map<String, Map<String, double>> pesosSubcategoriaPorPilar;

  /// 12 títulos próprios (Vitalismo é raro, merece pool próprio).
  final List<String> titulos;

  /// 20 quotes próprias.
  final List<String> quotes;

  const VitalismoPool({
    required this.modalidade,
    required this.corCanonica,
    required this.pesosSubcategoriaPorPilar,
    required this.titulos,
    required this.quotes,
  });

  factory VitalismoPool.fromJson(Map<String, dynamic> json) {
    final raw = (json['pesos_subcategoria_por_pilar'] as Map)
        .cast<String, dynamic>();
    return VitalismoPool(
      modalidade: json['modalidade'] as String,
      corCanonica: json['cor_canonica'] as String,
      pesosSubcategoriaPorPilar: {
        for (final e in raw.entries)
          e.key: (e.value as Map).cast<String, dynamic>().map(
                (k, v) => MapEntry(k, (v as num).toDouble()),
              ),
      },
      titulos: (json['titulos'] as List).cast<String>(),
      quotes: (json['quotes'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'modalidade': modalidade,
        'cor_canonica': corCanonica,
        'pesos_subcategoria_por_pilar': pesosSubcategoriaPorPilar,
        'titulos': titulos,
        'quotes': quotes,
      };
}
