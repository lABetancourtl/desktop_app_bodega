import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/categoria_model.dart';

class CategoriaRepository {
  final SupabaseClient _client;

  CategoriaRepository(this._client);

  // Stream en tiempo real
  Stream<List<CategoriaModel>> streamCategorias() {
    return _client
        .from('categorias')
        .stream(primaryKey: ['id'])
        .order('nombre')
        .map((data) => data.map((e) => CategoriaModel.fromMap(e)).toList());
  }

  // Obtener todas
  Future<List<CategoriaModel>> getAll() async {
    final response = await _client
        .from('categorias')
        .select()
        .order('nombre');
    return response.map((e) => CategoriaModel.fromMap(e)).toList();
  }

  // Agregar
  Future<CategoriaModel> add(CategoriaModel categoria) async {
    final response = await _client
        .from('categorias')
        .insert(categoria.toMap())
        .select()
        .single();
    return CategoriaModel.fromMap(response);
  }

  // Actualizar
  Future<void> update(CategoriaModel categoria) async {
    await _client
        .from('categorias')
        .update(categoria.toMap())
        .eq('id', categoria.id!);
  }

  // Eliminar
  Future<void> delete(String id) async {
    await _client.from('categorias').delete().eq('id', id);
  }
}