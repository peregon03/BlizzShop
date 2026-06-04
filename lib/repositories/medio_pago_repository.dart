import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medio_pago.dart';

class MedioPagoRepository {
  final SupabaseClient _client;
  MedioPagoRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<MedioPago>> fetchAll() async {
    final data = await _client
        .from('medios_pago')
        .select()
        .eq('usuario_id', _userId)
        .order('orden');
    return (data as List).map((e) => MedioPago.fromJson(e)).toList();
  }

  Future<MedioPago> insertar(String nombre) async {
    final orden = await _nextOrden();
    final data = await _client
        .from('medios_pago')
        .insert({'usuario_id': _userId, 'nombre': nombre, 'orden': orden})
        .select()
        .single();
    return MedioPago.fromJson(data);
  }

  Future<MedioPago> actualizar(String id, String nombre) async {
    final data = await _client
        .from('medios_pago')
        .update({'nombre': nombre})
        .eq('id', id)
        .eq('usuario_id', _userId)
        .select()
        .single();
    return MedioPago.fromJson(data);
  }

  Future<void> eliminar(String id) async {
    await _client
        .from('medios_pago')
        .delete()
        .eq('id', id)
        .eq('usuario_id', _userId);
  }

  /// Inserta "Efectivo" y "Transferencia" como métodos por defecto.
  Future<void> insertarDefaults() async {
    final defaults = ['Efectivo', 'Transferencia'];
    for (var i = 0; i < defaults.length; i++) {
      await _client.from('medios_pago').insert({
        'usuario_id': _userId,
        'nombre': defaults[i],
        'orden': i,
      });
    }
  }

  Future<int> _nextOrden() async {
    final data = await _client
        .from('medios_pago')
        .select('orden')
        .eq('usuario_id', _userId)
        .order('orden', ascending: false)
        .limit(1);
    if ((data as List).isEmpty) return 0;
    return (data.first['orden'] as int) + 1;
  }
}
