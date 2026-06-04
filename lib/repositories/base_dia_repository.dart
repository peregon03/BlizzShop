import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/base_dia.dart';

class BaseDiaRepository {
  final SupabaseClient _client;

  BaseDiaRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  String get _hoy => DateTime.now().toIso8601String().split('T')[0];

  Future<BaseDia?> fetchHoy() async {
    final data = await _client
        .from('base_dia')
        .select()
        .eq('usuario_id', _userId)
        .eq('fecha', _hoy)
        .maybeSingle();
    return data != null ? BaseDia.fromJson(data) : null;
  }

  /// Crea o actualiza la base del día (upsert por usuario+fecha).
  Future<BaseDia> guardar({required double monto, String? nota}) async {
    final payload = {
      'usuario_id': _userId,
      'fecha': _hoy,
      'monto': monto,
      if (nota != null && nota.isNotEmpty) 'nota': nota,
    };

    final data = await _client
        .from('base_dia')
        .upsert(payload, onConflict: 'usuario_id,fecha')
        .select()
        .single();

    return BaseDia.fromJson(data);
  }
}
