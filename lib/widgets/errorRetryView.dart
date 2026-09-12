import 'package:flutter/material.dart';

import 'package:bl_app/config/appTheme.dart';

/// Vista de error reutilizable: ícono + mensaje + detalle técnico +
/// botón «Reintentar». La usan Inicio e Histórico cuando falla la
/// carga de datos, para que ambos estados de error se vean y se
/// comporten exactamente igual.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    required this.error,
    required this.onReintentar,
    this.mensaje = 'No se pudieron cargar los datos.',
  });

  /// Error capturado por el FutureBuilder; su texto se muestra como
  /// detalle técnico debajo del mensaje principal. Si es null, no se
  /// pinta la línea de detalle.
  final Object? error;

  /// Acción del botón (recargar la petición que falló).
  final VoidCallback onReintentar;

  /// Mensaje principal; personalizable por pantalla.
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
