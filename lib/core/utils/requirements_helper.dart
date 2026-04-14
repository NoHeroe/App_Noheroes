import 'dart:convert';

class RequirementItem {
  final String label;
  final int target;
  final String unit; // reps, km, min, pages, words, glasses, hours, cycles
  int done;

  RequirementItem({
    required this.label,
    required this.target,
    this.unit = 'reps',
    this.done = 0,
  });

  factory RequirementItem.fromJson(Map<String, dynamic> j) => RequirementItem(
        label:  j['label'] as String,
        target: j['target'] as int,
        unit:   j['unit'] as String? ?? 'reps',
        done:   j['done'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'label':  label,
        'target': target,
        'unit':   unit,
        'done':   done,
      };

  double get progress => target == 0 ? 0 : (done / target).clamp(0.0, 1.0);
  bool get isComplete => done >= target;

  String get unitLabel => switch (unit) {
    'reps'   => 'x',
    'km'     => 'km',
    'min'    => 'min',
    'pages'  => 'pág',
    'words'  => 'pal',
    'glasses'=> 'copos',
    'hours'  => 'h',
    'cycles' => 'ciclos',
    _        => unit,
  };
}

class RequirementsHelper {
  static List<RequirementItem> parse(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => RequirementItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String serialize(List<RequirementItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static double calcCompletion(List<RequirementItem> items) {
    if (items.isEmpty) return 1.0;
    final total = items.fold(0, (s, r) => s + r.target);
    final done  = items.fold(0, (s, r) => s + r.done.clamp(0, r.target));
    return total == 0 ? 1.0 : done / total;
  }

  static String calcStatus(List<RequirementItem> items) {
    if (items.isEmpty) return 'completed';
    final c = calcCompletion(items);
    if (c >= 1.0) return 'completed';
    if (c > 0)    return 'partial';
    return 'niet';
  }
}
