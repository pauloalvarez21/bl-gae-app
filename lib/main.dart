import 'package:bl_app/screens/generadorScreen.dart';
import 'package:bl_app/screens/historicoScreen.dart';
import 'package:bl_app/screens/homeScreen.dart';
import 'package:bl_app/screens/verificarScreen.dart';
import 'package:bl_app/config/appTheme.dart';
import 'package:bl_app/services/balotoApi.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.api});

  /// Punto de inyección para pruebas: permite pasar un [BalotoApi]
  /// mockeado y así evitar llamadas de red reales en los tests.
  final BalotoApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baloto',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: MainShell(api: api),
    );
  }
}

/// Contenedor principal con navegación inferior: las 4 pantallas
/// viven aquí y se cambia entre ellas con la barra inferior.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.api});

  final BalotoApi? api;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final api = widget.api;

    // IndexedStack mantiene el estado (y el Future ya cargado) de cada
    // pantalla al cambiar de pestaña.
    final pantallas = [
      HomeScreen(api: api, onIrA: _irA),
      VerificarScreen(api: api),
      const GeneradorScreen(),
      HistoricoScreen(api: api),
    ];

    return Scaffold(
      body: IndexedStack(index: _indice, children: pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Verificar',
          ),
          NavigationDestination(
            icon: Icon(Icons.casino_outlined),
            selectedIcon: Icon(Icons.casino),
            label: 'Generador Aleatorio',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }

  /// Navegación programática desde HomeScreen (la CTA "¿Jugaste?").
  void _irA(int indice) => setState(() => _indice = indice);
}
