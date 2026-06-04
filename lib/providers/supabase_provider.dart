import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/producto_repository.dart';
import '../repositories/categoria_repository.dart';
import '../repositories/presentacion_repository.dart';
import '../repositories/movimiento_repository.dart';
import '../repositories/venta_repository.dart';
import '../repositories/cierre_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Emite un evento cada vez que cambia el estado de autenticación.
/// Todos los providers de datos lo observan para reiniciarse al
/// cambiar de usuario (sign-in / sign-out).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
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

final ventaRepositoryProvider = Provider<VentaRepository>((ref) {
  return VentaRepository(ref.watch(supabaseClientProvider));
});

final cierreRepositoryProvider = Provider<CierreRepository>((ref) {
  return CierreRepository(ref.watch(supabaseClientProvider));
});
