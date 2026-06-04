import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medio_pago.dart';
import '../repositories/medio_pago_repository.dart';
import 'supabase_provider.dart';

final medioPagoRepositoryProvider = Provider<MedioPagoRepository>((ref) {
  return MedioPagoRepository(ref.watch(supabaseClientProvider));
});

final mediosPagoProvider =
    AsyncNotifierProvider<MediosPagoNotifier, List<MedioPago>>(
  MediosPagoNotifier.new,
);

class MediosPagoNotifier extends AsyncNotifier<List<MedioPago>> {
  @override
  Future<List<MedioPago>> build() async {
    ref.watch(authStateChangesProvider);
    if (Supabase.instance.client.auth.currentUser == null) return [];
    final repo = ref.watch(medioPagoRepositoryProvider);
    final list = await repo.fetchAll();
    if (list.isEmpty) {
      await repo.insertarDefaults();
      return repo.fetchAll();
    }
    return list;
  }

  Future<void> agregar(String nombre) async {
    final nuevo =
        await ref.read(medioPagoRepositoryProvider).insertar(nombre);
    state = AsyncData([...state.value ?? [], nuevo]);
  }

  Future<void> actualizar(String id, String nombre) async {
    final actualizado =
        await ref.read(medioPagoRepositoryProvider).actualizar(id, nombre);
    state = AsyncData(
      state.value?.map((m) => m.id == id ? actualizado : m).toList() ?? [],
    );
  }

  Future<void> eliminar(String id) async {
    await ref.read(medioPagoRepositoryProvider).eliminar(id);
    state = AsyncData(
      state.value?.where((m) => m.id != id).toList() ?? [],
    );
  }
}
