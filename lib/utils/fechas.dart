import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Formatea la fecha de un sorteo para la UI.
///
/// La API entrega las fechas en ISO-8601 (`2026-09-05`); mostrarlas
/// crudas se ve técnico. Aquí se convierten a un formato corto en
/// español: `5 sep 2026`.
///
/// Si el string no se puede parsear (formato inesperado del backend),
/// se devuelve el original tal cual — mejor una fecha "fea" que
/// ninguna o una inventada.

// Los datos de localización de intl no vienen cargados por defecto y
// `DateFormat('…', 'es')` lanza LocaleDataException sin ellos. Se
// inicializan una sola vez, la primera vez que se formatea. Con ruta
// `null` usa los datos embebidos en el paquete (no hay I/O), de modo
// que ni la app ni los tests necesitan inicializar nada por su cuenta.
bool _localeInicializado = false;
DateFormat? _formateador;

String formatearFecha(String iso) {
  final fecha = DateTime.tryParse(iso);
  if (fecha == null) return iso;

  if (!_localeInicializado) {
    initializeDateFormatting('es', null);
    _localeInicializado = true;
  }

  // El formateador se crea una sola vez y se reutiliza (cada llamada
  // de lista del histórico pasa por aquí).
  return (_formateador ??= DateFormat('d MMM y', 'es')).format(fecha);
}
