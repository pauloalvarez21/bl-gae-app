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

  /// Tamaños de página ofrecidos en el selector (máximo backend: 50).
  static const List<int> _tamanosPagina = [10, 25, 50];

  /// Tamaño de página solicitado al backend.
  int _limit = _tamanosPagina.first;

  // Se crea una sola vez en initState (no en build).
  late Future<Historico> _historico;

  /// Metadatos de paginación de la última respuesta exitosa.
  Paginacion? _paginacion;

  /// Indica que hay una carga de página en curso (para no perder la
  /// lista actual de vista mientras llega la nueva página).
  bool _cargandoPagina = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? BalotoApi();
    // 2 pestañas: Baloto y Revancha
    _tabController = TabController(length: 2, vsync: this);
    _historico = _api.getHistorico(limit: _limit);
  }

  /// (Re)carga una página del histórico. Si [pagina] es distinta a la
  /// actual, mantiene los datos viejos en pantalla mientras llega la
  /// nueva respuesta (carga no bloqueante).
  void _cargar({int pagina = 1}) {
    setState(() {
      _cargandoPagina = pagina != 1;
      _historico = _api.getHistorico(page: pagina, limit: _limit);
    });
  }

  Future<void> _recargar() async {
    _cargar(pagina: 1);
    await _historico;
  }

  /// Cambia el tamaño de página y vuelve a la página 1.
  void _cambiarTamanoPagina(int nuevoLimite) {
    if (nuevoLimite == _limit) return;
    setState(() {
      _limit = nuevoLimite;
      _historico = _api.getHistorico(page: 1, limit: _limit);
    });
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
          // A) Cargando (solo la primera carga: los cambios de página
          // mantienen la lista anterior visible).
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_cargandoPagina) {
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
            // Recordar los metadatos de paginación más recientes y
            // apagar el indicador de cambio de página al terminar.
            if (data.paginacion != null) _paginacion = data.paginacion;
            if (snapshot.connectionState != ConnectionState.waiting) {
              _cargandoPagina = false;
            }

            return Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListView(balotoList, AppColors.baloto),
                      _buildListView(revanchaList, AppColors.revancha),
                    ],
                  ),
                ),
                _buildPaginador(),
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

  /// Barra inferior del histórico. Siempre muestra el selector de
  /// tamaño de página; los controles de navegación (primera / anterior /
  /// siguiente / última e indicador) solo aparecen cuando el backend
  /// reporta más de una página (`totalPaginas > 1`).
  Widget _buildPaginador() {
    final pag = _paginacion;
    final hayPaginas = pag != null && pag.totalPaginas > 1;

    final esPrimera = !hayPaginas || pag.paginaActual <= 1;
    final esUltima = !hayPaginas || pag.paginaActual >= pag.totalPaginas;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Controles de navegación: solo con más de una página.
            if (hayPaginas) ...[
              IconButton(
                tooltip: 'Primera página',
                icon: const Icon(Icons.first_page),
                color: AppColors.baloto,
                disabledColor: AppColors.textSecondary.withValues(alpha: 0.4),
                onPressed: esPrimera ? null : () => _cargar(pagina: 1),
              ),
              IconButton(
                tooltip: 'Página anterior',
                icon: const Icon(Icons.chevron_left),
                color: AppColors.baloto,
                disabledColor: AppColors.textSecondary.withValues(alpha: 0.4),
                onPressed: esPrimera
                    ? null
                    : () => _cargar(pagina: pag.paginaActual - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _cargandoPagina
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Pág. ${pag.paginaActual} de ${pag.totalPaginas}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
              ),
              IconButton(
                tooltip: 'Página siguiente',
                icon: const Icon(Icons.chevron_right),
                color: AppColors.baloto,
                disabledColor: AppColors.textSecondary.withValues(alpha: 0.4),
                onPressed: esUltima
                    ? null
                    : () => _cargar(pagina: pag.paginaActual + 1),
              ),
              IconButton(
                tooltip: 'Última página',
                icon: const Icon(Icons.last_page),
                color: AppColors.baloto,
                disabledColor: AppColors.textSecondary.withValues(alpha: 0.4),
                onPressed: esUltima
                    ? null
                    : () => _cargar(pagina: pag.totalPaginas),
              ),
              const SizedBox(width: 8),
            ],
            // Selector de tamaño de página: siempre visible.
            PopupMenuButton<int>(
              tooltip: 'Resultados por página',
              initialValue: _limit,
              onSelected: _cambiarTamanoPagina,
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.unfold_more,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_limit',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                for (final tam in _tamanosPagina)
                  PopupMenuItem<int>(
                    value: tam,
                    height: 40,
                    child: Row(
                      children: [
                        Icon(
                          tam == _limit
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 18,
                          color: tam == _limit
                              ? AppColors.baloto
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$tam por página',
                          style: TextStyle(
                            color: tam == _limit
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: tam == _limit
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
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
