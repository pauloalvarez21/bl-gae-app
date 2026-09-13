import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:bl_app/config/apiConfig.dart';
import 'package:bl_app/models/sorteo.dart';
import 'package:bl_app/services/cachedContentStore.dart';

/// Excepción de la API con un mensaje listo para mostrar en la UI.
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

/// Origen de los datos devueltos por la API.
enum OrigenDatos {
  /// Respuesta fresca del servidor.
  red,

  /// Servido desde el caché offline porque la petición falló.
  cache,
}

/// Resultado de una consulta con su origen, para que la UI pueda
/// avisar cuando lo que se muestra viene del caché offline.
class ResultadoEnLinea<T> {
  const ResultadoEnLinea(this.dato, this.origen);

  final T dato;
  final OrigenDatos origen;

  /// `true` si el dato NO vino del servidor sino del caché.
  bool get desdeCache => origen == OrigenDatos.cache;
}

/// Servicio central de la API de Baloto.
///
/// TODAS las llamadas HTTP de la app viven aquí: las pantallas solo
/// consumen métodos tipados y nunca importan `package:http`.
class BalotoApi {
  BalotoApi({http.Client? client, Duration? timeout, CachedContentStore? cache})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: ApiConfig.timeoutSeconds),
      _cache = cache ?? CachedContentStore();

  final http.Client _client;
  final Duration _timeout;
  final CachedContentStore _cache;

  /// Último resultado de Baloto y Revancha.
  ///
  /// Con caché offline: cada respuesta exitosa se persiste y, si la
  /// petición falla por red, se devuelve el último dato guardado con
  /// `origen: OrigenDatos.cache` (los errores de respuesta HTTP con
  /// cuerpo — 4xx/5xx con JSON — se respetan: el caché solo rescata
  /// de fallos de *conexión*).
  Future<ResultadoEnLinea<UltimoResultado>> getUltimo() async {
    try {
      final json = await _getJson(_uri('/baloto/ultimo'));
      final resultado = UltimoResultado.fromJson(json);
      await _cache.guardarUltimo(resultado);
      return ResultadoEnLinea(resultado, OrigenDatos.red);
    } on ApiException {
      final cacheado = _cache.leerUltimo();
      if (cacheado != null) {
        return ResultadoEnLinea(cacheado, OrigenDatos.cache);
      }
      rethrow;
    }
  }

  /// Histórico de sorteos de Baloto y Revancha.
  ///
  /// El backend ya no pagina: devuelve la lista completa en una sola
  /// respuesta (sin parámetros `page`/`limit`). Con caché offline con
  /// la misma semántica que [getUltimo].
  Future<ResultadoEnLinea<Historico>> getHistorico() async {
    try {
      final json = await _getJson(_uri('/baloto/historico'));
      final historico = Historico.fromJson(json);
      await _cache.guardarHistorico(historico);
      return ResultadoEnLinea(historico, OrigenDatos.red);
    } on ApiException {
      final cacheado = _cache.leerHistorico();
      if (cacheado != null) {
        return ResultadoEnLinea(cacheado, OrigenDatos.cache);
      }
      rethrow;
    }
  }

  /// Verifica una combinación contra el último sorteo.
  Future<Verificacion> verificar({
    required List<int> numeros,
    required int superbalota,
  }) async {
    final uri = _uri('/baloto/verificar').replace(
      queryParameters: {
        'numeros': numeros.join(','),
        'superbalota': '$superbalota',
      },
    );
    final json = await _getJson(uri);
    return Verificacion.fromJson(json);
  }

  // ---------- Internos ----------

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  /// GET que devuelve JSON decodificado o lanza [ApiException].
  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    http.Response response;

    try {
      response = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw ApiException('La conexión tardó demasiado. Intenta de nuevo.');
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }

    final body = _decode(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw ApiException(
      _errorMessageFrom(body) ?? 'Error del servidor (${response.statusCode})',
    );
  }

  dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      throw ApiException('Respuesta inválida del servidor.');
    }
  }

  /// Extrae el mensaje de error de la API (puede venir como String o Lista).
  String? _errorMessageFrom(dynamic body) {
    if (body is! Map<String, dynamic>) return null;
    final message = body['message'];
    if (message is List) return message.join(', ');
    if (message is String && message.isNotEmpty) return message;
    if (message != null) return message.toString();
    return null;
  }
}
