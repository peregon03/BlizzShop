import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';

class ProductoRepository {
  final SupabaseClient _client;

  ProductoRepository(this._client);

  Future<List<Producto>> fetchAll() async {
    final data = await _client
        .from('productos')
        .select('*, categoria:categorias(*), presentacion:presentaciones(*)')
        .eq('activo', true)
        .order('nombre');
    return (data as List).map((e) => Producto.fromJson(e)).toList();
  }

  Future<void> insert(Producto producto) async {
    await _client.from('productos').insert(producto.toInsertJson());
  }

  Future<void> update(Producto producto) async {
    await _client
        .from('productos')
        .update(producto.toInsertJson())
        .eq('id', producto.id);
  }

  /// Soft delete
  Future<void> delete(String id) async {
    await _client
        .from('productos')
        .update({'activo': false})
        .eq('id', id);
  }

  Future<void> updateStock(String productoId, int nuevoStock) async {
    await _client
        .from('productos')
        .update({'stock_actual': nuevoStock})
        .eq('id', productoId);
  }
}
