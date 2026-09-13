// Widget tests for the shared CachedDataBanner shown when the UI
// renders data rescued from the offline cache.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bl_app/widgets/cachedDataBanner.dart';

void main() {
  testWidgets('shows the offline message with the cloud icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CachedDataBanner())),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(
      find.text('Datos sin conexión: mostrando el último resultado guardado.'),
      findsOneWidget,
    );
  });
}
