/// Gerador reproduzível dos dados do Card Game ACDA.
///
/// Lê os arquivos `.md` das cartas reais (criaturas + relíquias) do vault,
/// parseia o frontmatter YAML e — para relíquias — a linha "Efeito" da tabela
/// markdown do corpo, e emite dois JSON:
///   assets/data/card_game/creatures.json  (80 criaturas)
///   assets/data/card_game/relics.json     (176 relíquias)
///
/// FIEL aos dados: não inventa stats. Onde o texto do efeito não casa com um
/// campo estruturado, preserva o texto cru em `raw_effect` e deixa os campos
/// estruturados nulos / `abilities` vazio.
///
/// Magnitudes de cura (tunáveis 🎚️): pequena=2, média=4, grande=6.
///
/// Uso (a partir da raiz do projeto):
///   dart run tool/gen_card_data.dart
library;

import 'dart:convert';
import 'dart:io';

// Magnitudes de cura por palavra-chave (🎚️ tunável; declarado, não inventado).
const int kHealSmall = 2;
const int kHealMedium = 4;
const int kHealLarge = 6;

const String _vaultCreatures =
    r'.vault\App\05_ACDA_Cards\03_cartas\criaturas';
const String _vaultRelics = r'.vault\App\05_ACDA_Cards\03_cartas\reliquias';

void main(List<String> args) {
  final root = Directory.current.path;
  final creaturesDir = Directory('$root${Platform.pathSeparator}'
      '${_vaultCreatures.replaceAll(r'\', Platform.pathSeparator)}');
  final relicsDir = Directory('$root${Platform.pathSeparator}'
      '${_vaultRelics.replaceAll(r'\', Platform.pathSeparator)}');

  if (!creaturesDir.existsSync()) {
    stderr.writeln('Pasta de criaturas não encontrada: ${creaturesDir.path}');
    exitCode = 2;
    return;
  }
  if (!relicsDir.existsSync()) {
    stderr.writeln('Pasta de relíquias não encontrada: ${relicsDir.path}');
    exitCode = 2;
    return;
  }

  final creatures = <Map<String, dynamic>>[];
  for (final f in _cardFiles(creaturesDir)) {
    creatures.add(_parseCreature(f));
  }
  creatures.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

  var parsed = 0;
  var rawOnly = 0;
  final relics = <Map<String, dynamic>>[];
  for (final f in _cardFiles(relicsDir)) {
    final r = _parseRelic(f);
    relics.add(r);
    final g = r['grants'] as Map<String, dynamic>;
    final structured = g.containsKey('atk_bonus') ||
        g.containsKey('hp_bonus') ||
        g.containsKey('armor') ||
        g.containsKey('heal') ||
        g.containsKey('attack_type') ||
        (g['abilities'] as List).isNotEmpty;
    if (structured) {
      parsed++;
    } else {
      rawOnly++;
    }
  }
  relics.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

  final outDir = Directory(
      '$root${Platform.pathSeparator}assets${Platform.pathSeparator}data'
      '${Platform.pathSeparator}card_game');
  outDir.createSync(recursive: true);

  const encoder = JsonEncoder.withIndent('  ');
  File('${outDir.path}${Platform.pathSeparator}creatures.json')
      .writeAsStringSync(encoder.convert(creatures), encoding: utf8);
  File('${outDir.path}${Platform.pathSeparator}relics.json')
      .writeAsStringSync(encoder.convert(relics), encoding: utf8);

  stdout.writeln('Criaturas geradas: ${creatures.length}');
  stdout.writeln('Relíquias geradas: ${relics.length}');
  stdout.writeln('Relíquias com campos estruturados: $parsed');
  stdout.writeln('Relíquias só com raw_effect: $rawOnly');
}

Iterable<File> _cardFiles(Directory dir) {
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.startsWith('carta_') &&
          f.path.endsWith('.md'));
}

// ---------------------------------------------------------------------------
// Frontmatter
// ---------------------------------------------------------------------------

/// Extrai o bloco de frontmatter (entre as duas linhas `---`) como mapa
/// chave→valor cru (string). Listas e strings citadas tratadas pelos helpers.
Map<String, String> _frontmatter(String content) {
  final lines = const LineSplitter().convert(content);
  if (lines.isEmpty || lines.first.trim() != '---') {
    throw const FormatException('Sem frontmatter');
  }
  final map = <String, String>{};
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim() == '---') break;
    final idx = line.indexOf(':');
    if (idx < 0) continue;
    final key = line.substring(0, idx).trim();
    final value = line.substring(idx + 1).trim();
    map[key] = value;
  }
  return map;
}

String _unquote(String v) {
  var s = v.trim();
  if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
    s = s.substring(1, s.length - 1);
  }
  return s;
}

