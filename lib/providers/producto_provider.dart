import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';
import '../models/movimiento_inventario.dart';
import 'supabase_provider.dart';

// Filtro de búsqueda y categoría
final busquedaProvider = StateProvider<String>((ref) => '');
final categoriaFiltroProvider = StateProvider<String?>((ref) => null);

final productosProvider =
    AsyncNotifierProvider<ProductosNotifier, List<Producto>>(
  ProductosNotifier.new,
);

class ProductosNotifier extends AsyncNotifier<List<Producto>> {
  @override
  Future<List<Producto>> build() async {
    ref.watch(authStateChangesProvider); // Reinicia al cambiar de usuario
    if (Supabase.instance.client.auth.currentUser == null) return [];
    return ref.watch(productoRepositoryProvider).fetchAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productoRepositoryProvider).fetchAll(),
    );
  }

  Future<void> insert(Producto producto) async {
    await ref.read(productoRepositoryProvider).insert(producto);
    await reload();
  }

  Future<void> guardar(Producto producto) async {
    await ref.read(productoRepositoryProvider).update(producto);
    await reload();
  }

  Future<void> delete(String id) async {
    await ref.read(productoRepositoryProvider).delete(id);
    state = AsyncData(
      state.value?.where((p) => p.id != id).toList() ?? [],
    );
  }

  Future<void> registrarMovimiento({
    required Producto producto,
    required TipoMovimiento tipo,
    required int cantidad,
    String? nota,
    String? proveedor,
    double? valor,
  }) async {
    final nuevoStock = _calcularNuevoStock(
      stockActual: producto.stockActual,
      tipo: tipo,
      cantidad: cantidad,
    );

    final movimiento = MovimientoInventario(
      id: _newUuid(),
      productoId: producto.id,
      tipo: tipo,
      cantidad: cantidad,
      valor: valor ?? 0,
      proveedor: proveedor,
      nota: nota,
    );

    await ref.read(movimientoRepositoryProvider).insert(movimiento);
    await ref.read(productoRepositoryProvider).updateStock(producto.id, nuevoStock);
    await reload();
  }

  int _calcularNuevoStock({
    required int stockActual,
    required TipoMovimiento tipo,
    required int cantidad,
  }) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return stockActual + cantidad;
      case TipoMovimiento.salida:
        return (stockActual - cantidad).clamp(0, double.maxFinite.toInt());
      case TipoMovimiento.ajuste:
        return cantidad;
      case TipoMovimiento.venta:
        return (stockActual - cantidad).clamp(0, double.maxFinite.toInt());
    }
  }

  String _newUuid() {
    // Simple UUID v4 sin dependencia extra (uuid package está en pubspec)
    // En uso real se usa: const Uuid().v4()
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (m) {
        final r = (now + m.start * 16) % 16;
        final v = m.group(0) == 'x' ? r : (r & 0x3 | 0x8);
        return v.toRadixString(16);
      },
    );
  }
}

// Productos filtrados (computed)
final productosFiltradosProvider = Provider<List<Producto>>((ref) {
  final productos = ref.watch(productosProvider).valueOrNull ?? [];
  final busqueda = ref.watch(busquedaProvider);
  final categoriaId = ref.watch(categoriaFiltroProvider);

  return productos.where((p) {
    final coincideBusqueda =
        busqueda.isEmpty || p.nombre.toLowerCase().contains(busqueda.toLowerCase());
    final coincideCategoria =
        categoriaId == null || p.categoriaId == categoriaId;
    return coincideBusqueda && coincideCategoria;
  }).toList();
});

// Movimientos de un producto
final movimientosProvider =
    FutureProvider.family<List<MovimientoInventario>, String>(
  (ref, productoId) {
    return ref.watch(movimientoRepositoryProvider).fetchByProducto(productoId);
  },
);
