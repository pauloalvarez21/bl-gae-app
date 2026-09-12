// Widget tests for the shared LoadingView used by Home and Histórico
// screens: optional message rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bl_app/widgets/loadingView.dart';

Future<void> pumpView(WidgetTester tester, LoadingView view) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: view)));
}

void main() {
  testWidgets('shows the spinner and the message when provided', (
    tester,
  ) async {
    await pumpView(
      tester,
      const LoadingView(mensaje: 'Consultando resultados...'),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Consultando resultados...'), findsOneWidget);
  });

  testWidgets('shows only the spinner when there is no message', (
    tester,
  ) async {
    await pumpView(tester, const LoadingView());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}
