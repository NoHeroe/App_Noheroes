import 'dart:convert';

class RequirementItem {
  final String label;
  final int target;
  int done;

  RequirementItem({
    required this.label,
    required this.target,
    this.done = 0,
  });

  factory RequirementItem.fromJson(Map<String, dynamic> j) =>
      RequirementItem(
        label:  j['label'] as String,
        target: j['target'] as int,
        done:   j['done'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'label':  label,
    'target': target,
    'done':   done,
  };

  double get progress => target == 0 ? 0 : (done / target).clamp(0.0, 1.0);
  bool get isComplete => done >= target;
}

class RequirementsHelper {
  static List<RequirementItem> parse(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => RequirementItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String serialize(List<RequirementItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  // Calcula % de conclusão baseado nos requisitos
  static double calcCompletion(List<RequirementItem> items) {
    if (items.isEmpty) return 1.0;
    final total = items.fold(0, (sum, r) => sum + r.target);
    final done  = items.fold(0, (sum, r) => sum + r.done.clamp(0, r.target));
    return total == 0 ? 1.0 : done / total;
  }

  // Define status baseado na % de conclusão
  static String calcStatus(List<RequirementItem> items) {
    if (items.isEmpty) return 'completed';
    final completion = calcCompletion(items);
    if (completion >= 1.0) return 'completed';
    if (completion >= 0.5) return 'partial';
    if (completion > 0)    return 'partial';
    return 'niet';
  }
}
