class Jornada {
  final String id;
  final String usuarioId;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final bool cerrada;
  final String? notaCierre;
  final DateTime? creadoEn;

  const Jornada({
    required this.id,
    required this.usuarioId,
    required this.fechaApertura,
    this.fechaCierre,
    required this.cerrada,
    this.notaCierre,
    this.creadoEn,
  });

  factory Jornada.fromJson(Map<String, dynamic> json) => Jornada(
        id: json['id'] as String,
        usuarioId: json['usuario_id'] as String,
        fechaApertura: DateTime.parse(json['fecha_apertura'] as String),
        fechaCierre: json['fecha_cierre'] != null
            ? DateTime.parse(json['fecha_cierre'] as String)
            : null,
        cerrada: json['cerrada'] as bool? ?? false,
        notaCierre: json['nota_cierre'] as String?,
        creadoEn: json['creado_en'] != null
            ? DateTime.parse(json['creado_en'] as String)
            : null,
      );
}
