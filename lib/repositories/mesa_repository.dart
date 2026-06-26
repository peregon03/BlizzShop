import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mesa.dart';

class MesaRepository {
  final SupabaseClient _client;
  MesaRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Mesa>> fetchAll() async {
    try {
      final data = await _client
          .from('mesas')
          .select()
          .eq('usuario_id', _userId)
          .eq('activo', true)
          .order('orden');
      return (data as List).map((e) => Mesa.fromJson(e)).toList();
    } on PostgrestException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Mesa> insertar(String nombre, {int orden = 0}) async {
    final data = await _client
        .from('mesas')
        .insert({
          'usuario_id': _userId,
          'nombre': nombre,
          'activo': true,
          'orden': orden,
        })
        .select()
        .single();
    return Mesa.fromJson(data);
  }

  Future<Mesa> actualizar(String id, String nombre) async {
    final data = await _client
        .from('mesas')
        .update({'nombre': nombre})
        .eq('id', id)
        .eq('usuario_id', _userId)
        .select()
        .single();
    return Mesa.fromJson(data);
  }

  Future<void> eliminar(String id) async {
    await _client
        .from('mesas')
        .delete()
        .eq('id', id)
        .eq('usuario_id', _userId);
  }

  Future<int> _nextOrden() async {
    final data = await _client
        .from('mesas')
        .select('orden')
        .eq('usuario_id', _userId)
        .order('orden', ascending: false)
        .limit(1);
    if ((data as List).isEmpty) return 0;
    return (data.first['orden'] as int) + 1;
  }

  Future<Mesa> insertarConOrden(String nombre) async {
    final orden = await _nextOrden();
    return insertar(nombre, orden: orden);
  }
}
