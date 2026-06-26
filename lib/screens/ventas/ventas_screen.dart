import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/producto.dart';
import '../../models/movimiento_inventario.dart';
import '../../providers/producto_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../providers/venta_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../providers/medio_pago_provider.dart';
import '../../providers/jornada_provider.dart';
import '../../providers/mesa_provider.dart';
import '../../core/theme.dart';

// Tab activo
final _ventasTabProvider = StateProvider<int>((ref) => 0);
// Búsqueda y filtro en tab Vender
final _busquedaVentaProvider = StateProvider<String>((ref) => '');
final _catFiltroVentaProvider = StateProvider<String?>((ref) => null);

// Productos filtrados para Vender (solo con stock > 0)
final _productosPVentaProvider = Provider<List<Producto>>((ref) {
  final todos = ref.watch(productosProvider).valueOrNull ?? [];
  final busq = ref.watch(_busquedaVentaProvider);
  final cat = ref.watch(_catFiltroVentaProvider);
  return todos.where((p) {
    if (p.stockActual <= 0) return false;
    if (cat != null && p.categoriaId != cat) return false;
    if (busq.isNotEmpty &&
        !p.nombre.toLowerCase().contains(busq.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();
});

class VentasScreen extends ConsumerStatefulWidget {
  const VentasScreen({super.key});

  @override
  ConsumerState<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends ConsumerState<VentasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      ref.read(_ventasTabProvider.notifier).state = _tabCtrl.index;
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final ventasHoy = ref.watch(ventasHoyProvider);
    final totalHoy = ventasHoy.valueOrNull
            ?.fold<double>(0, (s, v) => s + v.total) ??
        0;
    final itemsHoy = ventasHoy.valueOrNull
            ?.fold<int>(
                0, (s, v) => s + v.items.fold(0, (a, i) => a + i.cantidad)) ??
        0;

    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Cierre del día',
            onPressed: () => context.go('/cierre'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: () => context.push('/ajustes'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Vender'),
            Tab(text: 'Inventario'),
            Tab(text: 'Trazabilidad'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats del día
          Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _StatChip(label: 'Ventas jornada', valor: fmt.format(totalHoy)),
                const SizedBox(width: 8),
                _StatChip(label: 'Ítems vendidos', valor: '$itemsHoy'),
                const SizedBox(width: 8),
                const _JornadaChip(),
              ],
            ),
          ),

          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _TabVender(searchCtrl: _searchCtrl),
                const _TabInventario(),
                const _TabTrazabilidad(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB 0: VENDER
// ─────────────────────────────────────────────────────────

class _TabVender extends ConsumerStatefulWidget {
  final TextEditingController searchCtrl;
  const _TabVender({required this.searchCtrl});

  @override
  ConsumerState<_TabVender> createState() => _TabVenderState();
}

class _TabVenderState extends ConsumerState<_TabVender> {
  bool _confirmando = false;

  Future<void> _confirmarVenta() async {
    setState(() => _confirmando = true);
    try {
      await ref.read(ventasHoyProvider.notifier).confirmarVenta();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta registrada ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productos = ref.watch(_productosPVentaProvider);
    final categorias = ref.watch(categoriasProvider).valueOrNull ?? [];
    final catFiltro = ref.watch(_catFiltroVentaProvider);
    final carritoItems = ref.watch(carritoItemsProvider);
    final carritoTotal = ref.watch(carritoTotalProvider);
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Selector de mesa
        const _MesaSelector(),
        const SizedBox(height: 10),

        // Búsqueda
        SearchBar(
          controller: widget.searchCtrl,
          hintText: 'Buscar producto...',
          leading: const Icon(Icons.search, size: 20),
          trailing: ref.watch(_busquedaVentaProvider).isNotEmpty
              ? [
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      widget.searchCtrl.clear();
                      ref.read(_busquedaVentaProvider.notifier).state = '';
                    },
                  )
                ]
              : null,
          onChanged: (v) =>
              ref.read(_busquedaVentaProvider.notifier).state = v,
          backgroundColor: const WidgetStatePropertyAll(Color(0xFF2A2A2A)),
          elevation: const WidgetStatePropertyAll(0),
        ),
        const SizedBox(height: 10),

        // Filtro por categoría
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CatChip(
                label: 'Todas',
                color: null,
                selected: catFiltro == null,
                onTap: () =>
                    ref.read(_catFiltroVentaProvider.notifier).state = null,
              ),
              ...categorias.map((c) => _CatChip(
                    label: c.nombre,
                    color: _hexColor(c.color),
                    selected: catFiltro == c.id,
                    onTap: () =>
                        ref.read(_catFiltroVentaProvider.notifier).state = c.id,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Lista de productos
        if (productos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('Sin productos disponibles',
                  style: TextStyle(color: Colors.white38)),
            ),
          )
        else
          ...productos.map((p) => _ProductoVentaRow(producto: p)),

        // Carrito
        if (carritoItems.isNotEmpty) ...[
          const Divider(height: 24),
          const Text('Carrito actual',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          ...carritoItems.map((entry) {
            final (prod, qty) = entry;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${prod.nombre} ×$qty',
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Text(
                    fmt.format(prod.precioVenta * qty),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(
                fmt.format(carritoTotal),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _MedioPagoSelector(),
          const SizedBox(height: 8),
          _DividirCuentaRow(total: carritoTotal),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(carritoProvider.notifier).state = {};
                    ref.read(notaVentaProvider.notifier).state = null;
                  },
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _confirmando ? null : _confirmarVenta,
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700),
                  child: _confirmando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmar venta'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ProductoVentaRow extends ConsumerWidget {
  final Producto producto;
  const _ProductoVentaRow({required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(carritoProvider);
    final qty = carrito[producto.id] ?? 0;
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$');
    final catColor = producto.categoria != null
        ? _hexColor(producto.categoria!.color)
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(producto.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                Text(
                  '${producto.presentacion?.descripcion ?? ''} · Stock: ${producto.stockActual}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
          Text(fmt.format(producto.precioVenta),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          // Controles de cantidad
          Row(
            children: [
              _QtyBtn(
                icon: Icons.remove,
                onTap: qty > 0
                    ? () {
                        final c = Map<String, int>.from(
                            ref.read(carritoProvider));
                        if (qty - 1 <= 0) {
                          c.remove(producto.id);
                        } else {
                          c[producto.id] = qty - 1;
                        }
                        ref.read(carritoProvider.notifier).state = c;
                      }
                    : null,
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              _QtyBtn(
                icon: Icons.add,
                onTap: qty < producto.stockActual
                    ? () {
                        final c = Map<String, int>.from(
                            ref.read(carritoProvider));
                        c[producto.id] = qty + 1;
                        ref.read(carritoProvider.notifier).state = c;
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFF2E2E2E)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 16, color: onTap != null ? Colors.white : Colors.white24),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip(
      {required this.label,
      this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)
                : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
              ],
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB 1: INVENTARIO (resumen rápido de stock)
// ─────────────────────────────────────────────────────────

class _TabInventario extends ConsumerWidget {
  const _TabInventario();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync = ref.watch(productosProvider);

    return productosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (productos) {
        if (productos.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 48, color: Colors.white24),
              const SizedBox(height: 12),
              const Text('Sin productos',
                  style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/inventario/nuevo'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar producto'),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${productos.length} productos',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                TextButton.icon(
                  onPressed: () => context.go('/inventario'),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Gestionar'),
                ),
              ],
            ),
            ...productos.map((p) => _InventarioRow(producto: p)),
          ],
        );
      },
    );
  }
}

class _InventarioRow extends StatelessWidget {
  final Producto producto;
  const _InventarioRow({required this.producto});

  @override
  Widget build(BuildContext context) {
    final bajo = producto.stockActual <= producto.stockMinimo;
    final catColor = producto.categoria != null
        ? _hexColor(producto.categoria!.color)
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(producto.nombre,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(
            '${producto.stockActual} uds.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: bajo ? AppTheme.stockBajo : AppTheme.stockOk,
              fontSize: 13,
            ),
          ),
          if (bajo) ...[
            const SizedBox(width: 6),
            const Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 16),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB 2: TRAZABILIDAD
// ─────────────────────────────────────────────────────────

final _movimientosRecientesProvider =
    FutureProvider<List<MovimientoInventario>>((ref) {
  return ref.watch(movimientoRepositoryProvider).fetchRecientes();
});

class _TabTrazabilidad extends ConsumerWidget {
  const _TabTrazabilidad();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movsAsync = ref.watch(_movimientosRecientesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Historial de movimientos',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              FilledButton.icon(
                onPressed: () => _mostrarModalEntrada(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Entrada', style: TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: movsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (movs) {
              if (movs.isEmpty) {
                return const Center(
                  child: Text('Sin movimientos registrados',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(_movimientosRecientesProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: movs.length,
                  itemBuilder: (ctx, i) => _MovimientoRow(mov: movs[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarModalEntrada(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _EntradaModal(),
    );
  }
}

class _MovimientoRow extends StatelessWidget {
  final MovimientoInventario mov;
  const _MovimientoRow({required this.mov});

  @override
  Widget build(BuildContext context) {
    final (color, icono) = switch (mov.tipo) {
      TipoMovimiento.entrada => (Colors.green, Icons.arrow_downward),
      TipoMovimiento.venta || TipoMovimiento.salida =>
        (Colors.red, Icons.arrow_upward),
      TipoMovimiento.ajuste => (Colors.amber, Icons.tune),
    };
    final signo =
        mov.tipo == TipoMovimiento.entrada ? '+' : '−';
    final fecha = mov.creadoEn != null
        ? DateFormat('dd/MM/yy HH:mm').format(mov.creadoEn!)
        : '';
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mov.tipo.etiqueta,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                Text(
                  [
                    fecha,
                    if (mov.proveedor != null) mov.proveedor!,
                    if (mov.nota != null) mov.nota!,
                  ].join(' · '),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$signo${mov.cantidad}',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              if (mov.valor > 0)
                Text(fmt.format(mov.valor),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// Modal de entrada de inventario desde Trazabilidad
class _EntradaModal extends ConsumerStatefulWidget {
  const _EntradaModal();

  @override
  ConsumerState<_EntradaModal> createState() => _EntradaModalState();
}

class _EntradaModalState extends ConsumerState<_EntradaModal> {
  String? _prodId;
  final _qtyCtrl = TextEditingController(text: '1');
  final _costoCtrl = TextEditingController();
  final _proveedorCtrl = TextEditingController();
  final _notaCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costoCtrl.dispose();
    _proveedorCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final productos = ref.read(productosProvider).valueOrNull ?? [];
    if (_prodId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona un producto')));
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cantidad debe ser mayor a 0')));
      return;
    }
    setState(() => _guardando = true);
    try {
      final prod = productos.firstWhere((p) => p.id == _prodId);
      final costo = double.tryParse(_costoCtrl.text) ?? 0;
      final mov = MovimientoInventario(
        id: const Uuid().v4(),
        productoId: prod.id,
        tipo: TipoMovimiento.entrada,
        cantidad: qty,
        valor: costo,
        proveedor: _proveedorCtrl.text.trim().isEmpty
            ? null
            : _proveedorCtrl.text.trim(),
        nota: _notaCtrl.text.trim().isEmpty ? 'Compra' : _notaCtrl.text.trim(),
      );
      await ref.read(movimientoRepositoryProvider).insert(mov);
      await ref.read(productoRepositoryProvider).updateStock(
            prod.id,
            prod.stockActual + qty,
          );
      await ref.read(productosProvider.notifier).reload();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Entrada registrada: +$qty ${prod.nombre} ✓'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productos = ref.watch(productosProvider).valueOrNull ?? [];

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text('Registrar entrada',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DropdownButtonFormField<String>(
              initialValue: _prodId,
              hint: const Text('Seleccionar producto'),
              decoration: const InputDecoration(),
              items: productos
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nombre),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _prodId = v),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _field('Cantidad', _qtyCtrl,
                      type: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field('Costo total (\$)', _costoCtrl,
                      type: const TextInputType.numberWithOptions(decimal: true)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _field('Proveedor (opcional)', _proveedorCtrl),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _field('Nota', _notaCtrl),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: FilledButton(
              onPressed: _guardando ? null : _registrar,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Registrar entrada'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(hintText: hint),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Selector de medio de pago
// ─────────────────────────────────────────────────────────

class _MedioPagoSelector extends ConsumerWidget {
  const _MedioPagoSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediosAsync = ref.watch(mediosPagoProvider);
    final medios = mediosAsync.valueOrNull ?? [];
    final seleccionadoId = ref.watch(medioPagoSeleccionadoProvider);

    // Auto-seleccionar el primero si no hay ninguno
    final efectivoId = medios.isNotEmpty ? medios.first.id : null;
    final idActivo = seleccionadoId ?? efectivoId;

    if (medios.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Método de pago',
            style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: medios
                .map((m) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(medioPagoSeleccionadoProvider.notifier)
                            .state = m.id,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: idActivo == m.id
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2)
                                : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: idActivo == m.id
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(m.nombre,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: idActivo == m.id
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: idActivo == m.id
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white70,
                              )),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Selector de mesa
// ─────────────────────────────────────────────────────────

class _MesaSelector extends ConsumerWidget {
  const _MesaSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesasAsync = ref.watch(mesasProvider);
    final mesas = mesasAsync.valueOrNull ?? [];
    final mesaId = ref.watch(mesaSeleccionadaProvider);

    if (mesas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mesa',
            style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CatChip(
                label: 'Sin mesa',
                color: null,
                selected: mesaId == null,
                onTap: () =>
                    ref.read(mesaSeleccionadaProvider.notifier).state = null,
              ),
              ...mesas.map((m) => _CatChip(
                    label: m.nombre,
                    color: Theme.of(context).colorScheme.primary,
                    selected: mesaId == m.id,
                    onTap: () => ref
                        .read(mesaSeleccionadaProvider.notifier)
                        .state = m.id,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Fila de dividir cuenta
// ─────────────────────────────────────────────────────────

class _DividirCuentaRow extends ConsumerWidget {
  final double total;
  const _DividirCuentaRow({required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nota = ref.watch(notaVentaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_outline, size: 16, color: Colors.white54),
            const SizedBox(width: 6),
            const Text('Cuenta separada',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => _DividirCuentaModal(total: total),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: nota != null
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15)
                      : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: nota != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  nota != null ? 'Editar división' : 'Dividir cuenta',
                  style: TextStyle(
                    fontSize: 12,
                    color: nota != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white60,
                    fontWeight: nota != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
            if (nota != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () =>
                    ref.read(notaVentaProvider.notifier).state = null,
                child: const Icon(Icons.close, size: 16, color: Colors.white38),
              ),
            ],
          ],
        ),
        if (nota != null) ...[
          const SizedBox(height: 4),
          Text(
            nota,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Modal para dividir cuenta
// ─────────────────────────────────────────────────────────

class _DividirCuentaModal extends ConsumerStatefulWidget {
  final double total;
  const _DividirCuentaModal({required this.total});

  @override
  ConsumerState<_DividirCuentaModal> createState() =>
      _DividirCuentaModalState();
}

class _DividirCuentaModalState extends ConsumerState<_DividirCuentaModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Tab 0: Por total
  int _nPersonas = 2;

  // Tab 1: Por producto — Map<productoId, nPersonas>
  final Map<String, int> _personasPorProducto = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String _fmt(double monto) =>
      NumberFormat.currency(locale: 'es_CO', symbol: '\$').format(monto);

  void _confirmarPorTotal() {
    if (_nPersonas <= 0) return;
    final porPersona = widget.total / _nPersonas;
    ref.read(notaVentaProvider.notifier).state =
        'Entre $_nPersonas personas · ${_fmt(porPersona)} c/u';
    Navigator.of(context).pop();
  }

  void _confirmarPorProducto(List<(Producto, int)> items) {
    if (items.isEmpty) return;
    final partes = <String>[];
    for (final (prod, qty) in items) {
      final nP = _personasPorProducto[prod.id] ?? 1;
      final subtotal = prod.precioVenta * qty;
      if (nP > 1) {
        partes.add('${prod.nombre} → ${_fmt(subtotal / nP)} c/u (${nP}p)');
      } else {
        partes.add('${prod.nombre}: ${_fmt(subtotal)}');
      }
    }
    ref.read(notaVentaProvider.notifier).state = partes.join(' · ');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(carritoItemsProvider);

    // Inicializar nPersonas por producto
    for (final (prod, _) in items) {
      _personasPorProducto.putIfAbsent(prod.id, () => 1);
    }

    final tabH = MediaQuery.sizeOf(context).height * 0.46;
    final keyboardH = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Encabezado
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dividir cuenta',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  'Total: ${_fmt(widget.total)}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: 'Por total'),
              Tab(text: 'Por producto'),
            ],
          ),
          SizedBox(
            height: tabH,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildTabTotal(context),
                _buildTabProducto(context, items),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 0: divide el total entre N personas ──────────────
  Widget _buildTabTotal(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        children: [
          // Selector +/–
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepBtn(
                icon: Icons.remove,
                onTap: _nPersonas > 1
                    ? () => setState(() => _nPersonas--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      '$_nPersonas',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const Text('personas',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                onTap: () => setState(() => _nPersonas++),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Resultado
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _fmt(widget.total / _nPersonas),
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 4),
                const Text('por persona',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _confirmarPorTotal,
            style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: divide cada producto entre N personas ─────────
  Widget _buildTabProducto(BuildContext context, List<(Producto, int)> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('El carrito está vacío',
            style: TextStyle(color: Colors.white38)),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final (prod, qty) = items[i];
              final nP = _personasPorProducto[prod.id] ?? 1;
              final subtotal = prod.precioVenta * qty;
              final porPersona = subtotal / nP;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border.all(color: const Color(0xFF2E2E2E)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${prod.nombre} ×$qty',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          _fmt(subtotal),
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Entre cuántos:',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        const Spacer(),
                        _StepBtn(
                          icon: Icons.remove,
                          onTap: nP > 1
                              ? () => setState(() =>
                                  _personasPorProducto[prod.id] = nP - 1)
                              : null,
                          small: true,
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '$nP',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        _StepBtn(
                          icon: Icons.add,
                          onTap: () => setState(() =>
                              _personasPorProducto[prod.id] = nP + 1),
                          small: true,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '${_fmt(porPersona)} c/u',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: FilledButton(
            onPressed: () => _confirmarPorProducto(items),
            style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            child: const Text('Confirmar'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Botón paso (+/–) reutilizable
// ─────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool small;

  const _StepBtn({required this.icon, this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 28.0 : 44.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFF2E2E2E)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(small ? 6 : 10),
          border: Border.all(
            color: onTap != null
                ? Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Icon(icon,
            size: small ? 14 : 22,
            color: onTap != null ? Colors.white : Colors.white24),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Indicador de jornada activa
// ─────────────────────────────────────────────────────────

class _JornadaChip extends ConsumerStatefulWidget {
  const _JornadaChip();

  @override
  ConsumerState<_JornadaChip> createState() => _JornadaChipState();
}

class _JornadaChipState extends ConsumerState<_JornadaChip> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // Actualiza cada minuto para que el tiempo transcurrido sea preciso
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _duracion(DateTime apertura) {
    final diff = DateTime.now().difference(apertura);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final jornadaAsync = ref.watch(jornadaActivaProvider);

    return jornadaAsync.when(
      loading: () => const _StatChip(label: 'Jornada', valor: '...'),
      error: (_, __) => const _StatChip(label: 'Jornada', valor: 'Error'),
      data: (jornada) {
        if (jornada == null) {
          return const _StatChip(label: 'Jornada', valor: '—');
        }
        final apertura = jornada.fechaApertura.toLocal();
        final horaApertura = DateFormat('HH:mm').format(apertura);
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _duracion(apertura),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Desde $horaApertura',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String valor;
  const _StatChip({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(valor,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

Color _hexColor(String hex) {
  try {
    return Color(
        int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return Colors.grey;
  }
}
