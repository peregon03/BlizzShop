import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/producto.dart';
import '../../models/movimiento_inventario.dart';
import '../../providers/producto_provider.dart';

class MovimientoFormArgs {
  final Producto producto;
  final TipoMovimiento tipoInicial;

  const MovimientoFormArgs({
    required this.producto,
    this.tipoInicial = TipoMovimiento.entrada,
  });
}

class MovimientoFormScreen extends ConsumerStatefulWidget {
  final MovimientoFormArgs args;

  const MovimientoFormScreen({super.key, required this.args});

  @override
  ConsumerState<MovimientoFormScreen> createState() =>
      _MovimientoFormScreenState();
}

class _MovimientoFormScreenState extends ConsumerState<MovimientoFormScreen> {
  late TipoMovimiento _tipo;
  int _cantidad = 1;
  final _notaCtrl = TextEditingController();
  bool _guardando = false;

  Producto get _producto => widget.args.producto;

  int get _stockResultante {
    switch (_tipo) {
      case TipoMovimiento.entrada:
        return _producto.stockActual + _cantidad;
      case TipoMovimiento.salida:
        return (_producto.stockActual - _cantidad).clamp(0, 999999);
      case TipoMovimiento.ajuste:
        return _cantidad;
      case TipoMovimiento.venta:
        return (_producto.stockActual - _cantidad).clamp(0, 999999);
    }
  }

  bool get _valido {
    if (_cantidad <= 0) return false;
    if (_tipo == TipoMovimiento.salida && _cantidad > _producto.stockActual) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _tipo = widget.args.tipoInicial;
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_valido) return;
    setState(() => _guardando = true);

    try {
      await ref.read(productosProvider.notifier).registrarMovimiento(
            producto: _producto,
            tipo: _tipo,
            cantidad: _cantidad,
            nota: _notaCtrl.text.trim().isEmpty ? null : _notaCtrl.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movimiento registrado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              'Movimiento — ${_producto.nombre}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),

          // Selector de tipo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<TipoMovimiento>(
              segments: const [
                ButtonSegment(
                  value: TipoMovimiento.entrada,
                  label: Text('Entrada'),
                  icon: Icon(Icons.arrow_downward, size: 16),
                ),
                ButtonSegment(
                  value: TipoMovimiento.salida,
                  label: Text('Salida'),
                  icon: Icon(Icons.arrow_upward, size: 16),
                ),
                ButtonSegment(
                  value: TipoMovimiento.ajuste,
                  label: Text('Ajuste'),
                  icon: Icon(Icons.tune, size: 16),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
          ),
          const SizedBox(height: 20),

          // Cantidad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _tipo == TipoMovimiento.ajuste
                  ? 'Stock nuevo'
                  : 'Cantidad',
              style: const TextStyle(
                  color: Colors.white60, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton.outlined(
                  onPressed: _cantidad > 1 ? () => setState(() => _cantidad--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    '$_cantidad',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => setState(() => _cantidad++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Advertencia salida mayor que stock
          if (_tipo == TipoMovimiento.salida &&
              _cantidad > _producto.stockActual)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                'La salida supera el stock disponible (${_producto.stockActual})',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          const SizedBox(height: 12),

          // Preview stock resultante
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Stock actual:',
                    style: TextStyle(color: Colors.white54)),
                const SizedBox(width: 8),
                Text('${_producto.stockActual}',
                    style: const TextStyle(color: Colors.white54)),
                const Spacer(),
                const Text('Resultado:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text(
                  '$_stockResultante',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _stockResultante < _producto.stockMinimo
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nota
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _notaCtrl,
              decoration: const InputDecoration(
                hintText: 'Nota o motivo (opcional)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botón registrar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: FilledButton(
              onPressed: (_valido && !_guardando) ? _registrar : null,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Registrar movimiento',
                      style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
