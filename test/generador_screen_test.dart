// Smoke tests for GeneradorScreen: the shuffle animation runs with real
// timers, then the final combination appears and is copyable.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bl_app/screens/generadorScreen.dart';

Future<void> generateCombination(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: GeneradorScreen()));

  // Nothing generated yet: the copy button is hidden.
  expect(find.text('Copiar combinación'), findsNothing);

  await tester.tap(find.text('GENERAR COMBINACIÓN'));
  // Advances through the 800ms shuffle (periodic timer + delayed future)
  // until no more frames are scheduled.
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('generates a valid combination after the shuffle animation', (
    tester,
  ) async {
    await generateCombination(tester);

    // The copy button only appears once a final combination exists.
    expect(find.text('Copiar combinación'), findsOneWidget);
    expect(find.text('GENERAR COMBINACIÓN'), findsOneWidget);

    // 5 number circles + 1 superbalota circle.
    expect(find.byType(AnimatedScale), findsNWidgets(6));
  });

  testWidgets('copies the combination and shows the confirmation snackbar', (
    tester,
  ) async {
    await generateCombination(tester);

    await tester.tap(find.text('Copiar combinación'));
    await tester.pump();

    expect(find.text('¡Combinación copiada al portapapeles!'), findsOneWidget);

    // Let the snackbar's 2s auto-hide timer finish so no timer is left
    // pending when the test ends.
    await tester.pump(const Duration(seconds: 3));
  });
}
