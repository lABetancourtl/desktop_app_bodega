


import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/prodcuto_model.dart';

class ProductoRepository {
  final SupabaseClient _client;

  ProductoRepository(this._client);

  // Stream en tiempo real
  Stream<List<ProductoModel>> streamProductos() {
    return _client
        .from('productos')
        .stream(primaryKey: ['id'])
        .order('nombre')
        .map((data) => data.map((e) => ProductoModel.fromMap(e)).toList());
  }

  // Obtener todos
  Future<List<ProductoModel>> getAll() async {
    final response = await _client
        .from('productos')
        .select()
        .order('nombre');
    return response.map((e) => ProductoModel.fromMap(e)).toList();
  }

  // Obtener por categoría
  Future<List<ProductoModel>> getByCategoria(String categoriaId) async {
    final response = await _client
        .from('productos')
        .select()
        .eq('categoria_id', categoriaId)
        .order('nombre');
    return response.map((e) => ProductoModel.fromMap(e)).toList();
  }

  // Buscar por código de barras
  Future<ProductoModel?> getByCodigoBarras(String codigo) async {
    final response = await _client
        .from('productos')
        .select()
        .eq('codigo_barras', codigo)
        .maybeSingle();
    return response != null ? ProductoModel.fromMap(response) : null;
  }

  // Agregar
  Future<ProductoModel> add(ProductoModel producto) async {
    final response = await _client
        .from('productos')
        .insert(producto.toMap())
        .select()
        .single();
    return ProductoModel.fromMap(response);
  }

  // Actualizar
  Future<void> update(ProductoModel producto) async {
    await _client
        .from('productos')
        .update(producto.toMap())
        .eq('id', producto.id!);
  }

  // Eliminar
  Future<void> delete(String id) async {
    await _client.from('productos').delete().eq('id', id);
  }
}