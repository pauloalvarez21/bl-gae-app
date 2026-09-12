import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bl_app/services/balotoApi.dart';
import 'package:bl_app/models/sorteo.dart';
import 'package:bl_app/config/appTheme.dart';
import 'package:bl_app/utils/fechas.dart';
import 'package:bl_app/widgets/balota.dart';
import 'package:bl_app/widgets/balotoSiteLink.dart';
import 'package:bl_app/widgets/errorRetryView.dart';
import 'package:bl_app/widgets/loadingView.dart';

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

  /// Búsqueda local por número de sorteo sobre la lista cargada.
  /// (El backend aún no expone filtro ?sorteo=; cuando lo haga, esto
  /// se puede convertir en búsqueda en servidor sin cambiar la UI.)
  final _busquedaController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? BalotoApi();
    // 2 pestañas: Baloto y Revancha
    _tabController = TabController(length: 2, vsync: this);
    _historico = _api.getHistorico();
  }

  /// Recarga el histórico completo (el backend ya no pagina).
  void _cargar() {
    setState(() {
      _historico = _api.getHistorico();
    });
  }

  Future<void> _recargar() async {
    _cargar();
    await _historico;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busquedaController.dispose();
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
          // El backend ya no pagina: para sorteos más antiguos, el
          // histórico completo vive en el sitio oficial.
          const BalotoSiteLink(compacto: true),
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
            return const LoadingView();
          }
          // B) Error
          else if (snapshot.hasError) {
            return ErrorRetryView(
              error: snapshot.error,
              onReintentar: _recargar,
            );
          }
          // C) Éxito
          else if (snapshot.hasData) {
            final data = snapshot.data!;
            final balotoList = data.baloto;
            final revanchaList = data.revancha;

            return Column(
              children: [
                _buildBusqueda(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListView(balotoList, AppColors.baloto),
                      _buildListView(revanchaList, AppColors.revancha),
                    ],
                  ),
                ),
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

  /// Campo de búsqueda por número de sorteo (filtrado local sobre la
  /// página cargada, aplica a ambas pestañas).
  Widget _buildBusqueda() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _busquedaController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => setState(() => _query = value.trim()),
        decoration: InputDecoration(
          hintText: 'Buscar por número de sorteo…',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.baloto, width: 2),
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _busquedaController.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
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

    // Filtro local por número de sorteo (coincidencia parcial).
    final query = _query;
    final filtrados = query.isEmpty
        ? sorteos
        : sorteos
              .where((s) => s.numeroSorteo.toString().contains(query))
              .toList();

    if (filtrados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'Ningún sorteo coincide con "$query".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final sorteo = filtrados[index];
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
                      formatearFecha(fecha),
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
