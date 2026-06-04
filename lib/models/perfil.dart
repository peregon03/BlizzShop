class Perfil {
  final String id;
  final String nombre;
  final String nombreBar;
  final DateTime? creadoEn;

  const Perfil({
    required this.id,
    required this.nombre,
    required this.nombreBar,
    this.creadoEn,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        nombreBar: json['nombre_bar'] as String? ?? '',
        creadoEn: json['creado_en'] != null
            ? DateTime.parse(json['creado_en'] as String)
            : null,
      );

  Perfil copyWith({String? nombre, String? nombreBar}) => Perfil(
        id: id,
        nombre: nombre ?? this.nombre,
        nombreBar: nombreBar ?? this.nombreBar,
        creadoEn: creadoEn,
      );
}
