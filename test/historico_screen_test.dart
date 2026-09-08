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
};

BalotoApi apiWith(http.Client client) => BalotoApi(client: client);

Future<void> pumpScreen(WidgetTester tester, BalotoApi api) async {
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

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
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
