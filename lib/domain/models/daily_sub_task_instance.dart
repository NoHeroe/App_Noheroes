import '../enums/daily_unit_type.dart';

/// Sprint 3.2 Etapa 1.2 — instância concreta de uma sub-tarefa numa
/// missão diária. Snapshot dos campos canônicos (nome, escala, unidade)
/// pra ficar imune a mudanças no JSON dos pools depois do sorteio.
///
/// `subPilar` só é preenchido em sub-tarefas de missão Vitalismo (uma de
/// cada pilar). Pra missões mono-modalidade fica null.
class DailySubTaskInstance {
  final String subTaskKey;
  final String nomeVisivel;
  final int escalaAlvo;
  final String unidade;
  final DailyUnitType tipoUnidade;
  final int progressoAtual;
  final bool completed;
  final String? subPilar; // 'fisico' | 'mental' | 'espiritual' (Vitalismo)

  const DailySubTaskInstance({
    required this.subTaskKey,
    required this.nomeVisivel,
    required this.escalaAlvo,
    required this.unidade,
    required this.tipoUnidade,
    this.progressoAtual = 0,
    this.completed = false,
    this.subPilar,
  });

  DailySubTaskInstance copyWith({
    int? progressoAtual,
    bool? completed,
  }) =>
      DailySubTaskInstance(
        subTaskKey: subTaskKey,
        nomeVisivel: nomeVisivel,
        escalaAlvo: escalaAlvo,
        unidade: unidade,
        tipoUnidade: tipoUnidade,
        progressoAtual: progressoAtual ?? this.progressoAtual,
        completed: completed ?? this.completed,
        subPilar: subPilar,
      );

  factory DailySubTaskInstance.fromJson(Map<String, dynamic> json) =>
      DailySubTaskInstance(
        subTaskKey: json['sub_task_key'] as String,
        nomeVisivel: json['nome_visivel'] as String,
        escalaAlvo: (json['escala_alvo'] as num).toInt(),
        unidade: json['unidade'] as String,
        tipoUnidade:
            DailyUnitTypeCodec.fromStorage(json['tipo_unidade'] as String),
        progressoAtual: (json['progresso_atual'] as num?)?.toInt() ?? 0,
        completed: json['completed'] as bool? ?? false,
        subPilar: json['sub_pilar'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'sub_task_key': subTaskKey,
        'nome_visivel': nomeVisivel,
        'escala_alvo': escalaAlvo,
        'unidade': unidade,
        'tipo_unidade': tipoUnidade.storage,
        'progresso_atual': progressoAtual,
        'completed': completed,
        if (subPilar != null) 'sub_pilar': subPilar,
      };
}
