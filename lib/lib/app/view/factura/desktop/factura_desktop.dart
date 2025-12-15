import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../datasources/database_helper.dart';
import '../../../model/factura_model.dart';
import '../../../service/esc_pos_service.dart';
import '../../../theme/app_colors.dart';
import '../crear_factura_clientes_page.dart';
import '../crear_factura_limpia_page.dart';
import '../editar_factura_page.dart';
import '../mobile/factura_mobile.dart';
import '../resumen_productos__page.dart';

// Reutilizamos los mismos providers del mobile
class FacturaDesktop extends ConsumerStatefulWidget {
  const FacturaDesktop({super.key});

  @override
  ConsumerState<FacturaDesktop> createState() => _FacturaDesktopState();
}

class _FacturaDesktopState extends ConsumerState<FacturaDesktop> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    final dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return '${dias[fecha.weekday % 7]}, ${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  String _formatearPrecio(double precio) {
    final precioInt = precio.toInt();
    return precioInt.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
    );
  }

  void _mostrarSnackBar(String mensaje, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : (isError ? Icons.error : Icons.info),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.accent : (isError ? AppColors.error : AppColors.primary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  void _seleccionarFecha() async {
    final fechaState = ref.read(fechaProvider);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaState.fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(fechaProvider.notifier).setFecha(picked);
    }
  }

  void _crearFacturaCliente() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearFacturaPage()),
    );
    ref.invalidate(facturasStateProvider);
  }

  // void _crearFacturaLimpia() async {
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const CrearFacturaLimpiaPage()),
  //   );
  //   ref.invalidate(facturasProvider);
  // }

  void _editarFactura(FacturaModel factura) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarFacturaPage(factura: factura)),
    );
    ref.invalidate(facturasStateProvider);
  }

  void _confirmarEliminarFactura(FacturaModel factura) {
    final dbHelper = DatabaseHelper();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Eliminar Factura'),
          ],
        ),
        content: Text('¿Eliminar la factura de ${factura.nombreCliente}?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await dbHelper.eliminarFactura(factura.id!);
                ref.invalidate(facturasStateProvider);
                if (context.mounted) {
                  _mostrarSnackBar('Factura eliminada', isSuccess: true);
                }
              } catch (e) {
                if (context.mounted) {
                  _mostrarSnackBar('Error: $e', isError: true);
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _descargarFacturaPOS(FacturaModel factura) async {
    try {
      final opcion = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.print, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Seleccionar formato'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 20),
                ),
                title: const Text('Descargar PDF'),
                subtitle: const Text('Guardar como PDF (80mm)', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bluetooth, color: AppColors.primary, size: 20),
                ),
                title: const Text('Imprimir Bluetooth'),
                subtitle: const Text('Enviar a impresora térmica', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(context, 'bluetooth'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );

      if (opcion == null) return;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Procesando...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }

      if (opcion == 'pdf') {
        await EscPosService.descargarTicketPDF(factura);
        if (context.mounted) {
          Navigator.pop(context);
          _mostrarSnackBar('PDF generado correctamente', isSuccess: true);
        }
      } else if (opcion == 'bluetooth') {
        List<BluetoothDevice> impresoras = await EscPosService.escanearImpresorasBluetooth();

        if (context.mounted) {
          Navigator.pop(context);
        }

        if (impresoras.isEmpty) {
          if (context.mounted) {
            _mostrarSnackBar('No se encontraron impresoras Bluetooth', isError: true);
          }
          return;
        }

        if (context.mounted) {
          final impresoraSeleccionada = await showDialog<BluetoothDevice>(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.print, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Seleccionar Impresora'),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: impresoras.length,
                    itemBuilder: (context, index) {
                      final impresora = impresoras[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.print, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          impresora.platformName.isNotEmpty ? impresora.platformName : 'Impresora ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(impresora.remoteId.toString(), style: const TextStyle(fontSize: 12)),
                        onTap: () => Navigator.pop(context, impresora),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              );
            },
          );

          if (impresoraSeleccionada == null) return;

          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          await EscPosService.imprimirTicketBluetoothConDispositivo(factura, impresoraSeleccionada);

          if (context.mounted) {
            Navigator.pop(context);
            _mostrarSnackBar('Ticket enviado a impresora', isSuccess: true);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _mostrarSnackBar('Error: $e', isError: true);
      }
    }
  }

  List<FacturaModel> _filtrarFacturas(List<FacturaModel> facturas) {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return facturas;

    return facturas.where((f) =>
        f.nombreCliente.toLowerCase().contains(query)
    ).toList();
  }

  Map<String, dynamic> _calcularEstadisticas(List<FacturaModel> facturas) {
    final stats = <String, dynamic>{};
    final total = facturas.fold(0.0, (sum, factura) {
      return sum + factura.items.fold(0.0, (itemSum, item) => itemSum + item.subtotal);
    });

    stats['totalFacturas'] = facturas.length;
    stats['totalVendido'] = total;
    stats['totalProductos'] = facturas.fold(0, (sum, f) => sum + f.items.length);

    return stats;
  }

  Widget _buildEstadisticas(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.accent.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildStatCard('Facturas', stats['totalFacturas'], Icons.receipt_long, AppColors.primary),
          const SizedBox(width: 16),
          _buildStatCard('Total Vendido', '\$${_formatearPrecio(stats['totalVendido'])}', Icons.attach_money, AppColors.accent, isPrice: true),
          const SizedBox(width: 16),
          _buildStatCard('Productos', stats['totalProductos'], Icons.inventory_2, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, IconData icon, Color color, {bool isPrice = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabla(List<FacturaModel> facturas) {
    if (facturas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long, size: 80, color: AppColors.primary.withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin facturas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay facturas para esta fecha',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _crearFacturaCliente,
                  icon: const Icon(Icons.shopping_cart, size: 20),
                  label: const Text('Nueva Factura', style: TextStyle(fontSize: 15)),
                ),

              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(60),
            1: FlexColumnWidth(2.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1.5),
            5: FixedColumnWidth(200),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              children: [
                _buildHeaderCell('#'),
                _buildHeaderCell('Cliente'),
                _buildHeaderCell('Hora'),
                _buildHeaderCell('Items'),
                _buildHeaderCell('Total'),
                _buildHeaderCell('Acciones', center: true),
              ],
            ),
            // Rows
            ...facturas.asMap().entries.map((entry) {
              final index = entry.key;
              final factura = entry.value;
              final isEven = index % 2 == 0;
              final total = factura.items.fold(0.0, (sum, item) => sum + item.subtotal);

              return TableRow(
                decoration: BoxDecoration(
                  color: isEven ? AppColors.surface : AppColors.background.withOpacity(0.3),
                ),
                children: [
                  _buildDataCell(
                    Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _buildDataCell(
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: AppColors.primary, size: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            factura.nombreCliente,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDataCell(
                    Text(
                      '${factura.fecha.hour.toString().padLeft(2, '0')}:${factura.fecha.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                  _buildDataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${factura.items.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  _buildDataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '\$${_formatearPrecio(total)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  _buildDataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print_outlined, size: 18),
                          color: AppColors.primary,
                          tooltip: 'Imprimir',
                          onPressed: () => _descargarFacturaPOS(factura),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.primary,
                          tooltip: 'Editar',
                          onPressed: () => _editarFactura(factura),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminarFactura(factura),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        textAlign: center ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildDataCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final facturasAsync = ref.watch(facturasStateProvider);
    final facturasFiltradas = ref.watch(facturasFiltradasProvider);
    final fechaState = ref.watch(fechaProvider);

    final facturasMostrar = _filtrarFacturas(facturasFiltradas);
    final stats = _calcularEstadisticas(facturasMostrar);

    return Scaffold(
        backgroundColor: AppColors.background,
// Reemplaza TODO el AppBar completo (desde la línea ~720)
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const Text(
          'Gestión de Facturas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
        ),
        actions: [
          // Envolvemos todo en un Flexible para evitar overflow
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Obtenemos el ancho total de la pantalla
                final screenWidth = MediaQuery.of(context).size.width;

                // Si la pantalla es muy pequeña (menos de 900px)
                if (screenWidth < 900) {
                  // return Row(
                  //   mainAxisSize: MainAxisSize.min,
                  //   children: [
                  //     // Solo fecha en versión compacta
                  //     Flexible(
                  //       child: GestureDetector(
                  //         onTap: _seleccionarFecha,
                  //         child: Container(
                  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  //           margin: const EdgeInsets.symmetric(horizontal: 8),
                  //           decoration: BoxDecoration(
                  //             color: AppColors.primary.withOpacity(0.08),
                  //             borderRadius: BorderRadius.circular(10),
                  //             border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  //           ),
                  //           child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                  //         ),
                  //       ),
                  //     ),
                  //     // Menú con todas las opciones
                  //     PopupMenuButton<String>(
                  //       icon: const Icon(Icons.more_vert, color: AppColors.primary),
                  //       tooltip: 'Más opciones',
                  //       onSelected: (value) {
                  //         switch (value) {
                  //           case 'buscar':
                  //             _mostrarDialogoBusqueda();
                  //             break;
                  //           case 'resumen':
                  //             Navigator.push(
                  //               context,
                  //               MaterialPageRoute(
                  //                 builder: (context) => ResumenProductosDiaPage(
                  //                   facturas: facturasMostrar,
                  //                   fecha: fechaState.fechaSeleccionada,
                  //                 ),
                  //               ),
                  //             );
                  //             break;
                  //           case 'factura_cliente':
                  //             _crearFacturaCliente();
                  //             break;
                  //           case 'factura_limpia':
                  //             _crearFacturaLimpia();
                  //             break;
                  //         }
                  //       },
                  //       itemBuilder: (context) => [
                  //         const PopupMenuItem(
                  //           value: 'buscar',
                  //           child: Row(
                  //             children: [
                  //               Icon(Icons.search, size: 18, color: AppColors.primary),
                  //               SizedBox(width: 12),
                  //               Text('Buscar cliente'),
                  //             ],
                  //           ),
                  //         ),
                  //         const PopupMenuItem(
                  //           value: 'resumen',
                  //           child: Row(
                  //             children: [
                  //               Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                  //               SizedBox(width: 12),
                  //               Text('Resumen de productos'),
                  //             ],
                  //           ),
                  //         ),
                  //         const PopupMenuItem(
                  //           value: 'factura_cliente',
                  //           child: Row(
                  //             children: [
                  //               Icon(Icons.shopping_cart, size: 18, color: AppColors.primary),
                  //               SizedBox(width: 12),
                  //               Text('Factura a Cliente'),
                  //             ],
                  //           ),
                  //         ),
                  //         const PopupMenuItem(
                  //           value: 'factura_limpia',
                  //           child: Row(
                  //             children: [
                  //               Icon(Icons.person_add_outlined, size: 18, color: AppColors.accent),
                  //               SizedBox(width: 12),
                  //               Text('Factura Limpia'),
                  //             ],
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //     const SizedBox(width: 8),
                  //   ],
                  // );
                }

                // Pantallas medianas (900-1200px) - versión intermedia
                // if (screenWidth < 1200) {
                //   return Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       // Búsqueda más pequeña
                //       Container(
                //         width: 200,
                //         margin: const EdgeInsets.symmetric(vertical: 8),
                //         child: TextField(
                //           controller: _searchController,
                //           decoration: InputDecoration(
                //             hintText: 'Buscar...',
                //             hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                //             prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                //             filled: true,
                //             fillColor: AppColors.background,
                //             contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                //             border: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(10),
                //               borderSide: BorderSide(color: AppColors.border),
                //             ),
                //             enabledBorder: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(10),
                //               borderSide: BorderSide(color: AppColors.border),
                //             ),
                //             focusedBorder: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(10),
                //               borderSide: const BorderSide(color: AppColors.primary, width: 2),
                //             ),
                //           ),
                //           onChanged: (value) => setState(() {}),
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //       // Fecha compacta
                //       GestureDetector(
                //         onTap: _seleccionarFecha,
                //         child: Container(
                //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                //           decoration: BoxDecoration(
                //             color: AppColors.primary.withOpacity(0.08),
                //             borderRadius: BorderRadius.circular(10),
                //             border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                //           ),
                //           child: const Row(
                //             children: [
                //               Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                //             ],
                //           ),
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //       // Botones como iconos
                //       IconButton(
                //         icon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                //         tooltip: 'Resumen de productos',
                //         onPressed: () {
                //           Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //               builder: (context) => ResumenProductosDiaPage(
                //                 facturas: facturasMostrar,
                //                 fecha: fechaState.fechaSeleccionada,
                //               ),
                //             ),
                //           );
                //         },
                //       ),
                //       // IconButton(
                //       //   icon: const Icon(Icons.person_add_outlined, color: AppColors.accent),
                //       //   tooltip: 'Factura Limpia',
                //       //   onPressed: _crearFacturaLimpia,
                //       // ),
                //       IconButton(
                //         icon: const Icon(Icons.shopping_cart, color: AppColors.primary),
                //         tooltip: 'Factura a Cliente',
                //         onPressed: _crearFacturaCliente,
                //       ),
                //       const SizedBox(width: 16),
                //     ],
                //   );
                // }

                // Pantallas grandes (1200px+) - versión completa
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 300,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por cliente...',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _seleccionarFecha,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              _formatearFecha(fechaState.fechaSeleccionada),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                      tooltip: 'Resumen de productos',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResumenProductosDiaPage(
                              facturas: facturasMostrar,
                              fecha: fechaState.fechaSeleccionada,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _crearFacturaCliente,
                      icon: const Icon(Icons.shopping_cart, size: 20),
                      label: const Text('Nueva Factura', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      body: facturasAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Cargando facturas...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $err', style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(facturasStateProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (facturas) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildEstadisticas(stats),
              ),
              Expanded(child: _buildTabla(facturasMostrar)),
            ],
          );
        },
      ),
    );
  }

// Agrega este método nuevo en la clase _FacturaDesktopState
  void _mostrarDialogoBusqueda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.search, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Buscar cliente'),
          ],
        ),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nombre del cliente...',
            prefixIcon: const Icon(Icons.person_search, color: AppColors.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (value) {
            setState(() {});
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}