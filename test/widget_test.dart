// Widget tests for the app, using a mocked BalotoApi (MockClient from
// package:http/testing) so no real network calls are ever made.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bl_app/main.dart';
import 'package:bl_app/services/balotoApi.dart';

/// Valid JSON for the `/baloto/ultimo` endpoint.
const ultimoJson = {
  'baloto': {
    'fecha': '2026-09-05',
    'numeros': [5, 12, 23, 34, 42],
    'superbalota': 14,
  },
  'revancha': {
    'fecha': '2026-09-05',
    'numeros': [1, 2, 3, 4, 5],
    'superbalota': 7,
  },
};

BalotoApi apiWith(http.Client client) => BalotoApi(client: client);

Future<void> pumpApp(WidgetTester tester, BalotoApi api) async {
  // mostrarSplash: false → llega directo al shell (el splash se cubre
  // en su propio test).
  await tester.pumpWidget(MyApp(api: api, mostrarSplash: false));
  // Give the FutureBuilder a frame to resolve the (already completed) mock.
  await tester.pump();
}

void main() {
  testWidgets('shows a loading indicator while the request is in flight', (
    tester,
  ) async {
    // A completer keeps the future pending so we can see the loading state.
    final pending = Completer<http.Response>();

    final api = apiWith(MockClient((request) => pending.future));

    await tester.pumpWidget(MyApp(api: api, mostrarSplash: false));
    await tester.pump();

    expect(find.text('Consultando resultados...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete it to avoid a pending timer/future after the test ends.
    pending.complete(http.Response(jsonEncode(ultimoJson), 200));
    await tester.pump();
  });

  testWidgets('renders both lottery cards when the API responds', (
    tester,
  ) async {
    final api = apiWith(
      MockClient((request) async {
        // MainShell builds all tabs at startup, so /baloto/historico
        // (prefetch) also goes through this mock.
        if (request.url.path == '/baloto/ultimo') {
          expect(request.url.path, '/baloto/ultimo');
          return http.Response(jsonEncode(ultimoJson), 200);
        }
        return http.Response(jsonEncode({'baloto': [], 'revancha': []}), 200);
      }),
    );

    await pumpApp(tester, api);

    // Section titles.
    expect(find.text('BALOTO'), findsOneWidget);
    expect(find.text('REVANCHA'), findsOneWidget);
    expect(find.text('5 sept 2026'), findsNWidgets(2));

    // Padded numbers ("05" instead of "5").
    expect(find.text('05'), findsNWidgets(2)); // baloto 5 + revancha 5
    expect(find.text('12'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);

    // Superbalota badges.
    expect(find.text('14'), findsOneWidget);
    expect(find.text('07'), findsOneWidget);
  });

  testWidgets('shows the error UI when the API fails', (tester) async {
    final api = apiWith(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Internal server error'}),
          500,
        );
      }),
    );

    await pumpApp(tester, api);

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text('No se pudieron cargar los datos.'), findsOneWidget);
    // The server message is surfaced from ApiException.toString().
    expect(find.textContaining('Internal server error'), findsOneWidget);
  });

  testWidgets('error state offers a retry button that recovers the UI', (
    tester,
  ) async {
    var fallar = true;

    final api = apiWith(
      MockClient((request) async {
        if (request.url.path == '/baloto/ultimo') {
          if (fallar) {
            return http.Response(
              jsonEncode({'message': 'Internal server error'}),
              500,
            );
          }
          return http.Response(jsonEncode(ultimoJson), 200);
        }
        return http.Response(jsonEncode({'baloto': [], 'revancha': []}), 200);
      }),
    );

    await pumpApp(tester, api);

    // The error UI (with the new retry button) is showing.
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    // Next /baloto/ultimo call succeeds.
    fallar = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off), findsNothing);
    expect(find.text('BALOTO'), findsOneWidget);
    expect(find.text('REVANCHA'), findsOneWidget);
  });

  testWidgets('switches tabs with the bottom navigation bar', (tester) async {
    final api = apiWith(
      MockClient((request) async {
        if (request.url.path == '/baloto/ultimo') {
          return http.Response(jsonEncode(ultimoJson), 200);
        }
        return http.Response(jsonEncode({'baloto': [], 'revancha': []}), 200);
      }),
    );

    await pumpApp(tester, api);

    // The 4 destinations are present in the NavigationBar. Finders are
    // scoped to the bar as good practice, even though the Home quick
    // access tiles were replaced by a single Verify CTA.
    Finder navLabel(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

    expect(navLabel('Inicio'), findsOneWidget);
    expect(navLabel('Verificar'), findsOneWidget);
    expect(navLabel('Generador Aleatorio'), findsOneWidget);
    expect(navLabel('Histórico'), findsOneWidget);

    // Tap the generator destination: its screen becomes visible.
    await tester.tap(navLabel('Generador Aleatorio'));
    await tester.pumpAndSettle();
    expect(find.text('¡Prueba tu suerte!'), findsOneWidget);

    // Switch to Histórico: its AppBar title appears.
    await tester.tap(navLabel('Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de Sorteos'), findsOneWidget);

    // Back to Inicio: the results cards are visible again.
    await tester.tap(navLabel('Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('BALOTO'), findsOneWidget);
    expect(find.text('REVANCHA'), findsOneWidget);
  });

  testWidgets('has a refresh button that re-requests the endpoint', (
    tester,
  ) async {
    var callCount = 0;

    final api = apiWith(
      MockClient((request) async {
        // Only the last-draw endpoint counts: the shell also prefetches
        // /baloto/historico at startup.
        if (request.url.path == '/baloto/ultimo') callCount++;
        return http.Response(jsonEncode(ultimoJson), 200);
      }),
    );

    await pumpApp(tester, api);
    expect(callCount, 1);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(callCount, 2);
  });

  testWidgets('splash shows the credit and version, then enters the app', (
    tester,
  ) async {
    final api = apiWith(
      MockClient((request) async {
        if (request.url.path == '/baloto/ultimo') {
          return http.Response(jsonEncode(ultimoJson), 200);
        }
        return http.Response(jsonEncode({'baloto': [], 'revancha': []}), 200);
      }),
    );

    await tester.pumpWidget(MyApp(api: api, mostrarSplash: true));
    await tester.pump(); // primer frame de la animación de entrada

    // Crédito institucional y versión visibles durante el splash.
    expect(
      find.text('© 2026 Gaelectronica. Todos los derechos reservados.'),
      findsOneWidget,
    );
    expect(
      find.text('Herramienta desarrollada por el Gaelectronica.'),
      findsOneWidget,
    );
    expect(find.text('v1.0.0'), findsOneWidget);

    // Avanza el reloj de pruebas: la animación de entrada termina a los
    // 900 ms y pumpAndSettle se detendría ahí (sin frames programados),
    // así que se avanza explícitamente hasta disparar el Timer de 2 s.
    await tester.pump(const Duration(seconds: 2));
    // Completa el fundido de 600 ms hacia el shell.
    await tester.pumpAndSettle();

    // Ya estamos en el shell: el splash desapareció.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('v1.0.0'), findsNothing);
  });
}
