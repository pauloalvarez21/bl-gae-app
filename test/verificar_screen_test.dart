// Widget tests for VerificarScreen: form validation, result card rendering
// and API error handling. All API calls go through a mocked BalotoApi.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bl_app/screens/verificarScreen.dart';
import 'package:bl_app/services/balotoApi.dart';

/// JSON for a losing verification (no prize, no winner).
const perderJson = {
  'fecha': '2026-09-05',
  'baloto': {
    'ganador': false,
    'categoria': 'Sin premio',
    'premio': 0,
    'aciertos': {'numeros': 1, 'superbalota': false},
    'numerosGanadores': [5, 12, 23, 34, 42],
    'superbalotaGanadora': 14,
  },
  'revancha': {
    'ganador': false,
    'categoria': 'Sin premio',
    'premio': 0,
    'aciertos': {'numeros': 0, 'superbalota': false},
    'numerosGanadores': [5, 12, 23, 34, 42],
    'superbalotaGanadora': 14,
  },
};

/// JSON for a winning verification in Revancha.
const ganarJson = {
  'fecha': '2026-09-05',
  'baloto': {
    'ganador': false,
    'categoria': 'Sin premio',
    'premio': 0,
    'aciertos': {'numeros': 1, 'superbalota': false},
    'numerosGanadores': [5, 12, 23, 34, 42],
    'superbalotaGanadora': 14,
  },
  'revancha': {
    'ganador': true,
    'categoria': 'Acierto 5 + Superbalota',
    'premio': 1, // ID de categoría (1 = Premio Mayor), no un monto.
    'aciertos': {'numeros': 5, 'superbalota': true},
    'numerosGanadores': [5, 12, 23, 34, 42],
    'superbalotaGanadora': 14,
  },
};

BalotoApi apiWith(http.Client client) => BalotoApi(client: client);

Future<void> pumpScreen(WidgetTester tester, BalotoApi api) async {
  // Surface grande: la tarjeta de resultados debe quedar construible
  // dentro del viewport.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: VerificarScreen(api: api)));
}

/// Fields are located by index: 0..4 are the numbers, 5 is the Superbalota.
final formFields = find.byType(TextFormField);

/// Fills the 5 number fields + the Superbalota field.
Future<void> fillForm(
  WidgetTester tester,
  List<String> numeros,
  String superbalota,
) async {
  for (var i = 0; i < 5; i++) {
    await tester.enterText(formFields.at(i), numeros[i]);
  }
  await tester.enterText(formFields.at(5), superbalota);
  await tester.pump();
}

Future<void> tapVerificar(WidgetTester tester) async {
  await tester.tap(find.text('VERIFICAR PREMIO'));
  await tester.pumpAndSettle();
}

