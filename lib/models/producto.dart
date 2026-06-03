import 'categoria.dart';
import 'presentacion.dart';

enum EstadoStock { ok, minimo, bajo, agotado }

class Producto {
  final String id;
  final String nombre;
  final String? descripcion;
  final double precioVenta;
  final double? precioCosto;
  final int stockActual;
  final int stockMinimo;
  final String? categoriaId;
  final String? presentacionId;
  final bool activo;
  final String? imagenUrl;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  // Joins opcionales
  final Categoria? categoria;
  final Presentacion? presentacion;

  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precioVenta,
    this.precioCosto,
    required this.stockActual,
    required this.stockMinimo,
    this.categoriaId,
    this.presentacionId,
    this.activo = true,
    this.imagenUrl,
    this.creadoEn,
    this.actualizadoEn,
    this.categoria,
    this.presentacion,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precioVenta: (json['precio_venta'] as num).toDouble(),
      precioCosto: (json['precio_costo'] as num?)?.toDouble(),
      stockActual: json['stock_actual'] as int,
      stockMinimo: json['stock_minimo'] as int,
      categoriaId: json['categoria_id'] as String?,
      presentacionId: json['presentacion_id'] as String?,
      activo: json['activo'] as bool? ?? true,
      imagenUrl: json['imagen_url'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.parse(json['actualizado_en'] as String)
          : null,
      categoria: json['categoria'] != null
          ? Categoria.fromJson(json['categoria'] as Map<String, dynamic>)
          : null,
      presentacion: json['presentacion'] != null
          ? Presentacion.fromJson(json['presentacion'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        'precio_venta': precioVenta,
        if (precioCosto != null) 'precio_costo': precioCosto,
        'stock_actual': stockActual,
        'stock_minimo': stockMinimo,
        if (categoriaId != null) 'categoria_id': categoriaId,
        if (presentacionId != null) 'presentacion_id': presentacionId,
        'activo': activo,
      };

  EstadoStock get estadoStock {
    if (stockActual <= 0) return EstadoStock.agotado;
    if (stockActual < stockMinimo) return EstadoStock.bajo;
    if (stockActual == stockMinimo) return EstadoStock.minimo;
    return EstadoStock.ok;
  }

  Producto copyWith({
    String? nombre,
    String? descripcion,
    double? precioVenta,
    double? precioCosto,
    int? stockActual,
    int? stockMinimo,
    String? categoriaId,
    String? presentacionId,
  }) {
    return Producto(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioVenta: precioVenta ?? this.precioVenta,
      precioCosto: precioCosto ?? this.precioCosto,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      categoriaId: categoriaId ?? this.categoriaId,
      presentacionId: presentacionId ?? this.presentacionId,
      activo: activo,
      imagenUrl: imagenUrl,
      creadoEn: creadoEn,
    );
  }
}
