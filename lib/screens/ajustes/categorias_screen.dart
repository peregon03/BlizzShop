import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/categoria.dart';
import '../../providers/categoria_provider.dart';

class CategoriasScreen extends ConsumerWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      body: categoriasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categorias) => ListView.builder(
          itemCount: categorias.length,
          itemBuilder: (context, i) {
            final cat = categorias[i];
            return ListTile(
              leading: Icon(_iconoMaterial(cat.icono)),
              title: Text(cat.nombre),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _mostrarFormulario(context, ref, cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20,
                        color: Colors.red),
                    onPressed: () => _confirmarEliminar(context, ref, cat),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarFormulario(
      BuildContext context, WidgetRef ref, Categoria? categoria) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoriaForm(
        categoria: categoria,
        onGuardar: (cat) async {
          if (categoria == null) {
            await ref.read(categoriasProvider.notifier).insert(cat);
          } else {
            await ref.read(categoriasProvider.notifier).update(cat);
          }
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref, Categoria cat) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${cat.nombre}"? No se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar == true) {
      await ref.read(categoriasProvider.notifier).delete(cat.id);
    }
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

// MARK: - Formulario inline

class _CategoriaForm extends StatefulWidget {
  final Categoria? categoria;
  final Future<void> Function(Categoria) onGuardar;

  const _CategoriaForm({this.categoria, required this.onGuardar});

  @override
  State<_CategoriaForm> createState() => _CategoriaFormState();
}

class _CategoriaFormState extends State<_CategoriaForm> {
  final _nombreCtrl = TextEditingController();
  String _icono = 'label_outline';
  bool _guardando = false;

  static const _iconos = [
    ('wine_bar', Icons.wine_bar),
    ('local_bar', Icons.local_bar),
    ('liquor', Icons.liquor),
    ('restaurant', Icons.restaurant),
    ('shopping_cart', Icons.shopping_cart),
    ('coffee', Icons.coffee),
    ('local_cafe', Icons.local_cafe),
    ('fastfood', Icons.fastfood),
    ('storefront', Icons.storefront),
    ('category', Icons.category),
    ('label_outline', Icons.label_outline),
    ('star', Icons.star_outline),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoria != null) {
      _nombreCtrl.text = widget.categoria!.nombre;
      _icono = widget.categoria!.icono ?? 'label_outline';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _handle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              widget.categoria == null ? 'Nueva categoría' : 'Editar categoría',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre', hintText: 'Ej: Licores'),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconos
                  .map((entry) => _iconoBtn(entry.$1, entry.$2))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: FilledButton(
              onPressed: _guardando || _nombreCtrl.text.trim().isEmpty
                  ? null
                  : _guardar,
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
      ),
    );
  }

  Widget _iconoBtn(String nombre, IconData icono) {
    final sel = _icono == nombre;
    return GestureDetector(
      onTap: () => setState(() => _icono = nombre),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: sel
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icono, size: 22),
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    try {
      final cat = Categoria(
        id: widget.categoria?.id ?? const Uuid().v4(),
        nombre: _nombreCtrl.text.trim(),
        icono: _icono,
      );
      await widget.onGuardar(cat);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
