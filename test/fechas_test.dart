// Unit tests for the date formatting helper used by the screens.

import 'package:flutter_test/flutter_test.dart';

import 'package:bl_app/utils/fechas.dart';

void main() {
  group('formatearFecha', () {
    test('formats an ISO date as short Spanish date', () {
      expect(formatearFecha('2026-09-05'), '5 sept 2026');
    });

    test('formats the first day of the month without leading zero', () {
      expect(formatearFecha('2026-01-01'), '1 ene 2026');
    });

    test('returns the original string when it cannot be parsed', () {
      expect(formatearFecha('no-es-una-fecha'), 'no-es-una-fecha');
    });

    test('returns the original string when it is empty', () {
      expect(formatearFecha(''), '');
    });
    test('parses a full ISO timestamp, ignoring the time part', () {
      expect(formatearFecha('2026-09-05T20:30:00.000Z'), '5 sept 2026');
    });
  });
  test('accepts a date-only string with spaces as separators', () {
    expect(formatearFecha('2026-12-25'), '25 dic 2026');
  });
}
