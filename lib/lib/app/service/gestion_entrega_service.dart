// lib/service/gestion_entregas_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/factura_model.dart';
import '../service/inventario_service.dart';

class GestionEntregasService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final InventarioService _inventarioService = InventarioService();

  // Confirmar entrega completa (sin devoluciones)
  Future<void> confirmarEntregaCompleta(String facturaId, FacturaModel factura) async {
    try {
      // Primero actualizar items de la factura con cantidades entregadas
      final itemsActualizados = factura.items.map((item) {
        return item.copyWith(
          cantidadEntregadaPorSabor: item.tieneSabores && item.cantidadPorSabor.isNotEmpty
              ? item.cantidadPorSabor
              : {'default': item.cantidadTotal},
          cantidadDevueltaPorSabor: {},
        );
      }).toList();

      await _actualizarItemsFactura(facturaId, itemsActualizados);

      // Descontar del inventario
      for (var item in itemsActualizados) {
        if (item.tieneSabores && item.cantidadPorSabor.isNotEmpty) {
          // Productos con sabores: descontar por cada sabor
          for (var entry in item.cantidadPorSabor.entries) {
            final sabor = entry.key;
            final cantidad = entry.value;

            if (cantidad > 0) {
              await _inventarioService.registrarSalida(
                productoId: item.productoId!,
                cantidad: cantidad,
                motivo: 'Venta - Factura #${factura.id?.substring(0, 8)} - $sabor',
              );
            }
          }
        } else {
          // Producto sin sabores
          if (item.cantidadTotal > 0) {
            await _inventarioService.registrarSalida(
              productoId: item.productoId!,
              cantidad: item.cantidadTotal,
              motivo: 'Venta - Factura #${factura.id?.substring(0, 8)}',
            );
          }
        }
      }

      // Actualizar estado de la factura
      await _supabase
          .from('facturas')
          .update({
        'estado': EstadoFactura.entregada.name,
        'fecha_entrega': DateTime.now().toIso8601String(),
      })
          .eq('id', facturaId);
    } catch (e) {
      throw Exception('Error al confirmar entrega: $e');
    }
  }

  // Registrar entrega con devoluciones
  Future<void> registrarEntregaParcial({
    required String facturaId,
    required FacturaModel factura,
    required List<ItemEntrega> itemsEntregados,
  }) async {
    try {
      // Procesar cada item
      final itemsActualizados = factura.items.map((item) {
        final entrega = itemsEntregados.firstWhere(
              (e) => e.productoId == item.productoId,
          orElse: () => ItemEntrega(
            productoId: item.productoId!,
            cantidadEntregadaPorSabor: {},
            cantidadDevueltaPorSabor: item.tieneSabores
                ? item.cantidadPorSabor
                : {'default': item.cantidadTotal},
          ),
        );

        return item.copyWith(
          cantidadEntregadaPorSabor: entrega.cantidadEntregadaPorSabor,
          cantidadDevueltaPorSabor: entrega.cantidadDevueltaPorSabor,
        );
      }).toList();

      // Determinar estado final
      final todasDevueltas = itemsActualizados.every((item) => item.cantidadVendida == 0);
      final algunaDevuelta = itemsActualizados.any(
            (item) => item.cantidadTotalDevuelta > 0 || item.cantidadTotalEntregada < item.cantidadTotal,
      );

      EstadoFactura estadoFinal;
      if (todasDevueltas) {
        estadoFinal = EstadoFactura.cancelada; // Si todo se devolvió, se cancela
      } else if (algunaDevuelta) {
        estadoFinal = EstadoFactura.parcial;
      } else {
        estadoFinal = EstadoFactura.entregada;
      }

      // Actualizar factura
      await _supabase
          .from('facturas')
          .update({
        'estado': estadoFinal.name,
        'fecha_entrega': DateTime.now().toIso8601String(),
      })
          .eq('id', facturaId);

      await _actualizarItemsFactura(facturaId, itemsActualizados);

      // Procesar inventario
      for (var item in itemsActualizados) {
        if (item.tieneSabores) {
          // Productos con sabores
          for (var sabor in item.cantidadPorSabor.keys) {
            final cantidadEntregada = item.cantidadEntregadaPorSabor[sabor] ?? 0;
            final cantidadDevuelta = item.cantidadDevueltaPorSabor[sabor] ?? 0;

            // Descontar lo entregado
            if (cantidadEntregada > 0) {
              await _inventarioService.registrarSalida(
                productoId: item.productoId!,
                cantidad: cantidadEntregada,
                motivo: 'Venta parcial - Factura #${factura.id?.substring(0, 8)} - $sabor',
              );
            }

            // Devolver al inventario lo que no se entregó
            if (cantidadDevuelta > 0) {
              await _inventarioService.registrarEntrada(
                productoId: item.productoId!,
                cantidad: cantidadDevuelta,
                motivo: 'Devolución - Factura #${factura.id?.substring(0, 8)} - $sabor',
              );
            }
          }
        } else {
          // Producto sin sabores
          final cantidadEntregada = item.cantidadTotalEntregada;
          final cantidadDevuelta = item.cantidadTotalDevuelta;

          if (cantidadEntregada > 0) {
            await _inventarioService.registrarSalida(
              productoId: item.productoId!,
              cantidad: cantidadEntregada,
              motivo: 'Venta parcial - Factura #${factura.id?.substring(0, 8)}',
            );
          }

          if (cantidadDevuelta > 0) {
            await _inventarioService.registrarEntrada(
              productoId: item.productoId!,
              cantidad: cantidadDevuelta,
              motivo: 'Devolución - Factura #${factura.id?.substring(0, 8)}',
            );
          }
        }
      }
    } catch (e) {
      throw Exception('Error al registrar entrega parcial: $e');
    }
  }

  // Helper para actualizar items en la base de datos
  Future<void> _actualizarItemsFactura(String facturaId, List<ItemFacturaModel> items) async {
    try {
      // Eliminar items existentes
      await _supabase
          .from('items_factura')
          .delete()
          .eq('factura_id', facturaId);

      // Insertar items actualizados
      final itemsData = items.map((item) {
        final data = item.toMap();
        data['factura_id'] = facturaId;
        return data;
      }).toList();

      await _supabase
          .from('items_factura')
          .insert(itemsData);
    } catch (e) {
      throw Exception('Error al actualizar items: $e');
    }
  }

  // Cancelar factura
  Future<void> cancelarFactura(String facturaId, String motivo) async {
    try {
      await _supabase
          .from('facturas')
          .update({
        'estado': EstadoFactura.cancelada.name,
        'observaciones_cliente': motivo,
      })
          .eq('id', facturaId);
    } catch (e) {
      throw Exception('Error al cancelar factura: $e');
    }
  }

  // Obtener facturas por estado
  Future<List<FacturaModel>> obtenerFacturasPorEstado(EstadoFactura estado) async {
    try {
      final response = await _supabase
          .from('facturas')
          .select()
          .eq('estado', estado.name)
          .order('fecha', ascending: false);

      final facturas = <FacturaModel>[];
      for (var facturaData in response as List) {
        final factura = FacturaModel.fromMap(facturaData);

        // Cargar items de la factura
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

  // Obtener facturas en preventa/ruta (pendientes de entregar)
  Future<List<FacturaModel>> obtenerFacturasEnRuta([String? repartidorId]) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('facturas')
          .select()
          .eq('estado', EstadoFactura.preventa.name); // Solo preventa (en ruta)

      if (repartidorId != null) {
        query = query.eq('repartidor_id', repartidorId);
      }

      final response = await query.order('fecha', ascending: false);

      final facturas = <FacturaModel>[];
      for (var facturaData in response as List) {
        final factura = FacturaModel.fromMap(facturaData);

        // Cargar items
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
      throw Exception('Error al obtener facturas en ruta: $e');
    }
  }

  // Obtener resumen de entregas del día
  Future<ResumenEntregas> obtenerResumenDia([DateTime? fecha]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      final inicioDia = DateTime(fechaConsulta.year, fechaConsulta.month, fechaConsulta.day);
      final finDia = inicioDia.add(const Duration(days: 1));

      final response = await _supabase
          .from('facturas')
          .select()
          .gte('fecha', inicioDia.toIso8601String())
          .lt('fecha', finDia.toIso8601String());

      final facturas = (response as List)
          .map((item) => FacturaModel.fromMap(item))
          .toList();

      return ResumenEntregas(
        totalFacturas: facturas.length,
        pendientes: facturas.where((f) => f.estado == 'preventa').length,
        entregadas: facturas.where((f) => f.estado == 'entregada').length,
        parciales: facturas.where((f) => f.estado == 'parcial').length,
        devueltas: facturas.where((f) => f.estado == 'cancelada').length,
      );
    } catch (e) {
      throw Exception('Error al obtener resumen: $e');
    }
  }
}

// Modelo auxiliar para items de entrega
class ItemEntrega {
  final String productoId;
  final Map<String, int> cantidadEntregadaPorSabor;
  final Map<String, int> cantidadDevueltaPorSabor;

  ItemEntrega({
    required this.productoId,
    required this.cantidadEntregadaPorSabor,
    required this.cantidadDevueltaPorSabor,
  });
}

// Modelo para resumen de entregas
class ResumenEntregas {
  final int totalFacturas;
  final int pendientes;
  final int entregadas;
  final int parciales;
  final int devueltas;

  ResumenEntregas({
    required this.totalFacturas,
    required this.pendientes,
    required this.entregadas,
    required this.parciales,
    required this.devueltas,
  });

  int get completadas => entregadas + parciales;
  double get tasaExito => totalFacturas > 0
      ? ((entregadas + parciales) / totalFacturas * 100)
      : 0;
}