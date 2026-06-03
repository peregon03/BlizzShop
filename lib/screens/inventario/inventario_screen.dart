import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/producto_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../models/producto.dart';
import 'producto_card.dart';

class InventarioScreen extends ConsumerStatefulWidget {
  const InventarioScreen({super.key});

  @override
  ConsumerState<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends ConsumerState<InventarioScreen> {
  final _searchController = SearchController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosProvider);
    final productosFiltrados = ref.watch(productosFiltradosProvider);
    final categorias = ref.watch(categoriasProvider).valueOrNull ?? [];
    final categoriaFiltro = ref.watch(categoriaFiltroProvider);
    final busqueda = ref.watch(busquedaProvider);

    final totalBajo = productosAsync.valueOrNull
            ?.where((p) =>
                p.estadoStock == EstadoStock.bajo ||
                p.estadoStock == EstadoStock.agotado)
            .length ??
        0;
    final total = productosAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar producto…',
              leading: const Icon(Icons.search),
              trailing: busqueda.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(busquedaProvider.notifier).state = '';
                        },
                      )
                    ]
                  : null,
              onChanged: (value) {
                ref.read(busquedaProvider.notifier).state = value;
              },
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              elevation: const WidgetStatePropertyAll(0),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Banner de alertas
          if (totalBajo > 0)
            _AlertaBanner(total: total, bajo: totalBajo),

          // Chips de categorías
          _FiltrosCategorias(
            categorias: categorias.map((c) => (c.id, c.nombre, c.icono)).toList(),
            seleccionado: categoriaFiltro,
            onSelect: (id) {
              ref.read(categoriaFiltroProvider.notifier).state = id;
            },
          ),

          // Lista
          Expanded(
            child: productosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (_) {
                if (productosFiltrados.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: Colors.white24),
                        SizedBox(height: 12),
                        Text('Sin productos', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(productosProvider.notifier).reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: productosFiltrados.length,
                    itemBuilder: (context, i) {
                      final producto = productosFiltrados[i];
                      return ProductoCard(
                        producto: producto,
                        onTap: () => context.push(
                          '/inventario/detalle',
                          extra: producto,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventario/nuevo'),
        icon: const Icon(Icons.add),
        label: const Text('Producto'),
      ),
    );
  }
}

class _AlertaBanner extends StatelessWidget {
  final int total;
  final int bajo;

  const _AlertaBanner({required this.total, required this.bajo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade800.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            '$total productos  ·  $bajo con stock bajo',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosCategorias extends StatelessWidget {
  final List<(String, String, String?)> categorias;
  final String? seleccionado;
  final void Function(String?) onSelect;

  const _FiltrosCategorias({
    required this.categorias,
    required this.seleccionado,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip(context, null, 'Todas', Icons.grid_view),
          ...categorias.map(
            (c) => _chip(context, c.$1, c.$2, _iconoMaterial(c.$3)),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String? id, String nombre, IconData icono) {
    final seleccionada = seleccionado == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: Icon(icono, size: 14),
        label: Text(nombre),
        selected: seleccionada,
        onSelected: (_) => onSelect(id),
        showCheckmark: false,
      ),
    );
  }

  IconData _iconoMaterial(String? nombre) {
    switch (nombre) {
      case 'wine_bar':
        return Icons.wine_bar;
      case 'local_bar':
        return Icons.local_bar;
      case 'liquor':
        return Icons.liquor;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      default:
        return Icons.label_outline;
    }
  }
}
