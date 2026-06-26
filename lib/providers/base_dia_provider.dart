import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/base_dia.dart';
import '../repositories/base_dia_repository.dart';
import 'supabase_provider.dart';
import 'jornada_provider.dart';

final baseDiaRepositoryProvider = Provider<BaseDiaRepository>((ref) {
  return BaseDiaRepository(ref.watch(supabaseClientProvider));
});

final baseDiaProvider = AsyncNotifierProvider<BaseDiaNotifier, BaseDia?>(
  BaseDiaNotifier.new,
);

class BaseDiaNotifier extends AsyncNotifier<BaseDia?> {
  @override
  Future<BaseDia?> build() async {
    ref.watch(authStateChangesProvider);
    if (Supabase.instance.client.auth.currentUser == null) return null;
    final jornada = await ref.watch(jornadaActivaProvider.future);
    return ref.watch(baseDiaRepositoryProvider).fetchHoy(
          jornadaId: jornada?.id,
        );
  }

  Future<void> guardar({required double monto, String? nota}) async {
    final jornada = await ref.read(jornadaActivaProvider.future);
    final resultado = await ref.read(baseDiaRepositoryProvider).guardar(
          monto: monto,
          nota: nota,
          jornadaId: jornada?.id,
          fecha: jornada?.fechaApertura.toLocal(),
        );
    state = AsyncData(resultado);
  }
}
