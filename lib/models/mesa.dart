class Mesa {
  final String id;
  final String usuarioId;
  final String nombre;
  final bool activo;
  final int orden;

  const Mesa({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    this.activo = true,
    this.orden = 0,
  });

  factory Mesa.fromJson(Map<String, dynamic> json) => Mesa(
        id: json['id'] as String,
        usuarioId: json['usuario_id'] as String,
        nombre: json['nombre'] as String,
        activo: json['activo'] as bool? ?? true,
        orden: json['orden'] as int? ?? 0,
      );

  Mesa copyWith({String? nombre, bool? activo, int? orden}) => Mesa(
        id: id,
        usuarioId: usuarioId,
        nombre: nombre ?? this.nombre,
        activo: activo ?? this.activo,
        orden: orden ?? this.orden,
      );
}
