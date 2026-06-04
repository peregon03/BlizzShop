class CierreDia {
  final String id;
  final String usuarioId;
  final DateTime fecha;
  final double totalVentas;
  final double costoTotal;
  final int transacciones;
  final int itemsVendidos;
  final String? nota;
  final DateTime? creadoEn;

  const CierreDia({
    required this.id,
    required this.usuarioId,
    required this.fecha,
    required this.totalVentas,
    required this.costoTotal,
    required this.transacciones,
    required this.itemsVendidos,
    this.nota,
    this.creadoEn,
  });

  double get ganancia => totalVentas - costoTotal;

  factory CierreDia.fromJson(Map<String, dynamic> json) => CierreDia(
        id: json['id'] as String,
        usuarioId: json['usuario_id'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        totalVentas: (json['total_ventas'] as num).toDouble(),
        costoTotal: (json['costo_total'] as num).toDouble(),
        transacciones: json['transacciones'] as int,
        itemsVendidos: json['items_vendidos'] as int,
        nota: json['nota'] as String?,
        creadoEn: json['creado_en'] != null
            ? DateTime.parse(json['creado_en'] as String)
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'fecha': fecha.toIso8601String().split('T')[0],
        'total_ventas': totalVentas,
        'costo_total': costoTotal,
        'transacciones': transacciones,
        'items_vendidos': itemsVendidos,
        if (nota != null && nota!.isNotEmpty) 'nota': nota,
      };
}
