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
    final payload = {
      ...cierre.toInsertJson(),
      'usuario_id': _userId,
    };

    try {
      await _client.from('cierres_dia').insert(payload);
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (e.code != '42703' && !msg.contains('jornada_id')) rethrow;
      payload.remove('jornada_id');
      await _client.from('cierres_dia').insert(payload);
    }
  }

  Future<void> deleteCierre(String id) async {
    await _client.from('cierres_dia').delete().eq('id', id);
  }
}
