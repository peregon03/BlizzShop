import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/producto.dart';
import '../../models/movimiento_inventario.dart';
import '../../providers/producto_provider.dart';
import '../../core/theme.dart';
import '../formulario/movimiento_form_screen.dart';

class ProductoDetalleScreen extends ConsumerWidget {
  final Producto producto;

  const ProductoDetalleScreen({super.key, required this.producto});

  Color _stockColor(EstadoStock e) {
    switch (e) {
      case EstadoStock.ok:
        return AppTheme.stockOk;
      case EstadoStock.minimo:
        return AppTheme.stockMinimo;
      case EstadoStock.bajo:
        return AppTheme.stockBajo;
      case EstadoStock.agotado:
        return AppTheme.stockAgotado;
    }
  }

  String _stockLabel(EstadoStock e) {
    switch (e) {
      case EstadoStock.ok:
        return 'OK';
      case EstadoStock.minimo:
        return 'Mínimo';
      case EstadoStock.bajo:
        return 'Bajo';
      case EstadoStock.agotado:
        return 'Agotado';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientosAsync =
        ref.watch(movimientosProvider(producto.id));

    final precioFmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(producto.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/inventario/editar', extra: producto),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info principal
            _Card(
              titulo: 'Información',
              children: [
                _infoRow('Precio venta',
                    precioFmt.format(producto.precioVenta)),
                if (producto.precioCosto != null)
                  _infoRow('Precio costo',
                      precioFmt.format(producto.precioCosto)),
                if (producto.categoria != null)
                  _infoRow('Categoría', producto.categoria!.nombre),
                if (producto.presentacion != null)
                  _infoRow('Presentación', producto.presentacion!.descripcion),
                if (producto.descripcion != null &&
                    producto.descripcion!.isNotEmpty)
                  _infoRow('Descripción', producto.descripcion!),
              ],
            ),
            const SizedBox(height: 12),

            // Stock
            _Card(
              titulo: 'Stock',
              children: [
                Row(
                  children: [
                    const Text('Stock actual',
                        style: TextStyle(color: Colors.white60)),
                    const Spacer(),
                    Text(
                      '${producto.stockActual} uds.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _stockColor(producto.estadoStock),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _stockColor(producto.estadoStock)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _stockLabel(producto.estadoStock),
                        style: TextStyle(
                          fontSize: 11,
                          color: _stockColor(producto.estadoStock),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow('Stock mínimo', '${producto.stockMinimo} uds.'),
              ],
            ),
            const SizedBox(height: 12),

            // Botones de movimiento
            Row(
              children: [
                _botonMovimiento(
                  context: context,
                  etiqueta: 'Entrada',
                  icono: Icons.arrow_downward,
                  color: Colors.green,
                  tipo: TipoMovimiento.entrada,
                ),
                const SizedBox(width: 8),
                _botonMovimiento(
                  context: context,
                  etiqueta: 'Salida',
                  icono: Icons.arrow_upward,
                  color: Colors.red,
                  tipo: TipoMovimiento.salida,
                ),
                const SizedBox(width: 8),
                _botonMovimiento(
                  context: context,
                  etiqueta: 'Ajuste',
                  icono: Icons.tune,
                  color: Colors.amber,
                  tipo: TipoMovimiento.ajuste,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Historial
            _Card(
              titulo: 'Últimos movimientos',
              children: [
                movimientosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (movs) {
                    if (movs.isEmpty) {
                      return const Text('Sin movimientos registrados.',
                          style: TextStyle(color: Colors.white54));
                    }
                    return Column(
                      children: movs
                          .map((m) => _movimientoTile(m))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonMovimiento({
    required BuildContext context,
    required String etiqueta,
    required IconData icono,
    required Color color,
    required TipoMovimiento tipo,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _abrirMovimiento(context, tipo),
        icon: Icon(icono, size: 16, color: color),
        label: Text(etiqueta, style: TextStyle(color: color, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  void _abrirMovimiento(BuildContext context, TipoMovimiento tipo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MovimientoFormScreen(
        args: MovimientoFormArgs(producto: producto, tipoInicial: tipo),
      ),
    );
  }

  Widget _infoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          const Spacer(),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _movimientoTile(MovimientoInventario mov) {
    final (color, icono) = switch (mov.tipo) {
      TipoMovimiento.entrada => (Colors.green, Icons.arrow_downward),
      TipoMovimiento.salida => (Colors.red, Icons.arrow_upward),
      TipoMovimiento.ajuste => (Colors.amber, Icons.tune),
      TipoMovimiento.venta => (Colors.purple, Icons.point_of_sale),
    };

    final signo = mov.tipo == TipoMovimiento.salida ? '-' : '+';
    final fecha = mov.creadoEn != null
        ? DateFormat('dd/MM/yy HH:mm').format(mov.creadoEn!)
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mov.tipo.etiqueta,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                if (mov.nota != null)
                  Text(mov.nota!,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                Text(fecha,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '$signo${mov.cantidad}',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _Card({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white54,
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
