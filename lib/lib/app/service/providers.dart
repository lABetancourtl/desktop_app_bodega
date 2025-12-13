import 'package:desktop_app_bodega/lib/app/model/categoria_model.dart';
import 'package:desktop_app_bodega/lib/app/model/factura_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/categoria_repository.dart';
import '../datasources/cliente_repository.dart';
import '../datasources/factura_repository.dart';
import '../datasources/producto_repository.dart';
import '../model/cliente_model.dart';
import '../model/prodcuto_model.dart';


// Cliente Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Repositorios
final categoriaRepositoryProvider = Provider<CategoriaRepository>((ref) {
  return CategoriaRepository(ref.watch(supabaseClientProvider));
});

final productoRepositoryProvider = Provider<ProductoRepository>((ref) {
  return ProductoRepository(ref.watch(supabaseClientProvider));
});

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return ClienteRepository(ref.watch(supabaseClientProvider));
});

final facturaRepositoryProvider = Provider<FacturaRepository>((ref) {
  return FacturaRepository(ref.watch(supabaseClientProvider));
});

// Streams en tiempo real
final categoriasStreamProvider = StreamProvider<List<CategoriaModel>>((ref) {
  return ref.watch(categoriaRepositoryProvider).streamCategorias();
});

final productosStreamProvider = StreamProvider<List<ProductoModel>>((ref) {
  return ref.watch(productoRepositoryProvider).streamProductos();
});

final clientesStreamProvider = StreamProvider<List<ClienteModel>>((ref) {
  return ref.watch(clienteRepositoryProvider).streamClientes();
});

final facturasStreamProvider = StreamProvider<List<FacturaModel>>((ref) {
  return ref.watch(facturaRepositoryProvider).streamFacturas();
});