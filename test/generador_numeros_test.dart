// Unit tests for GeneradorNumeros (the extracted lottery generator).
//
// The Random instance is injected with fixed seeds, so every assertion
// is deterministic and repeatable.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bl_app/services/generadorNumeros.dart';

void main() {
  group('BalotoRules', () {
    test('match the real Baloto game rules', () {
      expect(BalotoRules.cantidadNumeros, 5);
      expect(BalotoRules.maxNumero, 43);
      expect(BalotoRules.maxSuperbalota, 16);
    });
  });

  group('generarNumeros', () {
    test('returns exactly 5 numbers', () {
      final generador = GeneradorNumeros(random: Random(1));

      expect(generador.generarNumeros(), hasLength(5));
    });

    test('numbers are within the 1..43 range', () {
      final generador = GeneradorNumeros(random: Random(2));

      for (var i = 0; i < 100; i++) {
        for (final n in generador.generarNumeros()) {
          expect(n, inInclusiveRange(1, 43), reason: 'número inválido: $n');
        }
      }
    });

    test('numbers are unique', () {
      final generador = GeneradorNumeros(random: Random(3));

      for (var i = 0; i < 100; i++) {
        final numeros = generador.generarNumeros();
        expect(numeros.toSet(), hasLength(5), reason: 'repetidos: $numeros');
      }
    });

    test('numbers come out sorted ascending', () {
      final generador = GeneradorNumeros(random: Random(4));

      for (var i = 0; i < 100; i++) {
        final numeros = generador.generarNumeros();
        expect(numeros, orderedEquals([...numeros]..sort()));
      }
    });

    test('is deterministic with a fixed seed', () {
      final a = GeneradorNumeros(random: Random(42));
      final b = GeneradorNumeros(random: Random(42));

      // Same seed -> identical sequence of combinations.
      for (var i = 0; i < 10; i++) {
        expect(a.generarNumeros(), b.generarNumeros());
      }
    });

    test('produces varied combinations across calls (not stuck)', () {
      final generador = GeneradorNumeros(random: Random(5));

      final combinaciones = <String>{
        for (var i = 0; i < 50; i++) generador.generarNumeros().join(','),
      };

      // With 962,598 possible combinations, getting fewer than 40
      // distinct results in 50 tries would be suspicious.
      expect(combinaciones.length, greaterThan(40));
    });
  });

  group('generarSuperbalota', () {
    test('is within the 1..16 range', () {
      final generador = GeneradorNumeros(random: Random(6));

      for (var i = 0; i < 200; i++) {
        final s = generador.generarSuperbalota();
        expect(s, inInclusiveRange(1, 16), reason: 'superbalota inválida: $s');
      }
    });

    test('eventually covers low and high values (no bias)', () {
      final generador = GeneradorNumeros(random: Random(7));

      final valores = {
        for (var i = 0; i < 200; i++) generador.generarSuperbalota(),
      };

      expect(
        valores.any((v) => v <= 8),
        isTrue,
        reason: 'no salen valores bajos',
      );
      expect(
        valores.any((v) => v >= 9),
        isTrue,
        reason: 'no salen valores altos',
      );
    });
  });

  group('generarCombinacion', () {
    test('returns a fully valid combination', () {
      final generador = GeneradorNumeros(random: Random(8));

      final combinacion = generador.generarCombinacion();

      expect(combinacion.numeros, hasLength(5));
      expect(combinacion.numeros.toSet(), hasLength(5));
      expect(
        combinacion.numeros.first,
        lessThanOrEqualTo(combinacion.numeros.last),
      );
      for (final n in combinacion.numeros) {
        expect(n, inInclusiveRange(1, 43));
      }
      expect(combinacion.superbalota, inInclusiveRange(1, 16));
    });

    test('is deterministic with a fixed seed', () {
      final a = GeneradorNumeros(random: Random(99));
      final b = GeneradorNumeros(random: Random(99));

      for (var i = 0; i < 5; i++) {
        expect(a.generarCombinacion().numeros, b.generarCombinacion().numeros);
        expect(a.generarSuperbalota(), b.generarSuperbalota());
      }
    });
  });
}
