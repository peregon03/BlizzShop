import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento_inventario.dart';

class MovimientoRepository {
  final SupabaseClient _client;

  MovimientoRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<MovimientoInventario>> fetchByProducto(
    String productoId, {
    int limit = 10,
  }) async {
    final data = await _client
        .from('movimientos_inventario')
        .select()
        .eq('usuario_id', _userId)
        .eq('producto_id', productoId)
        .order('creado_en', ascending: false)
        .limit(limit);
    return (data as List).map((e) => MovimientoInventario.fromJson(e)).toList();
  }

  Future<List<MovimientoInventario>> fetchRecientes({int limit = 50}) async {
    final data = await _client
        .from('movimientos_inventario')
        .select()
        .eq('usuario_id', _userId)
        .order('creado_en', ascending: false)
        .limit(limit);
    return (data as List).map((e) => MovimientoInventario.fromJson(e)).toList();
  }

  Future<void> insert(MovimientoInventario movimiento) async {
    await _client.from('movimientos_inventario').insert({
      ...movimiento.toJson(),
      'usuario_id': _userId,
    });
  }
}
