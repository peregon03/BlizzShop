import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/perfil_provider.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  // ── Campos de info ──────────────────────────────────────
  final _nombreCtrl = TextEditingController();
  final _nombreBarCtrl = TextEditingController();
  bool _guardandoInfo = false;
  bool _infoInicializada = false;

  // ── Campos de contraseña ────────────────────────────────
  final _passActualCtrl = TextEditingController();
  final _passNuevaCtrl = TextEditingController();
  final _passConfirmarCtrl = TextEditingController();
  bool _guardandoPass = false;
  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirmar = true;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nombreBarCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    _passConfirmarCtrl.dispose();
    super.dispose();
  }

  void _inicializarCampos(perfil) {
    if (_infoInicializada) return;
    _infoInicializada = true;
    _nombreCtrl.text = perfil?.nombre ?? '';
    _nombreBarCtrl.text = perfil?.nombreBar ?? '';
  }

  Future<void> _guardarInfo() async {
    final nombre = _nombreCtrl.text.trim();
    final nombreBar = _nombreBarCtrl.text.trim();
    if (nombreBar.isEmpty) {
      _showSnack('El nombre del negocio es obligatorio');
      return;
    }
    setState(() => _guardandoInfo = true);
    try {
      await ref.read(perfilProvider.notifier).actualizar(
            nombre: nombre,
            nombreBar: nombreBar,
          );
      if (mounted) _showSnack('Datos actualizados ✓', ok: true);
    } catch (e) {
      if (mounted) _showSnack('$e');
    } finally {
      if (mounted) setState(() => _guardandoInfo = false);
    }
  }

  Future<void> _cambiarPassword() async {
    final actual = _passActualCtrl.text;
    final nueva = _passNuevaCtrl.text;
    final confirmar = _passConfirmarCtrl.text;

    if (actual.isEmpty || nueva.isEmpty || confirmar.isEmpty) {
      _showSnack('Completa todos los campos de contraseña');
      return;
    }
    if (nueva.length < 6) {
      _showSnack('La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (nueva != confirmar) {
      _showSnack('Las contraseñas nuevas no coinciden');
      return;
    }

    setState(() => _guardandoPass = true);
    try {
      await ref.read(perfilRepositoryProvider).cambiarPassword(
            passwordActual: actual,
            passwordNuevo: nueva,
          );
      if (mounted) {
        _passActualCtrl.clear();
        _passNuevaCtrl.clear();
        _passConfirmarCtrl.clear();
        _showSnack('Contraseña actualizada ✓', ok: true);
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message);
    } catch (e) {
      if (mounted) _showSnack('$e');
    } finally {
      if (mounted) setState(() => _guardandoPass = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Cerrar sesión',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar != true) return;
    await ref.read(perfilRepositoryProvider).signOut();
    // El router redirige automáticamente al detectar sign-out
  }

  void _showSnack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? Colors.green : Colors.red.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    perfilAsync.whenData((p) => _inicializarCampos(p));

    final iniciales = _nombreCtrl.text.isNotEmpty
        ? _nombreCtrl.text[0].toUpperCase()
        : email.isNotEmpty
            ? email[0].toUpperCase()
            : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar ──────────────────────────────────────
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              child: Text(
                iniciales,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(email,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          const SizedBox(height: 24),

          // ── Información del negocio ──────────────────────
          _Card(
            titulo: 'Información',
            child: Column(
              children: [
                TextField(
                  controller: _nombreBarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del negocio *',
                    hintText: 'Ej: Bar El Farol',
                    prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tu nombre',
                    hintText: 'Nombre del administrador',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _guardandoInfo ? null : _guardarInfo,
                    child: _guardandoInfo
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Cambiar contraseña ───────────────────────────
          _Card(
            titulo: 'Cambiar contraseña',
            child: Column(
              children: [
                _PassField(
                  controller: _passActualCtrl,
                  label: 'Contraseña actual',
                  obscure: _obscureActual,
                  onToggle: () =>
                      setState(() => _obscureActual = !_obscureActual),
                ),
                const SizedBox(height: 12),
                _PassField(
                  controller: _passNuevaCtrl,
                  label: 'Nueva contraseña',
                  obscure: _obscureNueva,
                  onToggle: () =>
                      setState(() => _obscureNueva = !_obscureNueva),
                ),
                const SizedBox(height: 12),
                _PassField(
                  controller: _passConfirmarCtrl,
                  label: 'Confirmar nueva contraseña',
                  obscure: _obscureConfirmar,
                  onToggle: () =>
                      setState(() => _obscureConfirmar = !_obscureConfirmar),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _guardandoPass ? null : _cambiarPassword,
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white10),
                    child: _guardandoPass
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Cambiar contraseña'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Cerrar sesión ────────────────────────────────
          OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────

class _Card extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _Card({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white60)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  const _PassField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
