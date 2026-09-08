import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 2 pestañas: Baloto y Revancha
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 1. Función que consulta el histórico
  Future<Map<String, dynamic>> _consultarHistorico() async {
    final url = Uri.parse('https://bl-gae-api.onrender.com/baloto/historico');
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
        title: const Text('Histórico de Sorteos'),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'BALOTO', icon: Icon(Icons.emoji_events, size: 18)),
            Tab(text: 'REVANCHA', icon: Icon(Icons.star, size: 18)),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _consultarHistorico(),
        builder: (context, snapshot) {
          // A) Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }
          // B) Error
          else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            );
          }
          // C) Éxito
          else if (snapshot.hasData) {
            final data = snapshot.data!;
            // Convertimos las listas JSON a List<Map> de Dart
            final balotoList = List<Map<String, dynamic>>.from(
              data['baloto'] ?? [],
            );
            final revanchaList = List<Map<String, dynamic>>.from(
              data['revancha'] ?? [],
            );

            return TabBarView(
              controller: _tabController,
              children: [
                _buildListView(balotoList, Colors.deepPurple),
                _buildListView(revanchaList, Colors.orange),
              ],
            );
          }
          return const Center(child: Text('Sin datos disponibles'));
        },
      ),
    );
  }

  // Widget reutilizable para pintar la lista de sorteos
  Widget _buildListView(List<Map<String, dynamic>> sorteos, Color color) {
    if (sorteos.isEmpty) {
      return const Center(child: Text('No hay sorteos registrados aún.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sorteos.length,
      itemBuilder: (context, index) {
        final sorteo = sorteos[index];
        final fecha = sorteo['fecha'] ?? 'Fecha desconocida';
        final numeroSorteo = sorteo['sorteo'] ?? 0;
        final numeros = List<int>.from(sorteo['numeros'] ?? []);
        final superNumero = sorteo['superbalota'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado de la tarjeta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sorteo #$numeroSorteo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      fecha,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Números principales
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: numeros.map((num) {
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          num.toString().padLeft(2, '0'), // Formato "05"
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Super Balota / Super Revancha
                Row(
                  children: [
                    const Text(
                      'Super: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        boxShadow: [
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
      },
    );
  }
}
