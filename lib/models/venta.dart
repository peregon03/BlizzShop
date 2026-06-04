class VentaItem {
  final String id;
  final String ventaId;
  final String? productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double costoUnitario;

  const VentaItem({
    required this.id,
    required this.ventaId,
    this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.costoUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
  double get costoTotal => cantidad * costoUnitario;

  factory VentaItem.fromJson(Map<String, dynamic> json) => VentaItem(
        id: json['id'] as String,
        ventaId: json['venta_id'] as String,
        productoId: json['producto_id'] as String?,
        nombreProducto: json['nombre_producto'] as String,
        cantidad: json['cantidad'] as int,
        precioUnitario: (json['precio_unitario'] as num).toDouble(),
        costoUnitario: (json['costo_unitario'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'venta_id': ventaId,
        if (productoId != null) 'producto_id': productoId,
        'nombre_producto': nombreProducto,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'costo_unitario': costoUnitario,
      };
}

class Venta {
  final String id;
  final String usuarioId;
  final double total;
  final double costoTotal;
  final String? nota;
  final DateTime? creadoEn;
  final List<VentaItem> items;

  const Venta({
    required this.id,
    required this.usuarioId,
    required this.total,
    required this.costoTotal,
    this.nota,
    this.creadoEn,
    this.items = const [],
  });

  double get ganancia => total - costoTotal;

  factory Venta.fromJson(Map<String, dynamic> json) => Venta(
        id: json['id'] as String,
        usuarioId: json['usuario_id'] as String,
        total: (json['total'] as num).toDouble(),
        costoTotal: (json['costo_total'] as num).toDouble(),
        nota: json['nota'] as String?,
        creadoEn: json['creado_en'] != null
            ? DateTime.parse(json['creado_en'] as String)
            : null,
        items: (json['venta_items'] as List<dynamic>?)
                ?.map((e) => VentaItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
