import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/venta.dart';
import '../models/movimiento_inventario.dart';
import '../models/producto.dart';
import 'supabase_provider.dart';
import 'producto_provider.dart';

// ── Carrito: Map<productoId, cantidad> ─────────────────────
final carritoProvider = StateProvider<Map<String, int>>((ref) => {});

// ── Computed: items del carrito con su Producto ─────────────
final carritoItemsProvider = Provider<List<(Producto, int)>>((ref) {
  final carrito = ref.watch(carritoProvider);
  final productos = ref.watch(productosProvider).valueOrNull ?? [];
  return carrito.entries
      .where((e) => e.value > 0)
      .map((e) {
        try {
          final prod = productos.firstWhere((p) => p.id == e.key);
          return (prod, e.value);
        } catch (_) {
          return null;
        }
      })
      .whereType<(Producto, int)>()
      .toList();
});

// ── Computed: total del carrito ────────────────────────────
final carritoTotalProvider = Provider<double>((ref) {
  return ref.watch(carritoItemsProvider).fold(
        0.0,
        (sum, e) => sum + e.$1.precioVenta * e.$2,
      );
});

// ── Ventas del día ─────────────────────────────────────────
final ventasHoyProvider =
    AsyncNotifierProvider<VentasHoyNotifier, List<Venta>>(
  VentasHoyNotifier.new,
);

class VentasHoyNotifier extends AsyncNotifier<List<Venta>> {
  @override
  Future<List<Venta>> build() async {
    ref.watch(authStateChangesProvider);
    if (Supabase.instance.client.auth.currentUser == null) return [];
    return ref.watch(ventaRepositoryProvider).fetchHoy();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ventaRepositoryProvider).fetchHoy(),
    );
  }

  /// Confirma la venta: guarda en BD, descuenta stock y limpia carrito.
  Future<void> confirmarVenta() async {
    final items = ref.read(carritoItemsProvider);
    if (items.isEmpty) throw Exception('El carrito está vacío');

    double total = 0;
    double costoTotal = 0;
    final itemsPayload = <Map<String, dynamic>>[];

    for (final (prod, qty) in items) {
      if (prod.stockActual < qty) {
        throw Exception('Stock insuficiente para ${prod.nombre}');
      }
      total += prod.precioVenta * qty;
      costoTotal += (prod.precioCosto ?? 0) * qty;
      itemsPayload.add({
        'producto_id': prod.id,
        'nombre_producto': prod.nombre,
        'cantidad': qty,
        'precio_unitario': prod.precioVenta,
        'costo_unitario': prod.precioCosto ?? 0,
      });
    }

    // Insertar venta en BD
    await ref.read(ventaRepositoryProvider).insertar(
          total: total,
          costoTotal: costoTotal,
          items: itemsPayload,
        );

    // Registrar movimientos de salida y actualizar stock
    final movRepo = ref.read(movimientoRepositoryProvider);
    final prodRepo = ref.read(productoRepositoryProvider);
    for (final (prod, qty) in items) {
      final mov = MovimientoInventario(
        id: const Uuid().v4(),
        productoId: prod.id,
        tipo: TipoMovimiento.venta,
        cantidad: qty,
        valor: prod.precioVenta * qty,
        nota: 'Venta',
      );
      await movRepo.insert(mov);
      await prodRepo.updateStock(prod.id, prod.stockActual - qty);
    }

    // Limpiar carrito y recargar datos
    ref.read(carritoProvider.notifier).state = {};
    await reload();
    await ref.read(productosProvider.notifier).reload();
  }

  /// Elimina una venta y restaura el stock de sus productos.
  Future<void> deleteVenta(String ventaId) async {
    final ventas = state.value ?? [];
    final venta = ventas.where((v) => v.id == ventaId).isNotEmpty
        ? ventas.firstWhere((v) => v.id == ventaId)
        : null;
    if (venta == null) return;

    await ref.read(ventaRepositoryProvider).delete(ventaId);

    // Restaurar stock
    final prodRepo = ref.read(productoRepositoryProvider);
    final productos = ref.read(productosProvider).valueOrNull ?? [];
    for (final item in venta.items) {
      if (item.productoId == null) continue;
      final prod = productos.cast<Producto?>().firstWhere(
            (p) => p?.id == item.productoId,
            orElse: () => null,
          );
      if (prod != null) {
        await prodRepo.updateStock(prod.id, prod.stockActual + item.cantidad);
      }
    }

    // Actualizar estado local sin recargar todo
    state = AsyncData(ventas.where((v) => v.id != ventaId).toList());
    await ref.read(productosProvider.notifier).reload();
  }
}
