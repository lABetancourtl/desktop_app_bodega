// lib/model/inventario_model.dart
class InventarioModel {
  final String? id;
  final String productoId;
  final int cantidad;
  final int? cantidadMinima;
  final DateTime? ultimaActualizacion;

  InventarioModel({
    this.id,
    required this.productoId,
    required this.cantidad,
    this.cantidadMinima,
    this.ultimaActualizacion,
  });

  // Estado del inventario
  EstadoInventario get estado {
    if (cantidad == 0) return EstadoInventario.agotado;
    if (cantidad <= (cantidadMinima ?? 10)) return EstadoInventario.stockBajo;
    return EstadoInventario.disponible;
  }

  factory InventarioModel.fromMap(Map<String, dynamic> map) {
    return InventarioModel(
      id: map['id'],
      productoId: map['producto_id'],
      cantidad: map['cantidad'] ?? 0,
      cantidadMinima: map['cantidad_minima'],
      ultimaActualizacion: map['ultima_actualizacion'] != null
          ? DateTime.parse(map['ultima_actualizacion'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'producto_id': productoId,
      'cantidad': cantidad,
      'cantidad_minima': cantidadMinima,
    };
  }

  InventarioModel copyWith({
    String? id,
    String? productoId,
    int? cantidad,
    int? cantidadMinima,
    DateTime? ultimaActualizacion,
  }) {
    return InventarioModel(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      cantidadMinima: cantidadMinima ?? this.cantidadMinima,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }
}

enum EstadoInventario {
  disponible,
  stockBajo,
  agotado,
}

// Modelo para movimientos
class MovimientoInventarioModel {
  final String? id;
  final String productoId;
  final TipoMovimiento tipo;
  final int cantidad;
  final int cantidadAnterior;
  final int cantidadNueva;
  final String? motivo;
  final String? usuario;
  final DateTime fecha;

  MovimientoInventarioModel({
    this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    required this.cantidadAnterior,
    required this.cantidadNueva,
    this.motivo,
    this.usuario,
    required this.fecha,
  });

  factory MovimientoInventarioModel.fromMap(Map<String, dynamic> map) {
    return MovimientoInventarioModel(
      id: map['id'],
      productoId: map['producto_id'],
      tipo: TipoMovimiento.values.firstWhere(
            (t) => t.name == map['tipo'],
        orElse: () => TipoMovimiento.ajuste,
      ),
      cantidad: map['cantidad'] ?? 0,
      cantidadAnterior: map['cantidad_anterior'] ?? 0,
      cantidadNueva: map['cantidad_nueva'] ?? 0,
      motivo: map['motivo'],
      usuario: map['usuario'],
      fecha: DateTime.parse(map['fecha']),
    );
  }
}

enum TipoMovimiento {
  entrada,
  salida,
  ajuste,
  venta,
}