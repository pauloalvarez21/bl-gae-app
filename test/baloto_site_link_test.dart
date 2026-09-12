// Widget tests for BalotoSiteLink: URL launching (stubbed), the
// compact AppBar variant and the error SnackBars.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bl_app/main.dart';
import 'package:bl_app/screens/historicoScreen.dart';
import 'package:bl_app/services/balotoApi.dart';
import 'package:bl_app/widgets/balotoSiteLink.dart';

import 'widget_test.dart' show ultimoJson;

/// Valid JSON for /baloto/historico (no pagination anymore).
const historicoJson = {
  'baloto': [
    {
      'sorteo': 5221,
      'fecha': '2026-09-05',
      'numeros': [5, 12, 23, 34, 42],
      'superbalota': 14,
    },
  ],
  'revancha': [],
};

BalotoApi apiWith(http.Client client) => BalotoApi(client: client);

void main() {
  testWidgets('compact variant opens the official results page', (
    tester,
  ) async {
    Uri? launched;

    final original = abrirSitioBaloto;
    abrirSitioBaloto = () async {
      launched = Uri.parse('https://baloto.com/resultados');
      return true;
    };
    addTearDown(() => abrirSitioBaloto = original);

    final api = apiWith(
      MockClient((request) async {
        return http.Response(jsonEncode(historicoJson), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: HistoricoScreen(api: api)));
    await tester.pump();
    await tester.pump();

    // The compact link lives in the AppBar actions.
    expect(find.byTooltip('Más resultados en baloto.com'), findsOneWidget);

    await tester.tap(find.byTooltip('Más resultados en baloto.com'));
    await tester.pump();

    expect(launched, isNotNull);
    expect(launched!.host, 'baloto.com');
    expect(launched!.path, '/resultados');
  });

  testWidgets('home card opens the official results page', (tester) async {
    Uri? launched;

    final original = abrirSitioBaloto;
    abrirSitioBaloto = () async {
      launched = Uri.parse('https://baloto.com/resultados');
      return true;
    };
    addTearDown(() => abrirSitioBaloto = original);

    final api = apiWith(
      MockClient((request) async {
        if (request.url.path == '/baloto/ultimo') {
          return http.Response(jsonEncode(ultimoJson), 200);
        }
        return http.Response(jsonEncode({'baloto': [], 'revancha': []}), 200);
      }),
    );

    // Surface más alta que el viewport por defecto (800x600): la
    // tarjeta queda tras las dos de resultados y la CTA de verificar.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The real shell (splash skipped) so the Home card is visible.
    await tester.pumpWidget(MyApp(api: api, mostrarSplash: false));
    await tester.pump();
    await tester.pump();

    expect(find.text('Más resultados'), findsOneWidget);
    expect(find.text('Histórico completo en baloto.com'), findsOneWidget);

    await tester.tap(find.text('Más resultados'));
    await tester.pump();

    expect(launched, isNotNull);
    expect(launched!.host, 'baloto.com');
  });

  testWidgets('shows a SnackBar when the platform rejects the launch', (
    tester,
  ) async {
    final original = abrirSitioBaloto;
    abrirSitioBaloto = () async => false;
    addTearDown(() => abrirSitioBaloto = original);

    final api = apiWith(
      MockClient((request) async {
        return http.Response(jsonEncode(historicoJson), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: HistoricoScreen(api: api)));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Más resultados en baloto.com'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No se pudo abrir baloto.com/resultados'), findsOneWidget);
  });

  testWidgets('shows a SnackBar when launching throws', (tester) async {
    final original = abrirSitioBaloto;
    abrirSitioBaloto = () async => throw Exception('no browser');
    addTearDown(() => abrirSitioBaloto = original);

    final api = apiWith(
      MockClient((request) async {
        return http.Response(jsonEncode(historicoJson), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: HistoricoScreen(api: api)));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Más resultados en baloto.com'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('No se pudo abrir el navegador. Visita baloto.com/resultados'),
      findsOneWidget,
    );
  });
}
