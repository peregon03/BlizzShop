import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/medio_pago.dart';
import '../../providers/medio_pago_provider.dart';

class MediosPagoScreen extends ConsumerWidget {
  const MediosPagoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediosAsync = ref.watch(mediosPagoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Medios de pago')),
      body: mediosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (medios) {
          if (medios.isEmpty) {
            return const Center(
              child: Text(
                'Sin métodos. Agrega uno con el botón +',
                style: TextStyle(color: Colors.white38),
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: medios.length,
            onReorderItem: (oldIndex, newIndex) {
              // Solo reordenar visualmente — orden real se gestiona en BD
            },
            itemBuilder: (context, i) {
              final medio = medios[i];
              return ListTile(
                key: ValueKey(medio.id),
                leading: const Icon(Icons.payment_outlined),
                title: Text(medio.nombre),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () =>
                          _mostrarFormulario(context, ref, medio),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      onPressed: medios.length <= 1
                          ? null // No eliminar el último método
                          : () => _confirmarEliminar(context, ref, medio),
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
      BuildContext context, WidgetRef ref, MedioPago? medio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MedioPagoForm(
        medio: medio,
        onGuardar: (nombre) async {
          if (medio == null) {
            await ref.read(mediosPagoProvider.notifier).agregar(nombre);
          } else {
            await ref
                .read(mediosPagoProvider.notifier)
                .actualizar(medio.id, nombre);
          }
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref, MedioPago medio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar método de pago'),
        content: Text(
            '¿Eliminar "${medio.nombre}"? Las ventas existentes no se verán afectadas.'),
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
      await ref.read(mediosPagoProvider.notifier).eliminar(medio.id);
    }
  }
}

// ── Formulario ────────────────────────────────────────────

class _MedioPagoForm extends StatefulWidget {
  final MedioPago? medio;
  final Future<void> Function(String nombre) onGuardar;

  const _MedioPagoForm({this.medio, required this.onGuardar});

  @override
  State<_MedioPagoForm> createState() => _MedioPagoFormState();
}

class _MedioPagoFormState extends State<_MedioPagoForm> {
  late final TextEditingController _nombreCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.medio?.nombre ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              widget.medio == null
                  ? 'Nuevo método de pago'
                  : 'Editar método de pago',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _nombreCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej: Nequi, Daviplata, Efectivo...',
              ),
              onSubmitted: (_) => _guardar(),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: FilledButton(
              onPressed: _guardando ? null : _guardar,
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
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(nombre);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