void main() {
  group('form layout', () {
    testWidgets('shows 6 inputs with the Superbalota visually distinct', (
      tester,
    ) async {
      final api = apiWith(
        MockClient((request) async => http.Response('{}', 200)),
      );
      await pumpScreen(tester, api);

      // 5 number fields + 1 superbalota field.
      expect(formFields, findsNWidgets(6));

      // The Superbalota field is the amber/star one.
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Superbalota del 1 al 16'), findsOneWidget);
      expect(find.text('Números del 1 al 43, sin repetir'), findsOneWidget);
    });
  });

  group('form validation', () {
    testWidgets('flags every empty field individually', (tester) async {
      final api = apiWith(
        MockClient((request) async => http.Response('{}', 200)),
      );
      await pumpScreen(tester, api);

      await tapVerificar(tester);

      expect(find.textContaining('Falta el número'), findsNWidgets(5));
      expect(find.text('Ingresa la SB'), findsOneWidget);
    });

    testWidgets('flags only the fields left empty', (tester) async {
      final api = apiWith(
        MockClient((request) async => http.Response('{}', 200)),
      );
      await pumpScreen(tester, api);

      // Fill only the first 3 numbers.
      await fillForm(tester, ['5', '12', '23', '', ''], '14');
      await tapVerificar(tester);

      expect(find.text('Falta el número 4'), findsOneWidget);
      expect(find.text('Falta el número 5'), findsOneWidget);
      // The filled ones show no error.
      expect(find.text('Falta el número 1'), findsNothing);
    });

    testWidgets('rejects numbers out of range', (tester) async {
      final api = apiWith(
        MockClient((request) async => http.Response('{}', 200)),
      );
      await pumpScreen(tester, api);

      await fillForm(tester, ['44', '12', '23', '34', '42'], '14');
      await tapVerificar(tester);

      expect(find.text('Debe estar entre 1 y 43'), findsOneWidget);
    });

    testWidgets('rejects duplicated numbers', (tester) async {
      final api = apiWith(
        MockClient((request) async => http.Response('{}', 200)),
      );
      await pumpScreen(tester, api);

      await fillForm(tester, ['5', '5', '23', '34', '42'], '14');
      await tapVerificar(tester);

      // Both offending fields show the error.
      expect(find.text('Número repetido'), findsNWidgets(2));
    });

    testWidgets('rejects a superbalota out of range', (tester) async {
      final api = apiWith(
        MockClient((request) async => http.Response('{}', 200)),
      );
      await pumpScreen(tester, api);

      await fillForm(tester, ['5', '12', '23', '34', '42'], '17');
      await tapVerificar(tester);

      expect(find.text('Entre 1 y 16'), findsOneWidget);
    });

    testWidgets('does not call the API when validation fails', (tester) async {
      var callCount = 0;

      final api = apiWith(
        MockClient((request) async {
          callCount++;
          return http.Response(jsonEncode(perderJson), 200);
        }),
      );
      await pumpScreen(tester, api);

      await fillForm(tester, ['5', '12', '23', '', ''], '14');
      await tapVerificar(tester);

      expect(callCount, 0);
      expect(find.text('Falta el número 4'), findsOneWidget);
    });
  });

  group('result card', () {
    testWidgets('renders a losing verification correctly', (tester) async {
      final api = apiWith(
        MockClient((request) async {
          expect(request.url.path, '/baloto/verificar');
          expect(request.url.queryParameters['numeros'], '5,12,23,34,42');
          expect(request.url.queryParameters['superbalota'], '14');
          return http.Response(jsonEncode(perderJson), 200);
        }),
      );
      await pumpScreen(tester, api);

      await fillForm(tester, ['5', '12', '23', '34', '42'], '14');
      await tapVerificar(tester);

      // Main header (categories are not repeated in the detail sections).
      expect(find.text('SIN PREMIO'), findsOneWidget);
      expect(find.text('5 sept 2026'), findsOneWidget);

      // Losing icon.
      expect(find.byIcon(Icons.sentiment_dissatisfied), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsNothing);

      // No prize row when premioTotal == 0.
      expect(find.textContaining('Premio:'), findsNothing);

      // Per-draw detail sections.
      expect(find.text('BALOTO'), findsOneWidget);
      expect(find.text('REVANCHA'), findsOneWidget);
      expect(find.text('Tus aciertos: 1 números'), findsOneWidget);
      expect(find.text('Tus aciertos: 0 números'), findsOneWidget);
      expect(find.text('Números ganadores del sorteo:'), findsNWidgets(2));
      expect(find.text('05'), findsNWidgets(2)); // both lists share numbers
    });

    testWidgets('renders a winning verification with the prize', (
      tester,
    ) async {
      final api = apiWith(
        MockClient((request) async {
          return http.Response(jsonEncode(ganarJson), 200);
        }),
      );
      await pumpScreen(tester, api);

      await fillForm(tester, ['5', '12', '23', '34', '42'], '14');
      await tapVerificar(tester);

      // Trophy icon + revancha category as the main header.
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.text('ACIERTO 5 + SUPERBALOTA'), findsOneWidget);

      // The prize line shows the category name (premio is a category
      // ID 1-7 per the API contract, never a dollar amount).
      expect(find.text('Premio Mayor'), findsOneWidget);

      // The winning draw shows "+ Superbalota" in its aciertos line.
      expect(
        find.text('Tus aciertos: 5 números + Superbalota'),
        findsOneWidget,
      );
    });

    testWidgets('sends the entered numbers as query params', (tester) async {
      Uri? capturedUri;

      final api = apiWith(
        MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode(perderJson), 200);
        }),
      );
      await pumpScreen(tester, api);

      await fillForm(tester, ['3', '9', '17', '28', '40'], '7');
      await tapVerificar(tester);

      expect(capturedUri!.path, '/baloto/verificar');
      expect(capturedUri!.queryParameters['numeros'], '3,9,17,28,40');
      expect(capturedUri!.queryParameters['superbalota'], '7');
    });
  });

  group('api errors', () {
    testWidgets('shows the API message inside the red error box', (
      tester,
    ) async {
      final api = apiWith(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'message': ['numeros must have 5 items'],
            }),
            400,
          );
        }),
      );
      await pumpScreen(tester, api);

      await fillForm(tester, ['5', '12', '23', '34', '42'], '14');
      await tapVerificar(tester);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('numeros must have 5 items'), findsOneWidget);
      // No result card is shown when there is an error.
      expect(find.text('BALOTO'), findsNothing);
    });

    testWidgets('shows the result card again after an error is recovered', (
      tester,
    ) async {
      var failFirst = true;

      final api = apiWith(
        MockClient((request) async {
          if (failFirst) {
            failFirst = false;
            return http.Response(jsonEncode({'message': 'boom'}), 500);
          }
          return http.Response(jsonEncode(perderJson), 200);
        }),
      );
      await pumpScreen(tester, api);

      await fillForm(tester, ['5', '12', '23', '34', '42'], '14');
      await tapVerificar(tester);
      expect(find.text('boom'), findsOneWidget);

      // Second attempt succeeds and replaces the error with the card.
      await tapVerificar(tester);
      expect(find.text('boom'), findsNothing);
      expect(find.text('SIN PREMIO'), findsWidgets);
    });
  });
}
