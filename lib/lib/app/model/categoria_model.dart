class CategoriaModel {
  final String? id;
  final String nombre;

  CategoriaModel({
    this.id,
    required this.nombre,
  });

  // Desde Supabase Map
  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'],
      nombre: map['nombre'] ?? '',
    );
  }

  // Hacia Supabase Map (sin id para insertar)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
    };
  }

  // Hacia Supabase Map (con id para actualizar)
  Map<String, dynamic> toMapWithId() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  CategoriaModel copyWith({
    String? id,
    String? nombre,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }
}