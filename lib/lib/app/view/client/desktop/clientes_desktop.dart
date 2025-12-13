
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../datasources/database_helper.dart';
import '../../../model/cliente_model.dart';
import '../../../theme/app_colors.dart';
import '../crear_cliente_page.dart';
import '../editar_cliente_page.dart';
import '../historial_facturas_cliente_page.dart';
import '../mapa_clientes_page.dart';
import '../mobile/clientes_mobile.dart';
import '../view_ubicacion_cliente_page.dart';


class ClientesDesktop extends ConsumerStatefulWidget {
  const ClientesDesktop({super.key});

  @override
  ConsumerState<ClientesDesktop> createState() => _ClientesDesktopState();
}

class _ClientesDesktopState extends ConsumerState<ClientesDesktop> {
  final TextEditingController _searchController = TextEditingController();
  String? _rutaSeleccionada;

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

  List<ClienteModel> _filtrarClientes(List<ClienteModel> clientes) {
    var resultado = clientes;

    // Filtrar por ruta
    if (_rutaSeleccionada != null && _rutaSeleccionada != 'Todas') {
      resultado = resultado.where((c) =>
      c.ruta?.toString().split('.').last == _rutaSeleccionada?.toLowerCase().replaceAll(' ', '')
      ).toList();
    }

    // Filtrar por búsqueda
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      resultado = resultado.where((c) =>
      c.nombre.toLowerCase().contains(query) ||
          (c.nombreNegocio?.toLowerCase().contains(query) ?? false) ||
          (c.direccion?.toLowerCase().contains(query) ?? false) ||
          (c.telefono?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    return resultado;
  }

  Map<String, int> _calcularEstadisticas(List<ClienteModel> clientes) {
    final stats = <String, int>{};
    stats['total'] = clientes.length;
    stats['ruta1'] = clientes.where((c) => c.ruta?.toString().split('.').last == 'ruta1').length;
    stats['ruta2'] = clientes.where((c) => c.ruta?.toString().split('.').last == 'ruta2').length;
    stats['ruta3'] = clientes.where((c) => c.ruta?.toString().split('.').last == 'ruta3').length;
    stats['conTelefono'] = clientes.where((c) => c.telefono != null && c.telefono!.isNotEmpty).length;
    stats['conUbicacion'] = clientes.where((c) => c.latitud != null && c.longitud != null).length;
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
          _buildStatCard('Total Clientes', stats['total']!, Icons.people, AppColors.primary),
          const SizedBox(width: 16),
          _buildStatCard('Ruta 1', stats['ruta1']!, Icons.route, AppColors.accent),
          const SizedBox(width: 16),
          _buildStatCard('Ruta 2', stats['ruta2']!, Icons.route, AppColors.accent),
          const SizedBox(width: 16),
          _buildStatCard('Ruta 3', stats['ruta3']!, Icons.route, AppColors.accent),
          const SizedBox(width: 16),
          _buildStatCard('Con Teléfono', stats['conTelefono']!, Icons.phone, AppColors.primary),
          const SizedBox(width: 16),
          _buildStatCard('Con Ubicación', stats['conUbicacion']!, Icons.location_on, AppColors.primary),
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

  Future<void> _realizarLlamada(String telefono) async {
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri telUri = Uri(scheme: 'tel', path: telefonoLimpio);

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        _mostrarSnackBar('No se puede realizar la llamada', isError: true);
      }
    } catch (e) {
      _mostrarSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _abrirWhatsApp(String telefono) async {
    String telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    if (!telefonoLimpio.startsWith('+')) {
      if (telefonoLimpio.startsWith('57')) {
        telefonoLimpio = '+$telefonoLimpio';
      } else {
        telefonoLimpio = '+57$telefonoLimpio';
      }
    }

    final Uri whatsappUri = Uri.parse('https://wa.me/$telefonoLimpio');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        _mostrarSnackBar('No se puede abrir WhatsApp', isError: true);
      }
    } catch (e) {
      _mostrarSnackBar('Error: $e', isError: true);
    }
  }

  void _confirmarEliminarCliente(ClienteModel cliente) {
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
            const Text('Eliminar Cliente'),
          ],
        ),
        content: Text('¿Eliminar a ${cliente.nombre}?\n\nEsta acción no se puede deshacer.'),
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
                await dbHelper.eliminarCliente(cliente.id!);
                ref.invalidate(clientesProvider);
                if (context.mounted) {
                  _mostrarSnackBar('Cliente eliminado', isSuccess: true);
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

  void _editarCliente(ClienteModel cliente) async {
    final dbHelper = DatabaseHelper();
    final clienteActualizado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarClientePage(cliente: cliente)),
    );

