import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/base_dia.dart';
import '../repositories/base_dia_repository.dart';
import 'supabase_provider.dart';

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
    return ref.watch(baseDiaRepositoryProvider).fetchHoy();
  }

  Future<void> guardar({required double monto, String? nota}) async {
    final resultado = await ref.read(baseDiaRepositoryProvider).guardar(
          monto: monto,
          nota: nota,
        );
    state = AsyncData(resultado);
  }
}
