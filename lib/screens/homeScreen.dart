import 'package:flutter/material.dart';

import 'package:bl_app/services/balotoApi.dart';
import 'package:bl_app/models/sorteo.dart';
import 'package:bl_app/config/appTheme.dart';
import 'package:bl_app/utils/fechas.dart';
import 'package:bl_app/widgets/balota.dart';
import 'package:bl_app/widgets/balotoSiteLink.dart';
import 'package:bl_app/widgets/errorRetryView.dart';
import 'package:bl_app/widgets/loadingView.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.api, this.onIrA});

  /// API a usar; en pruebas se puede inyectar una versión mockeada.
  final BalotoApi? api;

  /// Navega a una pestaña del shell principal (0..3). En pruebas con
  /// [MaterialApp] directo puede ser null.
  final ValueChanged<int>? onIrA;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BalotoApi _api;

  // Se crea UNA sola vez en initState (y no en build), evitando
  // peticiones repetidas en cada redibujado de la pantalla.
  late Future<UltimoResultado> _resultado;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? BalotoApi();
    _resultado = _api.getUltimo();
  }

  /// Recarga el resultado. No lanza: si la petición falla, el error
  /// se pinta solo en el FutureBuilder (estado de error). Así el botón
  /// del AppBar y el de "Reintentar" comparten el mismo camino seguro,
  /// sin futuros rechazados no manejados.
  Future<void> _recargar() async {
    setState(() {
      _resultado = _api.getUltimo();
    });
    try {
      await _resultado;
    } catch (_) {
      // El error ya se pinta en el FutureBuilder del estado de error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resultados Baloto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _recargar,
          ),
        ],
      ),
      body: FutureBuilder<UltimoResultado>(
        future: _resultado,
        builder: (context, snapshot) {
          // A) Estado: Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(mensaje: 'Consultando resultados...');
          }

          // B) Estado: Error
          if (snapshot.hasError) {
            return ErrorRetryView(
              error: snapshot.error,
              onReintentar: _recargar,
            );
          }

          // C) Estado: Éxito (Datos listos)
          if (snapshot.hasData) {
            final data = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLotteryCard(
                    title: 'BALOTO',
                    fecha: formatearFecha(data.baloto.fecha),
                    numeros: data.baloto.numeros,
                    superNumero: data.baloto.superbalota,
                    accent: AppColors.baloto,
                    gradient: balotoGradient,
                  ),
                  const SizedBox(height: 24),
                  _buildLotteryCard(
                    title: 'REVANCHA',
                    fecha: formatearFecha(data.revancha.fecha),
                    numeros: data.revancha.numeros,
                    superNumero: data.revancha.superbalota,
                    accent: AppColors.revancha,
                    gradient: revanchaGradient,
                  ),
                  const SizedBox(height: 24),
                  _buildCtaVerificar(),
                  const SizedBox(height: 24),

                  // Enlace al histórico completo del sitio oficial.
                  const BalotoSiteLink(),
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
    required Color accent,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: accent, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              fecha,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final numero in numeros)
                  Balota(numero: numero, color: accent, size: 50),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.cardBorder.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title == 'BALOTO' ? 'Super Balota: ' : 'Super Revancha: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Balota(
                  numero: superNumero,
                  color: AppColors.superbalota,
                  size: 44,
                  isSuper: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// CTA contextual: tras ver los resultados, la acción natural es
  /// verificar si la jugada ganó. Reemplaza a la grilla "Explora",
  /// que duplicaba los destinos de la barra de navegación.
  Widget _buildCtaVerificar() {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: widget.onIrA == null ? null : () => widget.onIrA!(1),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.baloto.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.fact_check, color: AppColors.baloto, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Jugaste?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Verifica si ganaste un premio',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
