class Categoria {
  final String id;
  final String nombre;
  final String? icono;
  final DateTime? creadoEn;

  const Categoria({
    required this.id,
    required this.nombre,
    this.icono,
    this.creadoEn,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      icono: json['icono'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        if (icono != null) 'icono': icono,
      };

  Categoria copyWith({
    String? id,
    String? nombre,
    String? icono,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      icono: icono ?? this.icono,
      creadoEn: creadoEn,
    );
  }
}
