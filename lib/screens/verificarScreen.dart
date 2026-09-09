import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bl_app/services/balotoApi.dart';
import 'package:bl_app/services/generadorNumeros.dart';
import 'package:bl_app/models/sorteo.dart';
import 'package:bl_app/config/appTheme.dart';

class VerificarScreen extends StatefulWidget {
  const VerificarScreen({super.key, this.api});

  /// API a usar; en pruebas se puede inyectar una versión mockeada.
  final BalotoApi? api;

  @override
  State<VerificarScreen> createState() => _VerificarScreenState();
}

class _VerificarScreenState extends State<VerificarScreen> {
  final _formKey = GlobalKey<FormState>();

  // 5 controladores para los números + 1 para la Superbalota.
  late final List<TextEditingController> _numeroControllers;
  final _superbalotaController = TextEditingController();

  // Para saltar automáticamente al siguiente campo al digitar.
  late final List<FocusNode> _focusNodes;
  final _superbalotaFocus = FocusNode();

  late final BalotoApi _api;

  bool _cargando = false;
  Verificacion? _resultado;
  String? _error;

  void _verificarNumeros() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
      _resultado = null;
    });

    try {
      // Leemos los 6 campos y delegamos al servicio.
      final numeros = _numeroControllers
          .map((c) => int.parse(c.text.trim()))
          .toList();
      final superbalota = int.parse(_superbalotaController.text.trim());

      final resultado = await _api.verificar(
        numeros: numeros,
        superbalota: superbalota,
      );

      setState(() {
        _resultado = resultado;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  /// Validación por campo: requerido, 1..43 y no repetido.
  String? _validarNumero(
    String? value, {
    required Iterable<String> todosLosValores,
    required int indiceActual,
  }) {
    if (value == null || value.isEmpty) {
      return 'Falta el número ${indiceActual + 1}';
    }

    final num = int.tryParse(value);
    if (num == null || num < 1 || num > BalotoRules.maxNumero) {
      return 'Debe estar entre 1 y 43';
    }

    final repeticiones = todosLosValores.where((v) => v == value).length;
    if (repeticiones > 1) {
      return 'Número repetido';
    }

    return null;
  }

  // Validación: 1 número entre 1 y 16.
  // Mensajes cortos: el campo mide ~90px y un texto largo se corta.
  String? _validarSuperbalota(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa la SB';
    final num = int.tryParse(value.trim());
    if (num == null || num < 1 || num > BalotoRules.maxSuperbalota) {
      return 'Entre 1 y 16';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? BalotoApi();
    _numeroControllers = List.generate(5, (_) => TextEditingController());
    _focusNodes = List.generate(5, (_) => FocusNode());
  }

  /// Salta al siguiente campo (o a la Superbalota) al completar 2 dígitos.
  void _avanzarSiguiente(int index, String value) {
    if (value.length >= 2) {
      if (index < 4) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _superbalotaFocus.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _numeroControllers) {
      c.dispose();
    }
    _superbalotaController.dispose();
    for (final f in _focusNodes) {
      f.dispose();
    }
    _superbalotaFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verificar Números',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ingresa tus números para verificar si ganaste en el último sorteo.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // --- FILA DE ENTRADA: 5 NÚMEROS + SUPERBALOTA ---
              // crossAxisAlignment.start: el error cuelga debajo del
              // campo sin desalinear el resto de la fila.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 5; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                        child: TextFormField(
                          controller: _numeroControllers[i],
                          focusNode: _focusNodes[i],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: '${i + 1}',
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) => _avanzarSiguiente(i, value),
                          validator: (value) => _validarNumero(
                            value,
                            todosLosValores: () sync* {
                              for (final c in _numeroControllers) {
                                yield c.text;
                              }
                            }(),
                            indiceActual: i,
                          ),
                        ),
                      ),
                    ),

                  // --- SUPERBALOTA (destacada en ámbar) ---
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: _superbalotaController,
                      focusNode: _superbalotaFocus,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                      decoration: InputDecoration(
                        labelText: 'SB',
                        labelStyle: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                        prefixIcon: const Icon(
                          Icons.star,
                          size: 18,
                          color: Colors.amber,
                        ),
                        filled: true,
                        fillColor: Colors.amber.withValues(alpha: 0.12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.amber,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.orange.shade800,
                            width: 2,
                          ),
                        ),
                        // Error visible: borde grueso rojo + texto
                        // compacto que sí cabe en el campo angosto.
                        errorMaxLines: 2,
                        errorStyle: const TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
                      ),
                      // Feedback inmediato: valida mientras se digita,
                      // sin esperar a presionar el botón.
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: _validarSuperbalota,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Ayuda visual de rangos.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Números del 1 al 43, sin repetir',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Text(
                    'Superbalota del 1 al 16',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.superbalota,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón de verificar
              ElevatedButton(
                onPressed: _cargando ? null : _verificarNumeros,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.baloto,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'VERIFICAR PREMIO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              // Mostrar error si existe
              if (_error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Mostrar resultado si existe
              if (_resultado != null) ...[
                const SizedBox(height: 32),
                _buildResultadoCard(_resultado!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Tarjeta de resultados
  Widget _buildResultadoCard(Verificacion data) {
    final baloto = data.baloto;
    final revancha = data.revancha;
    final fecha = data.fecha;

    final ganoAlgo = baloto.ganador || revancha.ganador;
    final categoriaPrincipal = ganoAlgo
        ? (baloto.ganador ? baloto.categoria : revancha.categoria)
        : 'Sin premio';
    final premioTotal = baloto.premio + revancha.premio;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              ganoAlgo ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              color: ganoAlgo ? Colors.amber : Colors.grey,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              fecha,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              categoriaPrincipal.toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ganoAlgo
                    ? AppColors.superbalota
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (premioTotal > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Premio: \$${premioTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
            const Divider(height: 32),

            _buildDetalleSorteo('BALOTO', baloto, AppColors.baloto),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetalleSorteo('REVANCHA', revancha, AppColors.revancha),
          ],
        ),
      ),
    );
  }

  // Detalle por cada tipo de sorteo
  Widget _buildDetalleSorteo(
    String titulo,
    ResultadoVerificacion datos,
    Color color,
  ) {
    final aciertos = datos.aciertos;
    final numsGanadores = datos.numerosGanadores;
    final superGanadora = datos.superbalotaGanadora;
    final aciertosNum = aciertos.numeros;
    final aciertosSuper = aciertos.superbalota;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Tus aciertos: $aciertosNum números${aciertosSuper ? ' + Superbalota' : ''}',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Números ganadores del sorteo:',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: numsGanadores.map((num) {
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.6)),
              ),
              child: Center(
                child: Text(
                  num.toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Super: ',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber),
              ),
              child: Center(
                child: Text(
                  superGanadora.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Color(0xFF1C2440),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
