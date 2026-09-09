import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:bl_app/config/apiConfig.dart';
import 'package:bl_app/models/sorteo.dart';

/// Excepción de la API con un mensaje listo para mostrar en la UI.
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

/// Servicio central de la API de Baloto.
///
/// TODAS las llamadas HTTP de la app viven aquí: las pantallas solo
/// consumen métodos tipados y nunca importan `package:http`.
class BalotoApi {
  BalotoApi({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: ApiConfig.timeoutSeconds);

  final http.Client _client;
  final Duration _timeout;

  /// Último resultado de Baloto y Revancha.
  Future<UltimoResultado> getUltimo() async {
    final json = await _getJson(_uri('/baloto/ultimo'));
    return UltimoResultado.fromJson(json);
  }

  /// Histórico de sorteos, con paginación del lado del servidor.
  ///
  /// [page] y [limit] son opcionales: si se omiten, el backend usa sus
  /// valores por defecto (página 1, 10 resultados por página).
  Future<Historico> getHistorico({int? page, int? limit}) async {
    var uri = _uri('/baloto/historico');
    final params = <String, String>{
      if (page != null) 'page': '$page',
      if (limit != null) 'limit': '$limit',
    };
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    final json = await _getJson(uri);
    return Historico.fromJson(json);
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

  /// Verifica una jugada contra el sorteo de una fecha específica.
  ///
  /// [fecha] debe venir en formato `YYYY-MM-DD`. Si en esa fecha no
  /// hubo sorteo, el backend responde 404 y aquí se lanza [ApiException]
  /// con el mensaje del servidor.
  Future<Verificacion> verificarPorFecha({
    required String fecha,
    required List<int> numeros,
    required int superbalota,
  }) async {
    final uri = _uri('/baloto/verificar-por-fecha').replace(
      queryParameters: {
        'fecha': fecha,
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
