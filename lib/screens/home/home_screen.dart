import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  final StatefulNavigationShell shell;

  const HomeScreen({super.key, required this.shell});

  static const _destinations = [
    (Icons.point_of_sale_outlined, Icons.point_of_sale, 'Ventas'),
    (Icons.folder_outlined, Icons.folder, 'Categorías'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Productos'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Cierre'),
  ];

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final esDesktop = ancho > 700;

    if (esDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: shell.goBranch,
              labelType: NavigationRailLabelType.all,
              backgroundColor: const Color(0xFF1E1E1E),
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.$1),
                        selectedIcon: Icon(d.$2),
                        label: Text(d.$3),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.$1),
                  selectedIcon: Icon(d.$2),
                  label: d.$3,
                ))
            .toList(),
      ),
    );
  }
}
