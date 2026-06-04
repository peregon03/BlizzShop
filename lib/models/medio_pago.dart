class MedioPago {
  final String id;
  final String usuarioId;
  final String nombre;
  final bool activo;
  final int orden;

  const MedioPago({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.activo = true,
    this.orden = 0,
  });

  factory MedioPago.fromJson(Map<String, dynamic> json) => MedioPago(
        id: json['id'] as String,
        usuarioId: json['usuario_id'] as String,
        nombre: json['nombre'] as String,
        activo: json['activo'] as bool? ?? true,
        orden: json['orden'] as int? ?? 0,
      );

  MedioPago copyWith({String? nombre, bool? activo, int? orden}) => MedioPago(
        id: id,
        usuarioId: usuarioId,
        nombre: nombre ?? this.nombre,
        activo: activo ?? this.activo,
        orden: orden ?? this.orden,
      );
}
