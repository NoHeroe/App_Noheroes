// Importador dos docx de balanceamento ACDA → JSON do catálogo.
//
// Lê os .txt extraídos dos docx (Criaturas/Relíquias) e regenera
// `assets/data/card_game/creatures.json` e `relics.json` no shape exato dos
// modelos (CreatureCard/RelicCard). Padroniza habilidades pro enum interno e
// reporta tudo que dropou / derivou, pra auditoria do CEO.
//
// Uso:
//   dart run tool/import_acda_docx.dart C:/Dev/_cri.txt C:/Dev/_rel.txt
//
// Regras de design (decididas com o CEO 2026-06-12):
//   • 2 tipos de dano numa criatura = 2 ataques (extra_attacks, mesmo ATK).
//   • Magnitudes (espinhos_2, escudo_4, vampirismo_2) são honradas → token `_N`.
//   • vampirismo = roubo_de_pv (lifesteal). executor = nova keyword.
//   • Relíquia de facção sem ajuste manual herda o TIPO de dano da facção
//     (chrysalis→a_distancia, celestial/magico→magico, vitalismo→vitalismo,
//      corrompido→corpo_a_corpo) quando concede atk_bonus. Tudo logado.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final criPath = args.isNotEmpty ? args[0] : 'C:/Dev/_cri.txt';
  final relPath = args.length > 1 ? args[1] : 'C:/Dev/_rel.txt';

  final dropped = <String>{};
  final creatures = _parseCreatures(File(criPath).readAsStringSync(), dropped);
  final factionDerived = <String>[];
  final relics =
      _parseRelics(File(relPath).readAsStringSync(), dropped, factionDerived);

  const enc = JsonEncoder.withIndent('  ');
  File('assets/data/card_game/creatures.json')
      .writeAsStringSync('${enc.convert(creatures)}\n');
  File('assets/data/card_game/relics.json')
      .writeAsStringSync('${enc.convert(relics)}\n');

  stdout.writeln('Criaturas: ${creatures.length}');
  stdout.writeln('Relíquias: ${relics.length}');
  stdout.writeln('\n--- Tipos de dano derivados por facção (relíquias) ---');
  for (final f in factionDerived) {
    stdout.writeln('  $f');
  }
  stdout.writeln('\n--- Tokens de habilidade NÃO mapeados (dropados) ---');
  final sortedDropped = dropped.toList()..sort();
  for (final d in sortedDropped) {
    stdout.writeln('  "$d"');
  }
}

// ───────────────────────── parsing genérico ─────────────────────────

/// Quebra o arquivo em blocos ancorados em "ID (não editar):". Cada bloco
/// devolve {name, fields{label→value}}.
List<Map<String, dynamic>> _blocks(String raw) {
  final lines = raw.replaceAll('\r', '').split('\n');
  final idIdx = <int>[];
  for (var i = 0; i < lines.length; i++) {
    if (_foldLabel(lines[i]).startsWith('id')) idIdx.add(i);
  }
  final out = <Map<String, dynamic>>[];
  for (var b = 0; b < idIdx.length; b++) {
    final start = idIdx[b];
    final end = b + 1 < idIdx.length ? idIdx[b + 1] - 1 : lines.length;
    // nome = última linha não-vazia ANTES do "ID".
    var name = '';
    for (var i = start - 1; i >= 0; i--) {
      if (lines[i].trim().isNotEmpty) {
        name = lines[i].trim();
        break;
      }
    }
    final fields = <String, String>{};
    String id = '';
    for (var i = start; i < end; i++) {
      final line = lines[i];
      final c = line.indexOf(':');
      if (c < 0) continue;
      final label = _foldLabel(line.substring(0, c));
      final value = line.substring(c + 1).trim();
      if (label.startsWith('id')) {
        id = value;
      } else {
        fields[label] = value;
      }
    }
    if (id.isEmpty) continue;
    out.add({'name': name, 'id': id, 'fields': fields});
  }
  return out;
}

String _foldLabel(String s) {
  final f = _stripAccents(s.toLowerCase());
  final sb = StringBuffer();
  for (final c in f.codeUnits) {
    if (c >= 0x61 && c <= 0x7a) sb.writeCharCode(c); // só a-z p/ comparar label
  }
  return sb.toString();
}

String _stripAccents(String s) {
  const map = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    sb.write(map[ch] ?? ch);
  }
  return sb.toString();
}

int? _intOrNull(String? raw) {
  if (raw == null) return null;
  final m = RegExp(r'-?\d+').firstMatch(raw);
  return m == null ? null : int.parse(m.group(0)!);
}

// ───────────────────────── normalizadores ─────────────────────────

String _concept(String raw) {
  final f = _foldLabel(raw);
  if (f.startsWith('vitalist') || f == 'vitalismo') return 'vitalismo';
  if (f.startsWith('neutr')) return 'neutro';
  if (f.startsWith('chrysal')) return 'chrysalis';
  if (f.startsWith('celest')) return 'celestial';
  if (f.startsWith('magic')) return 'magico';
  if (f.startsWith('corrup') || f.startsWith('corromp')) return 'corrompido';
  throw 'conceito desconhecido: "$raw"';
}

