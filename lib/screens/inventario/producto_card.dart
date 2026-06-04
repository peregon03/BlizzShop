import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/producto.dart';
import '../../core/theme.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onTap,
  });

  Color get _stockColor {
    switch (producto.estadoStock) {
      case EstadoStock.ok:
        return AppTheme.stockOk;
      case EstadoStock.minimo:
        return AppTheme.stockMinimo;
      case EstadoStock.bajo:
        return AppTheme.stockBajo;
      case EstadoStock.agotado:
        return AppTheme.stockAgotado;
    }
  }

  String get _precioFormateado {
    final fmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$');
    return fmt.format(producto.precioVenta);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Indicador de stock
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _stockColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // Nombre + categoría + presentación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (producto.presentacion != null) ...[
                          Text(
                            producto.presentacion!.descripcion,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (producto.categoria != null)
                          _categoriaChip(context, producto.categoria!.nombre),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Precio + stock badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _precioFormateado,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _stockBadge(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoriaChip(BuildContext context, String nombre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        nombre,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _stockBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _stockColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${producto.stockActual} uds.',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _stockColor,
        ),
      ),
    );
  }
}
