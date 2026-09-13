import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:bl_app/models/sorteo.dart';

/// Caché offline del último resultado y del histórico.
///
/// Los datos se guardan como JSON en `shared_preferences` bajo claves
/// fijas. La instancia se llena con [cargarPrefs] una sola vez en
/// `main()`; si por alguna razón no está lista (p. ej. un test que no
/// la inicializó) o falla la lectura/escritura, todos los métodos son
/// no-throw y el caché simplemente se comporta como vacío: la app
/// funciona igual que antes, solo que sin datos offline.
class CachedContentStore {
  CachedContentStore({this.prefs});

  /// Inyectable para pruebas (`SharedPreferences.setMockInitialValues`
  /// + `SharedPreferences.getInstance()`). En producción llega vía
  /// [cargarPrefs].
  SharedPreferences? prefs;

  /// Claves fijas del caché. Cambiarlas invalida el caché viejo de
  /// todos los usuarios (útil si cambia el formato guardado).
  static const _kUltimo = 'cache_baloto_ultimo_v1';
  static const _kHistorico = 'cache_baloto_historico_v1';

  /// Carga la instancia real de SharedPreferences. Llamar UNA vez en
  /// `main()` antes de `runApp`.
  static Future<CachedContentStore> cargarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return CachedContentStore(prefs: prefs);
  }

  // ---------- Último resultado ----------

  Future<void> guardarUltimo(UltimoResultado resultado) async {
    try {
      await prefs?.setString(_kUltimo, jsonEncode(resultado.toJson()));
    } catch (_) {
      // Sin almacenamiento disponible: la app sigue online-only.
    }
  }

  /// Último resultado cacheado, o null si no hay caché válido.
  UltimoResultado? leerUltimo() {
    final crudo = _leer(_kUltimo);
    if (crudo == null) return null;
    try {
      return UltimoResultado.fromJson(
        jsonDecode(crudo) as Map<String, dynamic>,
      );
    } catch (_) {
      return null; // JSON corrupto: se trata como caché vacío.
    }
  }

  // ---------- Histórico ----------

  Future<void> guardarHistorico(Historico historico) async {
    try {
      await prefs?.setString(_kHistorico, jsonEncode(historico.toJson()));
    } catch (_) {
      // Sin almacenamiento disponible: la app sigue online-only.
    }
  }

  /// Histórico cacheado, o null si no hay caché válido.
  Historico? leerHistorico() {
    final crudo = _leer(_kHistorico);
    if (crudo == null) return null;
    try {
      return Historico.fromJson(jsonDecode(crudo) as Map<String, dynamic>);
    } catch (_) {
      return null; // JSON corrupto: se trata como caché vacío.
    }
  }

  // ---------- Internos ----------

  String? _leer(String clave) {
    try {
      return prefs?.getString(clave);
    } catch (_) {
      return null;
    }
  }
}
