import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../datasources/database_helper.dart';
import '../../model/inventario_model.dart';
import '../../model/prodcuto_model.dart';
import '../../service/inventario_service.dart';
import '../../theme/app_colors.dart';

class HistorialMovimientosPage extends ConsumerStatefulWidget {
  const HistorialMovimientosPage({super.key});

  @override
  ConsumerState<HistorialMovimientosPage> createState() => _HistorialMovimientosPageState();
}

class _HistorialMovimientosPageState extends ConsumerState<HistorialMovimientosPage> {
  final InventarioService _inventarioService = InventarioService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();

  List<MovimientoInventarioModel> _movimientos = [];
  List<MovimientoInventarioModel> _movimientosFiltrados = [];
  Map<String, ProductoModel> _productosMap = {};
  bool _isLoading = true;
  TipoMovimiento? _tipoFiltro;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Cargar productos
      final productos = await _dbHelper.obtenerProductos();
      _productosMap = {for (var p in productos) p.id!: p};

      // Cargar movimientos
      final movimientos = await _inventarioService.obtenerHistorialMovimientos(limit: 100);

      setState(() {
        _movimientos = movimientos;
        _movimientosFiltrados = movimientos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar movimientos: $e')),
        );
      }
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _movimientosFiltrados = _movimientos.where((movimiento) {
        // Filtro por búsqueda
        final producto = _productosMap[movimiento.productoId];
        final matchBusqueda = _searchController.text.isEmpty ||
            (producto?.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);

        // Filtro por tipo
        final matchTipo = _tipoFiltro == null || movimiento.tipo == _tipoFiltro;

        // Filtro por fecha
        bool matchFecha = true;
        if (_fechaInicio != null) {
          matchFecha = movimiento.fecha.isAfter(_fechaInicio!.subtract(const Duration(days: 1)));
        }
        if (_fechaFin != null && matchFecha) {
          matchFecha = movimiento.fecha.isBefore(_fechaFin!.add(const Duration(days: 1)));
        }

        return matchBusqueda && matchTipo && matchFecha;
      }).toList();
    });
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
      _aplicarFiltros();
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _searchController.clear();
      _tipoFiltro = null;
      _fechaInicio = null;
      _fechaFin = null;
      _movimientosFiltrados = _movimientos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.history, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historial de Movimientos',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_movimientosFiltrados.length} movimientos',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Búsqueda
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _aplicarFiltros(),
                        decoration: InputDecoration(
                          hintText: 'Buscar producto...',
                          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filtro por tipo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border.withOpacity(0.3)),
                      ),
                      child: DropdownButton<TipoMovimiento?>(
                        value: _tipoFiltro,
                        hint: Text('Todos los tipos', style: TextStyle(color: AppColors.textSecondary)),
                        underline: Container(),
                        icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                        items: [
                          DropdownMenuItem<TipoMovimiento?>(
                            value: null,
                            child: Text('Todos', style: TextStyle(color: AppColors.textPrimary)),
                          ),
                          ...TipoMovimiento.values.map((tipo) {
                            return DropdownMenuItem<TipoMovimiento?>(
                              value: tipo,
                              child: Row(
                                children: [
                                  Icon(_getIconoTipo(tipo), color: _getColorTipo(tipo), size: 18),
                                  const SizedBox(width: 8),
                                  Text(_getNombreTipo(tipo)),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (valor) {
                          setState(() => _tipoFiltro = valor);
                          _aplicarFiltros();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Fecha inicio
                    OutlinedButton.icon(
                      onPressed: () => _seleccionarFecha(true),
                      icon: Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                      label: Text(
                        _fechaInicio != null
                            ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                            : 'Fecha inicio',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: BorderSide(color: AppColors.border.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Fecha fin
                    OutlinedButton.icon(
                      onPressed: () => _seleccionarFecha(false),
                      icon: Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                      label: Text(
                        _fechaFin != null
                            ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                            : 'Fecha fin',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: BorderSide(color: AppColors.border.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Limpiar filtros
                    IconButton(
                      onPressed: _limpiarFiltros,
                      icon: Icon(Icons.clear_all, color: AppColors.error),
                      tooltip: 'Limpiar filtros',
                    ),
                  ],
                ),
                // Chips de filtros activos
                if (_tipoFiltro != null || _fechaInicio != null || _fechaFin != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_tipoFiltro != null)
                          Chip(
                            label: Text(_getNombreTipo(_tipoFiltro!)),
                            onDeleted: () {
                              setState(() => _tipoFiltro = null);
                              _aplicarFiltros();
                            },
                            backgroundColor: _getColorTipo(_tipoFiltro!).withOpacity(0.1),
                            deleteIcon: Icon(Icons.close, size: 18),
                          ),
                        if (_fechaInicio != null)
                          Chip(
                            label: Text('Desde: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}'),
                            onDeleted: () {
                              setState(() => _fechaInicio = null);
                              _aplicarFiltros();
                            },
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            deleteIcon: Icon(Icons.close, size: 18),
                          ),
                        if (_fechaFin != null)
                          Chip(
                            label: Text('Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}'),
                            onDeleted: () {
                              setState(() => _fechaFin = null);
                              _aplicarFiltros();
                            },
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            deleteIcon: Icon(Icons.close, size: 18),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Resumen
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                _buildResumenCard(
                  icon: Icons.arrow_downward,
                  label: 'Entradas',
                  value: _movimientosFiltrados.where((m) => m.tipo == TipoMovimiento.entrada).length.toString(),
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _buildResumenCard(
                  icon: Icons.arrow_upward,
                  label: 'Salidas',
                  value: _movimientosFiltrados.where((m) => m.tipo == TipoMovimiento.salida).length.toString(),
                  color: AppColors.error,
                ),
                const SizedBox(width: 12),
                _buildResumenCard(
                  icon: Icons.edit,
                  label: 'Ajustes',
                  value: _movimientosFiltrados.where((m) => m.tipo == TipoMovimiento.ajuste).length.toString(),
                  color: AppColors.warning,
                ),
                const SizedBox(width: 12),
                _buildResumenCard(
                  icon: Icons.shopping_cart,
                  label: 'Ventas',
                  value: _movimientosFiltrados.where((m) => m.tipo == TipoMovimiento.venta).length.toString(),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          // Tabla de movimientos
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _movimientosFiltrados.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay movimientos registrados',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        color: AppColors.primary.withOpacity(0.05),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text('Fecha/Hora', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                            Expanded(flex: 3, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                            Expanded(flex: 1, child: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                            Expanded(flex: 1, child: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center)),
                            Expanded(flex: 1, child: Text('Anterior', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center)),
                            Expanded(flex: 1, child: Text('Nueva', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text('Motivo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
                      // Filas
                      Expanded(
                        child: ListView.separated(
                          itemCount: _movimientosFiltrados.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withOpacity(0.3)),
                          itemBuilder: (context, index) {
                            final movimiento = _movimientosFiltrados[index];
                            final producto = _productosMap[movimiento.productoId];

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Row(
                                children: [
                                  // Fecha
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(movimiento.fecha),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('HH:mm:ss').format(movimiento.fecha),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Producto
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      producto?.nombre ?? 'Producto no encontrado',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Tipo
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getColorTipo(movimiento.tipo).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getIconoTipo(movimiento.tipo),
                                            size: 14,
                                            color: _getColorTipo(movimiento.tipo),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _getNombreTipo(movimiento.tipo),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getColorTipo(movimiento.tipo),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Cantidad
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${movimiento.tipo == TipoMovimiento.entrada ? '+' : '-'}${movimiento.cantidad}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: movimiento.tipo == TipoMovimiento.entrada
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                  // Anterior
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      movimiento.cantidadAnterior.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                  // Nueva
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      movimiento.cantidadNueva.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  // Motivo
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      movimiento.motivo ?? '-',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getNombreTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return 'Entrada';
      case TipoMovimiento.salida:
        return 'Salida';
      case TipoMovimiento.ajuste:
        return 'Ajuste';
      case TipoMovimiento.venta:
        return 'Venta';
    }
  }

  IconData _getIconoTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return Icons.arrow_downward;
      case TipoMovimiento.salida:
        return Icons.arrow_upward;
      case TipoMovimiento.ajuste:
        return Icons.edit;
      case TipoMovimiento.venta:
        return Icons.shopping_cart;
    }
  }

  Color _getColorTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return AppColors.success;
      case TipoMovimiento.salida:
        return AppColors.error;
      case TipoMovimiento.ajuste:
        return AppColors.warning;
      case TipoMovimiento.venta:
        return AppColors.primary;
    }
  }
}