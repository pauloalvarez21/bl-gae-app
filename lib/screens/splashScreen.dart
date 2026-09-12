import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  /// Versión leída de los metadatos del paquete (mismo valor que
  /// `version` en pubspec.yaml). Vacía hasta que llega la consulta.
  String _version = '';

  /// Año del crédito institucional, tomado del reloj del dispositivo
  /// para que no quede desactualizado (antes iba fijo «2026»).
  String get _anio => DateTime.now().year.toString();

  @override
  void initState() {
    super.initState();
    // Fondo blanco: iconos del sistema (status bar) en oscuro para que
    // sean visibles. Al entrar al shell, los AppBar del tema oscuro
    // restauran los iconos claros por sí solos.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _cargarVersion();

    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _opacidad = CurvedAnimation(parent: _entrada, curve: Curves.easeOut);
    _escala = Tween<double>(begin: 0.92, end: 1).animate(_opacidad);

    _timer = Timer(widget.duracion, _entrarALaApp);
  }

  /// Lee la versión del paquete. En pruebas no hay platform channel:
  /// el test instala valores mockeados con
  /// `PackageInfo.setMockInitialValues` y aquí siempre hay respuesta.
  Future<void> _cargarVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return; // el splash puede ya haber navegado (~2 s)
    setState(() => _version = 'v${info.version}');
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
                Text(
                  '© $_anio Gaelectronica. Todos los derechos reservados.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                if (_version.isNotEmpty)
                  Text(
                    _version,
                    style: const TextStyle(
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
