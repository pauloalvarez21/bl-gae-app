// Tests for the offline cache: CachedContentStore round-trips and
// BalotoApi fallback-to-cache behavior, all with in-memory
// SharedPreferences (setMockInitialValues) and MockClient.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bl_app/models/sorteo.dart';
import 'package:bl_app/services/balotoApi.dart';
import 'package:bl_app/services/cachedContentStore.dart';

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

const historicoJson = {
  'baloto': [
    {
      'sorteo': 5001,
      'fecha': '2026-09-05',
      'numeros': [5, 12, 23, 34, 42],
      'superbalota': 14,
    },
  ],
  'revancha': [],
};

Future<CachedContentStore> storeConPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return CachedContentStore(prefs: await SharedPreferences.getInstance());
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CachedContentStore', () {
    test('round-trips the last result through JSON', () async {
      final store = await storeConPrefs();
      final original = UltimoResultado.fromJson(ultimoJson);

      await store.guardarUltimo(original);
      final leido = store.leerUltimo();

      expect(leido, isNotNull);
      expect(leido!.baloto.numeros, original.baloto.numeros);
      expect(leido.baloto.superbalota, original.baloto.superbalota);
      expect(leido.revancha.fecha, original.revancha.fecha);
    });

    test('round-trips the histórico through JSON', () async {
      final store = await storeConPrefs();
      final original = Historico.fromJson(historicoJson);

      await store.guardarHistorico(original);
      final leido = store.leerHistorico();

      expect(leido, isNotNull);
      expect(leido!.baloto.first.numeroSorteo, 5001);
      expect(leido.baloto.first.numeros, [5, 12, 23, 34, 42]);
      expect(leido.revancha, isEmpty);
    });

    test('returns null when nothing was cached', () async {
      final store = await storeConPrefs();

      expect(store.leerUltimo(), isNull);
      expect(store.leerHistorico(), isNull);
    });

    test('treats corrupt JSON as an empty cache', () async {
      final store = await storeConPrefs();
      await store.prefs!.setString('cache_baloto_ultimo_v1', '{no-es-json');

      expect(store.leerUltimo(), isNull);
    });

    test('is no-throw when no prefs instance is set', () async {
      final store = CachedContentStore();

      await store.guardarUltimo(UltimoResultado.fromJson(ultimoJson));
      expect(store.leerUltimo(), isNull);
    });
  });

  group('BalotoApi offline fallback', () {
    test('serves the cached last result when the request fails', () async {
      final store = await storeConPrefs();
      await store.guardarUltimo(UltimoResultado.fromJson(ultimoJson));

      // Sin cache, la misma falla lanzaría ApiException.
      var cache = store;
      final api = BalotoApi(
        client: MockClient(
          (request) async => http.Response('Server down', 500),
        ),
        cache: cache,
      );

      final resultado = await api.getUltimo();
      expect(
        resultado.desdeCache,
        isTrue,
        reason: 'el dato debe marcarse como cacheado',
      );
      expect(resultado.dato.baloto.numeros, [5, 12, 23, 34, 42]);
    });

    test('serves the cached histórico when the connection fails', () async {
      final store = await storeConPrefs();
      await store.guardarHistorico(Historico.fromJson(historicoJson));

      final api = BalotoApi(
        client: MockClient((request) async => throw Exception('no network')),
        cache: store,
      );

      final historico = await api.getHistorico();
      expect(historico.desdeCache, isTrue);
      expect(historico.dato.baloto.first.numeroSorteo, 5001);
    });

    test('rethrows when the request fails and there is no cache', () async {
      final store = await storeConPrefs();
      final api = BalotoApi(
        client: MockClient(
          (request) async => http.Response('Server down', 500),
        ),
        cache: store,
      );

      expect(() => api.getUltimo(), throwsA(isA<ApiException>()));
    });

    test('persists successful responses into the cache', () async {
      final store = await storeConPrefs();
      final api = BalotoApi(
        client: MockClient((request) async {
          if (request.url.path == '/baloto/ultimo') {
            return http.Response(jsonEncode(ultimoJson), 200);
          }
          return http.Response(jsonEncode(historicoJson), 200);
        }),
        cache: store,
      );

      final ultimo = await api.getUltimo();
      expect(ultimo.desdeCache, isFalse);
      expect(store.leerUltimo(), isNotNull);

      final historico = await api.getHistorico();
      expect(historico.desdeCache, isFalse);
      expect(store.leerHistorico(), isNotNull);
    });
  });
}
