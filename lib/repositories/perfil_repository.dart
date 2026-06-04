import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil.dart';

class PerfilRepository {
  final SupabaseClient _client;

  PerfilRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;
  String get _email => _client.auth.currentUser?.email ?? '';

  Future<Perfil?> fetchMio() async {
    final data = await _client
        .from('perfiles')
        .select()
        .eq('id', _userId)
        .maybeSingle();
    return data != null ? Perfil.fromJson(data) : null;
  }

  Future<void> actualizar({
    required String nombre,
    required String nombreBar,
  }) async {
    await _client.from('perfiles').upsert({
      'id': _userId,
      'nombre': nombre,
      'nombre_bar': nombreBar,
    });
  }

  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    // Verificar contraseña actual re-autenticando
    await _client.auth.signInWithPassword(
      email: _email,
      password: passwordActual,
    );
    // Cambiar a la nueva contraseña
    await _client.auth.updateUser(UserAttributes(password: passwordNuevo));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
