// Widget tests for the shared ErrorRetryView used by Home and
// Histórico screens: message/detail rendering and the retry callback.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bl_app/widgets/errorRetryView.dart';

Future<void> pumpView(WidgetTester tester, ErrorRetryView view) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: view)));
}

void main() {
  testWidgets('shows icon, message, error detail and retry button', (
    tester,
  ) async {
    var reintentado = 0;

    await pumpView(
      tester,
      ErrorRetryView(
        error: 'Error de conexión: timeout',
        onReintentar: () => reintentado++,
      ),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text('No se pudieron cargar los datos.'), findsOneWidget);
    expect(find.text('Error de conexión: timeout'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('hides the detail line when error is null', (tester) async {
    await pumpView(tester, ErrorRetryView(error: null, onReintentar: () {}));

    expect(find.text('No se pudieron cargar los datos.'), findsOneWidget);
    // Exactly two Texts: the message and the button label — proves no
    // extra technical-detail Text was rendered when error is null.
    expect(find.byType(Text), findsNWidgets(2));
  });

  testWidgets('shows a custom message when provided', (tester) async {
    await pumpView(
      tester,
      ErrorRetryView(
        error: null,
        onReintentar: () {},
        mensaje: 'No se pudo cargar el histórico.',
      ),
    );

    expect(find.text('No se pudo cargar el histórico.'), findsOneWidget);
    expect(find.text('No se pudieron cargar los datos.'), findsNothing);
  });

  testWidgets('retry button invokes the callback', (tester) async {
    var reintentado = 0;

    await pumpView(
      tester,
      ErrorRetryView(error: null, onReintentar: () => reintentado++),
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(reintentado, 1);
  });
}
