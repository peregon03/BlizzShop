import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/base_dia.dart';
import '../../models/cierre_dia.dart';
import '../../models/venta.dart';
import '../../providers/base_dia_provider.dart';
import '../../providers/venta_provider.dart';
import '../../providers/cierre_provider.dart';

class CierreScreen extends ConsumerStatefulWidget {
  const CierreScreen({super.key});

  @override
  ConsumerState<CierreScreen> createState() => _CierreScreenState();
}

class _CierreScreenState extends ConsumerState<CierreScreen> {
  final _notaCtrl = TextEditingController();
  bool _confirmando = false;

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _hacerCierre() async {
    final ventasHoy = ref.read(ventasHoyProvider).valueOrNull ?? [];
    if (ventasHoy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ventas para cerrar hoy')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar cierre'),
        content: const Text('¿Confirmar cierre del día? El reporte quedará guardado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar',
                  style: TextStyle(color: Colors.green))),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _confirmando = true);
    try {
      await ref.read(cierresProvider.notifier).confirmarCierre(
            nota: _notaCtrl.text.trim(),
          );
      if (mounted) {
        _notaCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cierre del día confirmado ✓'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(ventasHoyProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _confirmando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsHoyProvider);
    final ventasHoy = ref.watch(ventasHoyProvider).valueOrNull ?? [];
    final baseDia = ref.watch(baseDiaProvider).valueOrNull;
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$');
    final hoy = DateFormat('EEEE d \'de\' MMMM').format(DateTime.now());
    final catEntries = stats.porCategoria.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final top = stats.topProductos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre del día'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de cierres',
            onPressed: () => _mostrarHistorial(context),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Exportar resumen',
            onPressed: () => _exportar(context, stats, ventasHoy, fmt),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(hoy,
              style: const TextStyle(fontSize: 13, color: Colors.white38)),
          const SizedBox(height: 14),

          // Base del día
          _BaseDiaCard(baseDia: baseDia, fmt: fmt,
              onEditar: () => _mostrarFormBase(context, baseDia)),
          const SizedBox(height: 14),

          // Stats
          _StatsGrid(stats: stats, fmt: fmt, baseDia: baseDia),
          const SizedBox(height: 14),

          // Desglose por categoría
          _CierreCard(
            titulo: 'Desglose por categoría',
            child: catEntries.isEmpty
                ? const Text('Sin ventas hoy',
                    style: TextStyle(color: Colors.white38, fontSize: 13))
                : Column(
                    children: catEntries
                        .map((cat) => _RowDoble(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: _hexColor(cat.color),
                                        shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(cat.nombre,
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              valor: fmt.format(cat.total),
                              sub: '${cat.qty} unidades',
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 12),

          // Desglose por medio de pago
          if (stats.porMedioPago.isNotEmpty) ...[
            _CierreCard(
              titulo: 'Por medio de pago',
              child: Column(
                children: stats.porMedioPago.entries
                    .map((e) => _RowDoble(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.payment_outlined,
                                  size: 14, color: Colors.white38),
                              const SizedBox(width: 6),
                              Text(e.key,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          valor: fmt.format(e.value),
                          sub: '${((e.value / stats.totalVentas) * 100).toStringAsFixed(0)}%',
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Top productos
          _CierreCard(
            titulo: 'Productos más vendidos',
            child: top.isEmpty
                ? const Text('Sin ventas hoy',
                    style: TextStyle(color: Colors.white38, fontSize: 13))
                : Column(
                    children: top
                        .asMap()
                        .entries
                        .map((e) => _RowDoble(
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('#${e.key + 1}',
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                      child: Text(e.value.$1,
                                          style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                              valor: fmt.format(e.value.$3),
                              sub: '${e.value.$2} und.',
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 12),

          // Historial ventas del día
          _CierreCard(
            titulo: 'Historial del día (${ventasHoy.length})',
            child: ventasHoy.isEmpty
                ? const Text('Sin ventas registradas hoy',
                    style: TextStyle(color: Colors.white38, fontSize: 13))
                : Column(
                    children: ventasHoy
                        .map((v) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Text(
                                    v.creadoEn != null
                                        ? DateFormat('HH:mm').format(v.creadoEn!)
                                        : '',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 12),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      v.items
                                          .map((i) =>
                                              '${i.nombreProducto} ×${i.cantidad}')
                                          .join(', '),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white60),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(fmt.format(v.total),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 13)),
                                  GestureDetector(
                                    onTap: () =>
                                        _confirmarEliminarVenta(context, v),
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.delete_outline,
                                          size: 16, color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Nota
          const Text('Nota de cierre (opcional)',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _notaCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Observaciones del día...'),
          ),
          const SizedBox(height: 16),

          FilledButton(
            onPressed: _confirmando ? null : _hacerCierre,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _confirmando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Confirmar cierre del día',
                    style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Al confirmar, el reporte queda guardado en el historial.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white24),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _mostrarFormBase(BuildContext context, BaseDia? actual) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom),
        child: _BaseFormSheet(
          montoInicial: actual != null ? actual.monto.toStringAsFixed(0) : '',
          notaInicial: actual?.nota ?? '',
          esEdicion: actual != null,
          onGuardar: (monto, nota) async {
            await ref.read(baseDiaProvider.notifier).guardar(
                  monto: monto,
                  nota: nota,
                );
            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
          },
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarVenta(BuildContext context, Venta venta) async {
    final messenger = ScaffoldMessenger.of(context);
    final hora = venta.creadoEn != null
        ? DateFormat('HH:mm').format(venta.creadoEn!)
        : '';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text(
          'Eliminar la venta de las $hora (${venta.items.length} ítems). '
          'El stock será restaurado.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await ref.read(ventasHoyProvider.notifier).deleteVenta(venta.id);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Venta eliminada y stock restaurado')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  void _mostrarHistorial(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Consumer permite ref.watch dentro del sheet de forma correcta
      builder: (sheetContext) => Consumer(
        builder: (_, watchRef, __) {
          final cierres = watchRef.watch(cierresProvider).valueOrNull ?? [];
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (_, scrollCtrl) => Column(
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
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Historial de cierres',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                Expanded(
                  child: cierres.isEmpty
                      ? const Center(
                          child: Text('Sin cierres registrados',
                              style: TextStyle(color: Colors.white38)))
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: cierres.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: Color(0xFF2E2E2E)),
                          itemBuilder: (_, i) {
                            final c = cierres[i];
                            return _CierreHistorialTile(
                              cierre: c,
                              fmt: fmt,
                              onDelete: () =>
                                  _eliminarCierreConPassword(context, c),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _eliminarCierreConPassword(
      BuildContext context, CierreDia cierre) async {
    final messenger = ScaffoldMessenger.of(context);
    // El dialog es un StatefulWidget propio → el controller tiene su ciclo
    // de vida correcto y no se dispone prematuramente.
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _PasswordAdminDialog(),
    );

    if (password == null || !mounted || password.isEmpty) return;

    try {
      final email = Supabase.instance.client.auth.currentUser?.email ?? '';
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await ref.read(cierresProvider.notifier).deleteCierre(cierre.id);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Cierre eliminado')),
        );
      }
    } on AuthException {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Contraseña incorrecta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportar(BuildContext context, dynamic stats, List ventasHoy,
      NumberFormat fmt) {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    final buf = StringBuffer();
    buf.writeln('═══ REPORTE DE CIERRE — $hoy ═══');
    buf.writeln('Total ventas: ${fmt.format(stats.totalVentas)}');
    buf.writeln('Costo total:  ${fmt.format(stats.costoTotal)}');
    buf.writeln('Ganancia:     ${fmt.format(stats.ganancia)}');
    buf.writeln('Transacciones: ${stats.transacciones}');
    buf.writeln('Ítems vendidos: ${stats.itemsVendidos}');
    buf.writeln('\nDETALLE DE VENTAS:');
    for (final v in ventasHoy) {
      buf.writeln('${v.creadoEn != null ? DateFormat('HH:mm').format(v.creadoEn!) : ''} — ${fmt.format(v.total)}');
      for (final i in v.items) {
        buf.writeln('  · ${i.nombreProducto} ×${i.cantidad}');
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resumen de cierre'),
        content: SingleChildScrollView(
          child: SelectableText(buf.toString(),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final dynamic stats;
  final NumberFormat fmt;
  final dynamic baseDia; // BaseDia?
  const _StatsGrid({required this.stats, required this.fmt, this.baseDia});

  @override
  Widget build(BuildContext context) {
    final efectivoEsperado = (baseDia?.monto ?? 0.0) + stats.totalVentas;
    return Column(
      children: [
        Row(children: [
          _StatCard(label: 'Total ventas', valor: fmt.format(stats.totalVentas)),
          const SizedBox(width: 10),
          _StatCard(label: 'Transacciones', valor: '${stats.transacciones}'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatCard(label: 'Ítems vendidos', valor: '${stats.itemsVendidos}'),
          const SizedBox(width: 10),
          _StatCard(
              label: 'Ticket promedio',
              valor: fmt.format(stats.ticketPromedio)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatCard(
              label: 'Costo total',
              valor: fmt.format(stats.costoTotal),
              color: Colors.white54),
          const SizedBox(width: 10),
          _StatCard(
              label: 'Ganancia',
              valor: fmt.format(stats.ganancia),
              color: Colors.green.shade400),
        ]),
        if (baseDia != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            _StatCard(
                label: 'Efectivo esperado en caja',
                valor: fmt.format(efectivoEsperado),
                color: Colors.amber.shade300),
          ]),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String valor;
  final Color? color;
  const _StatCard({required this.label, required this.valor, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(valor,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color ?? Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white38)),
        ]),
      ),
    );
  }
}

class _CierreCard extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _CierreCard({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white60)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _RowDoble extends StatelessWidget {
  final Widget leading;
  final String valor;
  final String sub;
  const _RowDoble(
      {required this.leading, required this.valor, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: leading),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(valor,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(sub,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CierreHistorialTile extends StatelessWidget {
  final CierreDia cierre;
  final NumberFormat fmt;
  final VoidCallback? onDelete;
  const _CierreHistorialTile(
      {required this.cierre, required this.fmt, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fechaStr = DateFormat('EEE d MMM yyyy', 'es_CO').format(cierre.fecha);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fechaStr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${cierre.transacciones} ventas · ${cierre.itemsVendidos} ítems',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                if (cierre.nota != null && cierre.nota!.isNotEmpty)
                  Text(cierre.nota!,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11,
                          fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmt.format(cierre.totalVentas),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary)),
              Text('G: ${fmt.format(cierre.ganancia)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade400)),
            ],
          ),
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Base del día ──────────────────────────────────────────

class _BaseDiaCard extends StatelessWidget {
  final dynamic baseDia; // BaseDia?
  final NumberFormat fmt;
  final VoidCallback onEditar;
  const _BaseDiaCard(
      {required this.baseDia, required this.fmt, required this.onEditar});

  @override
  Widget build(BuildContext context) {
    if (baseDia == null) {
      return InkWell(
        onTap: onEditar,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.4),
                style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Registrar base inicial del día',
                    style: TextStyle(fontSize: 13)),
              ),
              Icon(Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary, size: 20),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: Colors.amber.shade300, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Base inicial del día',
                    style: TextStyle(fontSize: 11, color: Colors.white38)),
                Text(fmt.format(baseDia.monto),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                if (baseDia.nota != null && baseDia.nota!.isNotEmpty)
                  Text(baseDia.nota!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEditar,
            tooltip: 'Editar base',
          ),
        ],
      ),
    );
  }
}

class _BaseFormSheet extends StatefulWidget {
  final String montoInicial;
  final String notaInicial;
  final bool esEdicion;
  final Future<void> Function(double monto, String nota) onGuardar;

  const _BaseFormSheet({
    required this.montoInicial,
    required this.notaInicial,
    required this.esEdicion,
    required this.onGuardar,
  });

  @override
  State<_BaseFormSheet> createState() => _BaseFormSheetState();
}

class _BaseFormSheetState extends State<_BaseFormSheet> {
  late final TextEditingController _montoCtrl;
  late final TextEditingController _notaCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(text: widget.montoInicial);
    _notaCtrl = TextEditingController(text: widget.notaInicial);
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Text(
            widget.esEdicion ? 'Editar base del día' : 'Base inicial del día',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _montoCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Monto de apertura *',
              hintText: '0',
              prefixText: '\$ ',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _notaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'Ej: Incluye billetes sueltos',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: FilledButton(
            onPressed: _guardando
                ? null
                : () async {
                    setState(() => _guardando = true);
                    try {
                      final monto = double.tryParse(
                              _montoCtrl.text.replaceAll(',', '.')) ??
                          0;
                      await widget.onGuardar(monto, _notaCtrl.text.trim());
                    } finally {
                      if (mounted) setState(() => _guardando = false);
                    }
                  },
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}

/// Dialog independiente que gestiona su propio TextEditingController.
/// Retorna la contraseña ingresada, o null si se cancela.
class _PasswordAdminDialog extends StatefulWidget {
  const _PasswordAdminDialog();

  @override
  State<_PasswordAdminDialog> createState() => _PasswordAdminDialogState();
}

class _PasswordAdminDialogState extends State<_PasswordAdminDialog> {
  final _ctrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar cierre'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ingresa tu contraseña de administrador para confirmar.'),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => Navigator.pop(context, _ctrl.text),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar')),
        TextButton(
            onPressed: () => Navigator.pop(context, _ctrl.text),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red))),
      ],
    );
  }
}

Color _hexColor(String hex) {
  try {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return Colors.grey;
  }
}
