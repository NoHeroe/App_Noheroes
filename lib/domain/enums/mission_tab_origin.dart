/// Sprint 3.1 Bloco 3 — aba de origem da missão (coluna
/// `player_mission_progress.tab_origin`).
///
/// **UI vs storage**: a aba **visível ao jogador** em `/quests` é Extras
/// (DESIGN_DOC §8) — *Individuais* é apenas uma sub-seção visual dentro
/// dela. Mas no banco `individual` é um `tab_origin` **próprio** pra
/// facilitar queries diretas ("dê todas as individuais ativas") sem
/// cruzar `tab_origin = 'extras' AND modality = 'individual'`.
///
/// Racional da decisão: lookup por índice secundário
/// `idx_mpprog_tab(player_id, tab_origin)` (ver Bloco 1) fica 1-hop pra
/// *todas* as abas, inclusive a sub-seção de Individuais. Bloco 10 (UI)
/// renderiza `individual` dentro do chip visual "Extras".
///
/// | Enum        | Storage       | Display (PT-BR)  |
/// |-------------|---------------|------------------|
/// | `daily`     | `'daily'`     | Diárias          |
/// | `classTab`  | `'class'`     | Classe           |
/// | `faction`   | `'faction'`   | Facção           |
/// | `extras`    | `'extras'`    | Extras           |
/// | `admission` | `'admission'` | Admissão         |
/// | `individual`| `'individual'`| Individuais      |
///
/// `classTab` evita colisão com a palavra reservada `class` do Dart.
enum MissionTabOrigin { daily, classTab, faction, extras, admission, individual }

extension MissionTabOriginCodec on MissionTabOrigin {
  /// String canônica pra persistência (DB + JSON).
  String get storage => switch (this) {
        MissionTabOrigin.daily => 'daily',
        MissionTabOrigin.classTab => 'class',
        MissionTabOrigin.faction => 'faction',
        MissionTabOrigin.extras => 'extras',
        MissionTabOrigin.admission => 'admission',
        MissionTabOrigin.individual => 'individual',
      };

  /// Label PT-BR pra UI.
  String get display => switch (this) {
        MissionTabOrigin.daily => 'Diárias',
        MissionTabOrigin.classTab => 'Classe',
        MissionTabOrigin.faction => 'Facção',
        MissionTabOrigin.extras => 'Extras',
        MissionTabOrigin.admission => 'Admissão',
        MissionTabOrigin.individual => 'Individuais',
      };

  /// Tolerante — retorna `null` se [value] não for um valor canônico.
  static MissionTabOrigin? fromString(String value) {
    for (final t in MissionTabOrigin.values) {
      if (t.storage == value) return t;
    }
    return null;
  }

  /// Estrito — lança [FormatException] se inválido. Usar em `fromJson`.
  static MissionTabOrigin fromStorage(String value) {
    final t = fromString(value);
    if (t == null) {
      throw FormatException("Invalid MissionTabOrigin '$value'");
    }
    return t;
  }
}
