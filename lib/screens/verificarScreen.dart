import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

class VerificarScreen extends StatefulWidget {
  const VerificarScreen({super.key});

  @override
  State<VerificarScreen> createState() => _VerificarScreenState();
}

class _VerificarScreenState extends State<VerificarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numerosController = TextEditingController();
  final _superbalotaController = TextEditingController();

  bool _cargando = false;
  Map<String, dynamic>? _resultado;
  String? _error;

  void _verificarNumeros() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
      _resultado = null;
    });

    try {
      // Formatear la URL quitando espacios extra
      final numerosStr = _numerosController.text.replaceAll(' ', '');
      final url = Uri.parse(
        'https://bl-gae-api.onrender.com/baloto/verificar?numeros=$numerosStr&superbalota=${_superbalotaController.text}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _resultado = jsonDecode(response.body);
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          // La API a veces devuelve el error como lista o como string
          _error = errorData['message'] is List
              ? errorData['message'].join(', ')
              : (errorData['message'] ?? 'Error desconocido');
        });
      }
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

  // Validación: 5 números, entre 1 y 43, sin repetir
  String? _validarNumeros(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa los 5 números';

    final partes = value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (partes.length != 5) return 'Debes ingresar exactamente 5 números';

    for (var p in partes) {
      final num = int.tryParse(p);
      if (num == null || num < 1 || num > 43)
        return 'Cada número debe estar entre 1 y 43';
    }

    final unicos = partes.toSet();
    if (unicos.length != 5) return 'Los números no pueden estar repetidos';

    return null;
  }

  // Validación: 1 número entre 1 y 16
  String? _validarSuperbalota(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa la Superbalota';
    final num = int.tryParse(value.trim());
    if (num == null || num < 1 || num > 16)
      return 'La Superbalota debe estar entre 1 y 16';
    return null;
  }

  @override
  void dispose() {
    _numerosController.dispose();
    _superbalotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Números'),
        backgroundColor: Colors.deepPurple,
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
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Input de 5 números
              TextFormField(
                controller: _numerosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tus 5 números (1 al 43)',
                  hintText: 'Ej: 5, 12, 23, 34, 42',
                  prefixIcon: Icon(Icons.numbers, color: Colors.deepPurple),
                  border: OutlineInputBorder(),
                ),
                validator: _validarNumeros,
              ),
              const SizedBox(height: 16),

              // Input de Superbalota
              TextFormField(
                controller: _superbalotaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Superbalota (1 al 16)',
                  hintText: 'Ej: 14',
                  prefixIcon: Icon(Icons.star, color: Colors.amber),
                  border: OutlineInputBorder(),
                ),
                validator: _validarSuperbalota,
              ),
              const SizedBox(height: 32),

              // Botón de verificar
              ElevatedButton(
                onPressed: _cargando ? null : _verificarNumeros,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
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
  Widget _buildResultadoCard(Map<String, dynamic> data) {
    final baloto = data['baloto'] as Map<String, dynamic>;
    final revancha = data['revancha'] as Map<String, dynamic>;
    final fecha = data['fecha'] ?? 'Fecha desconocida';

    final ganoAlgo = baloto['ganador'] == true || revancha['ganador'] == true;
    final categoriaPrincipal = ganoAlgo
        ? (baloto['ganador'] == true
              ? baloto['categoria']
              : revancha['categoria'])
        : 'Sin premio';
    final premioTotal = (baloto['premio'] ?? 0) + (revancha['premio'] ?? 0);

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
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              categoriaPrincipal.toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ganoAlgo ? Colors.deepPurple : Colors.grey,
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
                  color: Colors.green,
                ),
              ),
            ],
            const Divider(height: 32),

            _buildDetalleSorteo('BALOTO', baloto, Colors.deepPurple),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetalleSorteo('REVANCHA', revancha, Colors.orange),
          ],
        ),
      ),
    );
  }

  // Detalle por cada tipo de sorteo
  Widget _buildDetalleSorteo(
    String titulo,
    Map<String, dynamic> datos,
    Color color,
  ) {
    final aciertos = datos['aciertos'] as Map<String, dynamic>;
    final numsGanadores = List<int>.from(datos['numerosGanadores'] ?? []);
    final superGanadora = datos['superbalotaGanadora'] ?? 0;
    final aciertosNum = aciertos['numeros'] ?? 0;
    final aciertosSuper = aciertos['superbalota'] == true;

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
          'Tus aciertos: $aciertosNum números ${aciertosSuper ? '+ Superbalota' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          'Números ganadores del sorteo:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
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
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color),
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
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber),
              ),
              child: Center(
                child: Text(
                  superGanadora.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Colors.amber,
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
