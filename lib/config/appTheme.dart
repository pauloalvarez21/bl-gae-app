import 'package:flutter/material.dart';

/// Paleta "Dark premium": fondo azul noche profundo con acentos azul
/// eléctrico y naranja/ámbar, tomados del ícono de la app (glifo azul
/// marino con acentos naranjas).
class AppColors {
  AppColors._();

  // Fondos
  static const background = Color(0xFF070B1A);
  static const surface = Color(0xFF0D1430);
  static const card = Color(0xFF141C42);
  static const cardBorder = Color(0xFF25305C);

  // Acentos (BALOTO azul, REVANCHA naranja, Superbalota ámbar)
  static const baloto = Color(0xFF4F7CFF);
  static const revancha = Color(0xFFFF8A3D);
  static const superbalota = Color(0xFFFFC93C);

  /// Rampa de la Superbalota para su campo de entrada en Verificar:
  /// texto naranja profundo y borde en estado enfocado.
  static const superbalotaText = Color(0xFFFF5722);
  static const superbalotaFocus = Color(0xFFEF6C00);

  // Texto
  static const textPrimary = Color(0xFFF4F6FF);
  static const textSecondary = Color(0xFF9BA6D0);

  /// Contenido (texto/iconos) sobre fondos de acento, p. ej. el
  /// botón «VERIFICAR PREMIO».
  static const onAccent = Color(0xFFFFFFFF);

  /// Fondo blanco del splash in-app: el logo es un glifo azul marino
  /// pensado para fondos claros y desaparece sobre el tema oscuro.
  static const splashBackground = Color(0xFFFFFFFF);

  // Estados
  static const error = Color(0xFFFF5C6C);
  static const success = Color(0xFF4ADE80);
}

/// Gradientes de las tarjetas de resultados (BALOTO / REVANCHA).
const balotoGradient = [Color(0xFF1B2C7E), Color(0xFF0D1440)];
const revanchaGradient = [Color(0xFF7E3A12), Color(0xFF2E1508)];

/// Tema oscuro único de la aplicación (la app siempre se ve "premium").
ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.baloto,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.baloto,
        secondary: AppColors.revancha,
        error: AppColors.error,
        surface: AppColors.surface,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.baloto.withValues(alpha: 0.22),
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.baloto : AppColors.textSecondary,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? AppColors.baloto : AppColors.textSecondary,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.baloto, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.cardBorder),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.baloto,
    ),
  );
}
