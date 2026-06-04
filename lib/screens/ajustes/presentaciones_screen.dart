import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/presentacion.dart';
import '../../providers/presentacion_provider.dart';

class PresentacionesScreen extends ConsumerWidget {
  const PresentacionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentacionesAsync = ref.watch(presentacionesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Presentaciones')),
      body: presentacionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (presentaciones) => ListView.builder(
          itemCount: presentaciones.length,
          itemBuilder: (context, i) {
            final p = presentaciones[i];
            return ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(p.descripcion),
              subtitle: p.volumenMl != null
                  ? Text('${p.volumenMl} ml',
                      style: const TextStyle(color: Colors.white38))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _mostrarFormulario(context, ref, p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    onPressed: () => _confirmarEliminar(context, ref, p),
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
      BuildContext context, WidgetRef ref, Presentacion? pres) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PresentacionForm(
        presentacion: pres,
        onGuardar: (p) async {
          if (pres == null) {
            await ref.read(presentacionesProvider.notifier).insert(p);
          } else {
            await ref.read(presentacionesProvider.notifier).guardar(p);
          }
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref, Presentacion p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar presentación'),
        content: Text('¿Eliminar "${p.descripcion}"?'),
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
      await ref.read(presentacionesProvider.notifier).delete(p.id);
    }
  }
}

class _PresentacionForm extends StatefulWidget {
  final Presentacion? presentacion;
  final Future<void> Function(Presentacion) onGuardar;

  const _PresentacionForm({this.presentacion, required this.onGuardar});

  @override
  State<_PresentacionForm> createState() => _PresentacionFormState();
}

class _PresentacionFormState extends State<_PresentacionForm> {
  final _descripcionCtrl = TextEditingController();
  final _volumenCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.presentacion != null) {
      _descripcionCtrl.text = widget.presentacion!.descripcion;
      if (widget.presentacion!.volumenMl != null) {
        _volumenCtrl.text = '${widget.presentacion!.volumenMl}';
      }
    }
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _volumenCtrl.dispose();
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              widget.presentacion == null
                  ? 'Nueva presentación'
                  : 'Editar presentación',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Botella 750ml, Sixpack…',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _volumenCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Volumen (ml)',
                hintText: 'Solo bebidas — opcional',
                suffixText: 'ml',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: FilledButton(
              onPressed:
                  _guardando || _descripcionCtrl.text.trim().isEmpty
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

  Future<void> _guardar() async {
    if (_descripcionCtrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    try {
      final p = Presentacion(
        id: widget.presentacion?.id ?? const Uuid().v4(),
        descripcion: _descripcionCtrl.text.trim(),
        volumenMl: int.tryParse(_volumenCtrl.text.trim()),
      );
      await widget.onGuardar(p);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
