import 'package:flutter/material.dart';

/// Bola numerada con gradiente y glow, usada en todas las pantallas
/// para pintar números y Superbalotas con un estilo consistente.
class Balota extends StatelessWidget {
  const Balota({
    super.key,
    required this.numero,
    required this.color,
    this.size = 50,
    this.isSuper = false,
  });

  final int numero;
  final Color color;
  final double size;

  /// Las Superbalotas llevan texto oscuro sobre ámbar y (si caben)
  /// una estrellita encima del número.
  final bool isSuper;

  @override
  Widget build(BuildContext context) {
    final texto = numero.toString().padLeft(2, '0');
    final colorTexto = isSuper ? const Color(0xFF1C2440) : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: size * 0.24,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: isSuper && size >= 44
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: size * 0.26,
                    color: colorTexto.withValues(alpha: 0.8),
                  ),
                  Text(
                    texto,
                    style: TextStyle(
                      color: colorTexto,
                      fontSize: size * 0.34,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ],
              )
            : Text(
                texto,
                style: TextStyle(
                  color: colorTexto,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