List<String> _concepts(String raw) => raw
    .split(',')
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty && e != '—')
    .map(_concept)
    .toList();

String _rarity(String raw) {
  final f = _foldLabel(raw);
  if (f.startsWith('comum')) return 'comum';
  if (f.startsWith('rar')) return 'rara';
  if (f.startsWith('epic')) return 'epica';
  if (f.startsWith('lendar')) return 'lendaria';
  if (f.startsWith('elite')) return 'elite';
  throw 'raridade desconhecida: "$raw"';
}

/// Mapeia um pedaço de "tipo de ataque/dano" → chave snake do DamageType, ou
/// null se não reconhecer.
String? _damageType(String raw) {
  final f = _foldLabel(raw);
  if (f.isEmpty) return null;
  if (f.contains('corpo') || f.startsWith('fisic')) return 'corpo_a_corpo';
  if (f.contains('distan') || f.contains('alcance')) return 'a_distancia';
  if (f.contains('magic')) return 'magico';
  if (f.startsWith('vitalist') || f.startsWith('vitalismo')) return 'vitalismo';
  if (f.startsWith('verdadeir')) return 'vitalismo';
  if (f.startsWith('cura')) return 'cura';
  return null;
}

/// Lista ordenada e deduplicada de tipos de dano de uma criatura.
List<String> _damageTypes(String raw) {
  final parts = raw
      .replaceAll('/', ',')
      .replaceAll(RegExp(r'\s+e\s+'), ',')
      .split(',');
  final out = <String>[];
  for (final p in parts) {
    final t = _damageType(p);
    if (t != null && !out.contains(t)) out.add(t);
  }
  return out;
}

/// Base de habilidade (folded, sem dígitos) → token canônico snake. null = drop.
const Map<String, String> _abilityBase = {
  'provocar': 'provocar',
  'escudo': 'escudo',
  'defesa': 'escudo',
  'voo': 'voo',
  'ataqueduplo': 'ataque_duplo',
  'duploataque': 'ataque_duplo',
  'alcance': 'alcance',
  'inspirar': 'inspirar',
  'pisotear': 'pisotear',
  'silencio': 'silencio',
  'furtividade': 'furtividade',
  'cristaldedrenagem': 'cristal_de_drenagem',
  'roubodepv': 'roubo_de_pv',
  'vampirismo': 'roubo_de_pv',
  'investida': 'investida',
  'espinhos': 'espinhos',
  'espinho': 'espinhos',
  'escudoespelhado': 'escudo_espelhado',
  'escudosagrado': 'escudo_sagrado',
  'contraataque': 'contra_ataque',
  'reflexomagico': 'reflexo_magico',
  'reflexaomagica': 'reflexo_magico',
  'reversaodefeitico': 'reflexo_magico',
  'espelhomagico': 'reflexo_magico',
  'inabalavel': 'inabalavel',
  'sangramento': 'sangramento',
  'veneno': 'veneno',
  'atordoar': 'atordoar',
  'enredar': 'enredar',
  'desmoralizar': 'desmoralizar',
  'suprimirmagia': 'suprimir_magia',
  'doenca': 'doenca',
  'surto': 'surto',
  'andorinha': 'andorinha',
  'crescimento': 'crescimento',
  'mimico': 'mimico',
  'cartazumbi': 'zumbi',
  'zumbi': 'zumbi',
  'ressurreicao': 'ressurreicao',
  'transformar': 'transformar',
  'transformacao': 'transformar',
  'imunidade': 'imunidade',
  'perseveranca': 'perseveranca',
  'vigilante': 'vigilante',
  'furia': 'furia',
  'encantararmadura': 'encantar_armadura',
  'cristaladicional': 'cristal_adicional',
  'espinhodeescudo': 'espinho_de_escudo',
  'nevoa': 'nevoa',
  'antiaereo': 'anti_aereo',
  'quebraarmadura': 'quebra_armadura',
  'quebradearmadura': 'quebra_armadura',
  'quebraescudo': 'quebra_armadura',
  'explosaomagica': 'explosao_magica',
  'nevoatoxica': 'nevoa_toxica',
  'esquiva': 'esquiva',
  'curar': 'cura',
  'cura': 'cura',
  'recuo': 'recuo',
  'recuar': 'recuo',
  'percepcao': 'percepcao',
  'executor': 'executor',
};

/// Bases que aceitam magnitude `_N`.
const _magnitudeBases = {'espinhos', 'escudo', 'roubo_de_pv'};

/// Chaves de prefixo p/ frases verbosas (ex.: "imunidade a medo/controle...").
const _abilityPrefixes = ['imunidade', 'doenca'];