    if (clienteActualizado != null) {
      try {
        await dbHelper.actualizarCliente(clienteActualizado);
        ref.invalidate(clientesProvider);
        if (mounted) {
          _mostrarSnackBar('Cliente actualizado', isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          _mostrarSnackBar('Error: $e', isError: true);
        }
      }
    }
  }

  void _verHistorial(ClienteModel cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistorialFacturasClientePage(cliente: cliente)),
    );
  }

  void _crearCliente() async {
    final dbHelper = DatabaseHelper();
    final nuevoCliente = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearClientePage()),
    );

    if (nuevoCliente != null) {
      try {
        await dbHelper.insertarCliente(nuevoCliente);
        ref.invalidate(clientesProvider);
        if (mounted) {
          _mostrarSnackBar('Cliente ${nuevoCliente.nombre} creado', isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          _mostrarSnackBar('Error: $e', isError: true);
        }
      }
    }
  }

  Widget _buildTabla(List<ClienteModel> clientes) {
    if (clientes.isEmpty) {
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
              child: Icon(Icons.people_outline, size: 80, color: AppColors.primary.withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin clientes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agrega tu primer cliente para comenzar',
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
              onPressed: _crearCliente,
              icon: const Icon(Icons.add, size: 22),
              label: const Text('Agregar Cliente', style: TextStyle(fontSize: 16)),
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
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2.5),
            4: FlexColumnWidth(1.5),
            5: FlexColumnWidth(1.2),
            6: FixedColumnWidth(200),
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
                _buildHeaderCell('Negocio'),
                _buildHeaderCell('Cliente'),
                _buildHeaderCell('Dirección'),
                _buildHeaderCell('Teléfono'),
                _buildHeaderCell('Ruta'),
                _buildHeaderCell('Acciones', center: true),
              ],
            ),
            // Rows
            ...clientes.asMap().entries.map((entry) {
              final index = entry.key;
              final cliente = entry.value;
              final isEven = index % 2 == 0;

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
                            child: Icon(Icons.store, color: AppColors.primary, size: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cliente.nombreNegocio ?? 'Sin negocio',
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
                      cliente.nombre,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildDataCell(
                    Text(
                      cliente.direccion ?? 'Sin dirección',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildDataCell(
                    cliente.telefono != null && cliente.telefono!.isNotEmpty
                        ? Text(
                      cliente.telefono!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    )
                        : const Text(
                      'Sin teléfono',
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
                        cliente.ruta?.toString().split('.').last.toUpperCase() ?? 'SIN RUTA',
                        style: const TextStyle(
                          fontSize: 11,
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
                        if (cliente.telefono != null && cliente.telefono!.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(Icons.phone, size: 18),
                            color: AppColors.primary,
                            tooltip: 'Llamar',
                            onPressed: () => _realizarLlamada(cliente.telefono!),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chat, size: 18),
                            color: AppColors.primary,
                            tooltip: 'WhatsApp',
                            onPressed: () => _abrirWhatsApp(cliente.telefono!),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.history, size: 18),
                          color: AppColors.primary,
                          tooltip: 'Historial',
                          onPressed: () => _verHistorial(cliente),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppColors.primary,
                          tooltip: 'Editar',
                          onPressed: () => _editarCliente(cliente),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppColors.error,
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminarCliente(cliente),
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
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const Text(
          'Gestión de Clientes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
        ),
        actions: [
          Container(
            width: 300,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
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
          DropdownButton<String>(
            value: _rutaSeleccionada ?? 'Todas',
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            underline: Container(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            items: ['Todas', 'Ruta 1', 'Ruta 2', 'Ruta 3'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Icon(
                      value == 'Todas' ? Icons.all_inclusive : Icons.route,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(value),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _rutaSeleccionada = newValue;
              });
            },
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _crearCliente,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Nuevo Cliente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: clientesAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Cargando clientes...', style: TextStyle(color: AppColors.textSecondary)),
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
                onPressed: () => ref.invalidate(clientesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (clientes) {
          final clientesFiltrados = _filtrarClientes(clientes);
          final stats = _calcularEstadisticas(clientes);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildEstadisticas(stats),
              ),
              Expanded(child: _buildTabla(clientesFiltrados)),
            ],
          );
        },
      ),
    );
  }
}

class FiltrosNotifier extends StateNotifier<FiltrosState> {
  FiltrosNotifier() : super(FiltrosState());

  void setRutaIndex(int index) {
    state = state.copyWith(rutaIndex: index);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = FiltrosState();
  }
}

final filtrosProvider = StateNotifierProvider<FiltrosNotifier, FiltrosState>((ref) {
  return FiltrosNotifier();
});

// ============= PROVIDERS =============
final clientesProvider = StreamProvider<List<ClienteModel>>((ref) {
  final dbHelper = DatabaseHelper();
  return dbHelper.streamClientes();
});

final clientesPorRutaProvider = FutureProvider.family<List<ClienteModel>, String?>((ref, rutaValue) async {
  final clientesAsync = ref.watch(clientesProvider);

  return clientesAsync.whenData((clientes) {
    if (rutaValue == null) {
      return clientes;
    }
    return clientes.where((cliente) {
      return cliente.ruta?.toString().split('.').last == rutaValue;
    }).toList();
  }).value ?? [];
});

const List<Map<String, String?>> rutasDisponibles = [
  {'label': 'Todas', 'value': null},
  {'label': 'Ruta 1', 'value': 'ruta1'},
  {'label': 'Ruta 2', 'value': 'ruta2'},
  {'label': 'Ruta 3', 'value': 'ruta3'},
];

final clientesFiltradosProvider = Provider<List<ClienteModel>>((ref) {
  final filtros = ref.watch(filtrosProvider);
  final rutaSeleccionada = rutasDisponibles[filtros.rutaIndex]['value'];
  final clientesPorRuta = ref.watch(clientesPorRutaProvider(rutaSeleccionada));

  return clientesPorRuta.whenData((clientes) {
    return clientes.where((cliente) {
      final query = filtros.searchQuery.toLowerCase();
      final coincideBusqueda = filtros.searchQuery.isEmpty ||
          cliente.nombre.toLowerCase().contains(query) ||
          (cliente.nombreNegocio?.toLowerCase().contains(query) ?? false) ||
          (cliente.direccion?.toLowerCase().contains(query) ?? false);
      return coincideBusqueda;
    }).toList();
  }).maybeWhen(data: (data) => data, orElse: () => []);
});

// ============= PÁGINA MÓVIL =============
class ClientesMobile extends ConsumerStatefulWidget {
  const ClientesMobile({super.key});

  @override
  ConsumerState<ClientesMobile> createState() => _ClientesMobileState();
}

class _ClientesMobileState extends ConsumerState<ClientesMobile> {
  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  void _mostrarSelectorRutas(BuildContext context) {
    final filtros = ref.read(filtrosProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.route, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Seleccionar Ruta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rutasDisponibles.asMap().entries.map((entry) {
            final index = entry.key;
            final ruta = entry.value;
            final isSelected = index == filtros.rutaIndex;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withOpacity(0.15) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: AppColors.accent, width: 2) : null,
                ),
                child: Center(
                  child: Icon(
                    index == 0 ? Icons.all_inclusive : Icons.route,
                    color: isSelected ? AppColors.accent : AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              title: Text(
                ruta['label']!,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              trailing: isSelected
                  ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
                  : const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              onTap: () {
                Navigator.pop(sheetContext);
                ref.read(filtrosProvider.notifier).setRutaIndex(index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRouteSelector() {
    final filtros = ref.watch(filtrosProvider);
    final rutaActual = rutasDisponibles[filtros.rutaIndex];

    return GestureDetector(
      onTap: () => _mostrarSelectorRutas(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.route, color: Colors.white, size: 14),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              rutaActual['label']!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int totalPages, int currentPage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${currentPage + 1}/$totalPages',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Row(
          children: List.generate(
            totalPages > 5 ? 5 : totalPages,
                (index) {
              int dotIndex = index;
              if (totalPages > 5) {
                if (currentPage < 3) {
                  dotIndex = index;
                } else if (currentPage > totalPages - 3) {
                  dotIndex = totalPages - 5 + index;
                } else {
                  dotIndex = currentPage - 2 + index;
                }
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: dotIndex == currentPage ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotIndex == currentPage ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarOpcionesComunicacion(BuildContext context, ClienteModel cliente) {
    if (cliente.telefono == null || cliente.telefono!.isEmpty) {
      _mostrarSnackBar('Este cliente no tiene número de teléfono', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.contact_phone, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombreNegocio ?? cliente.nombre,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          cliente.telefono!,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone, color: AppColors.primary, size: 20),
              ),
              title: const Text('Llamada telefónica'),
              subtitle: const Text('Abrir marcador', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                _realizarLlamada(context, cliente.telefono!);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat, color: AppColors.primary, size: 20),
              ),
              title: const Text('WhatsApp'),
              subtitle: const Text('Abrir chat', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(sheetContext);
                _abrirWhatsApp(context, cliente.telefono!);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _realizarLlamada(BuildContext context, String telefono) async {
    final telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri telUri = Uri(scheme: 'tel', path: telefonoLimpio);

    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      } else {
        if (context.mounted) {
          _mostrarSnackBar('No se puede realizar la llamada', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _mostrarSnackBar('Error al realizar la llamada: $e', isError: true);
      }
    }
  }

  Future<void> _abrirWhatsApp(BuildContext context, String telefono) async {
    String telefonoLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    if (!telefonoLimpio.startsWith('+')) {
      if (telefonoLimpio.startsWith('57')) {
        telefonoLimpio = '+$telefonoLimpio';
      } else {
        telefonoLimpio = '+57$telefonoLimpio';
      }
    }

    final Uri whatsappUri = Uri.parse('https://wa.me/$telefonoLimpio');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _mostrarSnackBar('No se puede abrir WhatsApp', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _mostrarSnackBar('Error al abrir WhatsApp: $e', isError: true);
      }
    }
  }

  void _mostrarOpcionesCliente(BuildContext context, ClienteModel cliente) {
    final dbHelper = DatabaseHelper();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        (cliente.nombreNegocio ?? cliente.nombre).substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombreNegocio ?? 'Sin negocio',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          cliente.nombre,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        if (cliente.direccion != null)
                          Text(
                            cliente.direccion!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.contact_phone, color: AppColors.primary, size: 20),
                ),
                title: const Text('Comunicar'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _mostrarOpcionesComunicacion(context, cliente);
                },
              ),
            if (cliente.latitud != null && cliente.longitud != null)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 20),
                ),
                title: const Text('Ver en mapa'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewUbicacionClientePage(cliente: cliente)),
                  );
                },
              ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
              ),
              title: const Text('Editar cliente'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final clienteActualizado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditarClientePage(cliente: cliente)),
                );

                if (clienteActualizado != null) {
                  try {
                    await dbHelper.actualizarCliente(clienteActualizado);
                    ref.invalidate(clientesProvider);
                    if (context.mounted) {
                      _mostrarSnackBar('Cliente actualizado', isSuccess: true);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _mostrarSnackBar('Error: $e', isError: true);
                    }
                  }
                }
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history, color: AppColors.primary, size: 20),
              ),
              title: const Text('Historial de facturas'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistorialFacturasClientePage(cliente: cliente)),
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              ),
              title: const Text('Eliminar cliente', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmarEliminarCliente(context, cliente);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarCliente(BuildContext context, ClienteModel cliente) {
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
            const Text('Eliminar Cliente'),
          ],
        ),
        content: Text('¿Eliminar a ${cliente.nombre}?\n\nEsta acción no se puede deshacer.'),
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
                await dbHelper.eliminarCliente(cliente.id!);
                ref.invalidate(clientesProvider);
                if (context.mounted) {
                  _mostrarSnackBar('Cliente eliminado', isSuccess: true);
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

  Widget _construirListaClientes(List<ClienteModel> clientesFiltrados) {
    if (clientesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline, size: 64, color: AppColors.primary.withOpacity(0.3)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin clientes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega tu primer cliente',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _crearCliente(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar Cliente'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: clientesFiltrados.length,
      itemBuilder: (context, index) {
        final cliente = clientesFiltrados[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _mostrarOpcionesCliente(context, cliente),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.store, color: AppColors.primary, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.nombreNegocio ?? 'Sin negocio',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cliente.nombre,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (cliente.direccion != null)
                            Text(
                              cliente.direccion!,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cliente.ruta?.toString().split('.').last.toUpperCase() ?? 'SIN RUTA',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _crearCliente(BuildContext context) async {
    final dbHelper = DatabaseHelper();
    final nuevoCliente = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearClientePage()),
    );

    if (nuevoCliente != null) {
      try {
        await dbHelper.insertarCliente(nuevoCliente);
        ref.invalidate(clientesProvider);
        if (context.mounted) {
          _mostrarSnackBar('Cliente ${nuevoCliente.nombre} creado', isSuccess: true);
        }
      } catch (e) {
        if (context.mounted) {
          _mostrarSnackBar('Error: $e', isError: true);
        }
      }
    }
  }

  void _abrirMapaClientes() {
    final clientesAsync = ref.read(clientesProvider);

    clientesAsync.whenData((clientes) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MapaClientesPage(clientes: clientes)),
      );
    }).whenOrNull(
      error: (err, stack) {
        _mostrarSnackBar('Error al cargar clientes: $err', isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);
    final filtros = ref.watch(filtrosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 16,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar clientes...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          onChanged: (value) {
            ref.read(filtrosProvider.notifier).setSearchQuery(value);
          },
        )
            : _buildRouteSelector(),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(filtrosProvider.notifier).setSearchQuery('');
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              tooltip: 'Buscar',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.map_outlined, color: AppColors.primary),
              tooltip: 'Ver mapa',
              onPressed: _abrirMapaClientes,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              tooltip: 'Nuevo cliente',
              onPressed: () => _crearCliente(context),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
            ),
            child: _buildPageIndicator(rutasDisponibles.length, filtros.rutaIndex),
          ),
          Expanded(
            child: clientesAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Cargando clientes...', style: TextStyle(color: AppColors.textSecondary)),
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
                      onPressed: () => ref.invalidate(clientesProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (clientes) {
                return PageView.builder(
                  controller: _pageController,
                  itemCount: rutasDisponibles.length,
                  onPageChanged: (index) {
                    ref.read(filtrosProvider.notifier).setRutaIndex(index);
                  },
                  itemBuilder: (context, pageIndex) {
                    final rutaValue = rutasDisponibles[pageIndex]['value'];
                    final clientesDeRuta = rutaValue == null
                        ? clientes
                        : clientes.where((c) => c.ruta?.toString().split('.').last == rutaValue).toList();

                    final clientesBuscados = filtros.searchQuery.isEmpty
                        ? clientesDeRuta
                        : clientesDeRuta.where((c) =>
                    c.nombre.toLowerCase().contains(filtros.searchQuery.toLowerCase()) ||
                        c.direccion.toLowerCase().contains(filtros.searchQuery.toLowerCase()) ||
                        (c.nombreNegocio?.toLowerCase().contains(filtros.searchQuery.toLowerCase()) ?? false)
                    ).toList();

                    return _construirListaClientes(clientesBuscados);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}