// lib/pages/gestion_entregas_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/factura_model.dart';
import '../../service/gestion_entrega_service.dart';
import '../../theme/app_colors.dart';

class GestionEntregasPage extends ConsumerStatefulWidget {
  const GestionEntregasPage({super.key});

  @override
  ConsumerState<GestionEntregasPage> createState() => _GestionEntregasPageState();
}

class _GestionEntregasPageState extends ConsumerState<GestionEntregasPage> {
  final GestionEntregasService _service = GestionEntregasService();
  List<FacturaModel> _facturasEnRuta = [];
  ResumenEntregas? _resumen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final facturas = await _service.obtenerFacturasEnRuta();
      final resumen = await _service.obtenerResumenDia();

      if (!mounted) return;

      setState(() {
        _facturasEnRuta = facturas;
        _resumen = resumen;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _mostrarModalDetalleFactura(FacturaModel factura) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModalDetalleFactura(
        factura: factura,
        onActualizar: _cargarDatos,
        service: _service,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.local_shipping, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text('Gestión de Entregas', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        children: [
          if (_resumen != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildResumenCard(Icons.pending_actions, 'Pendientes', _resumen!.pendientes.toString(), AppColors.warning),
                  _buildResumenCard(Icons.check_circle, 'Entregadas', _resumen!.entregadas.toString(), AppColors.success),
                  _buildResumenCard(Icons.assignment_return, 'Parciales', _resumen!.parciales.toString(), AppColors.primary),
                ],
              ),
            ),
          Expanded(
            child: _facturasEnRuta.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppColors.success.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No hay entregas pendientes', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _facturasEnRuta.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildFacturaCardSimple(_facturasEnRuta[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard(IconData icon, String label, String value, Color color) {
    return SizedBox(
      width: 120,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFacturaCardSimple(FacturaModel factura) {
    return Card(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarModalDetalleFactura(factura),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.store, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(factura.negocioCliente ?? factura.nombreCliente, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(factura.nombreCliente, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(factura.direccionCliente, style: TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('${factura.items.length} items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 4),
                  Text('\$${factura.total.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalDetalleFactura extends StatefulWidget {
  final FacturaModel factura;
  final VoidCallback onActualizar;
  final GestionEntregasService service;

  const _ModalDetalleFactura({required this.factura, required this.onActualizar, required this.service});

  @override
  State<_ModalDetalleFactura> createState() => _ModalDetalleFacturaState();
}

class _ModalDetalleFacturaState extends State<_ModalDetalleFactura> {
  late List<ItemFacturaModel> _itemsEditables;

  @override
  void initState() {
    super.initState();
    _itemsEditables = List.from(widget.factura.items);
  }

  void _modificarCantidad(int index, int nuevaCantidad) {
    if (!mounted) return;

    setState(() {
      final item = _itemsEditables[index];
      if (item.tieneSabores && item.cantidadPorSabor.length == 1) {
        final sabor = item.cantidadPorSabor.keys.first;
        _itemsEditables[index] = item.copyWith(cantidadTotal: nuevaCantidad, cantidadPorSabor: {sabor: nuevaCantidad});
      } else {
        _itemsEditables[index] = item.copyWith(cantidadTotal: nuevaCantidad);
      }
    });
  }

  void _eliminarItem(int index) {
    if (!mounted) return;

    setState(() => _itemsEditables.removeAt(index));
  }

  double _calcularTotal() => _itemsEditables.fold(0.0, (sum, item) => sum + (item.precioUnitario * item.cantidadTotal));

  Future<void> _confirmarEntregaCompleta() async {
    if (_itemsEditables.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay productos para entregar')));
      }
      return;
    }

    try {
      final facturaActualizada = widget.factura.copyWith(items: _itemsEditables, total: _calcularTotal());
      await widget.service.confirmarEntregaCompleta(widget.factura.id!, facturaActualizada);

      if (!mounted) return;

      Navigator.pop(context);
      widget.onActualizar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrega confirmada exitosamente'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _cancelarFactura() {
    if (!mounted) return;

    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancelar Factura', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Estás seguro de cancelar esta factura?', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(controller: motivoController, decoration: InputDecoration(labelText: 'Motivo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Volver', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.service.cancelarFactura(widget.factura.id!, motivoController.text.isEmpty ? 'Sin motivo' : motivoController.text);

                if (!mounted) return;

                Navigator.pop(context);
                Navigator.pop(context);
                widget.onActualizar();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Factura cancelada'), backgroundColor: Colors.red));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancelar Factura'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCantidad(int index, ItemFacturaModel item) {
    if (!mounted) return;

    final cantidadController = TextEditingController(text: item.cantidadTotal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Editar cantidad',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.nombreProducto,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.shopping_cart, color: AppColors.primary),
              ),
              onSubmitted: (value) {
                final cantidad = int.tryParse(value);
                if (cantidad != null && cantidad > 0) {
                  _modificarCantidad(index, cantidad);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text);
              if (cantidad != null && cantidad > 0) {
                _modificarCantidad(index, cantidad);
                Navigator.pop(context);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa una cantidad válida'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(color: AppColors.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5)))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.receipt_long, color: AppColors.primary, size: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.factura.negocioCliente ?? widget.factura.nombreCliente, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              Text(widget.factura.nombreCliente, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(icon: Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(children: [Icon(Icons.location_on, size: 16, color: AppColors.textSecondary), const SizedBox(width: 4), Expanded(child: Text(widget.factura.direccionCliente, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)))]),
                    if (widget.factura.telefonoCliente != null) ...[const SizedBox(height: 4), Row(children: [Icon(Icons.phone, size: 16, color: AppColors.textSecondary), const SizedBox(width: 4), Text(widget.factura.telefonoCliente!, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))])],
                  ],
                ),
              ),
              Expanded(child: ListView.separated(controller: scrollController, padding: const EdgeInsets.all(16), itemCount: _itemsEditables.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) => _buildProductoCard(_itemsEditables[index], index))),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_itemsEditables.length} productos', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(height: 4), Text('Total:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))]),
                        Text('\$${_calcularTotal().toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.accent)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: _cancelarFactura, style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Cancelar'))),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: ElevatedButton(onPressed: _confirmarEntregaCompleta, style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Entrega Completa'))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductoCard(ItemFacturaModel item, int index) {
    return Card(
      color: AppColors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            InkWell(
              onTap: () => _mostrarDialogoCantidad(index, item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${item.cantidadTotal}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nombreProducto, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('\$${item.precioUnitario.toStringAsFixed(0)} c/u', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(6)
                      ),
                      child: Text(
                          '\$${(item.precioUnitario * item.cantidadTotal).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accent)
                      )
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Icon(Icons.delete_outline, color: AppColors.error, size: 20)
              ),
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                      title: const Text('Eliminar producto'),
                      content: Text('¿Eliminar "${item.nombreProducto}" de la entrega?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar')
                        ),
                        ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _eliminarItem(index);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                            child: const Text('Eliminar')
                        )
                      ]
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }
}