List<String> _abilities(String raw, Set<String> dropped) {
  if (raw.trim().isEmpty || raw.trim() == '—') return const [];
  // remove parentéticos e quebra em pedaços por vírgula/ponto.
  final cleaned = raw.replaceAll(RegExp(r'\([^)]*\)'), ' ');
  final pieces = cleaned.split(RegExp(r'[,.]'));
  final out = <String>[];
  for (final raw in pieces) {
    final piece = raw.trim();
    if (piece.isEmpty || piece == '—') continue;
    final num = RegExp(r'\d+').firstMatch(piece)?.group(0);
    final base = _foldLabel(piece); // só a-z (dígitos já removidos por _foldLabel)
    if (base.isEmpty) continue;
    var canon = _abilityBase[base];
    if (canon == null) {
      // tenta prefixo p/ frases verbosas
      for (final p in _abilityPrefixes) {
        if (base.startsWith(p)) {
          canon = _abilityBase[p];
          break;
        }
      }
    }
    if (canon == null) {
      dropped.add(piece);
      continue;
    }
    if (num != null && _magnitudeBases.contains(canon)) {
      canon = '${canon}_$num';
    }
    if (!out.contains(canon)) out.add(canon);
  }
  return out;
}

// ───────────────────────── criaturas ─────────────────────────

List<Map<String, dynamic>> _parseCreatures(String raw, Set<String> dropped) {
  final out = <Map<String, dynamic>>[];
  for (final blk in _blocks(raw)) {
    final f = blk['fields'] as Map<String, String>;
    final id = blk['id'] as String;
    final types = _damageTypes(f['tipodedano'] ?? 'corpo_a_corpo');
    if (types.isEmpty) types.add('corpo_a_corpo');
    final atk = _intOrNull(f['ataque']) ?? 0;
    final extra = <String, int>{};
    for (var i = 1; i < types.length; i++) {
      extra[types[i]] = atk; // mesmo ATK (2 ataques)
    }
    final m = <String, dynamic>{
      'id': id,
      'nome': blk['name'],
      'concepts': _concepts(f['conceitos'] ?? 'neutro'),
      'cost': _intOrNull(f['custo']) ?? 0,
      'atk': atk,
      'hp': _intOrNull(f['vida']) ?? 1,
      'damage_type': types.first,
      'rarity': _rarity(f['raridade'] ?? 'comum'),
      'relic_slots': _intOrNull(f['slotsdereliquia']) ?? 1,
      'abilities': _abilities(f['habilidades'] ?? '', dropped),
    };
    if (extra.isNotEmpty) m['extra_attacks'] = extra;
    out.add(m);
  }
  return out;
}

// ───────────────────────── relíquias ─────────────────────────

const _factionType = {
  'chrysalis': 'a_distancia',
  'celestial': 'magico',
  'magico': 'magico',
  'vitalismo': 'vitalismo',
  'corrompido': 'corpo_a_corpo',
};

/// Devolve o sufixo de facção do id ("..._chrysalis") ou null.
String? _factionSuffix(String id) {
  for (final k in _factionType.keys) {
    if (id.endsWith('_$k')) return k;
  }
  return null;
}

List<Map<String, dynamic>> _parseRelics(
    String raw, Set<String> dropped, List<String> factionDerived) {
  final out = <Map<String, dynamic>>[];
  for (final blk in _blocks(raw)) {
    final f = blk['fields'] as Map<String, String>;
    final id = blk['id'] as String;
    final concepts = _concepts(f['conceitos'] ?? 'neutro');
    final atkBonus = _intOrNull(f['bonusatq']);
    final hpBonus = _intOrNull(f['bonusvida']);
    final armor = _intOrNull(f['armadura']);
    final heal = _intOrNull(f['cura']);
    final rawEffect = f['efeito'] ?? '';

    // tipo de ataque: honra o docx; senão deriva da facção SÓ p/ variantes
    // repetidas (id com sufixo de facção) que concedem atk_bonus. Itens
    // standalone (katana, faca_militar...) mantêm o tipo nativo (null).
    String? attackType = _damageType(f['tipodeataque'] ?? '');
    if (attackType == null && (atkBonus ?? 0) > 0 && _factionSuffix(id) != null) {
      final derived = _factionType[_factionSuffix(id)];
      if (derived != null) {
        attackType = derived;
        factionDerived.add('$id → $derived (facção ${_factionSuffix(id)})');
      }
    }

    final grants = <String, dynamic>{};
    if (atkBonus != null) grants['atk_bonus'] = atkBonus;
    if (hpBonus != null) grants['hp_bonus'] = hpBonus;
    if (armor != null) grants['armor'] = armor;
    if (heal != null) grants['heal'] = heal;
    if (attackType != null) grants['attack_type'] = attackType;
    grants['abilities'] = _abilities(f['habilidades'] ?? '', dropped);
    grants['raw_effect'] = rawEffect;

    final flash = _foldLabel(f['flash'] ?? 'nao').startsWith('sim');
    out.add({
      'id': id,
      'nome': blk['name'],
      'concepts': concepts,
      'cost': _intOrNull(f['custo']) ?? 0,
      'grants': grants,
      'rarity': _rarity(f['raridade'] ?? 'comum'),
      'is_flash': flash,
    });
  }
  return out;
}
