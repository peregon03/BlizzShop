import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/base_dia.dart';

class BaseDiaRepository {
  final SupabaseClient _client;

  BaseDiaRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  String get _hoy => DateTime.now().toIso8601String().split('T')[0];

  Future<BaseDia?> fetchHoy({String? jornadaId}) async {
    if (jornadaId != null) {
      try {
        final data = await _client
            .from('base_dia')
            .select()
            .eq('usuario_id', _userId)
            .eq('jornada_id', jornadaId)
            .maybeSingle();
        return data != null ? BaseDia.fromJson(data) : null;
      } on PostgrestException catch (e) {
        if (!_schemaNoDisponible(e)) rethrow;
      }
    }

    final data = await _client
        .from('base_dia')
        .select()
        .eq('usuario_id', _userId)
        .eq('fecha', _hoy)
        .maybeSingle();
    return data != null ? BaseDia.fromJson(data) : null;
  }

  /// Crea o actualiza la base del día (upsert por usuario+fecha).
  Future<BaseDia> guardar({
    required double monto,
    String? nota,
    String? jornadaId,
    DateTime? fecha,
  }) async {
    final fechaKey = fecha != null
        ? '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}'
        : _hoy;
    final payload = {
      'usuario_id': _userId,
      'fecha': fechaKey,
      'monto': monto,
      if (nota != null && nota.isNotEmpty) 'nota': nota,
      if (jornadaId != null) 'jornada_id': jornadaId,
    };

    try {
      final data = await _client
          .from('base_dia')
          .upsert(
            payload,
            onConflict: jornadaId != null ? 'jornada_id' : 'usuario_id,fecha',
          )
          .select()
          .single();

      return BaseDia.fromJson(data);
    } on PostgrestException catch (e) {
      if (!_schemaNoDisponible(e)) rethrow;
      payload.remove('jornada_id');
    }

    final data = await _client
        .from('base_dia')
        .upsert(payload, onConflict: 'usuario_id,fecha')
        .select()
        .single();

    return BaseDia.fromJson(data);
  }

  bool _schemaNoDisponible(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return e.code == '42703' || msg.contains('jornada_id');
  }
}
