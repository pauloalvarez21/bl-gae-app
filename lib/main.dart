import 'package:bl_app/screens/homeScreen.dart';
import 'package:bl_app/services/balotoApi.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Ejemplo de cómo integrarlo en una aplicación completa
class MyApp extends StatelessWidget {
  const MyApp({super.key, this.api});

  /// Punto de inyección para pruebas: permite pasar un [BalotoApi]
  /// mockeado y así evitar llamadas de red reales en los tests.
  final BalotoApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        //brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        //brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system, // Usa el tema del sistema
      home: HomeScreen(api: api),
    );
  }
}
