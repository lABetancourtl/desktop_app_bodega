import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/cliente_model.dart';

class ClienteRepository {
  final SupabaseClient _client;

  ClienteRepository(this._client);

  // Stream en tiempo real
  Stream<List<ClienteModel>> streamClientes() {
    return _client
        .from('clientes')
        .stream(primaryKey: ['id'])
        .order('nombre')
        .map((data) => data.map((e) => ClienteModel.fromMap(e)).toList());
  }

  // Obtener todos
  Future<List<ClienteModel>> getAll() async {
    final response = await _client
        .from('clientes')
        .select()
        .order('nombre');
    return response.map((e) => ClienteModel.fromMap(e)).toList();
  }

  // Obtener por ruta
  Future<List<ClienteModel>> getByRuta(Ruta ruta) async {
    final response = await _client
        .from('clientes')
        .select()
        .eq('ruta', ruta.name)
        .order('nombre');
    return response.map((e) => ClienteModel.fromMap(e)).toList();
  }

  // Agregar
  Future<ClienteModel> add(ClienteModel cliente) async {
    final response = await _client
        .from('clientes')
        .insert(cliente.toMap())
        .select()
        .single();
    return ClienteModel.fromMap(response);
  }

  // Actualizar
  Future<void> update(ClienteModel cliente) async {
    await _client
        .from('clientes')
        .update(cliente.toMap())
        .eq('id', cliente.id!);
  }

  // Eliminar
  Future<void> delete(String id) async {
    await _client.from('clientes').delete().eq('id', id);
  }
}