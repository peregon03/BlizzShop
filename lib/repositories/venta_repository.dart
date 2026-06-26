import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/venta.dart';

class VentaRepository {
  final SupabaseClient _client;

  VentaRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<Venta>> fetchHoy({String? jornadaId}) async {
    if (jornadaId != null) {
      try {
        final data = await _client
            .from('ventas')
            .select('*, venta_items(*)')
            .eq('usuario_id', _userId)
            .eq('jornada_id', jornadaId)
            .order('creado_en', ascending: false);

        return (data as List).map((e) => Venta.fromJson(e)).toList();
      } on PostgrestException catch (e) {
        if (!_schemaNoDisponible(e)) rethrow;
      }
    }

    final hoy = DateTime.now();
    // Convertir a UTC para que coincida con cómo Supabase guarda los timestamps
    final inicio =
        DateTime(hoy.year, hoy.month, hoy.day).toUtc().toIso8601String();
    final fin = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59)
        .toUtc()
        .toIso8601String();

    final data = await _client
        .from('ventas')
        .select('*, venta_items(*)')
        .eq('usuario_id', _userId)
        .gte('creado_en', inicio)
        .lte('creado_en', fin)
        .order('creado_en', ascending: false);

    return (data as List).map((e) => Venta.fromJson(e)).toList();
  }

  /// Inserta la venta y todos sus ítems en Supabase.
  Future<Venta> insertar({
    required double total,
    required double costoTotal,
    required List<Map<String, dynamic>> items,
    String? medioPagoId,
    String? medioPagoNombre,
    String? jornadaId,
  }) async {
    final payload = {
      'usuario_id': _userId,
      'total': total,
      'costo_total': costoTotal,
      if (medioPagoId != null) 'medio_pago_id': medioPagoId,
      if (medioPagoNombre != null) 'medio_pago_nombre': medioPagoNombre,
      if (jornadaId != null) 'jornada_id': jornadaId,
    };

    Map<String, dynamic> ventaData;
    try {
      ventaData =
          await _client.from('ventas').insert(payload).select().single();
    } on PostgrestException catch (e) {
      if (!_schemaNoDisponible(e)) rethrow;
      payload.remove('jornada_id');
      ventaData =
          await _client.from('ventas').insert(payload).select().single();
    }

    final ventaId = ventaData['id'] as String;

    final itemsPayload =
        items.map((item) => {...item, 'venta_id': ventaId}).toList();

    await _client.from('venta_items').insert(itemsPayload);

    final itemsData =
        await _client.from('venta_items').select().eq('venta_id', ventaId);

    return Venta.fromJson({
      ...ventaData,
      'venta_items': itemsData,
    });
  }

  /// Elimina la venta y sus ítems. Los ítems se borran primero para evitar
  /// problemas de timing con RLS + CASCADE.
  Future<void> delete(String id) async {
    await _client.from('venta_items').delete().eq('venta_id', id);
    await _client.from('ventas').delete().eq('id', id);
  }

  bool _schemaNoDisponible(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return e.code == '42703' || msg.contains('jornada_id');
  }
}
