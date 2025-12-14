// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../../../datasources/database_helper.dart';
// import '../../../model/categoria_model.dart';
// import '../../../model/cliente_model.dart';
// import '../../../model/factura_model.dart';
// import '../../../model/prodcuto_model.dart';
// import '../../../theme/app_colors.dart';
//
// /// Vista unificada para crear facturas en desktop
// /// Todo en una sola pantalla: Cliente (izquierda) + Productos (centro) + Carrito (derecha)
// class CrearFacturaDesktop extends StatefulWidget {
//   const CrearFacturaDesktop({super.key});
//
//   @override
//   State<CrearFacturaDesktop> createState() => _CrearFacturaDesktopState();
// }
//
// class _CrearFacturaDesktopState extends State<CrearFacturaDesktop> {
//   final DatabaseHelper _dbHelper = DatabaseHelper();
//   final TextEditingController _searchClienteController = TextEditingController();
//   final TextEditingController _searchProductoController = TextEditingController();
//
//   ClienteModel? clienteSeleccionado;
//   List<ClienteModel> clientes = [];
//   List<CategoriaModel> categorias = [];
//   String? categoriaSeleccionadaId;
//   List<ProductoModel> productos = [];
//   List<ItemFacturaModel> carrito = [];
//
//   bool _cargandoClientes = true;
//   bool _cargandoCategorias = true;
//   bool _cargandoProductos = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _cargarDatos();
//   }
//
//   @override
//   void dispose() {
//     _searchClienteController.dispose();
//     _searchProductoController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _cargarDatos() async {
//     await _cargarClientes();
//     await _cargarCategorias();
//   }
//
//   Future<void> _cargarClientes() async {
//     setState(() => _cargandoClientes = true);
//     try {
//       final clientesDb = await _dbHelper.obtenerClientes();
//       setState(() {
//         clientes = clientesDb;
//         _cargandoClientes = false;
//       });
//     } catch (e) {
//       setState(() => _cargandoClientes = false);
//       _mostrarSnackBar('Error al cargar clientes: $e', isError: true);
//     }
//   }
//
//   Future<void> _cargarCategorias() async {
//     setState(() => _cargandoCategorias = true);
//     try {
//       final categoriasDb = await _dbHelper.obtenerCategorias();
//       setState(() {
//         categorias = categoriasDb;
//         _cargandoCategorias = false;
//         if (categoriaSeleccionadaId == null) {
//           categoriaSeleccionadaId = 'todas'; // Iniciar con "Todas"
//           _cargarTodosLosProductos();
//         }
//       });
//     } catch (e) {
//       setState(() => _cargandoCategorias = false);
//       _mostrarSnackBar('Error al cargar categorías: $e', isError: true);
//     }
//   }
//
//   Future<void> _cargarProductos(String categoriaId) async {
//     setState(() => _cargandoProductos = true);
//     try {
//       final productosDb = await _dbHelper.obtenerProductosPorCategoria(categoriaId);
//       setState(() {
//         productos = productosDb;
//         _cargandoProductos = false;
//       });
//     } catch (e) {
//       setState(() => _cargandoProductos = false);
//       _mostrarSnackBar('Error al cargar productos: $e', isError: true);
//     }
//   }
//
//   Future<void> _cargarTodosLosProductos() async {
//     setState(() => _cargandoProductos = true);
//     try {
//       final productosDb = await _dbHelper.obtenerProductos(); // Este método debe existir en tu DatabaseHelper
//       setState(() {
//         productos = productosDb;
//         _cargandoProductos = false;
//       });
//     } catch (e) {
//       setState(() => _cargandoProductos = false);
//       _mostrarSnackBar('Error al cargar productos: $e', isError: true);
//     }
//   }
//
//   String _formatearPrecio(double precio) {
//     final precioInt = precio.toInt();
//     return precioInt.toString().replaceAllMapped(
//       RegExp(r'\B(?=(\d{3})+(?!\d))'),
//           (match) => '.',
//     );
//   }
//
//   void _mostrarSnackBar(String mensaje, {bool isSuccess = false, bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isSuccess ? Icons.check_circle : (isError ? Icons.error : Icons.info),
//               color: Colors.white,
//               size: 20,
//             ),
//             const SizedBox(width: 12),
//             Expanded(child: Text(mensaje)),
//           ],
//         ),
//         backgroundColor: isSuccess ? AppColors.accent : (isError ? AppColors.error : AppColors.primary),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(16),
//         duration: const Duration(milliseconds: 2000),
//       ),
//     );
//   }
//
//   void _agregarProductoAlCarrito(ProductoModel producto) {
//     _mostrarDialogoAgregar(producto);
//   }
//
//   void _mostrarDialogoAgregar(ProductoModel producto) {
//     final TextEditingController cantidadController = TextEditingController(text: '1');
//     final Map<String, TextEditingController> controllersPorSabor = {};
//     final Map<String, int> cantidadPorSabor = {};
//
//     for (var sabor in producto.sabores) {
//       controllersPorSabor[sabor] = TextEditingController(text: '0');
//       cantidadPorSabor[sabor] = 0;
//     }
//
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Container(
//           width: 500,
//           constraints: const BoxConstraints(maxHeight: 600),
//           child: StatefulBuilder(
//             builder: (context, setState) {
//               int calcularTotal() {
//                 if (producto.sabores.length == 1) {
//                   return int.tryParse(cantidadController.text) ?? 0;
//                 }
//                 return cantidadPorSabor.values.fold(0, (sum, qty) => sum + qty);
//               }
//
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Header
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: AppColors.primary.withOpacity(0.05),
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(16),
//                         topRight: Radius.circular(16),
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: AppColors.primary.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: const Icon(Icons.add_shopping_cart, color: AppColors.primary, size: 24),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 producto.nombre,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                   color: AppColors.textPrimary,
//                                 ),
//                               ),
//                               Text(
//                                 '\$${_formatearPrecio(producto.precio)} c/u',
//                                 style: const TextStyle(fontSize: 14, color: AppColors.accent),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Divider(height: 1),
//                   // Content
//                   Flexible(
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           if (producto.sabores.length == 1) ...[
//                             TextField(
//                               controller: cantidadController,
//                               keyboardType: TextInputType.number,
//                               autofocus: true,
//                               decoration: InputDecoration(
//                                 labelText: 'Cantidad',
//                                 prefixIcon: const Icon(Icons.inventory, color: AppColors.primary),
//                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                               ),
//                               onChanged: (_) => setState(() {}),
//                             ),
//                           ] else ...[
//                             const Text(
//                               'Distribuir por sabor:',
//                               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                             ),
//                             const SizedBox(height: 16),
//                             ...producto.sabores.map((sabor) {
//                               return Padding(
//                                 padding: const EdgeInsets.only(bottom: 12),
//                                 child: Row(
//                                   children: [
//                                     Expanded(child: Text(sabor)),
//                                     SizedBox(
//                                       width: 100,
//                                       child: TextField(
//                                         controller: controllersPorSabor[sabor],
//                                         keyboardType: TextInputType.number,
//                                         textAlign: TextAlign.center,
//                                         decoration: InputDecoration(
//                                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                                           isDense: true,
//                                         ),
//                                         onChanged: (value) {
//                                           cantidadPorSabor[sabor] = int.tryParse(value) ?? 0;
//                                           setState(() {});
//                                         },
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                           ],
//                           const SizedBox(height: 16),
//                           Container(
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: AppColors.accentLight,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   'TOTAL: ${calcularTotal()} unidades',
//                                   style: const TextStyle(fontWeight: FontWeight.bold),
//                                 ),
//                                 Text(
//                                   '\$${_formatearPrecio(calcularTotal() * producto.precio)}',
//                                   style: const TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                     color: AppColors.accent,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   // Actions
//                   Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: const Text('Cancelar'),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () {
//                               final total = calcularTotal();
//                               if (total <= 0) {
//                                 _mostrarSnackBar('La cantidad debe ser mayor a 0', isError: true);
//                                 return;
//                               }
//
//                               final nuevoItem = ItemFacturaModel(
//                                 productoId: producto.id!,
//                                 nombreProducto: producto.nombre,
//                                 precioUnitario: producto.precio,
//                                 cantidadTotal: total,
//                                 cantidadPorSabor: producto.sabores.length > 1
//                                     ? cantidadPorSabor
//                                     : {producto.sabores[0]: total},
//                                 tieneSabores: producto.sabores.length > 1,
//                               );
//
//                               Navigator.pop(context);
//
//                               this.setState(() {
//                                 final index = carrito.indexWhere((item) => item.productoId == producto.id);
//                                 if (index != -1) {
//                                   carrito[index] = nuevoItem;
//                                 } else {
//                                   carrito.add(nuevoItem);
//                                 }
//                               });
//
//                               _mostrarSnackBar('${producto.nombre} agregado', isSuccess: true);
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: AppColors.accent,
//                             ),
//                             child: const Text('Agregar', style: TextStyle(color: Colors.white)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _guardarFactura() async {
//     if (clienteSeleccionado == null) {
//       _mostrarSnackBar('Selecciona un cliente', isError: true);
//       return;
//     }
//
//     if (carrito.isEmpty) {
//       _mostrarSnackBar('Agrega al menos un producto', isError: true);
//       return;
//     }
//
//     final factura = FacturaModel(
//       clienteId: clienteSeleccionado!.id!,
//       nombreCliente: clienteSeleccionado!.nombre,
//       direccionCliente: clienteSeleccionado!.direccion,
//       telefonoCliente: clienteSeleccionado!.telefono,
//       negocioCliente: clienteSeleccionado!.nombreNegocio,
//       observacionesCliente: clienteSeleccionado!.observaciones,
//       fecha: DateTime.now(),
//       items: carrito,
//       estado: 'pendiente',
//       total: carrito.fold(0.0, (sum, item) => sum + item.subtotal),
//     );
//
//     try {
//       await _dbHelper.insertarFactura(factura);
//       if (mounted) {
//         _mostrarSnackBar('Factura guardada', isSuccess: true);
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       _mostrarSnackBar('Error: $e', isError: true);
//     }
//   }
//
//   Widget _construirImagenProducto(String? imagenPath) {
//     if (imagenPath != null && imagenPath.isNotEmpty) {
//       if (imagenPath.startsWith('http')) {
//         return Image.network(
//           imagenPath,
//           fit: BoxFit.cover,
//           width: double.infinity,
//           height: double.infinity,
//           loadingBuilder: (context, child, loadingProgress) {
//             if (loadingProgress == null) return child;
//             return _imagenPlaceholder();
//           },
//           errorBuilder: (context, error, stackTrace) => _imagenPorDefecto(),
//         );
//       } else {
//         final file = File(imagenPath);
//         if (file.existsSync()) {
//           return Image.file(
//             file,
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//           );
//         }
//       }
//     }
//     return _imagenPorDefecto();
//   }
//
//   Widget _imagenPlaceholder() {
//     return Container(
//       color: AppColors.border,
//       child: const Center(
//         child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
//       ),
//     );
//   }
//
//   Widget _imagenPorDefecto() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             AppColors.primary.withOpacity(0.1),
//             AppColors.accent.withOpacity(0.1),
//           ],
//         ),
//       ),
//       child: const Center(
//         child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primary),
//       ),
//     );
//   }
//
//   Widget _buildPanelClientes() {
//     final clientesFiltrados = _searchClienteController.text.isEmpty
//         ? clientes
//         : clientes.where((c) {
//       final query = _searchClienteController.text.toLowerCase();
//       return c.nombre.toLowerCase().contains(query) ||
//           c.nombreNegocio.toLowerCase().contains(query) ||
//           c.direccion.toLowerCase().contains(query);
//     }).toList();
//
//     return Container(
//       width: 300,
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         border: Border(right: BorderSide(color: AppColors.border)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.05),
//               border: Border(bottom: BorderSide(color: AppColors.border)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(Icons.person, color: AppColors.primary, size: 20),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'Clientes',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: _searchClienteController,
//                   decoration: InputDecoration(
//                     hintText: 'Buscar...',
//                     prefixIcon: const Icon(Icons.search, size: 20),
//                     isDense: true,
//                     contentPadding: const EdgeInsets.symmetric(vertical: 8),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                   onChanged: (_) => setState(() {}),
//                 ),
//               ],
//             ),
//           ),
//           // Cliente seleccionado
//           if (clienteSeleccionado != null)
//             Container(
//               margin: const EdgeInsets.all(12),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: AppColors.accent.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: AppColors.accent),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.check_circle, color: AppColors.accent, size: 16),
//                       const SizedBox(width: 8),
//                       const Expanded(
//                         child: Text(
//                           'Cliente seleccionado',
//                           style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close, size: 16),
//                         onPressed: () => setState(() => clienteSeleccionado = null),
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     clienteSeleccionado!.nombre,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   if (clienteSeleccionado!.nombreNegocio.isNotEmpty)
//                     Text(
//                       clienteSeleccionado!.nombreNegocio,
//                       style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
//                     ),
//                   Text(
//                     clienteSeleccionado!.direccion,
//                     style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
//                   ),
//                 ],
//               ),
//             ),
//           // Lista de clientes
//           Expanded(
//             child: _cargandoClientes
//                 ? const Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//               padding: const EdgeInsets.all(8),
//               itemCount: clientesFiltrados.length,
//               itemBuilder: (context, index) {
//                 final cliente = clientesFiltrados[index];
//                 final isSelected = clienteSeleccionado?.id == cliente.id;
//                 return Card(
//                   color: isSelected ? AppColors.accent.withOpacity(0.1) : null,
//                   margin: const EdgeInsets.only(bottom: 8),
//                   child: ListTile(
//                     dense: true,
//                     leading: CircleAvatar(
//                       backgroundColor: isSelected ? AppColors.accent : AppColors.primary,
//                       child: Text(
//                         cliente.nombre[0].toUpperCase(),
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ),
//                     title: Text(
//                       cliente.nombre,
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                       ),
//                     ),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (cliente.nombreNegocio.isNotEmpty)
//                           Text(
//                             cliente.nombreNegocio,
//                             style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
//                           ),
//                         if (cliente.direccion.isNotEmpty)
//                           Text(
//                             cliente.direccion,
//                             style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                       ],
//                     ),
//                     onTap: () => setState(() => clienteSeleccionado = cliente),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPanelProductos() {
//     final productosFiltrados = _searchProductoController.text.isEmpty
//         ? productos
//         : productos.where((p) => p.nombre.toLowerCase().contains(_searchProductoController.text.toLowerCase())).toList();
//
//     return Expanded(
//       child: Column(
//         children: [
//           // Header con categorías y búsqueda
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               border: Border(bottom: BorderSide(color: AppColors.border)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Row(
//                   children: [
//                     Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
//                     SizedBox(width: 8),
//                     Text(
//                       'Productos',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: _searchProductoController,
//                   decoration: InputDecoration(
//                     hintText: 'Buscar productos...',
//                     prefixIcon: const Icon(Icons.search, size: 20),
//                     isDense: true,
//                     contentPadding: const EdgeInsets.symmetric(vertical: 8),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                   onChanged: (_) => setState(() {}),
//                 ),
//                 const SizedBox(height: 12),
//                 // Categorías horizontales
//                 SizedBox(
//                   height: 40,
//                   child: _cargandoCategorias
//                       ? const Center(child: CircularProgressIndicator())
//                       : ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: categorias.length + 1, // +1 para la opción "Todas"
//                     itemBuilder: (context, index) {
//                       // Primera opción: "Todas"
//                       if (index == 0) {
//                         final isSelected = categoriaSeleccionadaId == 'todos';
//                         return Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: ChoiceChip(
//                             label: const Text('Todos'),
//                             selected: isSelected,
//                             onSelected: (_) {
//                               setState(() {
//                                 categoriaSeleccionadaId = 'todos';
//                                 _cargarTodosLosProductos();
//                               });
//                             },
//                           ),
//                         );
//                       }
//
//                       // Las demás categorías
//                       final cat = categorias[index - 1];
//                       final isSelected = cat.id == categoriaSeleccionadaId;
//                       return Padding(
//                         padding: const EdgeInsets.only(right: 8),
//                         child: ChoiceChip(
//                           label: Text(cat.nombre),
//                           selected: isSelected,
//                           onSelected: (_) {
//                             setState(() {
//                               categoriaSeleccionadaId = cat.id;
//                               _cargarProductos(cat.id!);
//                             });
//                           },
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Grid de productos
//           Expanded(
//             child: _cargandoProductos
//                 ? const Center(child: CircularProgressIndicator())
//                 : productosFiltrados.isEmpty
//                 ? const Center(child: Text('Sin productos'))
//                 : GridView.builder(
//               padding: const EdgeInsets.all(16),
//               gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
//                 maxCrossAxisExtent: 200,
//                 childAspectRatio: 0.75,
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//               ),
//               itemCount: productosFiltrados.length,
//               itemBuilder: (context, index) {
//                 final producto = productosFiltrados[index];
//                 final estaEnCarrito = carrito.any((item) => item.productoId == producto.id);
//
//                 return Card(
//                   elevation: estaEnCarrito ? 4 : 1,
//                   child: InkWell(
//                     onTap: () => _agregarProductoAlCarrito(producto),
//                     borderRadius: BorderRadius.circular(8),
//                     child: Stack(
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Imagen del producto
//                             Expanded(
//                               child: ClipRRect(
//                                 borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
//                                 child: _construirImagenProducto(producto.imagenPath),
//                               ),
//                             ),
//                             // Información del producto
//                             Padding(
//                               padding: const EdgeInsets.all(8),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     producto.nombre,
//                                     style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
//                                     maxLines: 2,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Row(
//                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Text(
//                                         '\$${_formatearPrecio(producto.precio)}',
//                                         style: const TextStyle(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.bold,
//                                           color: AppColors.accent,
//                                         ),
//                                       ),
//                                       if (estaEnCarrito)
//                                         Container(
//                                           padding: const EdgeInsets.all(4),
//                                           decoration: const BoxDecoration(
//                                             color: AppColors.accent,
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: const Icon(
//                                             Icons.check,
//                                             color: Colors.white,
//                                             size: 14,
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         // Badge si está en el carrito
//                         if (estaEnCarrito)
//                           Positioned(
//                             top: 8,
//                             right: 8,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: AppColors.accent,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Text(
//                                 '${carrito.firstWhere((item) => item.productoId == producto.id).cantidadTotal}',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPanelCarrito() {
//     final total = carrito.fold(0.0, (sum, item) => sum + item.subtotal);
//
//     return Container(
//       width: 320,
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         border: Border(left: BorderSide(color: AppColors.border)),
//       ),
//       child: Column(
//         children: [
//           // Header
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.accent.withOpacity(0.05),
//               border: Border(bottom: BorderSide(color: AppColors.border)),
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     const Icon(Icons.shopping_cart, color: AppColors.accent, size: 20),
//                     const SizedBox(width: 8),
//                     const Expanded(
//                       child: Text(
//                         'Carrito',
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: AppColors.accent,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         '${carrito.length}',
//                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (carrito.isNotEmpty) ...[
//                   const SizedBox(height: 12),
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: AppColors.accentLight,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
//                         Text(
//                           '\$${_formatearPrecio(total)}',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.accent,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           // Lista de productos en carrito
//           Expanded(
//             child: carrito.isEmpty
//                 ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textSecondary),
//                   SizedBox(height: 16),
//                   Text('Carrito vacío', style: TextStyle(color: AppColors.textSecondary)),
//                 ],
//               ),
//             )
//                 : ListView.builder(
//               padding: const EdgeInsets.all(8),
//               itemCount: carrito.length,
//               itemBuilder: (context, index) {
//                 final item = carrito[index];
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   child: ListTile(
//                     dense: true,
//                     title: Text(item.nombreProducto, style: const TextStyle(fontSize: 13)),
//                     subtitle: Text(
//                       'Cantidad: ${item.cantidadTotal} - \$${_formatearPrecio(item.subtotal)}',
//                       style: const TextStyle(fontSize: 11),
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
//                       onPressed: () => setState(() => carrito.removeAt(index)),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           // Botón guardar
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               border: Border(top: BorderSide(color: AppColors.border)),
//             ),
//             child: ElevatedButton(
//               onPressed: carrito.isEmpty ? null : _guardarFactura,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.accent,
//                 minimumSize: const Size(double.infinity, 48),
//               ),
//               child: const Text(
//                 'Guardar Factura',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.surface,
//         title: const Text('Nueva Factura', style: TextStyle(fontWeight: FontWeight.bold)),
//       ),
//       body: Row(
//         children: [
//           _buildPanelClientes(),
//           _buildPanelProductos(),
//           _buildPanelCarrito(),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../datasources/database_helper.dart';
import '../../../model/categoria_model.dart';
import '../../../model/cliente_model.dart';
import '../../../model/factura_model.dart';
import '../../../model/prodcuto_model.dart';
import '../../../theme/app_colors.dart';

/// Vista unificada para crear facturas en desktop
/// Todo en una sola pantalla: Cliente (izquierda) + Productos (centro) + Carrito (derecha)
class CrearFacturaDesktop extends StatefulWidget {
  const CrearFacturaDesktop({super.key});

  @override
  State<CrearFacturaDesktop> createState() => _CrearFacturaDesktopState();
}

class _CrearFacturaDesktopState extends State<CrearFacturaDesktop> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchClienteController = TextEditingController();
  final TextEditingController _searchProductoController = TextEditingController();

  final TextEditingController _nombreClienteController = TextEditingController();
  final TextEditingController _negocioClienteController = TextEditingController();
  final TextEditingController _direccionClienteController = TextEditingController();
  final TextEditingController _telefonoClienteController = TextEditingController();
  final TextEditingController _observacionesClienteController = TextEditingController();
  final GlobalKey<FormState> _formKeyCliente = GlobalKey<FormState>();

  bool _modoClienteTemporal = false;

  ClienteModel? clienteSeleccionado;
  List<ClienteModel> clientes = [];
  List<CategoriaModel> categorias = [];
  String? categoriaSeleccionadaId;
  List<ProductoModel> productos = [];
  List<ItemFacturaModel> carrito = [];

  bool _cargandoClientes = true;
  bool _cargandoCategorias = true;
  bool _cargandoProductos = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchClienteController.dispose();
    _searchProductoController.dispose();
    _nombreClienteController.dispose();
    _negocioClienteController.dispose();
    _direccionClienteController.dispose();
    _telefonoClienteController.dispose();
    _observacionesClienteController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await _cargarClientes();
    await _cargarCategorias();
  }

  Future<void> _cargarClientes() async {
    setState(() => _cargandoClientes = true);
    try {
      final clientesDb = await _dbHelper.obtenerClientes();
      setState(() {
        clientes = clientesDb;
        _cargandoClientes = false;
      });
    } catch (e) {
      setState(() => _cargandoClientes = false);
      _mostrarSnackBar('Error al cargar clientes: $e', isError: true);
    }
  }

  Future<void> _cargarCategorias() async {
    setState(() => _cargandoCategorias = true);
    try {
      final categoriasDb = await _dbHelper.obtenerCategorias();
      setState(() {
        categorias = categoriasDb;
        _cargandoCategorias = false;
        if (categoriaSeleccionadaId == null) {
          categoriaSeleccionadaId = 'todas';
          _cargarTodosLosProductos();
        }
      });
    } catch (e) {
      setState(() => _cargandoCategorias = false);
      _mostrarSnackBar('Error al cargar categorías: $e', isError: true);
    }
  }

  Future<void> _cargarProductos(String categoriaId) async {
    setState(() => _cargandoProductos = true);
    try {
      final productosDb = await _dbHelper.obtenerProductosPorCategoria(categoriaId);
      setState(() {
        productos = productosDb;
        _cargandoProductos = false;
      });
    } catch (e) {
      setState(() => _cargandoProductos = false);
      _mostrarSnackBar('Error al cargar productos: $e', isError: true);
    }
  }

  Future<void> _cargarTodosLosProductos() async {
    setState(() => _cargandoProductos = true);
    try {
      final productosDb = await _dbHelper.obtenerProductos();
      setState(() {
        productos = productosDb;
        _cargandoProductos = false;
      });
    } catch (e) {
      setState(() => _cargandoProductos = false);
      _mostrarSnackBar('Error al cargar productos: $e', isError: true);
    }
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

  void _guardarClienteTemporal() {
    if (_formKeyCliente.currentState!.validate()) {
      final clienteTemporal = ClienteModel(
        id: null,
        nombre: _nombreClienteController.text.trim(),
        nombreNegocio: _negocioClienteController.text.trim(),
        direccion: _direccionClienteController.text.trim(),
        telefono: _telefonoClienteController.text.trim(),
        ruta: Ruta.ruta1,
        observaciones: _observacionesClienteController.text.trim().isEmpty
            ? null
            : _observacionesClienteController.text.trim(),
      );
      setState(() {
        clienteSeleccionado = clienteTemporal;
      });
      _mostrarSnackBar('Datos del cliente guardados', isSuccess: true);
    }
  }

  void _limpiarFormularioCliente() {
    _nombreClienteController.clear();
    _negocioClienteController.clear();
    _direccionClienteController.clear();
    _telefonoClienteController.clear();
    _observacionesClienteController.clear();
    setState(() {
      clienteSeleccionado = null;
    });
  }

  void _agregarProductoAlCarrito(ProductoModel producto) {
    _mostrarDialogoAgregar(producto);
  }

  void _mostrarDialogoAgregar(ProductoModel producto) {
    final TextEditingController cantidadController = TextEditingController(text: '1');
    final Map<String, TextEditingController> controllersPorSabor = {};
    final Map<String, int> cantidadPorSabor = {};

    for (var sabor in producto.sabores) {
      controllersPorSabor[sabor] = TextEditingController(text: '0');
      cantidadPorSabor[sabor] = 0;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          child: StatefulBuilder(
            builder: (context, setState) {
              int calcularTotal() {
                if (producto.sabores.length == 1) {
                  return int.tryParse(cantidadController.text) ?? 0;
                }
                return cantidadPorSabor.values.fold(0, (sum, qty) => sum + qty);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_shopping_cart, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '\$${_formatearPrecio(producto.precio)} c/u',
                                style: const TextStyle(fontSize: 14, color: AppColors.accent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (producto.sabores.length == 1) ...[
                            TextField(
                              controller: cantidadController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: 'Cantidad',
                                prefixIcon: const Icon(Icons.inventory, color: AppColors.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ] else ...[
                            const Text(
                              'Distribuir por sabor:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ...producto.sabores.map((sabor) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(sabor)),
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        controller: controllersPorSabor[sabor],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          cantidadPorSabor[sabor] = int.tryParse(value) ?? 0;
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL: ${calcularTotal()} unidades',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${_formatearPrecio(calcularTotal() * producto.precio)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final total = calcularTotal();
                              if (total <= 0) {
                                _mostrarSnackBar('La cantidad debe ser mayor a 0', isError: true);
                                return;
                              }

                              final nuevoItem = ItemFacturaModel(
                                productoId: producto.id!,
                                nombreProducto: producto.nombre,
                                precioUnitario: producto.precio,
                                cantidadTotal: total,
                                cantidadPorSabor: producto.sabores.length > 1
                                    ? cantidadPorSabor
                                    : {producto.sabores[0]: total},
                                tieneSabores: producto.sabores.length > 1,
                              );

                              Navigator.pop(context);

                              this.setState(() {
                                final index = carrito.indexWhere((item) => item.productoId == producto.id);
                                if (index != -1) {
                                  carrito[index] = nuevoItem;
                                } else {
                                  carrito.add(nuevoItem);
                                }
                              });

                              _mostrarSnackBar('${producto.nombre} agregado', isSuccess: true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                            ),
                            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _guardarFactura() async {
    if (clienteSeleccionado == null) {
      _mostrarSnackBar('Selecciona un cliente o ingresa datos temporales', isError: true);
      return;
    }

    if (carrito.isEmpty) {
      _mostrarSnackBar('Agrega al menos un producto', isError: true);
      return;
    }

    final factura = FacturaModel(
      clienteId: clienteSeleccionado!.id,
      nombreCliente: clienteSeleccionado!.nombre,
      direccionCliente: clienteSeleccionado!.direccion,
      telefonoCliente: clienteSeleccionado!.telefono,
      negocioCliente: clienteSeleccionado!.nombreNegocio,
      observacionesCliente: clienteSeleccionado!.observaciones,
      fecha: DateTime.now(),
      items: carrito,
      estado: 'pendiente',
      total: carrito.fold(0.0, (sum, item) => sum + item.subtotal),
    );

    try {
      await _dbHelper.insertarFactura(factura);
      if (mounted) {
        _mostrarSnackBar('Factura guardada', isSuccess: true);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _mostrarSnackBar('Error: $e', isError: true);
    }
  }

  Widget _construirImagenProducto(String? imagenPath) {
    if (imagenPath != null && imagenPath.isNotEmpty) {
      if (imagenPath.startsWith('http')) {
        return Image.network(
          imagenPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _imagenPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) => _imagenPorDefecto(),
        );
      } else {
        final file = File(imagenPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        }
      }
    }
    return _imagenPorDefecto();
  }

  Widget _imagenPlaceholder() {
    return Container(
      color: AppColors.border,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      ),
    );
  }

  Widget _imagenPorDefecto() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPanelClientes() {
    final clientesFiltrados = _searchClienteController.text.isEmpty
        ? clientes
        : clientes.where((c) {
      final query = _searchClienteController.text.toLowerCase();
      return c.nombre.toLowerCase().contains(query) ||
          c.nombreNegocio.toLowerCase().contains(query) ||
          c.direccion.toLowerCase().contains(query);
    }).toList();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Header con toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _modoClienteTemporal = false;
                              // Limpiar cliente temporal si cambia de modo
                              if (clienteSeleccionado?.id == null) {
                                clienteSeleccionado = null;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_modoClienteTemporal ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 18,
                                  color: !_modoClienteTemporal ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Clientes',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: !_modoClienteTemporal ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _modoClienteTemporal = true;
                              // Limpiar cliente existente si cambia de modo
                              if (clienteSeleccionado?.id != null) {
                                clienteSeleccionado = null;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _modoClienteTemporal ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 18,
                                  color: _modoClienteTemporal ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Temporal',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _modoClienteTemporal ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Búsqueda solo para clientes existentes
                if (!_modoClienteTemporal)
                  TextField(
                    controller: _searchClienteController,
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
              ],
            ),
          ),
          // Cliente seleccionado (mostrar para ambos modos)
          if (clienteSeleccionado != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.accent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          clienteSeleccionado!.id == null ? 'Cliente temporal' : 'Cliente seleccionado',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            clienteSeleccionado = null;
                            if (_modoClienteTemporal) {
                              _limpiarFormularioCliente();
                            }
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    clienteSeleccionado!.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (clienteSeleccionado!.nombreNegocio.isNotEmpty)
                    Text(
                      clienteSeleccionado!.nombreNegocio,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  Text(
                    clienteSeleccionado!.direccion,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (clienteSeleccionado!.telefono.isNotEmpty)
                    Text(
                      clienteSeleccionado!.telefono,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _modoClienteTemporal
                ? _buildFormularioClienteTemporal()
                : _buildListaClientes(clientesFiltrados),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioClienteTemporal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyCliente,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del Cliente',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ingresa la información del cliente temporal',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Nombre del cliente
            TextFormField(
              controller: _nombreClienteController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre del Cliente',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.person, color: AppColors.primary, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Nombre del negocio
            TextFormField(
              controller: _negocioClienteController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre del Negocio',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.store, color: AppColors.primary, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El negocio es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Dirección
            TextFormField(
              controller: _direccionClienteController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Dirección',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La dirección es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Teléfono
            TextFormField(
              controller: _telefonoClienteController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El teléfono es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            // Observaciones
            TextFormField(
              controller: _observacionesClienteController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Observaciones (opcional)',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.note, color: AppColors.primary, size: 20),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            // Botones
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _limpiarFormularioCliente,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _guardarClienteTemporal,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Guardar', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaClientes(List<ClienteModel> clientesFiltrados) {
    return _cargandoClientes
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: clientesFiltrados.length,
      itemBuilder: (context, index) {
        final cliente = clientesFiltrados[index];
        final isSelected = clienteSeleccionado?.id == cliente.id;
        return Card(
          color: isSelected ? AppColors.accent.withOpacity(0.1) : null,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: isSelected ? AppColors.accent : AppColors.primary,
              child: Text(
                cliente.nombre[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              cliente.nombre,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cliente.nombreNegocio.isNotEmpty)
                  Text(
                    cliente.nombreNegocio,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                if (cliente.direccion.isNotEmpty)
                  Text(
                    cliente.direccion,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            onTap: () => setState(() => clienteSeleccionado = cliente),
          ),
        );
      },
    );
  }

  Widget _buildPanelProductos() {
    final productosFiltrados = _searchProductoController.text.isEmpty
        ? productos
        : productos.where((p) => p.nombre.toLowerCase().contains(_searchProductoController.text.toLowerCase())).toList();

    return Expanded(
      child: Column(
        children: [
          // Header con categorías y búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Productos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchProductoController,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Categorías horizontales
                SizedBox(
                  height: 40,
                  child: _cargandoCategorias
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categorias.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = categoriaSeleccionadaId == 'todos';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Todos'),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                categoriaSeleccionadaId = 'todos';
                                _cargarTodosLosProductos();
                              });
                            },
                          ),
                        );
                      }

                      final cat = categorias[index - 1];
                      final isSelected = cat.id == categoriaSeleccionadaId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat.nombre),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              categoriaSeleccionadaId = cat.id;
                              _cargarProductos(cat.id!);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Grid de productos
          Expanded(
            child: _cargandoProductos
                ? const Center(child: CircularProgressIndicator())
                : productosFiltrados.isEmpty
                ? const Center(child: Text('Sin productos'))
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: productosFiltrados.length,
              itemBuilder: (context, index) {
                final producto = productosFiltrados[index];
                final estaEnCarrito = carrito.any((item) => item.productoId == producto.id);

                return Card(
                  elevation: estaEnCarrito ? 4 : 1,
                  child: InkWell(
                    onTap: () => _agregarProductoAlCarrito(producto),
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                child: _construirImagenProducto(producto.imagenPath),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto.nombre,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${_formatearPrecio(producto.precio)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      if (estaEnCarrito)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (estaEnCarrito)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${carrito.firstWhere((item) => item.productoId == producto.id).cantidadTotal}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelCarrito() {
    final total = carrito.fold(0.0, (sum, item) => sum + item.subtotal);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Carrito',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${carrito.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (carrito.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '\$${_formatearPrecio(total)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Lista de productos en carrito
          Expanded(
            child: carrito.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Carrito vacío', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: carrito.length,
              itemBuilder: (context, index) {
                final item = carrito[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text(item.nombreProducto, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      'Cantidad: ${item.cantidadTotal} - \$${_formatearPrecio(item.subtotal)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                      onPressed: () => setState(() => carrito.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
          ),
          // Botón guardar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton(
              onPressed: carrito.isEmpty ? null : _guardarFactura,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Guardar Factura',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Nueva Factura', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Row(
        children: [
          _buildPanelClientes(),
          _buildPanelProductos(),
          _buildPanelCarrito(),
        ],
      ),
    );
  }
}

