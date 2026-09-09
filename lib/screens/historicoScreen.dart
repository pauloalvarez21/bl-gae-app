import 'package:flutter/material.dart';

import 'package:bl_app/services/balotoApi.dart';
import 'package:bl_app/models/sorteo.dart';
import 'package:bl_app/config/appTheme.dart';
import 'package:bl_app/widgets/balota.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key, this.api});

  /// API a usar; en pruebas se puede inyectar una versión mockeada.
  final BalotoApi? api;

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen>
    with SingleTickerProviderStateMixin {
  late final BalotoApi _api;
  late TabController _tabController;

  // Se crea una sola vez en initState (no en build).
  late Future<Historico> _historico;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? BalotoApi();
    // 2 pestañas: Baloto y Revancha
    _tabController = TabController(length: 2, vsync: this);
    _historico = _api.getHistorico();
  }

  Future<void> _recargar() async {
    setState(() {
      _historico = _api.getHistorico();
    });
    await _historico;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de Sorteos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _recargar,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: AppColors.cardBorder,
          indicatorColor: AppColors.baloto,
          labelColor: AppColors.baloto,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'BALOTO', icon: Icon(Icons.emoji_events, size: 18)),
            Tab(text: 'REVANCHA', icon: Icon(Icons.star, size: 18)),
          ],
        ),
      ),
      body: FutureBuilder<Historico>(
        future: _historico,
        builder: (context, snapshot) {
          // A) Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // B) Error
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      color: AppColors.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudieron cargar los datos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _recargar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          // C) Éxito
          else if (snapshot.hasData) {
            final data = snapshot.data!;
            final balotoList = data.baloto;
            final revanchaList = data.revancha;

            return TabBarView(
              controller: _tabController,
              children: [
                _buildListView(balotoList, AppColors.baloto),
                _buildListView(revanchaList, AppColors.revancha),
              ],
            );
          }
          return const Center(
            child: Text(
              'Sin datos disponibles',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        },
      ),
    );
  }

  // Widget reutilizable para pintar la lista de sorteos
  Widget _buildListView(List<SorteoHistorico> sorteos, Color color) {
    if (sorteos.isEmpty) {
      return const Center(
        child: Text(
          'No hay sorteos registrados aún.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sorteos.length,
      itemBuilder: (context, index) {
        final sorteo = sorteos[index];
        final fecha = sorteo.fecha;
        final numeroSorteo = sorteo.numeroSorteo;
        final numeros = sorteo.numeros;
        final superNumero = sorteo.superbalota;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
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
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Números principales
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final num in numeros)
                      Balota(numero: num, color: color, size: 40),
                  ],
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Balota(
                      numero: superNumero,
                      color: AppColors.superbalota,
                      size: 36,
                      isSuper: true,
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
