import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/factura_model.dart';


class FacturaRepository {
  final SupabaseClient _client;

  FacturaRepository(this._client);

  // Stream en tiempo real
  Stream<List<FacturaModel>> streamFacturas() {
    return _client
        .from('facturas')
        .stream(primaryKey: ['id'])
        .order('fecha', ascending: false)
        .map((data) => data.map((e) => FacturaModel.fromMap(e)).toList());
  }

  // Obtener todas
  Future<List<FacturaModel>> getAll() async {
    final response = await _client
        .from('facturas')
        .select()
        .order('fecha', ascending: false);
    return response.map((e) => FacturaModel.fromMap(e)).toList();
  }

  // Obtener con items
  Future<FacturaModel> getWithItems(String id) async {
    final facturaResponse = await _client
        .from('facturas')
        .select()
        .eq('id', id)
        .single();

    final itemsResponse = await _client
        .from('items_factura')
        .select()
        .eq('factura_id', id);

    final factura = FacturaModel.fromMap(facturaResponse);
    final items = itemsResponse.map((e) => ItemFacturaModel.fromMap(e)).toList();

    return factura.copyWith(items: items);
  }

  // Crear factura con items
  Future<FacturaModel> create(FacturaModel factura, List<ItemFacturaModel> items) async {
    // Insertar factura
    final facturaResponse = await _client
        .from('facturas')
        .insert(factura.toMap())
        .select()
        .single();

    final nuevaFactura = FacturaModel.fromMap(facturaResponse);

    // Insertar items
    if (items.isNotEmpty) {
      final itemsData = items.map((item) =>
          item.copyWith(facturaId: nuevaFactura.id).toMap()
      ).toList();

      await _client.from('items_factura').insert(itemsData);
    }

    return getWithItems(nuevaFactura.id!);
  }

  // Actualizar estado
  Future<void> updateEstado(String id, String estado) async {
    await _client
        .from('facturas')
        .update({'estado': estado})
        .eq('id', id);
  }

  // Eliminar
  Future<void> delete(String id) async {
    // Los items se eliminan automáticamente por ON DELETE CASCADE
    await _client.from('facturas').delete().eq('id', id);
  }
}