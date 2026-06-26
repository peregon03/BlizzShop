class BaseDia {
  final String id;
  final String usuarioId;
  final DateTime fecha;
  final double monto;
  final String? nota;
  final DateTime? creadoEn;
  final String? jornadaId;

  const BaseDia({
    required this.id,
    required this.usuarioId,
    required this.fecha,
    required this.monto,
    this.nota,
    this.creadoEn,
    this.jornadaId,
  });

  factory BaseDia.fromJson(Map<String, dynamic> json) => BaseDia(
        id: json['id'] as String,
        usuarioId: json['usuario_id'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        monto: (json['monto'] as num).toDouble(),
        nota: json['nota'] as String?,
        creadoEn: json['creado_en'] != null
            ? DateTime.parse(json['creado_en'] as String)
            : null,
        jornadaId: json['jornada_id'] as String?,
      );
}
