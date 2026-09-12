import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bl_app/config/appTheme.dart';

/// Abre la página oficial de resultados (https://baloto.com/resultados)
/// en el navegador del dispositivo. Devuelve `true` si el sistema
/// aceptó la petición.
///
/// Variable (no `final`) para poder sobreescribirla en pruebas y así
/// no depender de la plataforma subyacente.
Future<bool> Function() abrirSitioBaloto = _abrirSitioBalotoDefault;

Future<bool> _abrirSitioBalotoDefault() => launchUrl(
  Uri.parse('https://baloto.com/resultados'),
  mode: LaunchMode.externalApplication,
);

/// Botón/enlace reutilizable que abre la página de resultados oficial
/// de Baloto (https://baloto.com/resultados) en el navegador.
///
/// Si el dispositivo no puede abrir el enlace, muestra un SnackBar
/// con la URL para que el usuario pueda copiarla.
class BalotoSiteLink extends StatelessWidget {
  const BalotoSiteLink({super.key, this.compacto = false});

  /// En `true` se pinta como acción compacta (solo icono), pensada para
  /// el `actions` del AppBar. En `false`, como tarjeta con texto.
  final bool compacto;

  Future<void> _abrir(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await abrirSitioBaloto();
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir baloto.com/resultados'),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir el navegador. Visita baloto.com/resultados',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compacto) {
      return IconButton(
        icon: const Icon(Icons.open_in_new),
        color: AppColors.revancha,
        tooltip: 'Más resultados en baloto.com',
        onPressed: () => _abrir(context),
      );
    }

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _abrir(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.revancha.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.open_in_new,
                color: AppColors.revancha,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Más resultados',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Histórico completo en baloto.com',
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
