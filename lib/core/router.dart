import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/producto.dart';
import '../screens/home/home_screen.dart';
import '../screens/inventario/inventario_screen.dart';
import '../screens/inventario/producto_detalle_screen.dart';
import '../screens/formulario/producto_form_screen.dart';
import '../screens/formulario/movimiento_form_screen.dart';
import '../screens/ajustes/ajustes_screen.dart';
import '../screens/ajustes/categorias_screen.dart';
import '../screens/ajustes/presentaciones_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeScreen(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const InventarioScreen(),
              routes: [
                GoRoute(
                  path: 'detalle',
                  builder: (context, state) => ProductoDetalleScreen(
                    producto: state.extra as Producto,
                  ),
                ),
                GoRoute(
                  path: 'nuevo',
                  builder: (context, state) => const ProductoFormScreen(),
                ),
                GoRoute(
                  path: 'editar',
                  builder: (context, state) => ProductoFormScreen(
                    producto: state.extra as Producto,
                  ),
                ),
                GoRoute(
                  path: 'movimiento',
                  builder: (context, state) => MovimientoFormScreen(
                    args: state.extra as MovimientoFormArgs,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nuevo',
              builder: (context, state) => const ProductoFormScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ajustes',
              builder: (context, state) => const AjustesScreen(),
              routes: [
                GoRoute(
                  path: 'categorias',
                  builder: (context, state) => const CategoriasScreen(),
                ),
                GoRoute(
                  path: 'presentaciones',
                  builder: (context, state) => const PresentacionesScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
