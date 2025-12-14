import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../datasources/database_helper.dart';
import '../../../model/categoria_model.dart';
import '../../../model/prodcuto_model.dart';
import '../../../service/cache_manager.dart';
import '../../../theme/app_colors.dart';
import '../crear_categoria_page.dart';
import '../crear_producto_page.dart';
import '../editar_categoria_page.dart';
import '../editar_prodcuto_page.dart';
import '../../barcode/barcode_scaner_page.dart' as scanner;
import 'package:vibration/vibration.dart';

class ProductosDesktop extends ConsumerStatefulWidget {
  const ProductosDesktop({super.key});

  @override
  ConsumerState<ProductosDesktop> createState() => _ProductosDesktopState();
}

class _ProductosDesktopState extends ConsumerState<ProductosDesktop> {
  final TextEditingController _searchController = TextEditingController();
  String? _categoriaSeleccionada;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<ProductoModel> _filtrarProductos(List<ProductoModel> productos, List<CategoriaModel> categorias) {
    var resultado = productos;

    // Filtrar por categoría
    if (_categoriaSeleccionada != null && _categoriaSeleccionada != 'Todas') {
      resultado = resultado.where((p) => p.categoriaId == _categoriaSeleccionada).toList();
    }

    // Filtrar por búsqueda
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado.where((p) =>
      p.nombre.toLowerCase().contains(query) ||
          p.sabores.any((s) => s.toLowerCase().contains(query)) ||
          (p.codigoBarras?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    return resultado;
  }

  Map<String, int> _calcularEstadisticas(List<ProductoModel> productos, List<CategoriaModel> categorias) {
    final stats = <String, int>{};
    stats['total'] = productos.length;
    stats['categorias'] = categorias.length;
    stats['conImagen'] = productos.where((p) => p.imagenPath != null && p.imagenPath!.isNotEmpty).length;
    stats['conCodigoBarras'] = productos.where((p) => p.codigoBarras != null && p.codigoBarras!.isNotEmpty).length;

    // Valor total del inventario
    final valorTotal = productos.fold<double>(0, (sum, p) => sum + p.precio);
    // stats['valorPromedio'] = valorTotal > 0 ? (valorTotal / productos.length).toInt() : 0;

    return stats;
  }

  Widget _buildEstadisticas(Map<String, int> stats) {
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
          _buildStatCard('Total Productos', stats['total']!, Icons.inventory_2, AppColors.primary),
          const SizedBox(width: 16),
          _buildStatCard('Categorías', stats['categorias']!, Icons.category, AppColors.accent),
          const SizedBox(width: 16),
          _buildStatCard('Con Imagen', stats['conImagen']!, Icons.image, AppColors.primary),
          // const SizedBox(width: 16),
          // _buildStatCard('Precio Prom.', stats['valorPromedio']!, Icons.attach_money, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
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
                  label.contains('Precio') ? '\$${_formatearPrecio(value.toDouble())}' : value.toString(),
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

  String _formatearPrecio(double precio) {
    final precioInt = precio.toInt();
    return precioInt.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
    );
  }

  Widget _construirImagenProducto(String? imagenPath, {double size = 56}) {
    if (imagenPath != null && imagenPath.isNotEmpty) {
      if (imagenPath.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imagenPath,
            fit: BoxFit.cover,
            width: size,
            height: size,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _imagenPlaceholder(size);
            },
            errorBuilder: (context, error, stackTrace) => _imagenPorDefecto(size),
          ),
        );
      } else {
        final file = File(imagenPath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file, fit: BoxFit.cover, width: size, height: size),
          );
        }
      }
    }
    return _imagenPorDefecto(size);
  }

  Widget _imagenPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _imagenPorDefecto(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.1), AppColors.accent.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.inventory_2_outlined, size: size * 0.4, color: AppColors.primary),
    );
  }

  void _verImagenProducto(ProductoModel producto) {
    if (producto.imagenPath != null && producto.imagenPath!.isNotEmpty) {
      Widget imageWidget;

      if (producto.imagenPath!.startsWith('http')) {
        imageWidget = Image.network(producto.imagenPath!, fit: BoxFit.contain);
      } else {
        final file = File(producto.imagenPath!);
        if (file.existsSync()) {
          imageWidget = Image.file(file, fit: BoxFit.contain);
        } else {
          _mostrarSnackBar('Este producto no tiene imagen');
          return;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(producto.nombre, style: const TextStyle(fontSize: 16)),
            ),
            body: Center(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: imageWidget,
              ),
            ),
          ),
        ),
      );
    } else {
      _mostrarSnackBar('Este producto no tiene imagen');
    }
  }

  void _crearProducto(List<CategoriaModel> categorias) async {
    final dbHelper = DatabaseHelper();
    final nuevoProducto = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CrearProductoPage(categorias: categorias)),
    );

    if (nuevoProducto != null) {
      try {
        await dbHelper.insertarProducto(nuevoProducto);
        ref.invalidate(productosProvider);
        if (mounted) {
          _mostrarSnackBar('Producto ${nuevoProducto.nombre} creado', isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          _mostrarSnackBar('Error: $e', isError: true);
        }
      }
    }
  }

  void _crearCategoria() async {
    final dbHelper = DatabaseHelper();
    final nuevaCategoria = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearCategoriaPage()),
    );

    if (nuevaCategoria != null) {
      try {
        await dbHelper.insertarCategoria(nuevaCategoria);
        ref.invalidate(categoriasProvider);
        if (mounted) {
          _mostrarSnackBar('Categoría ${nuevaCategoria.nombre} creada', isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          _mostrarSnackBar('Error: $e', isError: true);
        }
      }
    }
  }

  void _editarProducto(ProductoModel producto, List<CategoriaModel> categorias) async {
    final dbHelper = DatabaseHelper();
    final productoActualizado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarProductoPage(producto: producto, categorias: categorias)),
    );

    if (productoActualizado != null) {
      try {
        await dbHelper.actualizarProducto(productoActualizado);
        ref.invalidate(productosProvider);
        if (mounted) {
          _mostrarSnackBar('Producto actualizado', isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          _mostrarSnackBar('Error: $e', isError: true);
        }
      }
    }
  }

  void _confirmarEliminarProducto(ProductoModel producto) {
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
            const Text('Eliminar Producto'),
          ],
        ),
        content: Text('¿Eliminar "${producto.nombre}"?\n\nEsta acción no se puede deshacer.'),
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
                await dbHelper.eliminarProducto(producto.id!);
                ref.invalidate(productosProvider);
                if (context.mounted) {
                  _mostrarSnackBar('Producto eliminado', isSuccess: true);
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

  void _escanearCodigoBarras(List<CategoriaModel> categorias) async {
    final codigoBarras = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const scanner.BarcodeScannerPage()),
    );

    if (codigoBarras != null && codigoBarras.isNotEmpty) {
      _buscarProductoPorCodigoBarras(codigoBarras);
    }
  }

  void _buscarProductoPorCodigoBarras(String codigoBarras) async {
    final dbHelper = DatabaseHelper();

    try {
      final producto = await dbHelper.obtenerProductoPorCodigoBarras(codigoBarras);

      if (producto != null) {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 100, 50, 100], intensities: [0, 200, 0, 255]);
        }

        _searchController.text = producto.nombre;
        setState(() {});

        if (mounted) {
          _mostrarSnackBar('Producto encontrado: ${producto.nombre}', isSuccess: true);
        }
      } else {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 300, 100, 300], intensities: [0, 128, 0, 128]);
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar('Error al buscar producto: $e', isError: true);
      }
    }
  }

  Widget _buildTabla(List<ProductoModel> productos, List<CategoriaModel> categorias) {
    if (productos.isEmpty) {
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
              child: Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.primary.withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin productos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agrega tu primer producto para comenzar',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _crearProducto(categorias),
              icon: const Icon(Icons.add, size: 22),
              label: const Text('Agregar Producto', style: TextStyle(fontSize: 16)),
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
            1: FixedColumnWidth(80),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.5),
            5: FlexColumnWidth(1.2),
            6: FlexColumnWidth(1),
            7: FixedColumnWidth(180),
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
                _buildHeaderCell('Imagen'),
                _buildHeaderCell('Producto'),
                _buildHeaderCell('Sabores'),
                _buildHeaderCell('Categoría'),
                _buildHeaderCell('Precio'),
                _buildHeaderCell('x Paca'),
                _buildHeaderCell('Acciones', center: true),
              ],
            ),
            // Rows
            ...productos.asMap().entries.map((entry) {
              final index = entry.key;
              final producto = entry.value;
              final isEven = index % 2 == 0;
              final categoria = categorias.firstWhere(
                    (c) => c.id == producto.categoriaId,
                orElse: () => CategoriaModel(id: '', nombre: 'Sin categoría'),
              );

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
                  _buildDataCell(_construirImagenProducto(producto.imagenPath, size: 48)),
                  _buildDataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          producto.nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (producto.codigoBarras != null && producto.codigoBarras!.isNotEmpty)
                          Text(
                            producto.codigoBarras!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildDataCell(
                    producto.sabores.isNotEmpty
                        ? Text(
                      producto.sabores.join(', '),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                        : const Text(
                      'Sin sabores',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),
                  _buildDataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categoria.nombre.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  _buildDataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '\$${_formatearPrecio(producto.precio)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  _buildDataCell(
                    producto.cantidadPorPaca != null
                        ? Text(
                      '${producto.cantidadPorPaca}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    )
                        : const Text(
                      '-',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildDataCell(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (producto.imagenPath != null && producto.imagenPath!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.image_outlined, size: 18),
                            color: AppColors.primary,
                            tooltip: 'Ver imagen',
                            onPressed: () => _verImagenProducto(producto),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.primary,
                          tooltip: 'Editar',
                          onPressed: () => _editarProducto(producto, categorias),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminarProducto(producto),
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
    final productosAsync = ref.watch(productosProvider);
    final categoriasAsync = ref.watch(categoriasProvider);

    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          title: const Text(
            'Gestión de Productos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
          ),
          actions: [
          Container(
          width: 300,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
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
            categoriasAsync.when(
              data: (categorias) {
                // Crear lista de items SIN duplicados
                final items = <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: null, // Cambiado de 'Todas' a null
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Todas'),
                      ],
                    ),
                  ),
                  ...categorias.map((c) => DropdownMenuItem<String>(
                    value: c.id, // Usar el ID directamente
                    child: Row(
                      children: [
                        Icon(Icons.category, color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(c.nombre),
                      ],
                    ),
                  )),
                ];

                return DropdownButton<String>(
                  value: _categoriaSeleccionada,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  underline: Container(),
                  hint: const Row(
                    children: [
                      Icon(Icons.all_inclusive, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text('Todas', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  items: items,
                  onChanged: (String? newValue) {
                    setState(() {
                      _categoriaSeleccionada = newValue;
                    });
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
          tooltip: 'Escanear código',
          onPressed: () => categoriasAsync.whenData((cats) => _escanearCodigoBarras(cats)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _crearCategoria,
          icon: const Icon(Icons.category, size: 20),
          label: const Text('Nueva Categoría', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          onPressed: () => categoriasAsync.whenData((cats) => _crearProducto(cats)),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Nuevo Producto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
            const SizedBox(width: 24),
          ],
        ),
      body: productosAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Cargando productos...', style: TextStyle(color: AppColors.textSecondary)),
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
                onPressed: () => ref.invalidate(productosProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (productos) {
          return categoriasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (categorias) {
              final productosFiltrados = _filtrarProductos(productos, categorias);
              final stats = _calcularEstadisticas(productos, categorias);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildEstadisticas(stats),
                  ),
                  Expanded(child: _buildTabla(productosFiltrados, categorias)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ============= PROVIDERS =============
final productosProvider = StreamProvider<List<ProductoModel>>((ref) async* {
  final dbHelper = DatabaseHelper();
  final categoriasStream = dbHelper.streamCategorias();

  await for (final categorias in categoriasStream) {
    final todosProductos = <ProductoModel>[];
    for (final categoria in categorias) {
      final productos = await dbHelper.obtenerProductosPorCategoria(categoria.id!);
      todosProductos.addAll(productos);
    }
    yield todosProductos;
  }
});

final categoriasProvider = StreamProvider<List<CategoriaModel>>((ref) {
  final dbHelper = DatabaseHelper();
  return dbHelper.streamCategorias();
});

// State para filtros
class FiltrosProductosState {
  final String? categoriaId;
  final String searchQuery;

  FiltrosProductosState({
    this.categoriaId,
    this.searchQuery = '',
  });

  FiltrosProductosState copyWith({
    String? categoriaId,
    String? searchQuery,
  }) {
    return FiltrosProductosState(
      categoriaId: categoriaId ?? this.categoriaId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FiltrosProductosNotifier extends StateNotifier<FiltrosProductosState> {
  FiltrosProductosNotifier() : super(FiltrosProductosState());

  void setCategoriaId(String? categoriaId) {
    state = state.copyWith(categoriaId: categoriaId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = FiltrosProductosState();
  }
}

final filtrosProductosProvider = StateNotifierProvider<FiltrosProductosNotifier, FiltrosProductosState>((ref) {
  return FiltrosProductosNotifier();
});

final productosPorCategoriaProvider = FutureProvider.family<List<ProductoModel>, String?>((ref, categoriaId) async {
  final productosAsync = ref.watch(productosProvider);

  return productosAsync.whenData((productos) {
    if (categoriaId == null) {
      return productos;
    }
    return productos.where((producto) {
      return producto.categoriaId == categoriaId;
    }).toList();
  }).value ?? [];
});

final productosFiltradosProvider = Provider<List<ProductoModel>>((ref) {
  final filtros = ref.watch(filtrosProductosProvider);
  final productosPorCategoria = ref.watch(productosPorCategoriaProvider(filtros.categoriaId));

  return productosPorCategoria.whenData((productos) {
    return productos.where((producto) {
      final query = filtros.searchQuery.toLowerCase();
      final coincideBusqueda = filtros.searchQuery.isEmpty ||
          producto.nombre.toLowerCase().contains(query) ||
          producto.sabores.any((s) => s.toLowerCase().contains(query)) ||
          (producto.codigoBarras?.toLowerCase().contains(query) ?? false);
      return coincideBusqueda;
    }).toList();
  }).maybeWhen(data: (data) => data, orElse: () => []);
});