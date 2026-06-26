import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/jornada.dart';
import '../repositories/jornada_repository.dart';
import 'supabase_provider.dart';

final jornadaRepositoryProvider = Provider<JornadaRepository>((ref) {
  return JornadaRepository(ref.watch(supabaseClientProvider));
});

final jornadaActivaProvider =
    AsyncNotifierProvider<JornadaActivaNotifier, Jornada?>(
  JornadaActivaNotifier.new,
);

class JornadaActivaNotifier extends AsyncNotifier<Jornada?> {
  @override
  Future<Jornada?> build() async {
    ref.watch(authStateChangesProvider);
    if (Supabase.instance.client.auth.currentUser == null) return null;
    return ref.watch(jornadaRepositoryProvider).ensureAbierta();
  }

  Future<void> cerrar({String? nota}) async {
    final jornada = state.valueOrNull;
    if (jornada == null) return;
    await ref.read(jornadaRepositoryProvider).cerrar(jornada.id, nota: nota);
    state = const AsyncData(null);
  }
}
