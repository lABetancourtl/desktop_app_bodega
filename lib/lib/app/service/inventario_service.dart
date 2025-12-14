// lib/service/inventario_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/inventario_model.dart';

class InventarioService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ Obtener inventario de un producto
  Future<InventarioModel?> obtenerInventarioPorProducto(String productoId) async {
    try {
      final response = await _supabase
          .from('inventarios')
          .select()
          .eq('producto_id', productoId)
          .maybeSingle();

      if (response == null) return null;
      return InventarioModel.fromMap(response);
    } catch (e) {
      throw Exception('Error al obtener inventario: $e');
    }
  }

  // ✅ Obtener todos los inventarios
  Future<List<InventarioModel>> obtenerTodosLosInventarios() async {
    try {
      final response = await _supabase
          .from('inventarios')
          .select()
          .order('ultima_actualizacion', ascending: false);

      return (response as List)
          .map((item) => InventarioModel.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener inventarios: $e');
    }
  }

  // ✅ Stream de inventarios en tiempo real
  Stream<List<InventarioModel>> streamInventarios() {
    return _supabase
        .from('inventarios')
        .stream(primaryKey: ['id'])
        .order('ultima_actualizacion', ascending: false)
        .map((data) => data.map((item) => InventarioModel.fromMap(item)).toList());
  }

  // ✅ Crear inventario inicial para un producto
  Future<InventarioModel> crearInventario({
    required String productoId,
    int cantidadInicial = 0,
    int? cantidadMinima,
  }) async {
    try {
      final data = {
        'producto_id': productoId,
        'cantidad': cantidadInicial,
        'cantidad_minima': cantidadMinima ?? 10,
      };

      final response = await _supabase
          .from('inventarios')
          .insert(data)
          .select()
          .single();

      return InventarioModel.fromMap(response);
    } catch (e) {
      throw Exception('Error al crear inventario: $e');
    }
  }

  // ✅ Actualizar cantidad (CORREGIDO)
  Future<InventarioModel> actualizarCantidad({
    required String productoId,
    required int nuevaCantidad,
  }) async {
    if (nuevaCantidad < 0) {
      throw Exception('La cantidad no puede ser negativa');
    }

    try {
      final response = await _supabase
          .from('inventarios')
          .update({'cantidad': nuevaCantidad})
          .eq('producto_id', productoId)
          .select()
          .single();

      return InventarioModel.fromMap(response);
    } catch (e) {
      throw Exception('Error al actualizar cantidad: $e');
    }
  }

  // ✅ Entrada de inventario
  Future<InventarioModel> registrarEntrada({
    required String productoId,
    required int cantidad,
    String? motivo,
  }) async {
    if (cantidad <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    try {
      final inventarioActual = await obtenerInventarioPorProducto(productoId);

      if (inventarioActual == null) {
        throw Exception('No existe inventario para este producto');
      }

      final nuevaCantidad = inventarioActual.cantidad + cantidad;

      return await actualizarCantidad(
        productoId: productoId,
        nuevaCantidad: nuevaCantidad,
      );
    } catch (e) {
      throw Exception('Error al registrar entrada: $e');
    }
  }

  // ✅ Salida de inventario
  Future<InventarioModel> registrarSalida({
    required String productoId,
    required int cantidad,
    String? motivo,
  }) async {
    if (cantidad <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    try {
      final inventarioActual = await obtenerInventarioPorProducto(productoId);

      if (inventarioActual == null) {
        throw Exception('No existe inventario para este producto');
      }

      if (inventarioActual.cantidad < cantidad) {
        throw Exception('No hay suficiente inventario disponible');
      }

      final nuevaCantidad = inventarioActual.cantidad - cantidad;

      return await actualizarCantidad(
        productoId: productoId,
        nuevaCantidad: nuevaCantidad,
      );
    } catch (e) {
      throw Exception('Error al registrar salida: $e');
    }
  }

  // ✅ Obtener historial de movimientos (CORREGIDO)
  Future<List<MovimientoInventarioModel>> obtenerHistorialMovimientos({
    String? productoId,
    int limit = 50,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('movimientos_inventario')
          .select();

      if (productoId != null) {
        query = query.eq('producto_id', productoId);
      }

      final response = await query
          .order('fecha', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => MovimientoInventarioModel.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }

  // ✅ Ajustar inventario manualmente
  Future<InventarioModel> ajustarInventario({
    required String productoId,
    required int cantidadNueva,
    required String motivo,
  }) async {
    return await actualizarCantidad(
      productoId: productoId,
      nuevaCantidad: cantidadNueva,
    );
  }

  // ✅ Procesar venta (reducir inventario)
  Future<void> procesarVenta(List<Map<String, dynamic>> items) async {
    try {
      for (var item in items) {
        final productoId = item['producto_id'] as String;
        final cantidad = item['cantidad'] as int;

        await registrarSalida(
          productoId: productoId,
          cantidad: cantidad,
          motivo: 'Venta',
        );
      }
    } catch (e) {
      throw Exception('Error al procesar venta: $e');
    }
  }

  // ✅ Obtener productos con stock bajo (CORREGIDO)
  Future<List<InventarioModel>> obtenerProductosStockBajo() async {
    try {
      final response = await _supabase
          .from('inventarios')
          .select()
          .lte('cantidad', 10); // cantidad <= 10

      return (response as List)
          .map((item) => InventarioModel.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos con stock bajo: $e');
    }
  }

  // ✅ Verificar si existe inventario para un producto
  Future<bool> existeInventario(String productoId) async {
    try {
      final response = await _supabase
          .from('inventarios')
          .select('id')
          .eq('producto_id', productoId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ✅ Inicializar inventario para un producto si no existe
  Future<InventarioModel> inicializarSiNoExiste(String productoId) async {
    try {
      final existe = await existeInventario(productoId);

      if (!existe) {
        return await crearInventario(
          productoId: productoId,
          cantidadInicial: 0,
          cantidadMinima: 10,
        );
      }

      final inventario = await obtenerInventarioPorProducto(productoId);
      return inventario!;
    } catch (e) {
      throw Exception('Error al inicializar inventario: $e');
    }
  }
}