import 'dart:convert';

import '../enums/intensity.dart';
import '../enums/mission_category.dart';
import '../enums/mission_style.dart';

/// Sprint 3.1 Bloco 3 — domain model das preferências do jogador coletadas
/// no quiz de calibração (DESIGN_DOC §7, ADR 0015).
///
/// Espelha a row `player_mission_preferences` com tipos fortes. Os
/// subfocus são `List<String>` (valores livres do P4/P5/P6) — o codec
/// interno serializa/desserializa como JSON array.
///
/// O quiz condicional aplica P4 quando primaryFocus ∈ {fisico, vitalismo},
/// P5 quando ∈ {mental, vitalismo}, P6 quando ∈ {espiritual, vitalismo};
/// fora dessas combinações, os subfocus vêm vazios.
class MissionPreferences {
  final int playerId;
  final MissionCategory primaryFocus;
  final Intensity intensity;
  final MissionStyle missionStyle;
  final List<String> physicalSubfocus;
  final List<String> mentalSubfocus;
  final List<String> spiritualSubfocus;
  final int timeDailyMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int updatesCount;

  const MissionPreferences({
    required this.playerId,
    required this.primaryFocus,
    required this.intensity,
    required this.missionStyle,
    required this.createdAt,
    required this.updatedAt,
    this.physicalSubfocus = const [],
    this.mentalSubfocus = const [],
    this.spiritualSubfocus = const [],
    this.timeDailyMinutes = 30,
    this.updatesCount = 0,
  });

  MissionPreferences copyWith({
    MissionCategory? primaryFocus,
    Intensity? intensity,
    MissionStyle? missionStyle,
    List<String>? physicalSubfocus,
    List<String>? mentalSubfocus,
    List<String>? spiritualSubfocus,
    int? timeDailyMinutes,
    DateTime? updatedAt,
    int? updatesCount,
  }) {
    return MissionPreferences(
      playerId: playerId,
      primaryFocus: primaryFocus ?? this.primaryFocus,
      intensity: intensity ?? this.intensity,
      missionStyle: missionStyle ?? this.missionStyle,
      physicalSubfocus: physicalSubfocus ?? this.physicalSubfocus,
      mentalSubfocus: mentalSubfocus ?? this.mentalSubfocus,
      spiritualSubfocus: spiritualSubfocus ?? this.spiritualSubfocus,
      timeDailyMinutes: timeDailyMinutes ?? this.timeDailyMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatesCount: updatesCount ?? this.updatesCount,
    );
  }

  /// Sprint 3.1 Bloco 9 — troca `primaryFocus` com **wipe condicional**
  /// dos subfocus que não são aplicáveis ao novo foco:
  ///
  /// - Físico → zera mental + spiritual (P5/P6 não aparecem no quiz)
  /// - Mental → zera physical + spiritual
  /// - Espiritual → zera physical + mental
  /// - Vitalismo → **preserva todos** (P4/P5/P6 renderizam)
  ///
  /// Motivo: `MissionCalibrationScreen` só renderiza subfocus aplicáveis.
  /// Se o jogador chega no P4/P5/P6 como Vitalismo, preenche os 3, volta
  /// e muda pra Físico, sem esse wipe `save()` persistiria valores que
  /// ele não viu mais — data corruption silenciosa do ponto de vista
  /// dele. Usado como `draft = draft.withPrimaryFocus(newFocus)` no
  /// callback da P1.
  MissionPreferences withPrimaryFocus(MissionCategory newFocus) {
    switch (newFocus) {
      case MissionCategory.fisico:
        return copyWith(
          primaryFocus: newFocus,
          mentalSubfocus: const [],
          spiritualSubfocus: const [],
        );
      case MissionCategory.mental:
        return copyWith(
          primaryFocus: newFocus,
          physicalSubfocus: const [],
          spiritualSubfocus: const [],
        );
      case MissionCategory.espiritual:
        return copyWith(
          primaryFocus: newFocus,
          physicalSubfocus: const [],
          mentalSubfocus: const [],
        );
      case MissionCategory.vitalismo:
        return copyWith(primaryFocus: newFocus);
    }
  }

  static List<String> _parseSubfocusList(dynamic raw, String field) {
    if (raw == null || raw == '') return const [];
    if (raw is List) {
      return raw.map((e) => e as String).toList(growable: false);
    }
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw FormatException(
            "MissionPreferences.$field JSON não é array ($raw)");
      }
      return decoded.map((e) => e as String).toList(growable: false);
    }
    throw FormatException(
        "MissionPreferences.$field formato inválido ($raw)");
  }

  factory MissionPreferences.fromJson(Map<String, dynamic> json) {
    final playerId = json['player_id'];
    if (playerId is! int) {
      throw FormatException(
          "MissionPreferences.player_id inválido ($playerId)");
    }
    final primary = json['primary_focus'];
    if (primary is! String) {
      throw FormatException(
          "MissionPreferences.primary_focus ausente em player=$playerId");
    }
    final intensity = json['intensity'];
    if (intensity is! String) {
      throw FormatException(
          "MissionPreferences.intensity ausente em player=$playerId");
    }
    final style = json['mission_style'];
    if (style is! String) {
      throw FormatException(
          "MissionPreferences.mission_style ausente em player=$playerId");
    }
    final createdAt = json['created_at'];
    if (createdAt is! int) {
      throw FormatException(
          "MissionPreferences.created_at inválido ($createdAt) em player=$playerId");
    }
    final updatedAt = json['updated_at'];
    if (updatedAt is! int) {
      throw FormatException(
          "MissionPreferences.updated_at inválido ($updatedAt) em player=$playerId");
    }
    return MissionPreferences(
      playerId: playerId,
      primaryFocus: MissionCategoryCodec.fromStorage(primary),
      intensity: IntensityCodec.fromStorage(intensity),
      missionStyle: MissionStyleCodec.fromStorage(style),
      physicalSubfocus:
          _parseSubfocusList(json['physical_subfocus'], 'physical_subfocus'),
      mentalSubfocus:
          _parseSubfocusList(json['mental_subfocus'], 'mental_subfocus'),
      spiritualSubfocus: _parseSubfocusList(
          json['spiritual_subfocus'], 'spiritual_subfocus'),
      timeDailyMinutes: (json['time_daily_minutes'] as int?) ?? 30,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      updatesCount: (json['updates_count'] as int?) ?? 0,
    );
  }

  /// `toJson` com subfocus já em `List<String>` — use quando serializar
  /// pra outro serviço (ex: Supabase).
  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'primary_focus': primaryFocus.storage,
        'intensity': intensity.storage,
        'mission_style': missionStyle.storage,
        'physical_subfocus': physicalSubfocus,
        'mental_subfocus': mentalSubfocus,
        'spiritual_subfocus': spiritualSubfocus,
        'time_daily_minutes': timeDailyMinutes,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'updates_count': updatesCount,
      };

  /// `toRow` com subfocus serializados como string JSON — espelha o
  /// formato esperado pela coluna Drift (TEXT com default '[]'). Usado
  /// pelo Repository no Bloco 4.
  Map<String, dynamic> toRow() => {
        ...toJson(),
        'physical_subfocus': jsonEncode(physicalSubfocus),
        'mental_subfocus': jsonEncode(mentalSubfocus),
        'spiritual_subfocus': jsonEncode(spiritualSubfocus),
      };
}
