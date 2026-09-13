import 'package:flutter/material.dart';

import 'package:bl_app/config/appTheme.dart';

/// Aviso discreto que se muestra encima del contenido cuando los datos
/// que se ven NO vienen del servidor sino del caché offline (la
/// petición falló y se rescató el último dato guardado).
class CachedDataBanner extends StatelessWidget {
  const CachedDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.superbalota.withValues(alpha: 0.12),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off,
                size: 16,
                color: AppColors.superbalotaFocus,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Datos sin conexión: mostrando el último resultado guardado.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.superbalotaFocus,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
