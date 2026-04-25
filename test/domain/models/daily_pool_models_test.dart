import 'package:flutter_test/flutter_test.dart';

import 'package:noheroes_app/domain/enums/daily_unit_type.dart';
import 'package:noheroes_app/domain/models/daily_modalidade_pool.dart';
import 'package:noheroes_app/domain/models/daily_sub_task_spec.dart';
import 'package:noheroes_app/domain/models/vitalismo_pool.dart';

/// Sprint 3.2 Etapa 1.1 — round-trip fromJson/toJson preserva todos os
/// campos dos 3 models do pool diário.
void main() {
  group('DailyUnitTypeCodec', () {
    test('todos os tipos têm storage estável', () {
      for (final t in DailyUnitType.values) {
        expect(DailyUnitTypeCodec.fromStorage(t.storage), t);
      }
    });

    test('valor inválido lança FormatException', () {
      expect(() => DailyUnitTypeCodec.fromStorage('garbage'),
          throwsFormatException);
    });
  });

  group('DailySubTaskSpec round-trip', () {
    test('preserva campos contagem (flexoes-like)', () {
      final json = {
        'key': 'flexoes',
        'nome_visivel': 'Flexões',
        'sub_categoria': 'treino',
        'unidade': 'x',
        'tipo_unidade': 'contagem',
        'escala_por_rank': {'E': 10, 'D': 25, 'C': 50, 'B': 90, 'A': 150, 'S': 300},
        'requer_imc': false,
      };
      final spec = DailySubTaskSpec.fromJson(json);
      expect(spec.key, 'flexoes');
      expect(spec.tipoUnidade, DailyUnitType.contagem);
      expect(spec.escalaPorRank['E'], 10);
      expect(spec.escalaPorRank['S'], 300);
      expect(spec.toJson(), json);
    });

    test('preserva requer_imc = true', () {
      final json = {
        'key': 'agua_diaria',
        'nome_visivel': 'Beber água',
        'sub_categoria': 'nutricao',
        'unidade': 'ml',
        'tipo_unidade': 'volumeMl',
        'escala_por_rank': {'E': 0, 'D': 0, 'C': 0, 'B': 0, 'A': 0, 'S': 0},
        'requer_imc': true,
      };
      final spec = DailySubTaskSpec.fromJson(json);
      expect(spec.requerImc, isTrue);
      expect(spec.tipoUnidade, DailyUnitType.volumeMl);
      expect(spec.toJson(), json);
    });

    test('default requer_imc = false quando ausente', () {
      final json = {
        'key': 'k',
        'nome_visivel': 'N',
        'sub_categoria': 'sc',
        'unidade': 'x',
        'tipo_unidade': 'contagem',
        'escala_por_rank': {'E': 1, 'D': 1, 'C': 1, 'B': 1, 'A': 1, 'S': 1},
      };
      final spec = DailySubTaskSpec.fromJson(json);
      expect(spec.requerImc, isFalse);
    });
  });

  group('DailyModalidadePool round-trip', () {
    test('preserva pesos, sub-tarefas, títulos e quotes', () {
      final json = {
        'modalidade': 'fisico',
        'cor_canonica': '#A32D2D',
        'pesos_subcategoria': {
          'treino': 0.35,
          'recuperacao': 0.25,
          'nutricao': 0.25,
          'descanso': 0.15,
        },
        'sub_tarefas': [
          {
            'key': 'flexoes',
            'nome_visivel': 'Flexões',
            'sub_categoria': 'treino',
            'unidade': 'x',
            'tipo_unidade': 'contagem',
            'escala_por_rank': {
              'E': 10,
              'D': 25,
              'C': 50,
              'B': 90,
              'A': 150,
              'S': 300,
            },
            'requer_imc': false,
          },
        ],
        'titulos_por_subcategoria': {
          'treino': ['Forja do Caçador', 'Pés na Cinza'],
        },
        'quotes': [
          'Cada gota de suor é uma promessa contra o Vazio.',
        ],
      };
      final pool = DailyModalidadePool.fromJson(json);
      expect(pool.modalidade, 'fisico');
      expect(pool.pesosSubcategoria['treino'], 0.35);
      expect(pool.subTarefas.length, 1);
      expect(pool.subTarefas.first.key, 'flexoes');
      expect(pool.titulosPorSubcategoria['treino']!.first,
          'Forja do Caçador');
      expect(pool.quotes.length, 1);

      // Round-trip — toJson reconstruído deve dar parse idêntico.
      final reparsed = DailyModalidadePool.fromJson(pool.toJson());
      expect(reparsed.modalidade, pool.modalidade);
      expect(reparsed.subTarefas.first.key, pool.subTarefas.first.key);
      expect(reparsed.titulosPorSubcategoria, pool.titulosPorSubcategoria);
      expect(reparsed.quotes, pool.quotes);
    });
  });

  group('VitalismoPool round-trip', () {
    test('preserva pesos por pilar + títulos + quotes', () {
      final json = {
        'modalidade': 'vitalismo',
        'cor_canonica': '#534AB7',
        'pesos_subcategoria_por_pilar': {
          'fisico': {
            'treino': 0.40,
            'recuperacao': 0.30,
            'nutricao': 0.20,
            'descanso': 0.10,
          },
          'mental': {
            'foco': 0.35,
            'estudo': 0.30,
            'organizacao': 0.20,
            'criatividade': 0.15,
          },
          'espiritual': {
            'proposito': 0.35,
            'silencio': 0.30,
            'ritual': 0.20,
            'conexao': 0.15,
          },
        },
        'titulos': ['Caminho do Vitalista', 'Forja dos Três'],
        'quotes': ['Inerte tem 1. Mago tem 2. Vitalista tem os 3.'],
      };
      final pool = VitalismoPool.fromJson(json);
      expect(pool.modalidade, 'vitalismo');
      expect(pool.pesosSubcategoriaPorPilar['fisico']!['treino'], 0.40);
      expect(pool.titulos.length, 2);
      expect(pool.quotes.length, 1);

      final reparsed = VitalismoPool.fromJson(pool.toJson());
      expect(reparsed.titulos, pool.titulos);
      expect(reparsed.quotes, pool.quotes);
      expect(reparsed.pesosSubcategoriaPorPilar['mental']!['foco'], 0.35);
    });
  });
}
