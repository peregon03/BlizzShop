import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/ventas/ventas_screen.dart';
import '../screens/inventario/inventario_screen.dart';
import '../screens/inventario/producto_detalle_screen.dart';
import '../screens/formulario/producto_form_screen.dart';
import '../screens/formulario/movimiento_form_screen.dart';
import '../screens/ajustes/ajustes_screen.dart';
import '../screens/ajustes/categorias_screen.dart';
import '../screens/ajustes/presentaciones_screen.dart';
import '../screens/ajustes/perfil_screen.dart';
import '../screens/ajustes/medios_pago_screen.dart';
import '../screens/ajustes/mesas_screen.dart';
import '../screens/cierre/cierre_screen.dart';

// ── ChangeNotifier que reacciona a cambios de auth ───────
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ── Router lazy (se crea después de Supabase.initialize()) ──
GoRouter? _routerInstance;

GoRouter get router {
  _routerInstance ??= GoRouter(
    initialLocation: '/auth/splash',
    refreshListenable: _AuthNotifier(),
    redirect: (context, state) {
      final isLoggedIn =
          Supabase.instance.client.auth.currentSession != null;
      final isAuthPath =
          state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthPath) return '/auth/splash';
      if (isLoggedIn && isAuthPath) return '/ventas';
      return null;
    },
    routes: [
      // ── Auth (fuera del shell) ──────────────────────────
      GoRoute(
        path: '/auth/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/registro',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Ajustes (fuera del shell, accesible desde topbar) ─
      GoRoute(
        path: '/ajustes',
        builder: (_, __) => const AjustesScreen(),
        routes: [
          GoRoute(
            path: 'perfil',
            builder: (_, __) => const PerfilScreen(),
          ),
          GoRoute(
            path: 'categorias',
            builder: (_, __) => const CategoriasScreen(),
          ),
          GoRoute(
            path: 'presentaciones',
            builder: (_, __) => const PresentacionesScreen(),
          ),
          GoRoute(
            path: 'medios-pago',
            builder: (_, __) => const MediosPagoScreen(),
          ),
          GoRoute(
            path: 'mesas',
            builder: (_, __) => const MesasScreen(),
          ),
        ],
      ),

      // ── Shell principal ─────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeScreen(shell: shell),
        branches: [
          // Branch 0: Ventas (home)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ventas',
                builder: (_, __) => const VentasScreen(),
              ),
            ],
          ),

          // Branch 1: Categorías
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categorias',
                builder: (_, __) => const CategoriasScreen(),
              ),
            ],
          ),

          // Branch 2: Productos / Inventario
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventario',
                builder: (_, __) => const InventarioScreen(),
                routes: [
                  GoRoute(
                    path: 'detalle',
                    builder: (_, state) => ProductoDetalleScreen(
                      producto: state.extra as Producto,
                    ),
                  ),
                  GoRoute(
                    path: 'nuevo',
                    builder: (_, __) => const ProductoFormScreen(),
                  ),
                  GoRoute(
                    path: 'editar',
                    builder: (_, state) => ProductoFormScreen(
                      producto: state.extra as Producto,
                    ),
                  ),
                  GoRoute(
                    path: 'movimiento',
                    builder: (_, state) => MovimientoFormScreen(
                      args: state.extra as MovimientoFormArgs,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Cierre del día
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cierre',
                builder: (_, __) => const CierreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return _routerInstance!;
}
