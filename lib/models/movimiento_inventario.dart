enum TipoMovimiento { entrada, salida, ajuste }

extension TipoMovimientoX on TipoMovimiento {
  String get value {
    switch (this) {
      case TipoMovimiento.entrada:
        return 'entrada';
      case TipoMovimiento.salida:
        return 'salida';
      case TipoMovimiento.ajuste:
        return 'ajuste';
    }
  }

  String get etiqueta {
    switch (this) {
      case TipoMovimiento.entrada:
        return 'Entrada';
      case TipoMovimiento.salida:
        return 'Salida';
      case TipoMovimiento.ajuste:
        return 'Ajuste';
    }
  }

  static TipoMovimiento fromString(String s) {
    switch (s) {
      case 'entrada':
        return TipoMovimiento.entrada;
      case 'salida':
        return TipoMovimiento.salida;
      default:
        return TipoMovimiento.ajuste;
    }
  }
}

class MovimientoInventario {
  final String id;
  final String productoId;
  final TipoMovimiento tipo;
  final int cantidad;
  final String? nota;
  final DateTime? creadoEn;

  const MovimientoInventario({
    required this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    this.nota,
    this.creadoEn,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    return MovimientoInventario(
      id: json['id'] as String,
      productoId: json['producto_id'] as String,
      tipo: TipoMovimientoX.fromString(json['tipo'] as String),
      cantidad: json['cantidad'] as int,
      nota: json['nota'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'producto_id': productoId,
        'tipo': tipo.value,
        'cantidad': cantidad,
        if (nota != null) 'nota': nota,
      };
}
