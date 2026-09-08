import 'dart:math';

/// Reglas del juego Baloto, centralizadas para que la lógica y las
/// pruebas usen los mismos valores.
class BalotoRules {
  BalotoRules._();

  /// Cantidad de números principales.
  static const int cantidadNumeros = 5;

  /// Máximo valor de un número principal (rango 1..43).
  static const int maxNumero = 43;

  /// Máximo valor de la Superbalota (rango 1..16).
  static const int maxSuperbalota = 16;
}

/// Genera combinaciones aleatorias de Baloto.
///
/// El [Random] es inyectable: en producción se usa uno real y en las
/// pruebas uno con semilla fija para obtener resultados deterministas.
class GeneradorNumeros {
  GeneradorNumeros({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Genera una combinación válida: 5 números únicos ordenados
  /// entre 1 y 43, más la Superbalota entre 1 y 16.
  ({List<int> numeros, int superbalota}) generarCombinacion() {
    return (numeros: generarNumeros(), superbalota: generarSuperbalota());
  }

  /// 5 números únicos, ordenados, en el rango 1..43.
  List<int> generarNumeros() {
    final numerosUnicos = <int>{};

    while (numerosUnicos.length < BalotoRules.cantidadNumeros) {
      numerosUnicos.add(_random.nextInt(BalotoRules.maxNumero) + 1);
    }

    final lista = numerosUnicos.toList()..sort();
    return lista;
  }

  /// Un número entre 1 y 16 para la Superbalota.
  int generarSuperbalota() {
    return _random.nextInt(BalotoRules.maxSuperbalota) + 1;
  }
}
