// lib/service/factura_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/factura_model.dart';

class FacturaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // CREAR FACTURA
  Future<FacturaModel> crearFactura(FacturaModel factura) async {
    try {
      final facturaData = factura.toMap();
      facturaData['estado'] = 'preventa'; // Siempre inicia en preventa

      final response = await _supabase
          .from('facturas')
          .insert(facturaData)
          .select()
          .single();

      final facturaCreada = FacturaModel.fromMap(response);

      if (factura.items.isNotEmpty) {
        final itemsData = factura.items.map((item) {
          final data = item.toMap();
          data['factura_id'] = facturaCreada.id;
          return data;
        }).toList();

        await _supabase.from('items_factura').insert(itemsData);
      }

      return facturaCreada.copyWith(items: factura.items);
    } catch (e) {
      throw Exception('Error al crear factura: $e');
    }
  }

  // OBTENER TODAS LAS FACTURAS
  Future<List<FacturaModel>> obtenerFacturas() async {
    try {
      final response = await _supabase
          .from('facturas')
          .select()
          .order('fecha', ascending: false);

      final facturas = <FacturaModel>[];
      for (var facturaData in response as List) {
        final factura = FacturaModel.fromMap(facturaData);

        final itemsResponse = await _supabase
            .from('items_factura')
            .select()
            .eq('factura_id', factura.id!);

        final items = (itemsResponse as List)
            .map((item) => ItemFacturaModel.fromMap(item))
            .toList();

        facturas.add(factura.copyWith(items: items));
      }

      return facturas;
    } catch (e) {
      throw Exception('Error al obtener facturas: $e');
    }
  }

  // OBTENER FACTURA POR ID
  Future<FacturaModel?> obtenerFacturaPorId(String facturaId) async {
    try {
      final response = await _supabase
          .from('facturas')
          .select()
          .eq('id', facturaId)
          .maybeSingle();

      if (response == null) return null;

      final factura = FacturaModel.fromMap(response);

      final itemsResponse = await _supabase
          .from('items_factura')
          .select()
          .eq('factura_id', facturaId);

      final items = (itemsResponse as List)
          .map((item) => ItemFacturaModel.fromMap(item))
          .toList();

      return factura.copyWith(items: items);
    } catch (e) {
      throw Exception('Error al obtener factura: $e');
    }
  }

  // OBTENER FACTURAS POR ESTADO
  Future<List<FacturaModel>> obtenerFacturasPorEstado(String estado) async {
    try {
      final response = await _supabase
          .from('facturas')
          .select()
          .eq('estado', estado)
          .order('fecha', ascending: false);

      final facturas = <FacturaModel>[];
      for (var facturaData in response as List) {
        final factura = FacturaModel.fromMap(facturaData);

        final itemsResponse = await _supabase
            .from('items_factura')
            .select()
            .eq('factura_id', factura.id!);

        final items = (itemsResponse as List)
            .map((item) => ItemFacturaModel.fromMap(item))
            .toList();

        facturas.add(factura.copyWith(items: items));
      }

      return facturas;
    } catch (e) {
      throw Exception('Error al obtener facturas: $e');
    }
  }

  // OBTENER FACTURAS DEL DÍA
  Future<List<FacturaModel>> obtenerFacturasDelDia([DateTime? fecha]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      final inicioDia = DateTime(fechaConsulta.year, fechaConsulta.month, fechaConsulta.day);
      final finDia = inicioDia.add(const Duration(days: 1));

      final response = await _supabase
          .from('facturas')
          .select()
          .gte('fecha', inicioDia.toIso8601String())
          .lt('fecha', finDia.toIso8601String())
          .order('fecha', ascending: false);

      final facturas = <FacturaModel>[];
      for (var facturaData in response as List) {
        final factura = FacturaModel.fromMap(facturaData);

        final itemsResponse = await _supabase
            .from('items_factura')
            .select()
            .eq('factura_id', factura.id!);

        final items = (itemsResponse as List)
            .map((item) => ItemFacturaModel.fromMap(item))
            .toList();

        facturas.add(factura.copyWith(items: items));
      }

      return facturas;
    } catch (e) {
      throw Exception('Error al obtener facturas del día: $e');
    }
  }

  // ACTUALIZAR ESTADO
  Future<void> actualizarEstado(String facturaId, String nuevoEstado) async {
    try {
      await _supabase
          .from('facturas')
          .update({'estado': nuevoEstado})
          .eq('id', facturaId);
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  // ELIMINAR FACTURA
  Future<void> eliminarFactura(String facturaId, String estado) async {
    if (estado != 'preventa') {
      throw Exception('Solo se pueden eliminar facturas en estado de preventa');
    }

    try {
      await _supabase
          .from('items_factura')
          .delete()
          .eq('factura_id', facturaId);

      await _supabase
          .from('facturas')
          .delete()
          .eq('id', facturaId);
    } catch (e) {
      throw Exception('Error al eliminar factura: $e');
    }
  }

  // STREAM DE FACTURAS
  Stream<List<FacturaModel>> streamFacturas() {
    return _supabase
        .from('facturas')
        .stream(primaryKey: ['id'])
        .order('fecha', ascending: false)
        .asyncMap((facturasData) async {
      final facturas = <FacturaModel>[];

      for (var facturaData in facturasData) {
        final factura = FacturaModel.fromMap(facturaData);

        final itemsResponse = await _supabase
            .from('items_factura')
            .select()
            .eq('factura_id', factura.id!);

        final items = (itemsResponse as List)
            .map((item) => ItemFacturaModel.fromMap(item))
            .toList();

        facturas.add(factura.copyWith(items: items));
      }

      return facturas;
    });
  }

  // ESTADÍSTICAS DEL DÍA
  Future<EstadisticasFacturas> obtenerEstadisticasDelDia([DateTime? fecha]) async {
    try {
      final facturas = await obtenerFacturasDelDia(fecha);

      return EstadisticasFacturas(
        totalFacturas: facturas.length,
        totalVentas: facturas.fold(0.0, (sum, f) => sum + f.total),
        enPreventa: facturas.where((f) => f.estado == 'preventa').length,
        entregadas: facturas.where((f) => f.estado == 'entregada').length,
        parciales: facturas.where((f) => f.estado == 'parcial').length,
        canceladas: facturas.where((f) => f.estado == 'cancelada').length,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // BUSCAR FACTURAS
  Future<List<FacturaModel>> buscarFacturas(String query) async {
    try {
      final response = await _supabase
          .from('facturas')
          .select()
          .or('nombre_cliente.ilike.%$query%,negocio_cliente.ilike.%$query%,telefono_cliente.ilike.%$query%')
          .order('fecha', ascending: false);

      final facturas = <FacturaModel>[];
      for (var facturaData in response as List) {
        final factura = FacturaModel.fromMap(facturaData);

        final itemsResponse = await _supabase
            .from('items_factura')
            .select()
            .eq('factura_id', factura.id!);

        final items = (itemsResponse as List)
            .map((item) => ItemFacturaModel.fromMap(item))
            .toList();

        facturas.add(factura.copyWith(items: items));
      }

      return facturas;
    } catch (e) {
      throw Exception('Error al buscar facturas: $e');
    }
  }
}

// MODELO DE ESTADÍSTICAS
class EstadisticasFacturas {
  final int totalFacturas;
  final double totalVentas;
  final int enPreventa;
  final int entregadas;
  final int parciales;
  final int canceladas;

  EstadisticasFacturas({
    required this.totalFacturas,
    required this.totalVentas,
    required this.enPreventa,
    required this.entregadas,
    required this.parciales,
    required this.canceladas,
  });

  int get completadas => entregadas + parciales;
  int get pendientes => enPreventa;
  double get promedioVenta => totalFacturas > 0 ? totalVentas / totalFacturas : 0;
  double get tasaEntrega => totalFacturas > 0 ? (completadas / totalFacturas * 100) : 0;
}