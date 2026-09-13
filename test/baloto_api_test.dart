// Unit tests for BalotoApi using a mocked http.Client (http.testing).
//
// No real network calls are made: every response is simulated in memory.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bl_app/services/balotoApi.dart';

void main() {
  group('BalotoApi', () {
    group('getUltimo', () {
      test('parses the last draw correctly on 200', () async {
        http.Request? capturedRequest;

        final mockClient = MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({
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
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final api = BalotoApi(client: mockClient);
        final result = await api.getUltimo();

        expect(capturedRequest!.method, 'GET');
        expect(
          capturedRequest!.url.toString(),
          'https://bl-gae-api.onrender.com/baloto/ultimo',
        );

        expect(result.origen, OrigenDatos.red);
        expect(result.dato.baloto.fecha, '2026-09-05');
        expect(result.dato.baloto.numeros, [5, 12, 23, 34, 42]);
        expect(result.dato.baloto.superbalota, 14);
        expect(result.dato.revancha.numeros, [1, 2, 3, 4, 5]);
        expect(result.dato.revancha.superbalota, 7);
      });

      test('throws ApiException with server message on 500', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'message': 'Internal server error'}),
            500,
          );
        });

        final api = BalotoApi(client: mockClient);

        await expectLater(
          api.getUltimo(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Internal server error',
            ),
          ),
        );
      });
    });

    group('getHistorico', () {
      test('parses both draw lists on 200', () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/baloto/historico');

          return http.Response(
            jsonEncode({
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
              ],
              'revancha': [
                {
                  'sorteo': 5221,
                  'fecha': '2026-09-05',
                  'numeros': [6, 11, 22, 33, 42],
                  'superbalota': 8,
                },
              ],
            }),
            200,
          );
        });

        final api = BalotoApi(client: mockClient);
        final historico = await api.getHistorico();

        expect(historico.origen, OrigenDatos.red);
        expect(historico.dato.baloto, hasLength(2));
        expect(historico.dato.baloto.first.numeroSorteo, 5221);
        expect(historico.dato.baloto.first.fecha, '2026-09-05');
        expect(historico.dato.baloto[1].numeros, [3, 9, 17, 28, 40]);

        expect(historico.dato.revancha, hasLength(1));
        expect(historico.dato.revancha.first.superbalota, 8);
      });

      test('does not send page or limit query params anymore', () async {
        Uri? capturedUri;

        final mockClient = MockClient((request) async {
          capturedUri = request.url;

          return http.Response(jsonEncode({'baloto': [], 'revancha': []}), 200);
        });

        final api = BalotoApi(client: mockClient);
        await api.getHistorico();

        // The backend removed server-side pagination: the request must
        // go out without page/limit params.
        expect(capturedUri!.path, '/baloto/historico');
        expect(capturedUri!.queryParameters, isEmpty);
      });

      test('tolerates missing keys returning empty lists', () async {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({}), 200);
        });

        final api = BalotoApi(client: mockClient);
        final historico = await api.getHistorico();

        expect(historico.dato.baloto, isEmpty);
        expect(historico.dato.revancha, isEmpty);
      });
    });

    group('verificar', () {
      test('sends numbers and superbalota as query params', () async {
        Uri? capturedUri;

        final mockClient = MockClient((request) async {
          capturedUri = request.url;

          return http.Response(
            jsonEncode({
              'fecha': '2026-09-05',
              'baloto': {
                'ganador': false,
                'categoria': 'Sin premio',
                'premio': 0,
                'aciertos': {'numeros': 3, 'superbalota': false},
                'numerosGanadores': [5, 12, 23, 34, 42],
                'superbalotaGanadora': 14,
              },
              'revancha': {
                'ganador': true,
                'categoria': 'Acierto 4 + Superbalota',
                'premio': 540000,
                'aciertos': {'numeros': 4, 'superbalota': true},
                'numerosGanadores': [5, 12, 23, 34, 42],
                'superbalotaGanadora': 14,
              },
            }),
            200,
          );
        });

        final api = BalotoApi(client: mockClient);
        final result = await api.verificar(
          numeros: [5, 12, 23, 34, 42],
          superbalota: 14,
        );

        // The service must URL-encode the query properly.
        expect(capturedUri!.path, '/baloto/verificar');
        expect(capturedUri!.queryParameters['numeros'], '5,12,23,34,42');
        expect(capturedUri!.queryParameters['superbalota'], '14');

        expect(result.fecha, '2026-09-05');
        expect(result.baloto.ganador, isFalse);
        expect(result.baloto.aciertos.numeros, 3);
        expect(result.revancha.ganador, isTrue);
        expect(result.revancha.premio, 540000);
      });

      test('joins validation error lists from the API (400)', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'message': [
                'numeros must have 5 items',
                'superbalota must be between 1 and 16',
              ],
            }),
            400,
          );
        });

        final api = BalotoApi(client: mockClient);

        await expectLater(
          api.verificar(numeros: [1], superbalota: 99),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'numeros must have 5 items, superbalota must be between 1 and 16',
            ),
          ),
        );
      });
    });

    group('error handling', () {
      test('throws ApiException on malformed JSON', () async {
        final mockClient = MockClient((request) async {
          return http.Response('<html>gateway error</html>', 200);
        });

        final api = BalotoApi(client: mockClient);

        await expectLater(api.getUltimo(), throwsA(isA<ApiException>()));
      });

      test(
        'translates TimeoutException into a friendly ApiException',
        () async {
          // Simulates a hung request: the future never responds.
          final mockClient = MockClient(
            (request) => Completer<http.Response>().future,
          );

          final api = BalotoApi(
            client: mockClient,
            timeout: const Duration(milliseconds: 50),
          );

          await expectLater(
            api.getUltimo(),
            throwsA(
              isA<ApiException>().having(
                (e) => e.message,
                'message',
                contains('demasiado'),
              ),
            ),
          );
        },
      );
    });
  });
}
