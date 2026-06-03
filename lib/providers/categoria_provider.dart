import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/categoria.dart';
import 'supabase_provider.dart';

final categoriasProvider =
    AsyncNotifierProvider<CategoriasNotifier, List<Categoria>>(
  CategoriasNotifier.new,
);

class CategoriasNotifier extends AsyncNotifier<List<Categoria>> {
  @override
  Future<List<Categoria>> build() async {
    return ref.watch(categoriaRepositoryProvider).fetchAll();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(categoriaRepositoryProvider).fetchAll(),
    );
  }

  Future<void> insert(Categoria categoria) async {
    await ref.read(categoriaRepositoryProvider).insert(categoria);
    await reload();
  }

  Future<void> update(Categoria categoria) async {
    await ref.read(categoriaRepositoryProvider).update(categoria);
    await reload();
  }

  Future<void> delete(String id) async {
    await ref.read(categoriaRepositoryProvider).delete(id);
    state = AsyncData(
      state.value?.where((c) => c.id != id).toList() ?? [],
    );
  }
}
