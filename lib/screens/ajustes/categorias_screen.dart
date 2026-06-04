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
        data: (categorias) {
          if (categorias.isEmpty) {
            return const Center(
              child: Text('Sin categorías. Agrega una con el botón +',
                  style: TextStyle(color: Colors.white38)),
            );
          }
          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, i) {
              final cat = categorias[i];
              return ListTile(
                leading: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _hexColor(cat.color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text(cat.nombre),
                subtitle: cat.descripcion != null && cat.descripcion!.isNotEmpty
                    ? Text(cat.descripcion!,
                        style: const TextStyle(color: Colors.white38))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () =>
                          _mostrarFormulario(context, ref, cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      onPressed: () =>
                          _confirmarEliminar(context, ref, cat),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
            await ref.read(categoriasProvider.notifier).guardar(cat);
          }
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref, Categoria cat) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${cat.nombre}"? No se puede deshacer.'),
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
    if (confirmar == true) {
      await ref.read(categoriasProvider.notifier).delete(cat.id);
    }
  }
}

// ── Formulario de categoría ──────────────────────────────

class _CategoriaForm extends StatefulWidget {
  final Categoria? categoria;
  final Future<void> Function(Categoria) onGuardar;

  const _CategoriaForm({this.categoria, required this.onGuardar});

  @override
  State<_CategoriaForm> createState() => _CategoriaFormState();
}

class _CategoriaFormState extends State<_CategoriaForm> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _color = '#e8a838';
  bool _guardando = false;

  static const _colores = [
    '#e8a838', '#4a9eff', '#3dba6e', '#e85454',
    '#a070f0', '#f07050', '#50c0d0', '#c070a0',
    '#80b040', '#e070c0', '#ff8c42', '#6ec6ca',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoria != null) {
      _nombreCtrl.text = widget.categoria!.nombre;
      _descCtrl.text = widget.categoria!.descripcion ?? '';
      _color = widget.categoria!.color;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
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
              widget.categoria == null
                  ? 'Nueva categoría'
                  : 'Editar categoría',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nombre *', hintText: 'Ej: Cervezas'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Descripción', hintText: 'Opcional'),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Color',
                    style: TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colores.map((col) {
                    final sel = _color == col;
                    return GestureDetector(
                      onTap: () => setState(() => _color = col),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _hexColor(col),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                      color: _hexColor(col).withValues(alpha: 0.5),
                                      blurRadius: 8)
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: FilledButton(
              onPressed:
                  _guardando || _nombreCtrl.text.trim().isEmpty ? null : _guardar,
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

  Widget _handle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),
      );

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    try {
      final cat = Categoria(
        id: widget.categoria?.id ?? const Uuid().v4(),
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        color: _color,
      );
      await widget.onGuardar(cat);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

Color _hexColor(String hex) {
  try {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return Colors.grey;
  }
}
