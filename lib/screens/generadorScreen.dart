import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bl_app/services/generadorNumeros.dart';
import 'package:bl_app/config/appTheme.dart';
import 'package:bl_app/widgets/balota.dart';

class GeneradorScreen extends StatefulWidget {
  const GeneradorScreen({super.key});

  @override
  State<GeneradorScreen> createState() => _GeneradorScreenState();
}

class _GeneradorScreenState extends State<GeneradorScreen> {
  final _generador = GeneradorNumeros();

  List<int> _numeros = [];
  int _superbalota = 0;
  bool _estaGenerando = false;
  Timer? _timerMezcla;

  @override
  void dispose() {
    _timerMezcla?.cancel();
    super.dispose();
  }

  void _generarCombinacion() {
    setState(() {
      _estaGenerando = true;
    });

    _timerMezcla = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        // Combinación provisional mientras "gira" la animación.
        final provisional = _generador.generarCombinacion();
        _numeros = provisional.numeros;
        _superbalota = provisional.superbalota;
      });
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      // El widget pudo haberse destruido durante la animación: si el
      // método se ejecuta sobre un State desmontado, setState crashea.
      if (!mounted) return;
      _timerMezcla?.cancel();
      setState(() {
        // Combinación final válida.
        final combinacion = _generador.generarCombinacion();
        _numeros = combinacion.numeros;
        _superbalota = combinacion.superbalota;
        _estaGenerando = false;
      });
    });
  }

  void _copiarAlPortapapeles() {
    if (_numeros.isEmpty) return;

    final texto =
        "Mis números Baloto: ${_numeros.map((e) => e.toString().padLeft(2, '0')).join(', ')} | Superbalota: ${_superbalota.toString().padLeft(2, '0')}";
    Clipboard.setData(ClipboardData(text: texto));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Combinación copiada al portapapeles!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generador Aleatorio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      // 1. AGREGAMOS SingleChildScrollView para evitar desbordamientos
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // 2. Quitamos MainAxisAlignment.center para que conviva bien con el scroll
            children: [
              const SizedBox(height: 20), // Espacio superior
              const Icon(Icons.casino_sharp, size: 80, color: AppColors.baloto),
              const SizedBox(height: 16),
              const Text(
                '¡Prueba tu suerte!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '5 números (1-43) + 1 Superbalota (1-16)',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- SECCIÓN DE NÚMEROS GENERADOS ---
              if (_numeros.isNotEmpty || _estaGenerando) ...[
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final num in _numeros)
                      AnimatedScale(
                        scale: _estaGenerando ? 0.9 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Balota(
                          numero: num,
                          color: AppColors.baloto,
                          size: 60,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Superbalota: ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedScale(
                      scale: _estaGenerando ? 0.9 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Balota(
                        numero: _superbalota,
                        color: AppColors.superbalota,
                        size: 50,
                        isSuper: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                if (!_estaGenerando && _numeros.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: _copiarAlPortapapeles,
                    icon: const Icon(Icons.copy, color: AppColors.baloto),
                    label: const Text(
                      'Copiar combinación',
                      style: TextStyle(
                        color: AppColors.baloto,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.baloto, width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],

              // --- BOTÓN PRINCIPAL DE GENERAR ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _estaGenerando ? null : _generarCombinacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.baloto,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _estaGenerando
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Mezclando...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'GENERAR COMBINACIÓN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(
                height: 24,
              ), // 3. Espacio inferior para que no quede pegado al borde
            ],
          ),
        ),
      ),
    );
  }
}
