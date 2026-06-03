import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimiento_inventario.dart';

class MovimientoRepository {
  final SupabaseClient _client;

  MovimientoRepository(this._client);

  Future<List<MovimientoInventario>> fetchByProducto(
    String productoId, {
    int limit = 10,
  }) async {
    final data = await _client
        .from('movimientos_inventario')
        .select()
        .eq('producto_id', productoId)
        .order('creado_en', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => MovimientoInventario.fromJson(e))
        .toList();
  }

  Future<void> insert(MovimientoInventario movimiento) async {
    await _client.from('movimientos_inventario').insert(movimiento.toJson());
  }
}
