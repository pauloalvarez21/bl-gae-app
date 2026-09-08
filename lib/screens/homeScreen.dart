import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:bl_app/screens/historicoScreen.dart';
import 'package:bl_app/screens/verificarScreen.dart';
import 'package:bl_app/screens/generadorScreen.dart';

import 'dart:convert';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 1. Función que consulta el endpoint
  Future<Map<String, dynamic>> _consultarEndpoint() async {
    final url = Uri.parse('https://bl-gae-api.onrender.com/baloto/ultimo');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados Baloto'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Menú Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.deepPurple),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.casino_sharp, color: Colors.deepPurple),
              title: const Text('Generador Aleatorio'),
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GeneradorScreen(),
                  ),
                ),
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.deepPurple),
              title: const Text('Historico'),
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoricoScreen()),
                ),
              },
            ),
            Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.deepPurple),
              title: const Text('Verificar Números'),
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VerificarScreen()),
                ),
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _consultarEndpoint(),
        builder: (context, snapshot) {
          // A) Estado: Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.deepPurple),
                  SizedBox(height: 16),
                  Text(
                    'Consultando resultados...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          // B) Estado: Error
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.orange, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudieron cargar los datos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }
          // C) Estado: Éxito (Datos listos)
          else if (snapshot.hasData) {
            final data = snapshot.data!;

            // Extraemos los datos de Baloto
            final baloto = data['baloto'] as Map<String, dynamic>;
            final fechaBaloto = baloto['fecha'] ?? 'Fecha desconocida';
            final numerosBaloto = List<int>.from(baloto['numeros'] ?? []);
            final superBaloto = baloto['superbalota'] ?? 0;

            // Extraemos los datos de Revancha
            final revancha = data['revancha'] as Map<String, dynamic>;
            final numerosRevancha = List<int>.from(revancha['numeros'] ?? []);
            final superRevancha = revancha['superbalota'] ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- SECCIÓN BALOTO ---
                  _buildLotteryCard(
                    title: 'BALOTO',
                    fecha: fechaBaloto,
                    numeros: numerosBaloto,
                    superNumero: superBaloto,
                    color: Colors.deepPurple,
                    icon: Icons.emoji_events,
                  ),

                  const SizedBox(height: 24),

                  // --- SECCIÓN REVANCHA ---
                  _buildLotteryCard(
                    title: 'REVANCHA',
                    fecha: fechaBaloto, // Usualmente es la misma fecha
                    numeros: numerosRevancha,
                    superNumero: superRevancha,
                    color: Colors.orange,
                    icon: Icons.star,
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Sin datos disponibles'));
        },
      ),
    );
  }

  // Widget reutilizable para pintar las tarjetas de resultados
  Widget _buildLotteryCard({
    required String title,
    required String fecha,
    required List<int> numeros,
    required int superNumero,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              fecha,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Números principales
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: numeros.map((numero) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      numero.toString().padLeft(2, '0'), // Ej: "05"
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Super Balota / Super Revancha
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title == 'BALOTO' ? 'Super Balota: ' : 'Super Revancha: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.shade800, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      superNumero.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black26, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
