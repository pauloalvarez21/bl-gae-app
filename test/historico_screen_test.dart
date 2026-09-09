// Widget tests for HistoricoScreen: tab switching and list rendering.
// All API calls go through a mocked BalotoApi (no real network).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bl_app/screens/historicoScreen.dart';
import 'package:bl_app/services/balotoApi.dart';

/// Histórico with several draws in Baloto and a single Revancha draw.
/// Single page (totalPaginas: 1) so the pager bar stays hidden.
const historicoJson = {
  'baloto': [
    {
      'sorteo': 5221,
      'fecha': '2026-09-05',
      'numeros': [5, 12, 23, 34, 42],
      'superbalota': 14,
    },
    {
      'sorteo': 5220,
      'fecha': '2026-09-02',
      'numeros': [3, 9, 17, 28, 40],
      'superbalota': 2,
    },
    {
      'sorteo': 5219,
      'fecha': '2026-08-29',
      'numeros': [1, 8, 15, 22, 39],
      'superbalota': 9,
    },
  ],
  'revancha': [
    {
      'sorteo': 5221,
      'fecha': '2026-09-05',
      'numeros': [6, 11, 22, 33, 42],
      'superbalota': 8,
    },
  ],
  'paginacion': {
    'paginaActual': 1,
    'totalPaginas': 1,
    'resultadosPorPagina': 10,
  },
};

/// Multi-page histórico: the pager bar becomes visible.
const historicoPaginadoJson = {
  'baloto': [
    {
      'sorteo': 5221,
      'fecha': '2026-09-05',
      'numeros': [5, 12, 23, 34, 42],
      'superbalota': 14,
    },
  ],
  'revancha': [
    {
      'sorteo': 5221,
      'fecha': '2026-09-05',
      'numeros': [6, 11, 22, 33, 42],
      'superbalota': 8,
    },
  ],
  'paginacion': {
    'paginaActual': 1,
    'totalPaginas': 3,
    'resultadosPorPagina': 10,
  },
};

/// Page 2 of the multi-page histórico: different draws, new metadata.
const historicoPagina2Json = {
  'baloto': [
    {
      'sorteo': 5218,
      'fecha': '2026-08-26',
      'numeros': [2, 10, 20, 30, 41],
      'superbalota': 5,
    },
  ],
  'revancha': [],
  'paginacion': {
    'paginaActual': 2,
    'totalPaginas': 3,
    'resultadosPorPagina': 10,
  },
};

/// Same multi-page histórico but served with limit=25.
const historicoLimit25Json = {
  'baloto': [
    {
      'sorteo': 5221,
      'fecha': '2026-09-05',
      'numeros': [5, 12, 23, 34, 42],
      'superbalota': 14,
    },
  ],
  'revancha': [
    {
      'sorteo': 5221,
      'fecha': '2026-09-05',
      'numeros': [6, 11, 22, 33, 42],
      'superbalota': 8,
    },
  ],
  'paginacion': {
    'paginaActual': 1,
    'totalPaginas': 2,
    'resultadosPorPagina': 25,
  },
};

BalotoApi apiWith(http.Client client) => BalotoApi(client: client);

Future<void> pumpScreen(WidgetTester tester, BalotoApi api) async {
  // Superficie más alta que el viewport por defecto (800x600): el campo
  // de búsqueda empuja la tercera tarjeta fuera de pantalla y el
  // ListView.builder no la construye.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: HistoricoScreen(api: api)));
  // One frame to build the FutureBuilder's pending state...
  await tester.pump();
  // ...and one more so the completed mock future renders the data.
  await tester.pump();
}

