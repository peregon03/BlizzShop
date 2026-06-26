import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/jornada.dart';

class JornadaRepository {
  final SupabaseClient _client;

  JornadaRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<Jornada?> fetchAbierta() async {
    final data = await _client
        .from('jornadas')
        .select()
        .eq('usuario_id', _userId)
        .eq('cerrada', false)
        .order('fecha_apertura', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? Jornada.fromJson(data) : null;
  }

  Future<Jornada> abrir() async {
    final data = await _client
        .from('jornadas')
        .insert({'usuario_id': _userId})
        .select()
        .single();
    return Jornada.fromJson(data);
  }

  Future<Jornada?> ensureAbierta() async {
    try {
      final abierta = await fetchAbierta();
      if (abierta != null) return abierta;
      return abrir();
    } on PostgrestException catch (e) {
      if (_schemaNoDisponible(e)) return null;
      rethrow;
    }
  }

  Future<void> cerrar(String id, {String? nota}) async {
    await _client
        .from('jornadas')
        .update({
          'cerrada': true,
          'fecha_cierre': DateTime.now().toUtc().toIso8601String(),
          if (nota != null && nota.isNotEmpty) 'nota_cierre': nota,
        })
        .eq('id', id)
        .eq('usuario_id', _userId);
  }

  bool _schemaNoDisponible(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return e.code == '42P01' ||
        e.code == '42703' ||
        msg.contains('jornadas') ||
        msg.contains('schema cache');
  }
}
