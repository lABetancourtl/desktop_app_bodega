class ProductoModel {
  final String? id;
  final String nombre;
  final String? categoriaId;
  final List<String> sabores;
  final double precio;
  final int? cantidadPorPaca;
  final String? imagenPath;
  final String? codigoBarras;
  final Map<String, String> codigosPorSabor;

  ProductoModel({
    this.id,
    required this.nombre,
    this.categoriaId,
    this.sabores = const [],
    required this.precio,
    this.cantidadPorPaca,
    this.imagenPath,
    this.codigoBarras,
    this.codigosPorSabor = const {},
  });

  factory ProductoModel.fromMap(Map<String, dynamic> map) {
    return ProductoModel(
      id: map['id'],
      nombre: map['nombre'] ?? '',
      categoriaId: map['categoria_id'],
      sabores: List<String>.from(map['sabores'] ?? []),
      precio: (map['precio'] ?? 0).toDouble(),
      cantidadPorPaca: map['cantidad_por_paca'],
      imagenPath: map['imagen_path'],
      codigoBarras: map['codigo_barras'],
      codigosPorSabor: Map<String, String>.from(map['codigos_por_sabor'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'categoria_id': categoriaId,
      'sabores': sabores,
      'precio': precio,
      'cantidad_por_paca': cantidadPorPaca,
      'imagen_path': imagenPath,
      'codigo_barras': codigoBarras,
      'codigos_por_sabor': codigosPorSabor,
    };
  }

  ProductoModel copyWith({
    String? id,
    String? nombre,
    String? categoriaId,
    List<String>? sabores,
    double? precio,
    int? cantidadPorPaca,
    String? imagenPath,
    String? codigoBarras,
    Map<String, String>? codigosPorSabor,
  }) {
    return ProductoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoriaId: categoriaId ?? this.categoriaId,
      sabores: sabores ?? this.sabores,
      precio: precio ?? this.precio,
      cantidadPorPaca: cantidadPorPaca ?? this.cantidadPorPaca,
      imagenPath: imagenPath ?? this.imagenPath,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      codigosPorSabor: codigosPorSabor ?? this.codigosPorSabor,
    );
  }
}