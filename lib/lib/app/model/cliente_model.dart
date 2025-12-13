enum Ruta { ruta1, ruta2, ruta3 }

class ClienteModel {
  final String? id;
  final String nombre;
  final String nombreNegocio;
  final String direccion;
  final String telefono;
  final Ruta ruta;
  final String? observaciones;
  final double? latitud;
  final double? longitud;

  ClienteModel({
    this.id,
    required this.nombre,
    required this.nombreNegocio,
    required this.direccion,
    required this.telefono,
    required this.ruta,
    this.observaciones,
    this.latitud,
    this.longitud,
  });

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      id: map['id'],
      nombre: map['nombre'] ?? '',
      nombreNegocio: map['nombre_negocio'] ?? '',
      direccion: map['direccion'] ?? '',
      telefono: map['telefono'] ?? '',
      ruta: _rutaFromString(map['ruta']),
      observaciones: map['observaciones'],
      latitud: map['latitud']?.toDouble(),
      longitud: map['longitud']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'nombre_negocio': nombreNegocio,
      'direccion': direccion,
      'telefono': telefono,
      'ruta': ruta.name,
      'observaciones': observaciones,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  static Ruta _rutaFromString(String? value) {
    switch (value) {
      case 'ruta2':
        return Ruta.ruta2;
      case 'ruta3':
        return Ruta.ruta3;
      default:
        return Ruta.ruta1;
    }
  }

  ClienteModel copyWith({
    String? id,
    String? nombre,
    String? nombreNegocio,
    String? direccion,
    String? telefono,
    Ruta? ruta,
    String? observaciones,
    double? latitud,
    double? longitud,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nombreNegocio: nombreNegocio ?? this.nombreNegocio,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      ruta: ruta ?? this.ruta,
      observaciones: observaciones ?? this.observaciones,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
    );
  }
}