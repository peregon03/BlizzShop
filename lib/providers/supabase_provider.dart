import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/producto_repository.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/presentacion_repository.dart';
import '../repositories/movimiento_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final productoRepositoryProvider = Provider<ProductoRepository>((ref) {
  return ProductoRepository(ref.watch(supabaseClientProvider));
});

final categoriaRepositoryProvider = Provider<CategoriaRepository>((ref) {
  return CategoriaRepository(ref.watch(supabaseClientProvider));
});

final presentacionRepositoryProvider = Provider<PresentacionRepository>((ref) {
  return PresentacionRepository(ref.watch(supabaseClientProvider));
});

final movimientoRepositoryProvider = Provider<MovimientoRepository>((ref) {
  return MovimientoRepository(ref.watch(supabaseClientProvider));
});
