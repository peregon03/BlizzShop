import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cierre_dia.dart';

class CierreRepository {
  final SupabaseClient _client;

  CierreRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<CierreDia>> fetchAll() async {
    final data = await _client
        .from('cierres_dia')
        .select()
        .eq('usuario_id', _userId)
        .order('creado_en', ascending: false)
        .limit(90);
    return (data as List).map((e) => CierreDia.fromJson(e)).toList();
  }

  Future<void> insertar(CierreDia cierre) async {
    await _client.from('cierres_dia').insert({
      ...cierre.toInsertJson(),
      'usuario_id': _userId,
    });
  }

  Future<void> deleteCierre(String id) async {
    await _client.from('cierres_dia').delete().eq('id', id);
  }
}
