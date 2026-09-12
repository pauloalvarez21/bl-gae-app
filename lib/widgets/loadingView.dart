import 'package:flutter/material.dart';

import 'package:bl_app/config/appTheme.dart';

/// Vista de carga reutilizable: indicador circular centrado con un
/// mensaje opcional debajo. La usan Inicio e Histórico mientras la
/// petición a la API está en vuelo, para que ambos estados de carga
/// se vean igual.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.mensaje});

  /// Texto opcional debajo del indicador (p. ej. "Consultando
  /// resultados..."). Si es null, solo se muestra el indicador.
  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (mensaje != null) ...[
            const SizedBox(height: 16),
            Text(
              mensaje!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
