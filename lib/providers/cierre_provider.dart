import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/cierre_dia.dart';
import '../models/venta.dart';
import '../models/producto.dart';
import 'supabase_provider.dart';
import 'venta_provider.dart';
import 'producto_provider.dart';

final cierresProvider =
    AsyncNotifierProvider<CierresNotifier, List<CierreDia>>(
  CierresNotifier.new,
);

class CierresNotifier extends AsyncNotifier<List<CierreDia>> {
  @override
  Future<List<CierreDia>> build() async {
    ref.watch(authStateChangesProvider);
    if (Supabase.instance.client.auth.currentUser == null) return [];
    return ref.watch(cierreRepositoryProvider).fetchAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(cierreRepositoryProvider).fetchAll(),
    );
  }

  Future<void> confirmarCierre({String? nota}) async {
    final ventasHoy = ref.read(ventasHoyProvider).valueOrNull ?? [];
    if (ventasHoy.isEmpty) throw Exception('No hay ventas para registrar en el cierre');

    final total = ventasHoy.fold<double>(0, (s, v) => s + v.total);
    final costo = ventasHoy.fold<double>(0, (s, v) => s + v.costoTotal);
    final items = ventasHoy.fold<int>(
        0, (s, v) => s + v.items.fold(0, (a, i) => a + i.cantidad));

    final cierre = CierreDia(
      id: const Uuid().v4(),
      usuarioId: '',
      fecha: DateTime.now(),
      totalVentas: total,
      costoTotal: costo,
      transacciones: ventasHoy.length,
      itemsVendidos: items,
      nota: nota,
    );

    await ref.read(cierreRepositoryProvider).insertar(cierre);
    await reload();
  }

  Future<void> deleteCierre(String id) async {
    await ref.read(cierreRepositoryProvider).deleteCierre(id);
    state = AsyncData(
      state.value?.where((c) => c.id != id).toList() ?? [],
    );
  }
}

// ── Estadísticas del día para CierreScreen ─────────────────
final statsHoyProvider = Provider<_StatsHoy>((ref) {
  final ventasHoy = ref.watch(ventasHoyProvider).valueOrNull ?? [];
  final productos = ref.watch(productosProvider).valueOrNull ?? [];
  return _StatsHoy.calcular(ventasHoy, productos);
});

class _StatsHoy {
  final double totalVentas;
  final double costoTotal;
  final int transacciones;
  final int itemsVendidos;
  final double ticketPromedio;
  final Map<String, _CatStat> porCategoria;
  final List<(String, int, double)> topProductos; // (nombre, qty, total)

  const _StatsHoy({
    required this.totalVentas,
    required this.costoTotal,
    required this.transacciones,
    required this.itemsVendidos,
    required this.ticketPromedio,
    required this.porCategoria,
    required this.topProductos,
  });

  double get ganancia => totalVentas - costoTotal;

  factory _StatsHoy.calcular(List<Venta> ventas, List<Producto> productos) {
    if (ventas.isEmpty) {
      return const _StatsHoy(
        totalVentas: 0,
        costoTotal: 0,
        transacciones: 0,
        itemsVendidos: 0,
        ticketPromedio: 0,
        porCategoria: {},
        topProductos: [],
      );
    }

    double total = 0, costo = 0;
    int items = 0;
    final porProd = <String, (int, double)>{};
    final porCat = <String, _CatStat>{};

    for (final v in ventas) {
      total += v.total;
      costo += v.costoTotal;
      for (final i in v.items) {
        items += i.cantidad;
        final prev = porProd[i.nombreProducto];
        porProd[i.nombreProducto] = (
          (prev?.$1 ?? 0) + i.cantidad,
          (prev?.$2 ?? 0) + i.subtotal,
        );

        // Categoría
        final prod = productos.cast<Producto?>().firstWhere(
              (p) => p?.id == i.productoId,
              orElse: () => null,
            );
        final catNombre = prod?.categoria?.nombre ?? 'Sin categoría';
        final catColor = prod?.categoria?.color ?? '#666666';
        final prev2 = porCat[catNombre];
        porCat[catNombre] = _CatStat(
          nombre: catNombre,
          color: catColor,
          total: (prev2?.total ?? 0) + i.subtotal,
          qty: (prev2?.qty ?? 0) + i.cantidad,
        );
      }
    }

    final top = porProd.entries
        .map((e) => (e.key, e.value.$1, e.value.$2))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return _StatsHoy(
      totalVentas: total,
      costoTotal: costo,
      transacciones: ventas.length,
      itemsVendidos: items,
      ticketPromedio: total / ventas.length,
      porCategoria: porCat,
      topProductos: top.take(5).toList(),
    );
  }
}

class _CatStat {
  final String nombre;
  final String color;
  final double total;
  final int qty;

  const _CatStat({
    required this.nombre,
    required this.color,
    required this.total,
    required this.qty,
  });
}