/// Parse de uma lista YAML inline `[a, b]`.
List<String> _yamlList(String v) {
  var s = v.trim();
  if (s.startsWith('[') && s.endsWith(']')) {
    s = s.substring(1, s.length - 1);
  }
  if (s.trim().isEmpty) return const [];
  return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

/// id estável derivado do nome do arquivo (sem `carta_` e sem `.md`).
String _idFromFile(File f) {
  var name = f.uri.pathSegments.last;
  if (name.startsWith('carta_')) name = name.substring('carta_'.length);
  if (name.endsWith('.md')) name = name.substring(0, name.length - 3);
  return name;
}

// ---------------------------------------------------------------------------
// Criatura
// ---------------------------------------------------------------------------

Map<String, dynamic> _parseCreature(File f) {
  final content = f.readAsStringSync(encoding: utf8);
  final fm = _frontmatter(content);

  final concepts = _yamlList(fm['conceito'] ?? '[]');
  final abilities = _yamlList(fm['habilidades'] ?? '[]');

  return <String, dynamic>{
    'id': _idFromFile(f),
    'nome': _unquote(fm['nome_canonico'] ?? _idFromFile(f)),
    'concepts': concepts,
    'cost': int.parse(fm['custo']!.trim()),
    'atk': int.parse(fm['ataque']!.trim()),
    'hp': int.parse(fm['pv']!.trim()),
    'damage_type': fm['tipo_dano']!.trim(),
    'rarity': fm['raridade']!.trim(),
    'relic_slots': int.parse((fm['slots_reliquia'] ?? '1').trim()),
    'abilities': abilities,
  };
}

// ---------------------------------------------------------------------------
// Relíquia
// ---------------------------------------------------------------------------

Map<String, dynamic> _parseRelic(File f) {
  final content = f.readAsStringSync(encoding: utf8);
  final fm = _frontmatter(content);

  final concepts = _yamlList(fm['conceito'] ?? '[]');
  final tipo = (fm['tipo'] ?? 'equipamento').trim();
  final isFlash = tipo == 'flash';

  final effect = _extractEffect(content);
  final grants = _parseEffect(effect);

  return <String, dynamic>{
    'id': _idFromFile(f),
    'nome': _unquote(fm['nome_canonico'] ?? _idFromFile(f)),
    'concepts': concepts,
    'cost': int.parse(fm['custo']!.trim()),
    'grants': grants,
    'rarity': fm['raridade']!.trim(),
    'is_flash': isFlash,
  };
}

/// Lê a linha `| **Efeito** | <texto> |` da tabela markdown do corpo.
String _extractEffect(String content) {
  for (final line in const LineSplitter().convert(content)) {
    final m = RegExp(r'^\|\s*\*\*Efeito\*\*\s*\|\s*(.+?)\s*\|\s*$')
        .firstMatch(line);
    if (m != null) return m.group(1)!.trim();
  }
  return '';
}

/// Parse best-effort do texto do efeito para campos estruturados.
/// `raw_effect` SEMPRE preservado. O que não casar fica só no raw + abilities [].
Map<String, dynamic> _parseEffect(String effect) {
  final grants = <String, dynamic>{
    'raw_effect': effect,
  };
  final abilities = <String>[];
  final lower = effect.toLowerCase();

  // --- Ataque: "+N de ataque [à distância|mágico|corpo a corpo]" ---
  final atk = RegExp(r'\+\s*(\d+)\s+de\s+ataque').firstMatch(lower);
  if (atk != null) {
    grants['atk_bonus'] = int.parse(atk.group(1)!);
  }

  // --- Alcance => ataque à distância ---
  if (lower.contains('alcance')) {
    grants['attack_type'] = 'a_distancia';
    // "Alcance: +N de ataque à distância" — captura o bônus se houver.
    final ranged = RegExp(r'\+\s*(\d+)\s+de\s+ataque\s+à\s+dist')
        .firstMatch(lower);
    if (ranged != null) {
      grants['atk_bonus'] = int.parse(ranged.group(1)!);
    }
  }

  // --- PV: "+N PV" => hp_bonus ---
  final pv = RegExp(r'\+\s*(\d+)\s*pv').firstMatch(lower);
  if (pv != null) {
    grants['hp_bonus'] = int.parse(pv.group(1)!);
  }

  // --- Escudo / bloqueia X dano físico => armor ---
  // Evita falsos positivos de "Escudo" em contexto negativo (ex.: "reduz
  // Escudo inimigo" — não concede escudo ao portador).
  final negativeShield = lower.contains('reduz escudo') ||
      lower.contains('reduz a escudo') ||
      lower.contains('escudo inimigo');
  if (!negativeShield && (lower.contains('escudo') || lower.contains('bloqueia'))) {
    final block = RegExp(r'bloqueia\s+(\d+)\s+dano').firstMatch(lower);
    if (block != null) {
      grants['armor'] = int.parse(block.group(1)!);
    } else {
      // "Escudo + 1 PV": Escudo genérico = bloqueia 1 (magnitude declarada 🎚️).
      grants['armor'] = (grants['armor'] as int? ?? 0) + 1;
    }
  }

  // --- Cura: pequena/média/grande => heal com magnitude declarada ---
  if (lower.contains('cura')) {
    if (lower.contains('grande')) {
      grants['heal'] = kHealLarge;
    } else if (lower.contains('média') || lower.contains('media')) {
      grants['heal'] = kHealMedium;
    } else if (lower.contains('pequena')) {
      grants['heal'] = kHealSmall;
    }
    // "Cura" sem magnitude (ex.: "(Cura)") => não fabrica número.
  }

  // --- Keywords de habilidade ---
  void kw(String needle, String label) {
    if (lower.contains(needle) && !abilities.contains(label)) {
      abilities.add(label);
    }
  }

  kw('furtividade', 'Furtividade');
  kw('investida', 'Investida');
  kw('inspirar', 'Inspirar');
  kw('ataque duplo', 'AtaqueDuplo');

  // Silêncio/Provocar: só conta como concedido se NÃO for contexto de
  // remoção/imunidade (ex.: "Remove Silêncio", "anti-Silêncio", "Imunidade").
  final negativeControl = lower.contains('remove silêncio') ||
      lower.contains('remove silencio') ||
      lower.contains('anti-') ||
      lower.contains('imunidade');
  if (!negativeControl) {
    kw('silêncio', 'Silencio');
    kw('silencio', 'Silencio');
    kw('provocar', 'Provocar');
  }

  grants['abilities'] = abilities;
  return grants;
}