/// Switches to the tab with the given label ('BALOTO' / 'REVANCHA').
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a loading indicator while the request is in flight', (
    tester,
  ) async {
    final pending = Completer<http.Response>();

    final api = apiWith(MockClient((request) => pending.future));

    await pumpScreenWithoutSettling(tester, api);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Tabs are still present above the loading body.
    expect(find.text('BALOTO'), findsOneWidget);
    expect(find.text('REVANCHA'), findsOneWidget);

    // Complete to avoid a pending future after the test.
    pending.complete(http.Response(jsonEncode(historicoJson), 200));
    await tester.pump();
  });

  testWidgets('renders the BALOTO tab with all its draws', (tester) async {
    final api = apiWith(
      MockClient((request) async {
        expect(request.url.path, '/baloto/historico');
        return http.Response(jsonEncode(historicoJson), 200);
      }),
    );

    await pumpScreen(tester, api);

    // BALOTO is the first tab, so it is visible by default.
    expect(find.text('Sorteo #5221'), findsOneWidget);
    expect(find.text('Sorteo #5220'), findsOneWidget);
    expect(find.text('Sorteo #5219'), findsOneWidget);

    // Dates for each draw.
    expect(find.text('2026-09-05'), findsOneWidget);
    expect(find.text('2026-09-02'), findsOneWidget);
    expect(find.text('2026-08-29'), findsOneWidget);

    // Padded numbers from the first card ("05", not "5").
    expect(find.text('05'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);

    // Superbalota badges (one per visible card; the list may recycle
    // off-screen items, so we only assert on the first draw's badge).
    expect(find.text('Super: '), findsWidgets);
  });

  testWidgets('switching to REVANCHA shows only its draws', (tester) async {
    final api = apiWith(
      MockClient((request) async {
        return http.Response(jsonEncode(historicoJson), 200);
      }),
    );

    await pumpScreen(tester, api);

    await tapTab(tester, 'REVANCHA');

    // Revancha's single draw is visible...
    expect(find.text('Sorteo #5221'), findsOneWidget);
    expect(find.text('2026-09-05'), findsOneWidget);
    expect(find.text('08'), findsOneWidget); // its superbalota

    // ...and Baloto's other draws are not (page changed).
    expect(find.text('Sorteo #5220'), findsNothing);
    expect(find.text('Sorteo #5219'), findsNothing);

    // Switching back restores the Baloto list.
    await tapTab(tester, 'BALOTO');
    expect(find.text('Sorteo #5220'), findsOneWidget);
    expect(find.text('Sorteo #5219'), findsOneWidget);
  });

  testWidgets('shows the empty message when a list has no draws', (
    tester,
  ) async {
    final api = apiWith(
      MockClient((request) async {
        return http.Response(jsonEncode({'baloto': [], 'revancha': []}), 200);
      }),
    );

    await pumpScreen(tester, api);

    expect(find.text('No hay sorteos registrados aún.'), findsOneWidget);

    // The empty message is also shown on the Revancha tab.
    await tapTab(tester, 'REVANCHA');
    expect(find.text('No hay sorteos registrados aún.'), findsOneWidget);
  });

  testWidgets('shows the error UI when the API fails', (tester) async {
    final api = apiWith(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'service unavailable'}),
          503,
        );
      }),
    );

    await pumpScreen(tester, api);

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.textContaining('service unavailable'), findsOneWidget);
  });

  testWidgets('renders exactly one card per draw in the BALOTO tab', (
    tester,
  ) async {
    final api = apiWith(
      MockClient((request) async {
        return http.Response(jsonEncode(historicoJson), 200);
      }),
    );

    await pumpScreen(tester, api);

    // The baloto list has 3 draws -> 3 cards with a "Sorteo #" header.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Card &&
            find
                .descendant(
                  of: find.byWidget(widget),
                  matching: find.textContaining('Sorteo #'),
                )
                .evaluate()
                .isNotEmpty,
      ),
      findsNWidgets(3),
    );
  });

  testWidgets(
    'hides navigation controls but keeps the size selector with one page',
    (tester) async {
      final api = apiWith(
        MockClient((request) async {
          return http.Response(jsonEncode(historicoJson), 200);
        }),
      );

      await pumpScreen(tester, api);

      // Single page: no pager indicator nor navigation buttons...
      expect(find.text('Pág. 1 de 1'), findsNothing);
      expect(find.byIcon(Icons.first_page), findsNothing);
      expect(find.byIcon(Icons.last_page), findsNothing);

      // ...but the page-size selector stays visible.
      expect(find.text('10'), findsOneWidget);
    },
  );

  testWidgets('shows the pager and requests the next page when tapping it', (
    tester,
  ) async {
    final requestedPages = <String>[];

    final api = apiWith(
      MockClient((request) async {
        requestedPages.add(request.url.queryParameters['page'] ?? '1');
        final page = int.parse(requestedPages.last);
        return http.Response(
          jsonEncode(page == 1 ? historicoPaginadoJson : historicoPagina2Json),
          200,
        );
      }),
    );

    await pumpScreen(tester, api);

    // Multi-page response -> pager bar is visible.
    expect(find.text('Pág. 1 de 3'), findsOneWidget);

    // On the first page, backward controls are disabled.
    final backButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.first_page),
    );
    expect(backButton.onPressed, isNull);

    // Go to page 2: the mock serves different draws.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Pág. 2 de 3'), findsOneWidget);
    expect(find.text('Sorteo #5218'), findsOneWidget);
    expect(find.text('Sorteo #5221'), findsNothing);
    // The first request carried page=1 (limit is always sent).
    expect(requestedPages.first, '1');
  });

  testWidgets('changing the page size reloads page 1 with the new limit', (
    tester,
  ) async {
    final capturedQueries = <Map<String, String>>[];

    final api = apiWith(
      MockClient((request) async {
        capturedQueries.add(request.url.queryParameters);
        final limit = int.parse(request.url.queryParameters['limit'] ?? '10');
        return http.Response(
          jsonEncode(
            limit == 25 ? historicoLimit25Json : historicoPaginadoJson,
          ),
          200,
        );
      }),
    );

    await pumpScreen(tester, api);

    // Default page size is 10 with a multi-page histórico.
    expect(find.text('Pág. 1 de 3'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // the selector chip

    // Open the selector and pick 25.
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25 por página'));
    await tester.pumpAndSettle();

    // The chip now shows 25 and the pager reflects the new metadata.
    expect(find.text('25'), findsOneWidget);
    expect(find.text('Pág. 1 de 2'), findsOneWidget);

    // The reload went back to page 1 with limit=25.
    expect(capturedQueries.last['page'], '1');
    expect(capturedQueries.last['limit'], '25');
  });

  testWidgets('filters draws by draw number as the query is typed', (
    tester,
  ) async {
    final api = apiWith(
      MockClient((request) async {
        return http.Response(jsonEncode(historicoJson), 200);
      }),
    );

    await pumpScreen(tester, api);

    // All three draws are visible before searching.
    expect(find.text('Sorteo #5221'), findsOneWidget);
    expect(find.text('Sorteo #5220'), findsOneWidget);
    expect(find.text('Sorteo #5219'), findsOneWidget);

    // Partial match: "522" keeps 5221 and 5220 (substring match),
    // and drops 5219 ('5219' does not contain '522').
    await tester.enterText(find.byType(TextField), '522');
    await tester.pumpAndSettle();

    expect(find.text('Sorteo #5221'), findsOneWidget);
    expect(find.text('Sorteo #5220'), findsOneWidget);
    expect(find.text('Sorteo #5219'), findsNothing);

    // Clearing the search restores the full list.
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Sorteo #5220'), findsOneWidget);
  });

  testWidgets('shows a no-results message when nothing matches', (
    tester,
  ) async {
    final api = apiWith(
      MockClient((request) async {
        return http.Response(jsonEncode(historicoJson), 200);
      }),
    );

    await pumpScreen(tester, api);

    await tester.enterText(find.byType(TextField), '999');
    await tester.pumpAndSettle();

    expect(
      find.text('Ningún sorteo coincide con "999" en esta página.'),
      findsOneWidget,
    );
    expect(find.text('Sorteo #5221'), findsNothing);

    // The Revancha tab shows the same message for its filtered list.
    await tapTab(tester, 'REVANCHA');
    expect(
      find.text('Ningún sorteo coincide con "999" en esta página.'),
      findsOneWidget,
    );
  });
}

/// Helper for the loading test: pumps without pumpAndSettle because the
/// pending future would never settle.
Future<void> pumpScreenWithoutSettling(
  WidgetTester tester,
  BalotoApi api,
) async {
  await tester.pumpWidget(MaterialApp(home: HistoricoScreen(api: api)));
  await tester.pump();
}
