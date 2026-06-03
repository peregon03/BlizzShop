import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/categoria.dart';

class CategoriaRepository {
  final SupabaseClient _client;

  CategoriaRepository(this._client);

  Future<List<Categoria>> fetchAll() async {
    final data = await _client
        .from('categorias')
        .select()
        .order('nombre');
    return (data as List).map((e) => Categoria.fromJson(e)).toList();
  }

  Future<void> insert(Categoria categoria) async {
    await _client.from('categorias').insert(categoria.toJson());
  }

  Future<void> update(Categoria categoria) async {
    await _client
        .from('categorias')
        .update(categoria.toJson())
        .eq('id', categoria.id);
  }

  Future<void> delete(String id) async {
    await _client.from('categorias').delete().eq('id', id);
  }
}
