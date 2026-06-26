import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/producto_provider.dart';
import '../../providers/perfil_provider.dart';

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilProvider).valueOrNull;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final nombreMostrar = perfil?.nombre.isNotEmpty == true
        ? perfil!.nombre
        : email;
    final negocio = perfil?.nombreBar.isNotEmpty == true
        ? perfil!.nombreBar
        : 'Sin nombre';

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // Perfil
          const _SectionHeader('Cuenta'),
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              child: Text(
                nombreMostrar.isNotEmpty
                    ? nombreMostrar[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(negocio),
            subtitle: Text(email,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ajustes/perfil'),
          ),
          const Divider(),

          // Gestionar
          const _SectionHeader('Gestionar'),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Categorías'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ajustes/categorias'),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_outlined),
            title: const Text('Presentaciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ajustes/presentaciones'),
          ),
          ListTile(
            leading: const Icon(Icons.payment_outlined),
            title: const Text('Medios de pago'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ajustes/medios-pago'),
          ),
          ListTile(
            leading: const Icon(Icons.table_restaurant_outlined),
            title: const Text('Mesas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ajustes/mesas'),
          ),
          const Divider(),

          // Datos
          const _SectionHeader('Datos'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Exportar inventario (CSV)'),
            onTap: () => _exportarCSV(context, ref),
          ),
          const Divider(),

          // App info
          const _SectionHeader('App'),
          const ListTile(
            leading: Icon(Icons.info_outlined),
            title: Text('BlizzShop'),
            subtitle: Text('v1.0.0 · Gestión de inventario para licorería'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarCSV(BuildContext context, WidgetRef ref) async {
    final productos = ref.read(productosProvider).valueOrNull ?? [];
    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos para exportar.')),
      );
      return;
    }

    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$');
    final buffer = StringBuffer();
    buffer.writeln(
        '"Nombre","Categoría","Presentación","Precio Venta","Precio Costo","Stock Actual","Stock Mínimo","Estado"');

    for (final p in productos) {
      final estado = switch (p.estadoStock) {
        _ when p.stockActual <= 0 => 'Agotado',
        _ when p.stockActual < p.stockMinimo => 'Bajo',
        _ when p.stockActual == p.stockMinimo => 'Mínimo',
        _ => 'OK',
      };
      buffer.writeln([
        '"${p.nombre}"',
        '"${p.categoria?.nombre ?? ''}"',
        '"${p.presentacion?.descripcion ?? ''}"',
        '"${fmt.format(p.precioVenta)}"',
        '"${p.precioCosto != null ? fmt.format(p.precioCosto) : ''}"',
        '"${p.stockActual}"',
        '"${p.stockMinimo}"',
        '"$estado"',
      ].join(','));
    }

    await Share.share(
      buffer.toString(),
      subject: 'Inventario BlizzShop',
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String texto;

  const _SectionHeader(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
