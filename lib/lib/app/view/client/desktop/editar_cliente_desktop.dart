import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../model/cliente_model.dart';
import '../../../theme/app_colors.dart';

class EditarClienteDesktop extends StatefulWidget {
  final ClienteModel cliente;

  const EditarClienteDesktop({
    super.key,
    required this.cliente,
  });

  @override
  State<EditarClienteDesktop> createState() => _EditarClienteDesktopState();
}

class _EditarClienteDesktopState extends State<EditarClienteDesktop> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _nombreNegocioController;
  late TextEditingController _direccionController;
  late TextEditingController _telefonoController;
  late TextEditingController _observacionesController;

  late Ruta _rutaSeleccionada;
  double? _latitud;
  double? _longitud;
  bool _cargandoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente.nombre);
    _nombreNegocioController = TextEditingController(text: widget.cliente.nombreNegocio);
    _direccionController = TextEditingController(text: widget.cliente.direccion);
    _telefonoController = TextEditingController(text: widget.cliente.telefono ?? '');
    _observacionesController = TextEditingController(text: widget.cliente.observaciones ?? '');
    _latitud = widget.cliente.latitud;
    _longitud = widget.cliente.longitud;
    _rutaSeleccionada = widget.cliente.ruta;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreNegocioController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final clienteActualizado = ClienteModel(
      id: widget.cliente.id,
      nombre: _nombreController.text,
      nombreNegocio: _nombreNegocioController.text,
      direccion: _direccionController.text,
      telefono: _telefonoController.text,
      ruta: _rutaSeleccionada,
      observaciones: _observacionesController.text.isEmpty ? null : _observacionesController.text,
      latitud: _latitud,
      longitud: _longitud,
    );

    Navigator.pop(context, clienteActualizado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Editar Cliente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cliente.nombreNegocio ?? widget.cliente.nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Edición de cliente (Desktop)',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // FORMULARIO EN 2 COLUMNAS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COLUMNA IZQUIERDA
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nombreController,
                              decoration: _inputDecoration('Nombre del cliente', Icons.person),
                              validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nombreNegocioController,
                              decoration: _inputDecoration('Nombre del negocio', Icons.store),
                              validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _direccionController,
                              decoration: _inputDecoration('Dirección', Icons.location_on),
                              validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // COLUMNA DERECHA
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _telefonoController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: _inputDecoration('Teléfono', Icons.phone),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Ruta>(
                              value: _rutaSeleccionada,
                              decoration: _inputDecoration('Ruta', Icons.route),
                              items: Ruta.values
                                  .map(
                                    (ruta) => DropdownMenuItem(
                                  value: ruta,
                                  child: Text(ruta.name.toUpperCase()),
                                ),
                              )
                                  .toList(),
                              onChanged: (v) => setState(() => _rutaSeleccionada = v!),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _observacionesController,
                              maxLines: 3,
                              decoration: _inputDecoration('Observaciones', Icons.note),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // BOTONES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _guardar,
                        icon: const Icon(Icons.check),
                        label: const Text('Guardar cambios'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
