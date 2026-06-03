class Presentacion {
  final String id;
  final String descripcion;
  final int? volumenMl;
  final DateTime? creadoEn;

  const Presentacion({
    required this.id,
    required this.descripcion,
    this.volumenMl,
    this.creadoEn,
  });

  factory Presentacion.fromJson(Map<String, dynamic> json) {
    return Presentacion(
      id: json['id'] as String,
      descripcion: json['descripcion'] as String,
      volumenMl: json['volumen_ml'] as int?,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'descripcion': descripcion,
        if (volumenMl != null) 'volumen_ml': volumenMl,
      };

  Presentacion copyWith({
    String? id,
    String? descripcion,
    int? volumenMl,
    bool clearVolumen = false,
  }) {
    return Presentacion(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      volumenMl: clearVolumen ? null : (volumenMl ?? this.volumenMl),
      creadoEn: creadoEn,
    );
  }
}
