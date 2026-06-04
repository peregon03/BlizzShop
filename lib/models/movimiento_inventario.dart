enum TipoMovimiento { entrada, salida, ajuste, venta }

extension TipoMovimientoX on TipoMovimiento {
  String get value => switch (this) {
        TipoMovimiento.entrada => 'entrada',
        TipoMovimiento.salida => 'salida',
        TipoMovimiento.ajuste => 'ajuste',
        TipoMovimiento.venta => 'venta',
      };

  String get etiqueta => switch (this) {
        TipoMovimiento.entrada => 'Entrada',
        TipoMovimiento.salida => 'Salida',
        TipoMovimiento.ajuste => 'Ajuste',
        TipoMovimiento.venta => 'Venta',
      };

  static TipoMovimiento fromString(String s) => switch (s) {
        'entrada' => TipoMovimiento.entrada,
        'salida' => TipoMovimiento.salida,
        'venta' => TipoMovimiento.venta,
        _ => TipoMovimiento.ajuste,
      };
}

class MovimientoInventario {
  final String id;
  final String productoId;
  final TipoMovimiento tipo;
  final int cantidad;
  final double valor;
  final String? proveedor;
  final String? nota;
  final DateTime? creadoEn;

  const MovimientoInventario({
    required this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    this.valor = 0,
    this.proveedor,
    this.nota,
    this.creadoEn,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    return MovimientoInventario(
      id: json['id'] as String,
      productoId: json['producto_id'] as String,
      tipo: TipoMovimientoX.fromString(json['tipo'] as String),
      cantidad: json['cantidad'] as int,
      valor: (json['valor'] as num?)?.toDouble() ?? 0,
      proveedor: json['proveedor'] as String?,
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
        'valor': valor,
        if (proveedor != null) 'proveedor': proveedor,
        if (nota != null) 'nota': nota,
      };
}
