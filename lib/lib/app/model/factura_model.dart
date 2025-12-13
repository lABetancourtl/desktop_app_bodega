// ============= ITEM FACTURA MODEL =============
class ItemFacturaModel {
  final String? id;
  final String? facturaId;
  final String? productoId;
  final String nombreProducto;
  final double precioUnitario;
  final int cantidadTotal;
  final Map<String, int> cantidadPorSabor;
  final bool tieneSabores;

  ItemFacturaModel({
    this.id,
    this.facturaId,
    this.productoId,
    required this.nombreProducto,
    required this.precioUnitario,
    required this.cantidadTotal,
    this.cantidadPorSabor = const {},
    this.tieneSabores = false,
  });

  double get subtotal => precioUnitario * cantidadTotal;

  factory ItemFacturaModel.fromMap(Map<String, dynamic> map) {
    return ItemFacturaModel(
      id: map['id'],
      facturaId: map['factura_id'],
      productoId: map['producto_id'],
      nombreProducto: map['nombre_producto'] ?? '',
      precioUnitario: (map['precio_unitario'] ?? 0).toDouble(),
      cantidadTotal: map['cantidad_total'] ?? 1,
      cantidadPorSabor: Map<String, int>.from(
        (map['cantidad_por_sabor'] ?? {}).map(
              (key, value) => MapEntry(key, value is int ? value : int.parse(value.toString())),
        ),
      ),
      tieneSabores: map['tiene_sabores'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'factura_id': facturaId,
      'producto_id': productoId,
      'nombre_producto': nombreProducto,
      'precio_unitario': precioUnitario,
      'cantidad_total': cantidadTotal,
      'cantidad_por_sabor': cantidadPorSabor,
      'tiene_sabores': tieneSabores,
    };
  }

  ItemFacturaModel copyWith({
    String? id,
    String? facturaId,
    String? productoId,
    String? nombreProducto,
    double? precioUnitario,
    int? cantidadTotal,
    Map<String, int>? cantidadPorSabor,
    bool? tieneSabores,
  }) {
    return ItemFacturaModel(
      id: id ?? this.id,
      facturaId: facturaId ?? this.facturaId,
      productoId: productoId ?? this.productoId,
      nombreProducto: nombreProducto ?? this.nombreProducto,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      cantidadTotal: cantidadTotal ?? this.cantidadTotal,
      cantidadPorSabor: cantidadPorSabor ?? this.cantidadPorSabor,
      tieneSabores: tieneSabores ?? this.tieneSabores,
    );
  }
}

// ============= FACTURA MODEL =============

class FacturaModel {
  final String? id;
  final String? clienteId;
  final String nombreCliente;
  final String direccionCliente;
  final String? telefonoCliente;
  final String? negocioCliente;
  final String? rutaCliente;
  final String? observacionesCliente;
  final DateTime fecha;
  final String estado;
  final double total;
  final List<ItemFacturaModel> items;

  FacturaModel({
    this.id,
    this.clienteId,
    required this.nombreCliente,
    required this.direccionCliente,
    this.telefonoCliente,
    this.negocioCliente,
    this.rutaCliente,
    this.observacionesCliente,
    required this.fecha,
    this.estado = 'pendiente',
    this.total = 0,
    this.items = const [],
  });

  factory FacturaModel.fromMap(Map<String, dynamic> map) {
    return FacturaModel(
      id: map['id'],
      clienteId: map['cliente_id'],
      nombreCliente: map['nombre_cliente'] ?? '',
      direccionCliente: map['direccion_cliente'] ?? '',
      telefonoCliente: map['telefono_cliente'],
      negocioCliente: map['negocio_cliente'],
      rutaCliente: map['ruta_cliente'],
      observacionesCliente: map['observaciones_cliente'],
      fecha: DateTime.parse(map['fecha']),
      estado: map['estado'] ?? 'pendiente',
      total: (map['total'] ?? 0).toDouble(),
      items: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cliente_id': clienteId,
      'nombre_cliente': nombreCliente,
      'direccion_cliente': direccionCliente,
      'telefono_cliente': telefonoCliente,
      'negocio_cliente': negocioCliente,
      'ruta_cliente': rutaCliente,
      'observaciones_cliente': observacionesCliente,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'total': total,
    };
  }

  FacturaModel copyWith({
    String? id,
    String? clienteId,
    String? nombreCliente,
    String? direccionCliente,
    String? telefonoCliente,
    String? negocioCliente,
    String? rutaCliente,
    String? observacionesCliente,
    DateTime? fecha,
    String? estado,
    double? total,
    List<ItemFacturaModel>? items,
  }) {
    return FacturaModel(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      direccionCliente: direccionCliente ?? this.direccionCliente,
      telefonoCliente: telefonoCliente ?? this.telefonoCliente,
      negocioCliente: negocioCliente ?? this.negocioCliente,
      rutaCliente: rutaCliente ?? this.rutaCliente,
      observacionesCliente: observacionesCliente ?? this.observacionesCliente,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
      total: total ?? this.total,
      items: items ?? this.items,
    );
  }


}