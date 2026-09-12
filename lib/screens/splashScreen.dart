import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bl_app/config/appTheme.dart';

/// Pantalla de presentación (in-app): muestra el logo con una animación
/// de entrada suave y el crédito institucional con la versión; al
/// terminar, entra a la app con un fundido.
///
/// Fondo BLANCO a propósito: el logo es un glifo azul marino pensado
/// para fondos claros (como el ícono del launcher) y desaparece sobre
/// el fondo oscuro de la app. El crédito va justo debajo del logo,
/// centrado y en tonos oscuros para garantizar contraste.
///
/// Nota de rendimiento: en dispositivos lentos el primer frame puede
/// tardar varios segundos (p. ej. ~18 s en debug sobre una tablet
/// MediaTek con Android 9); lo que se ve antes es el splash nativo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.siguiente,
    this.duracion = const Duration(seconds: 2),
  });

  /// Pantalla a la que se entra al terminar el splash (el shell
  /// principal). Se inyecta para mantener este widget desacoplado.
  final Widget siguiente;

  /// Tiempo visible antes de navegar. En pruebas se acorta.
  final Duration duracion;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;
  late final Animation<double> _opacidad;
  late final Animation<double> _escala;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Fondo blanco: iconos del sistema (status bar) en oscuro para que
    // sean visibles. Al entrar al shell, los AppBar del tema oscuro
    // restauran los iconos claros por sí solos.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _opacidad = CurvedAnimation(parent: _entrada, curve: Curves.easeOut);
    _escala = Tween<double>(begin: 0.92, end: 1).animate(_opacidad);

    _timer = Timer(widget.duracion, _entrarALaApp);
  }

  /// Entra al shell con un fundido de 600 ms. Restaura los iconos
  /// claros de la barra de estado (el shell es oscuro).
  void _entrarALaApp() {
    if (!mounted) return;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, animation, _) =>
            FadeTransition(opacity: animation, child: widget.siguiente),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: FadeTransition(
        opacity: _opacidad,
        // Bloque centrado: logo con el crédito justo debajo (no anclado
        // al pie, donde pasaba desapercibido).
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo de marca (mismo asset que el splash nativo).
                ScaleTransition(
                  scale: _escala,
                  child: Image.asset(
                    'assets/splash.png',
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '© 2026 Gaelectronica. Todos los derechos reservados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Herramienta desarrollada por el Gaelectronica.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF5A648C)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.baloto,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
