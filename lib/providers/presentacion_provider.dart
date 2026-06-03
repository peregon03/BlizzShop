import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/presentacion.dart';
import 'supabase_provider.dart';

final presentacionesProvider =
    AsyncNotifierProvider<PresentacionesNotifier, List<Presentacion>>(
  PresentacionesNotifier.new,
);

class PresentacionesNotifier extends AsyncNotifier<List<Presentacion>> {
  @override
  Future<List<Presentacion>> build() async {
    return ref.watch(presentacionRepositoryProvider).fetchAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(presentacionRepositoryProvider).fetchAll(),
    );
  }

  Future<void> insert(Presentacion p) async {
    await ref.read(presentacionRepositoryProvider).insert(p);
    await reload();
  }

  Future<void> update(Presentacion p) async {
    await ref.read(presentacionRepositoryProvider).update(p);
    await reload();
  }

  Future<void> delete(String id) async {
    await ref.read(presentacionRepositoryProvider).delete(id);
    state = AsyncData(
      state.value?.where((p) => p.id != id).toList() ?? [],
    );
  }
}
