/// Configuración central de la API.
///
/// Si la URL del backend cambia, solo se edita este archivo.
class ApiConfig {
  ApiConfig._();

  /// URL base del backend (sin `/` final).
  static const String baseUrl = 'https://bl-gae-api.onrender.com';

  /// Timeout por defecto para las peticiones (en segundos).
  static const int timeoutSeconds = 15;
}
