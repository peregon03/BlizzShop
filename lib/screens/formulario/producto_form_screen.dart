import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../models/producto.dart';
import '../../providers/producto_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../providers/presentacion_provider.dart';

class ProductoFormScreen extends ConsumerStatefulWidget {
  final Producto? producto;

  const ProductoFormScreen({super.key, this.producto});

  @override
  ConsumerState<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends ConsumerState<ProductoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();
  final _precioCostoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  int _stockActual = 0;
  int _stockMinimo = 5;
  String? _categoriaId;
  String? _presentacionId;
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    if (widget.producto != null) {
      final p = widget.producto!;
      _nombreCtrl.text = p.nombre;
      _precioVentaCtrl.text = p.precioVenta.toString();
      _precioCostoCtrl.text = p.precioCosto?.toString() ?? '';
      _descripcionCtrl.text = p.descripcion ?? '';
      _stockActual = p.stockActual;
      _stockMinimo = p.stockMinimo;
      _categoriaId = p.categoriaId;
      _presentacionId = p.presentacionId;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _precioVentaCtrl.dispose();
    _precioCostoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final producto = Producto(
        id: widget.producto?.id ?? const Uuid().v4(),
        nombre: _nombreCtrl.text.trim(),
        descripcion:
            _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        precioVenta: double.parse(
            _precioVentaCtrl.text.trim().replaceAll(',', '.')),
        precioCosto: _precioCostoCtrl.text.trim().isEmpty
            ? null
            : double.parse(_precioCostoCtrl.text.trim().replaceAll(',', '.')),
        stockActual: _stockActual,
        stockMinimo: _stockMinimo,
        categoriaId: _categoriaId,
        presentacionId: _presentacionId,
      );

      if (_esEdicion) {
        await ref.read(productosProvider.notifier).guardar(producto);
      } else {
        await ref.read(productosProvider.notifier).insert(producto);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esEdicion
                ? 'Producto actualizado correctamente'
                : 'Producto creado correctamente'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/inventario');
        }
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
    final categorias = ref.watch(categoriasProvider).valueOrNull ?? [];
    final presentaciones = ref.watch(presentacionesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre
            _label('Nombre *'),
            TextFormField(
              controller: _nombreCtrl,
              decoration:
                  const InputDecoration(hintText: 'Nombre del producto'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 16),

            // Categoría
            _label('Categoría'),
            DropdownButtonFormField<String>(
              initialValue: _categoriaId,
              hint: const Text('Sin categoría'),
              decoration: const InputDecoration(),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                ...categorias.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                ),
              ],
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            const SizedBox(height: 16),

            // Presentación
            _label('Presentación'),
            DropdownButtonFormField<String>(
              initialValue: _presentacionId,
              hint: const Text('Sin presentación'),
              decoration: const InputDecoration(),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Sin presentación')),
                ...presentaciones.map(
                  (p) =>
                      DropdownMenuItem(value: p.id, child: Text(p.descripcion)),
                ),
              ],
              onChanged: (v) => setState(() => _presentacionId = v),
            ),
            const SizedBox(height: 16),

            // Precios
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Precio venta *'),
                      TextFormField(
                        controller: _precioVentaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            prefixText: '\$ ', hintText: '0.00'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Obligatorio';
                          }
                          final parsed = double.tryParse(
                              v.trim().replaceAll(',', '.'));
                          if (parsed == null || parsed < 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Precio costo'),
                      TextFormField(
                        controller: _precioCostoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            prefixText: '\$ ', hintText: 'Opcional'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock actual
            _label('Stock actual'),
            _StockStepper(
              valor: _stockActual,
              min: 0,
              onChanged: (v) => setState(() => _stockActual = v),
            ),
            const SizedBox(height: 16),

            // Stock mínimo
            _label('Stock mínimo (alerta)'),
            _StockStepper(
              valor: _stockMinimo,
              min: 0,
              onChanged: (v) => setState(() => _stockMinimo = v),
            ),
            const SizedBox(height: 16),

            // Descripción
            _label('Descripción (opcional)'),
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Descripción o notas adicionales…'),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_esEdicion ? 'Actualizar producto' : 'Crear producto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          texto,
          style: const TextStyle(
              fontWeight: FontWeight.w500, color: Colors.white70, fontSize: 13),
        ),
      );
}

class _StockStepper extends StatelessWidget {
  final int valor;
  final int min;
  final void Function(int) onChanged;

  const _StockStepper({
    required this.valor,
    required this.min,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: valor > min ? () => onChanged(valor - 1) : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          )),
        ),
        Expanded(
          child: Text(
            '$valor',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton.outlined(
          onPressed: () => onChanged(valor + 1),
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          )),
        ),
      ],
    );
  }
}
