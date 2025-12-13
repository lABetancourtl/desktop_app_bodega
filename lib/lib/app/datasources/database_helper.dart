import 'package:desktop_app_bodega/lib/app/model/prodcuto_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/categoria_model.dart';
import '../model/cliente_model.dart';
import '../model/factura_model.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  final SupabaseClient _supabase = Supabase.instance.client;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  // ============= MÉTODOS PARA CLIENTES =============

  Future<String> insertarCliente(ClienteModel cliente) async {
    try {
      final response = await _supabase
          .from('clientes')
          .insert(cliente.toMap())
          .select('id')
          .single();
      return response['id'];
    } catch (e) {
      throw Exception('Error al insertar cliente: $e');
    }
  }

  Future<List<ClienteModel>> obtenerClientes() async {
    try {
      final response = await _supabase
          .from('clientes')
          .select()
          .order('nombre');
      return response.map((e) => ClienteModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  // Stream en tiempo real para clientes
  Stream<List<ClienteModel>> streamClientes() {
    return _supabase
        .from('clientes')
        .stream(primaryKey: ['id'])
        .order('nombre')
        .map((data) => data.map((e) => ClienteModel.fromMap(e)).toList());
  }

  Future<ClienteModel?> obtenerClientePorId(String id) async {
    try {
      final response = await _supabase
          .from('clientes')
          .select()
          .eq('id', id)
          .maybeSingle();
      return response != null ? ClienteModel.fromMap(response) : null;
    } catch (e) {
      throw Exception('Error al obtener cliente: $e');
    }
  }

  Future<void> actualizarCliente(ClienteModel cliente) async {
    try {
      if (cliente.id == null) {
        throw Exception('El cliente debe tener un ID para actualizarse');
      }
      await _supabase
          .from('clientes')
          .update(cliente.toMap())
          .eq('id', cliente.id!);
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  Future<void> eliminarCliente(String id) async {
    try {
      await _supabase.from('clientes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar cliente: $e');
    }
  }

  // ============= MÉTODOS PARA CATEGORÍAS =============

  Future<String> insertarCategoria(CategoriaModel categoria) async {
    try {
      final response = await _supabase
          .from('categorias')
          .insert(categoria.toMap())
          .select('id')
          .single();
      return response['id'];
    } catch (e) {
      throw Exception('Error al insertar categoría: $e');
    }
  }

  Future<List<CategoriaModel>> obtenerCategorias() async {
    try {
      final response = await _supabase
          .from('categorias')
          .select()
          .order('nombre');
      return response.map((e) => CategoriaModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  // Stream en tiempo real para categorías
  Stream<List<CategoriaModel>> streamCategorias() {
    return _supabase
        .from('categorias')
        .stream(primaryKey: ['id'])
        .order('nombre')
        .map((data) => data.map((e) => CategoriaModel.fromMap(e)).toList());
  }

  Future<CategoriaModel?> obtenerCategoriaPorId(String id) async {
    try {
      final response = await _supabase
          .from('categorias')
          .select()
          .eq('id', id)
          .maybeSingle();
      return response != null ? CategoriaModel.fromMap(response) : null;
    } catch (e) {
      throw Exception('Error al obtener categoría: $e');
    }
  }

  Future<void> actualizarCategoria(CategoriaModel categoria) async {
    try {
      if (categoria.id == null) {
        throw Exception('La categoría debe tener un ID');
      }
      await _supabase
          .from('categorias')
          .update(categoria.toMap())
          .eq('id', categoria.id!);
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  Future<void> eliminarCategoria(String id) async {
    try {
      await _supabase.from('categorias').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }

  // ============= MÉTODOS PARA PRODUCTOS =============

  Future<ProductoModel?> obtenerProductoPorCodigoBarras(String codigoBarras) async {
    try {
      // 1. Buscar en el campo codigo_barras principal
      var response = await _supabase
          .from('productos')
          .select()
          .eq('codigo_barras', codigoBarras)
          .maybeSingle();

      if (response != null) {
        return ProductoModel.fromMap(response);
      }

      // 2. Buscar en codigos_por_sabor (JSONB)
      // Supabase permite buscar dentro de JSONB
      final todosLosProductos = await _supabase
          .from('productos')
          .select();

      for (var data in todosLosProductos) {
        if (data['codigos_por_sabor'] != null) {
          final codigosPorSabor = Map<String, dynamic>.from(data['codigos_por_sabor']);
          for (var codigo in codigosPorSabor.values) {
            if (codigo == codigoBarras) {
              return ProductoModel.fromMap(data);
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Error al obtener producto por código de barras: $e');
      throw Exception('Error al obtener producto por código de barras: $e');
    }
  }

  Future<ProductoModel?> buscarProductoPorCodigoBarras(String codigoBarras) async {
    return await obtenerProductoPorCodigoBarras(codigoBarras);
  }

  Future<String?> obtenerSaborPorCodigoBarras(String codigoBarras) async {
    try {
      final producto = await obtenerProductoPorCodigoBarras(codigoBarras);

      if (producto == null) return null;

      if (producto.codigoBarras == codigoBarras && producto.sabores.length == 1) {
        return producto.sabores[0];
      }

      if (producto.codigosPorSabor.isNotEmpty) {
        for (var entry in producto.codigosPorSabor.entries) {
          if (entry.value == codigoBarras) {
            return entry.key;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error al obtener sabor por código de barras: $e');
      return null;
    }
  }

  Future<String> insertarProducto(ProductoModel producto) async {
    try {
      final response = await _supabase
          .from('productos')
          .insert(producto.toMap())
          .select('id')
          .single();
      return response['id'];
    } catch (e) {
      throw Exception('Error al insertar producto: $e');
    }
  }

  Future<List<ProductoModel>> obtenerProductos() async {
    try {
      final response = await _supabase
          .from('productos')
          .select()
          .order('nombre');
      return response.map((e) => ProductoModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  // Stream en tiempo real para productos
  Stream<List<ProductoModel>> streamProductos() {
    return _supabase
        .from('productos')
        .stream(primaryKey: ['id'])
        .order('nombre')
        .map((data) => data.map((e) => ProductoModel.fromMap(e)).toList());
  }

  Future<List<ProductoModel>> obtenerProductosPorCategoria(String categoriaId) async {
    try {
      final response = await _supabase
          .from('productos')
          .select()
          .eq('categoria_id', categoriaId)
          .order('nombre');
      return response.map((e) => ProductoModel.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos por categoría: $e');
    }
  }

  Future<ProductoModel?> obtenerProductoPorId(String id) async {
    try {
      final response = await _supabase
          .from('productos')
          .select()
          .eq('id', id)
          .maybeSingle();
      return response != null ? ProductoModel.fromMap(response) : null;
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  Future<void> actualizarProducto(ProductoModel producto) async {
    try {
      if (producto.id == null) {
        throw Exception('El producto debe tener un ID para actualizarse');
      }
      await _supabase
          .from('productos')
          .update(producto.toMap())
          .eq('id', producto.id!);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  Future<void> eliminarProducto(String id) async {
    try {
      await _supabase.from('productos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  Future<List<ProductoModel>> obtenerTodosProductos() async {
    return obtenerProductos();
  }

  // ============= MÉTODOS PARA FACTURAS =============

  Future<String> insertarFactura(FacturaModel factura) async {
    try {
      print('=== INICIANDO INSERCIÓN DE FACTURA ===');
      print('Cliente: ${factura.nombreCliente}');
      print('Total items en factura.items: ${factura.items.length}');

      // Imprimir detalles de cada item
      for (var i = 0; i < factura.items.length; i++) {
        final item = factura.items[i];
        print('Item $i:');
        print('  - Producto ID: ${item.productoId}');
        print('  - Nombre: ${item.nombreProducto}');
        print('  - Cantidad: ${item.cantidadTotal}');
        print('  - Precio: ${item.precioUnitario}');
        print('  - Subtotal: ${item.subtotal}');
      }

      // Insertar factura
      print('\n📝 Insertando factura en tabla facturas...');
      final facturaMap = factura.toMap();
      print('Datos de factura a insertar: $facturaMap');

      final facturaResponse = await _supabase
          .from('facturas')
          .insert(facturaMap)
          .select('id')
          .single();

      final facturaId = facturaResponse['id'] as String;
      print('✅ Factura creada con ID: $facturaId');

      // Insertar items
      if (factura.items.isEmpty) {
        print('⚠️ WARNING: No hay items para insertar!');
      } else {
        print('\n📦 Preparando items para insertar...');
        final itemsData = factura.items.map((item) {
          final itemConFacturaId = item.copyWith(facturaId: facturaId);
          final itemMap = itemConFacturaId.toMap();
          print('Item a insertar: $itemMap');
          return itemMap;
        }).toList();

        print('\n🔄 Insertando ${itemsData.length} items en tabla items_factura...');
        final itemsResponse = await _supabase
            .from('items_factura')
            .insert(itemsData)
            .select();

        print('✅ Items insertados correctamente: ${itemsResponse.length} items');
        print('Respuesta de items: $itemsResponse');
      }

      print('=== INSERCIÓN COMPLETADA ===\n');
      return facturaId;
    } catch (e, stackTrace) {
      print('❌ ERROR AL INSERTAR FACTURA:');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Error al insertar factura: $e');
    }
  }

// Reemplaza tu método obtenerFacturas() con este:

  Future<List<FacturaModel>> obtenerFacturas({int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('facturas')
          .select()
          .order('fecha', ascending: false)
          .range(offset, offset + limit - 1);

      List<FacturaModel> facturas = [];

      for (var facturaData in response) {
        final facturaId = facturaData['id'] as String;

        // Obtener los items de esta factura
        final itemsResponse = await _supabase
            .from('items_factura')
            .select()
            .eq('factura_id', facturaId);

        final items = itemsResponse
            .map((e) => ItemFacturaModel.fromMap(e))
            .toList();

        // Crear la factura con sus items
        final factura = FacturaModel.fromMap(facturaData);
        final facturaConItems = factura.copyWith(items: items);

        facturas.add(facturaConItems);
      }

      return facturas;
    } catch (e) {
      throw Exception('Error al obtener facturas: $e');
    }
  }

  // Stream en tiempo real para facturas
// Reemplaza tu método streamFacturas() con este:

  Stream<List<FacturaModel>> streamFacturas() {
    return _supabase
        .from('facturas')
        .stream(primaryKey: ['id'])
        .order('fecha', ascending: false)
        .asyncMap((facturasData) async {
      // Para cada factura, obtener sus items
      List<FacturaModel> facturasConItems = [];

      for (var facturaData in facturasData) {
        final facturaId = facturaData['id'] as String;

        // Obtener los items de esta factura
        final itemsResponse = await _supabase
            .from('items_factura')
            .select()
            .eq('factura_id', facturaId);

        final items = itemsResponse
            .map((e) => ItemFacturaModel.fromMap(e))
            .toList();

        // Crear la factura con sus items
        final factura = FacturaModel.fromMap(facturaData);
        final facturaConItems = factura.copyWith(items: items);

        facturasConItems.add(facturaConItems);
      }

      return facturasConItems;
    });
  }

  Future<FacturaModel?> obtenerFacturaPorId(String id) async {
    try {
      final facturaResponse = await _supabase
          .from('facturas')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (facturaResponse == null) return null;

      // Obtener items de la factura
      final itemsResponse = await _supabase
          .from('items_factura')
          .select()
          .eq('factura_id', id);

      final items = itemsResponse.map((e) => ItemFacturaModel.fromMap(e)).toList();
      final factura = FacturaModel.fromMap(facturaResponse);

      return factura.copyWith(items: items);
    } catch (e) {
      throw Exception('Error al obtener factura: $e');
    }
  }

  Future<void> actualizarFactura(FacturaModel factura) async {
    try {
      if (factura.id == null) {
        throw Exception('La factura debe tener un ID');
      }

      // Actualizar factura
      await _supabase
          .from('facturas')
          .update(factura.toMap())
          .eq('id', factura.id!);

      // Eliminar items existentes
      await _supabase
          .from('items_factura')
          .delete()
          .eq('factura_id', factura.id!);

      // Insertar nuevos items
      if (factura.items.isNotEmpty) {
        final itemsData = factura.items.map((item) {
          return item.copyWith(facturaId: factura.id).toMap();
        }).toList();

        await _supabase.from('items_factura').insert(itemsData);
      }
    } catch (e) {
      throw Exception('Error al actualizar factura: $e');
    }
  }

  Future<void> eliminarFactura(String id) async {
    try {
      // Los items se eliminan automáticamente por ON DELETE CASCADE
      await _supabase.from('facturas').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar factura: $e');
    }
  }

  Future<List<FacturaModel>> obtenerFacturasPorCliente(String clienteId, {int limit = 3}) async {
    try {
      final response = await _supabase
          .from('facturas')
          .select()
          .eq('cliente_id', clienteId)
          .order('fecha', ascending: false)
          .limit(limit);

      List<FacturaModel> facturas = [];
      for (var data in response) {
        final itemsResponse = await _supabase
            .from('items_factura')
            .select()
            .eq('factura_id', data['id']);

        final items = itemsResponse.map((e) => ItemFacturaModel.fromMap(e)).toList();
        facturas.add(FacturaModel.fromMap(data).copyWith(items: items));
      }
      return facturas;
    } catch (e) {
      throw Exception('Error al obtener facturas del cliente: $e');
    }
  }
}