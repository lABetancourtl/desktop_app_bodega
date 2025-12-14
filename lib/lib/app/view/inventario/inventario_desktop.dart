import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datasources/database_helper.dart';
import '../../model/categoria_model.dart';
import '../../model/prodcuto_model.dart';
import '../../theme/app_colors.dart';

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

  List<ProductoModel> _productos = [];
  List<ProductoModel> _productosFiltrados = [];
  Map<String, int> _inventario = {};
  bool _isLoading = true;
  String? _categoriaSeleccionada;

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
    setState(() => _isLoading = true);
    try {
      final productos = await _dbHelper.obtenerProductos();
      setState(() {
        _productos = productos;
        _productosFiltrados = productos;
        for (var producto in productos) {
          _inventario[producto.id ?? ''] = 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  void _actualizarInventario(String productoId, int cantidad) {
    setState(() {
      _inventario[productoId] = cantidad;
    });
  }

  void _mostrarDialogoEditar(ProductoModel producto) {
    final cantidadController = TextEditingController(
        text: (_inventario[producto.id] ?? 0).toString()
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Actualizar Inventario',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto.nombre,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cantidad en stock',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final cantidad = int.tryParse(cantidadController.text) ?? 0;
              _actualizarInventario(producto.id ?? '', cantidad);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
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
                // Dropdown de categorías
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
                        onChanged: (String? newValue) {
                          _filtrarPorCategoria(newValue);
                        },
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
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                      // Header de la tabla
                      Container(
                        color: AppColors.primary.withOpacity(0.05),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                            Expanded(flex: 2, child: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                            Expanded(flex: 1, child: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                            Expanded(flex: 1, child: Text('Sabores', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                            Expanded(flex: 1, child: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center)),
                            Expanded(flex: 1, child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                            Expanded(flex: 2, child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
                      // Filas de la tabla
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
                                  // Sabores
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      producto.sabores.isNotEmpty ? '${producto.sabores.length} sabores' : '-',
                                      style: TextStyle(color: AppColors.textSecondary),
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
                                        color: cantidad == 0 ? AppColors.error : cantidad <= 10 ? AppColors.warning : AppColors.textPrimary,
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
                                        IconButton(
                                          icon: Icon(Icons.remove_circle_outline, color: AppColors.error),
                                          onPressed: cantidad > 0 ? () => _actualizarInventario(producto.id ?? '', cantidad - 1) : null,
                                          tooltip: 'Restar',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add_circle_outline, color: AppColors.success),
                                          onPressed: () => _actualizarInventario(producto.id ?? '', cantidad + 1),
                                          tooltip: 'Agregar',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, color: AppColors.primary),
                                          onPressed: () => _mostrarDialogoEditar(producto),
                                          tooltip: 'Editar cantidad',
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
