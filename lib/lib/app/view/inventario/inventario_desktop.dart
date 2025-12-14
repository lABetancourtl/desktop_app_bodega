import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datasources/database_helper.dart';
import '../../model/categoria_model.dart';
import '../../model/prodcuto_model.dart';
import '../../service/inventario_service.dart';
import '../../theme/app_colors.dart';
import 'historial_movimientos_page.dart';

final categoriasInventarioProvider = StreamProvider<List<CategoriaModel>>((ref) {
  final dbHelper = DatabaseHelper();
  return dbHelper.streamCategorias();
});

class InventarioDesktop extends ConsumerStatefulWidget {
  const InventarioDesktop({super.key});

  @override
  ConsumerState<InventarioDesktop> createState() => _InventarioDesktopState();
}

class _InventarioDesktopState extends ConsumerState<InventarioDesktop> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  final InventarioService _inventarioService = InventarioService();

  List<ProductoModel> _productos = [];
  List<ProductoModel> _productosFiltrados = [];
  Map<String, int> _inventario = {};
  bool _isLoading = true;
  String? _categoriaSeleccionada;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productos = await _dbHelper.obtenerProductos();

      if (productos.isEmpty) {
        setState(() {
          _errorMessage = 'No hay productos registrados. Agrega productos primero.';
          _isLoading = false;
        });
        return;
      }

      // Cargar o inicializar inventarios
      for (var producto in productos) {
        try {
          // Intentar obtener inventario existente
          var inventario = await _inventarioService.obtenerInventarioPorProducto(producto.id!);

          // Si no existe, crearlo
          if (inventario == null) {
            inventario = await _inventarioService.crearInventario(
              productoId: producto.id!,
              cantidadInicial: 0,
              cantidadMinima: 10,
            );
          }

          _inventario[producto.id!] = inventario.cantidad;
        } catch (e) {
          print('Error al cargar inventario para ${producto.nombre}: $e');
          _inventario[producto.id!] = 0;
        }
      }

      setState(() {
        _productos = productos;
        _productosFiltrados = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar productos: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _actualizarInventario(String productoId, int cantidad) async {
    if (cantidad < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cantidad no puede ser negativa')),
      );
      return;
    }

    try {
      await _inventarioService.actualizarCantidad(
        productoId: productoId,
        nuevaCantidad: cantidad,
      );

      setState(() {
        _inventario[productoId] = cantidad;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inventario actualizado: $cantidad unidades'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filtrarProductos(String query) {
    setState(() {
      _productosFiltrados = _productos.where((producto) {
        final matchNombre = producto.nombre.toLowerCase().contains(query.toLowerCase());
        final matchCategoria = _categoriaSeleccionada == null ||
            producto.categoriaId == _categoriaSeleccionada;
        return matchNombre && matchCategoria;
      }).toList();
    });
  }

  void _filtrarPorCategoria(String? categoriaId) {
    setState(() {
      _categoriaSeleccionada = categoriaId;
      _filtrarProductos(_searchController.text);
    });
  }

  void _mostrarDialogoAgregarCantidad(ProductoModel producto) {
    final cantidadController = TextEditingController();
    final cantidadActual = _inventario[producto.id] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_box, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Agregar Stock',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    if (producto.imagenPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          producto.imagenPath!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, size: 40, color: AppColors.primary),
                        ),
                      )
                    else
                      Icon(Icons.inventory_2, size: 40, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock actual: $cantidadActual unidades',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cantidad a agregar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cantidadController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Ej: 100',
                  prefixIcon: Icon(Icons.add_circle_outline, color: AppColors.success),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.success, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Accesos rápidos',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [10, 25, 50, 100, 200].map((cantidad) {
                  return InkWell(
                    onTap: () {
                      cantidadController.text = cantidad.toString();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        '+$cantidad',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final cantidadAgregar = int.tryParse(cantidadController.text) ?? 0;
              if (cantidadAgregar > 0) {
                final nuevaCantidad = cantidadActual + cantidadAgregar;
                _actualizarInventario(producto.id ?? '', nuevaCantidad);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Agregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEstablecerCantidad(ProductoModel producto) {
    final cantidadController = TextEditingController(
        text: (_inventario[producto.id] ?? 0).toString()
    );
    final cantidadActual = _inventario[producto.id] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Establecer Cantidad',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    if (producto.imagenPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          producto.imagenPath!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, size: 40, color: AppColors.primary),
                        ),
                      )
                    else
                      Icon(Icons.inventory_2, size: 40, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto.nombre,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock actual: $cantidadActual unidades',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nueva cantidad total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cantidadController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Cantidad total en stock',
                  prefixIcon: Icon(Icons.inventory, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text) ?? 0;
              _actualizarInventario(producto.id ?? '', cantidad);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save, size: 20),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasInventarioProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
          children: [
      // Header
      Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Control de Inventario',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_productos.length} productos registrados',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildResumenCard(
            icon: Icons.check_circle_outline,
            label: 'En Stock',
            value: _inventario.values.where((c) => c > 10).length.toString(),
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildResumenCard(
            icon: Icons.warning_amber_outlined,
            label: 'Stock Bajo',
            value: _inventario.values.where((c) => c > 0 && c <= 10).length.toString(),
            color: AppColors.warning,
          ),
          const SizedBox(width: 12),
          _buildResumenCard(
            icon: Icons.error_outline,
            label: 'Agotados',
            value: _inventario.values.where((c) => c == 0).length.toString(),
            color: AppColors.error,
          ),
        ],
      ),
    ),
// Barra de búsqueda y filtros
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withOpacity(0.3)),
                    ),
                    child: categoriasAsync.when(
                      data: (categorias) {
                        final items = <DropdownMenuItem<String?>>[
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.all_inclusive, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                const Text('Todos'),
                              ],
                            ),
                          ),
                          ...categorias.map((c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(Icons.category, color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Text(c.nombre),
                              ],
                            ),
                          )),
                        ];

                        return DropdownButton<String?>(
                          value: _categoriaSeleccionada,
                          icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          underline: Container(),
                          hint: Row(
                            children: [
                              Icon(Icons.all_inclusive, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text('Todos', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          items: items,
                          onChanged: _filtrarPorCategoria,
                        );
                      },
                      loading: () => const SizedBox(
                        width: 100,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => const Text('Error'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filtrarProductos,
                      decoration: InputDecoration(
                        hintText: 'Buscar producto...',
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _cargarProductos,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Actualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // En la sección de la barra de búsqueda, después del botón "Actualizar"
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistorialMovimientosPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, size: 20),
                    label: const Text('Historial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary ?? AppColors.primary.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _cargarProductos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
                  : _productosFiltrados.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron productos',
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
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        Container(
                          color: AppColors.primary.withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                              Expanded(flex: 2, child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                              Expanded(flex: 1, child: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                              Expanded(flex: 1, child: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center)),
                              Expanded(flex: 1, child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                              Expanded(flex: 2, child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _productosFiltrados.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withOpacity(0.3)),
                            itemBuilder: (context, index) {
                              final producto = _productosFiltrados[index];
                              final cantidad = _inventario[producto.id] ?? 0;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                child: Row(
                                  children: [
                                    // Producto
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: producto.imagenPath != null
                                                ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                producto.imagenPath!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: AppColors.primary),
                                              ),
                                            )
                                                : Icon(Icons.inventory_2, color: AppColors.primary),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              producto.nombre,
                                              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Categoría
                                    Expanded(
                                      flex: 2,
                                      child: categoriasAsync.when(
                                        data: (categorias) {
                                          final categoria = categorias.firstWhere(
                                                (c) => c.id == producto.categoriaId,
                                            orElse: () => CategoriaModel(id: '', nombre: 'Sin categoría'),
                                          );
                                          return Text(categoria.nombre, style: TextStyle(color: AppColors.textSecondary));
                                        },
                                        loading: () => const Text('-'),
                                        error: (_, __) => const Text('-'),
                                      ),
                                    ),
                                    // Precio
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '\$${producto.precio.toStringAsFixed(0)}',
                                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    // Cantidad
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        cantidad.toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: cantidad == 0 ? AppColors.error : cantidad <= 10 ? AppColors.warning : AppColors.success,
                                        ),
                                      ),
                                    ),
                                    // Estado
                                    Expanded(flex: 1, child: _buildEstadoChip(cantidad)),
                                    // Acciones
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => _mostrarDialogoAgregarCantidad(producto),
                                            icon: Icon(Icons.add_circle, size: 18),
                                            label: const Text('Agregar'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.success,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined, color: AppColors.primary),
                                            onPressed: () => _mostrarDialogoEstablecerCantidad(producto),
                                            tooltip: 'Establecer cantidad',
                                          ),
                                        ],
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
    return Container(
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
    );
  }

  Widget _buildEstadoChip(int cantidad) {
    String label;
    Color color;
    IconData icon;

    if (cantidad == 0) {
      label = 'Agotado';
      color = AppColors.error;
      icon = Icons.error_outline;
    } else if (cantidad <= 10) {
      label = 'Stock bajo';
      color = AppColors.warning;
      icon = Icons.warning_amber_outlined;
    } else {
      label = 'Disponible';
      color = AppColors.success;
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}