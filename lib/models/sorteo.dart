// Modelos tipados que representan las respuestas de la API de Baloto.
//
// Convertir el JSON a objetos con tipos da autocompletado en el editor
// y convierte los errores de claves en errores de compilación.

// ---------- Helpers privados de parseo ----------

int _toInt(dynamic value, [int defaultValue = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

List<int> _toIntList(dynamic value) {
  if (value is List) return value.map(_toInt).toList();
  return [];
}

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return [];
}

// ---------- /baloto/ultimo ----------

/// Un sorteo con sus resultados.
class Sorteo {
  final String fecha;
  final List<int> numeros;
  final int superbalota;

  const Sorteo({
    required this.fecha,
    required this.numeros,
    required this.superbalota,
  });

  factory Sorteo.fromJson(Map<String, dynamic> json) {
    return Sorteo(
      fecha: json['fecha']?.toString() ?? 'Fecha desconocida',
      numeros: _toIntList(json['numeros']),
      superbalota: _toInt(json['superbalota']),
    );
  }
}

/// Respuesta de `/baloto/ultimo`: incluye Baloto y Revancha.
class UltimoResultado {
  final Sorteo baloto;
  final Sorteo revancha;

  const UltimoResultado({required this.baloto, required this.revancha});

  factory UltimoResultado.fromJson(Map<String, dynamic> json) {
    return UltimoResultado(
      baloto: Sorteo.fromJson(json['baloto'] ?? <String, dynamic>{}),
      revancha: Sorteo.fromJson(json['revancha'] ?? <String, dynamic>{}),
    );
  }
}

// ---------- /baloto/historico ----------

/// Un sorteo del histórico (incluye el número de sorteo).
class SorteoHistorico {
  final int numeroSorteo;
  final String fecha;
  final List<int> numeros;
  final int superbalota;

  const SorteoHistorico({
    required this.numeroSorteo,
    required this.fecha,
    required this.numeros,
    required this.superbalota,
  });

  factory SorteoHistorico.fromJson(Map<String, dynamic> json) {
    return SorteoHistorico(
      numeroSorteo: _toInt(json['sorteo']),
      fecha: json['fecha']?.toString() ?? 'Fecha desconocida',
      numeros: _toIntList(json['numeros']),
      superbalota: _toInt(json['superbalota']),
    );
  }
}

/// Respuesta de `/baloto/historico`: listas de Baloto y Revancha.

class Historico {
  final List<SorteoHistorico> baloto;
  final List<SorteoHistorico> revancha;

  /// Metadatos de paginación que devuelve el backend.
  /// Puede ser null si el servidor aún no envía el bloque `paginacion`.
  final Paginacion? paginacion;

  const Historico({
    required this.baloto,
    required this.revancha,
    this.paginacion,
  });

  factory Historico.fromJson(Map<String, dynamic> json) {
    final paginacionJson = json['paginacion'];
    return Historico(
      baloto: _toMapList(json['baloto']).map(SorteoHistorico.fromJson).toList(),
      revancha: _toMapList(json['revancha'])
          .map(SorteoHistorico.fromJson)
          .toList(),
      paginacion: paginacionJson is Map<String, dynamic>
          ? Paginacion.fromJson(paginacionJson)
          : null,
    );
  }
}

/// Bloque `paginacion` de la respuesta `/baloto/historico`.
class Paginacion {
  final int paginaActual;
  final int totalPaginas;
  final int resultadosPorPagina;

  const Paginacion({
    required this.paginaActual,
    required this.totalPaginas,
    required this.resultadosPorPagina,
  });

  factory Paginacion.fromJson(Map<String, dynamic> json) {
    return Paginacion(
      paginaActual: _toInt(json['paginaActual'], 1),
      totalPaginas: _toInt(json['totalPaginas'], 1),
      resultadosPorPagina: _toInt(json['resultadosPorPagina'], 10),
    );
  }
}

// ---------- /baloto/verificar ----------

/// Cantidad de aciertos de una verificación.
class Aciertos {
  final int numeros;
  final bool superbalota;

  const Aciertos({required this.numeros, required this.superbalota});

  factory Aciertos.fromJson(Map<String, dynamic> json) {
    return Aciertos(
      numeros: _toInt(json['numeros']),
      superbalota: json['superbalota'] == true,
    );
  }
}

/// Resultado de la verificación para un juego (Baloto o Revancha).
class ResultadoVerificacion {
  final bool ganador;
  final String categoria;
  final int premio;
  final Aciertos aciertos;
  final List<int> numerosGanadores;
  final int superbalotaGanadora;

  const ResultadoVerificacion({
    required this.ganador,
    required this.categoria,
    required this.premio,
    required this.aciertos,
    required this.numerosGanadores,
    required this.superbalotaGanadora,
  });

  factory ResultadoVerificacion.fromJson(Map<String, dynamic> json) {
    final aciertos = json['aciertos'];
    return ResultadoVerificacion(
      ganador: json['ganador'] == true,
      categoria: json['categoria']?.toString() ?? 'Sin premio',
      premio: _toInt(json['premio']),
      aciertos: aciertos is Map<String, dynamic>
          ? Aciertos.fromJson(aciertos)
          : const Aciertos(numeros: 0, superbalota: false),
      numerosGanadores: _toIntList(json['numerosGanadores']),
      superbalotaGanadora: _toInt(json['superbalotaGanadora']),
    );
  }
}

/// Respuesta de `/baloto/verificar`.
class Verificacion {
  final String fecha;
  final ResultadoVerificacion baloto;
  final ResultadoVerificacion revancha;

  const Verificacion({
    required this.fecha,
    required this.baloto,
    required this.revancha,
  });

  factory Verificacion.fromJson(Map<String, dynamic> json) {
    return Verificacion(
      fecha: json['fecha']?.toString() ?? 'Fecha desconocida',
      baloto: ResultadoVerificacion.fromJson(
        json['baloto'] ?? <String, dynamic>{},
      ),
      revancha: ResultadoVerificacion.fromJson(
        json['revancha'] ?? <String, dynamic>{},
      ),
    );
  }
}
