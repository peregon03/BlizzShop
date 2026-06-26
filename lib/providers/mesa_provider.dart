import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mesa.dart';
import '../repositories/mesa_repository.dart';
import 'supabase_provider.dart';

final mesaRepositoryProvider = Provider<MesaRepository>((ref) {
  return MesaRepository(ref.watch(supabaseClientProvider));
});

final mesasProvider = AsyncNotifierProvider<MesasNotifier, List<Mesa>>(
  MesasNotifier.new,
);

class MesasNotifier extends AsyncNotifier<List<Mesa>> {
  @override
  Future<List<Mesa>> build() async {
    ref.watch(authStateChangesProvider);
    if (Supabase.instance.client.auth.currentUser == null) return [];
    return ref.watch(mesaRepositoryProvider).fetchAll();
  }

  Future<void> agregar(String nombre) async {
    final nueva =
        await ref.read(mesaRepositoryProvider).insertarConOrden(nombre);
    state = AsyncData([...state.value ?? [], nueva]);
  }

  Future<void> actualizar(String id, String nombre) async {
    final actualizada =
        await ref.read(mesaRepositoryProvider).actualizar(id, nombre);
    state = AsyncData(
      state.value?.map((m) => m.id == id ? actualizada : m).toList() ?? [],
    );
  }

  Future<void> eliminar(String id) async {
    await ref.read(mesaRepositoryProvider).eliminar(id);
    state = AsyncData(
      state.value?.where((m) => m.id != id).toList() ?? [],
    );
  }
}
