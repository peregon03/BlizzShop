class Categoria {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? icono;
  final String color;
  final DateTime? creadoEn;

  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.icono,
    this.color = '#e8a838',
    this.creadoEn,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String?,
      color: json['color'] as String? ?? '#e8a838',
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (icono != null) 'icono': icono,
        'color': color,
      };

  Categoria copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? icono,
    String? color,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      creadoEn: creadoEn,
    );
  }
}
