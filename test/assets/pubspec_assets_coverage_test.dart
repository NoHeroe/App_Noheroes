import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// Rede de proteção: todo asset referenciado via rootBundle.loadString('…')
// precisa estar declarado em pubspec.yaml. Sem isso, o asset não é empacotado
// no APK e o seed/leitura falha em runtime com FlutterError: Unable to load
// asset, frequentemente silenciado por try/catch.
//
// Origem: bug da Sprint 2.2 — recipes.json não declarado, seeder falhava
// silencioso, /forge vazia pra todos.
void main() {
  test('assets referenciados via rootBundle.loadString estão em pubspec.yaml',
      () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final libFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    // Captura apenas string literals (ignora path dinâmico como em
    // asset_loader.dart, que recebe path via parâmetro).
    final assetPathRegex = RegExp(
      r'''rootBundle\.loadString\s*\(\s*['"]([^'"]+)['"]''',
    );

    final referencedAssets = <String>{};
    for (final f in libFiles) {
      final content = f.readAsStringSync();
      for (final match in assetPathRegex.allMatches(content)) {
        referencedAssets.add(match.group(1)!);
      }
    }

    // Pra cada asset referenciado, cross-check em pubspec.yaml. Usa regex
    // ancorado pra evitar match parcial (ex: recipes.json ≠ recipes.json.bak).
    final missing = <String>[];
    for (final asset in referencedAssets) {
      final pattern = RegExp(r'-\s+' + RegExp.escape(asset) + r'\s*$',
          multiLine: true);
      if (!pattern.hasMatch(pubspec)) {
        missing.add(asset);
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'Assets referenciados via rootBundle mas NÃO declarados em '
          'pubspec.yaml:\n${missing.join("\n")}\n\n'
          'Adicione cada um sob `flutter.assets:` do pubspec.yaml.',
    );
  });
}
