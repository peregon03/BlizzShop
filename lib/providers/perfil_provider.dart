import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil.dart';
import '../repositories/perfil_repository.dart';
import 'supabase_provider.dart';

final perfilRepositoryProvider = Provider<PerfilRepository>((ref) {
  return PerfilRepository(ref.watch(supabaseClientProvider));
});

final perfilProvider = AsyncNotifierProvider<PerfilNotifier, Perfil?>(
  PerfilNotifier.new,
);

class PerfilNotifier extends AsyncNotifier<Perfil?> {
  @override
  Future<Perfil?> build() async {
    ref.watch(authStateChangesProvider);
    if (Supabase.instance.client.auth.currentUser == null) return null;
    return ref.watch(perfilRepositoryProvider).fetchMio();
  }

  Future<void> actualizar({
    required String nombre,
    required String nombreBar,
  }) async {
    await ref.read(perfilRepositoryProvider).actualizar(
          nombre: nombre,
          nombreBar: nombreBar,
        );
    state = AsyncData(
      state.value?.copyWith(nombre: nombre, nombreBar: nombreBar),
    );
  }
}
