import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mesa.dart';
import '../../providers/mesa_provider.dart';

class MesasScreen extends ConsumerWidget {
  const MesasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesasAsync = ref.watch(mesasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mesas')),
      body: mesasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (mesas) {
          if (mesas.isEmpty) {
            return const Center(
              child: Text(
                'Sin mesas configuradas.\nAgrega una con el botón +',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: mesas.length,
            itemBuilder: (context, i) {
              final mesa = mesas[i];
              return ListTile(
                leading: const Icon(Icons.table_restaurant_outlined),
                title: Text(mesa.nombre),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _mostrarFormulario(context, ref, mesa),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      onPressed: () => _confirmarEliminar(context, ref, mesa),
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

  void _mostrarFormulario(BuildContext context, WidgetRef ref, Mesa? mesa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MesaForm(
        mesa: mesa,
        onGuardar: (nombre) async {
          if (mesa == null) {
            await ref.read(mesasProvider.notifier).agregar(nombre);
          } else {
            await ref.read(mesasProvider.notifier).actualizar(mesa.id, nombre);
          }
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref, Mesa mesa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar mesa'),
        content: Text(
            '¿Eliminar "${mesa.nombre}"? Las ventas existentes no se verán afectadas.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar == true) {
      await ref.read(mesasProvider.notifier).eliminar(mesa.id);
    }
  }
}

// ── Formulario ────────────────────────────────────────────

class _MesaForm extends StatefulWidget {
  final Mesa? mesa;
  final Future<void> Function(String nombre) onGuardar;

  const _MesaForm({this.mesa, required this.onGuardar});

  @override
  State<_MesaForm> createState() => _MesaFormState();
}

class _MesaFormState extends State<_MesaForm> {
  late final TextEditingController _nombreCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.mesa?.nombre ?? '');
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
              widget.mesa == null ? 'Nueva mesa' : 'Editar mesa',
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
                hintText: 'Ej: Mesa 1, Barra, Terraza...',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
