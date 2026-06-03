import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/presentacion.dart';

class PresentacionRepository {
  final SupabaseClient _client;

  PresentacionRepository(this._client);

  Future<List<Presentacion>> fetchAll() async {
    final data = await _client
        .from('presentaciones')
        .select()
        .order('descripcion');
    return (data as List).map((e) => Presentacion.fromJson(e)).toList();
  }

  Future<void> insert(Presentacion p) async {
    await _client.from('presentaciones').insert(p.toJson());
  }

  Future<void> update(Presentacion p) async {
    await _client
        .from('presentaciones')
        .update(p.toJson())
        .eq('id', p.id);
  }

  Future<void> delete(String id) async {
    await _client.from('presentaciones').delete().eq('id', id);
  }
}
