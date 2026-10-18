import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> producto;

  const ProductDetailScreen({
    super.key,
    required this.producto,
  });

  // ICONO SEGÚN LA CATEGORÍA DEL PRODUCTO
  IconData _iconoCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'alimentos':
        return Icons.restaurant_rounded;
      case 'bebidas':
        return Icons.local_cafe_rounded;
      case 'limpieza':
        return Icons.cleaning_services_rounded;
      case 'tecnología':
      case 'tecnologia':
        return Icons.devices_rounded;
      case 'hogar':
        return Icons.chair_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cantidad =
        int.tryParse(producto['cantidad']?.toString() ?? '') ?? 0;

    final stockMinimo =
        int.tryParse(producto['stockMinimo']?.toString() ?? '') ?? 5;

    final precio =
        double.tryParse(producto['precio']?.toString() ?? '') ?? 0.0;

    final nombre = producto['nombre']?.toString() ?? 'Sin nombre';
    final codigo = producto['codigo']?.toString() ?? 'Sin código';
    final categoria = producto['categoria']?.toString() ?? 'Otros';

    final bajoStock = cantidad <= stockMinimo;

    return Scaffold(
      backgroundColor: InventoryScreen.fondo,

      // BARRA SUPERIOR
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Detalle del producto',
          style: TextStyle(
            color: Color(0xFF292333),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: InventoryScreen.moradoOscuro,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // CONTENIDO
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TARJETA PRINCIPAL DEL PRODUCTO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 26,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFECE7F2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: InventoryScreen.moradoOscuro.withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF1E8FF),
                          Color(0xFFE2D1FF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),

                    // MISMO ICONO SEGÚN LA CATEGORÍA
                    child: Icon(
                      _iconoCategoria(categoria),
                      size: 52,
                      color: InventoryScreen.moradoOscuro,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    nombre,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF292333),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F4FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Código: $codigo',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF625B6D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: InventoryScreen.moradoClaro,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: InventoryScreen.moradoOscuro,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          categoria,
                          style: const TextStyle(
                            color: InventoryScreen.moradoOscuro,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ESTADO DEL INVENTARIO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: bajoStock
                    ? const Color(0xFFFFF7E5)
                    : const Color(0xFFEAF7EF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: bajoStock
                      ? const Color(0xFFFFE1A3)
                      : const Color(0xFFCBEBD6),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      bajoStock
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 27,
                      color: bajoStock
                          ? const Color(0xFFB77900)
                          : const Color(0xFF16834B),
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bajoStock ? 'Stock bajo' : 'Disponible',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: bajoStock
                                ? const Color(0xFF9A6700)
                                : const Color(0xFF16834B),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          bajoStock
                              ? 'Revisa las existencias de este producto.'
                              : 'El producto tiene existencias suficientes.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF625B6D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // INFORMACIÓN DEL PRODUCTO
            const Text(
              'Información del producto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292333),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Consulta las características registradas.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF777080),
              ),
            ),

            const SizedBox(height: 17),

            // CANTIDAD Y STOCK MÍNIMO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.inventory_outlined,
                    titulo: 'Cantidad',
                    valor: '$cantidad unidades',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.warning_amber_outlined,
                    titulo: 'Stock mínimo',
                    valor: '$stockMinimo unidades',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CATEGORÍA
            _InfoCard(
              icon: Icons.category_outlined,
              titulo: 'Categoría',
              valor: categoria,
            ),

            const SizedBox(height: 12),

            // PRECIO
            _InfoCard(
              icon: Icons.attach_money_rounded,
              titulo: 'Precio por unidad',
              valor: '\$${precio.toStringAsFixed(2)}',
              destacado: true,
            ),

            const SizedBox(height: 28),

            // BOTÓN EDITAR
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final productoActualizado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductScreen(
                        producto: Map<String, dynamic>.from(producto),
                      ),
                    ),
                  );

                  if (!context.mounted) return;

                  if (productoActualizado is Map) {
                    Navigator.pop(
                      context,
                      Map<String, dynamic>.from(productoActualizado),
                    );
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'EDITAR PRODUCTO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: InventoryScreen.moradoOscuro,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // BOTÓN ELIMINAR
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 38,
                        ),
                        title: const Text(
                          'Eliminar producto',
                          textAlign: TextAlign.center,
                        ),
                        content: Text(
                          '¿Estás segura de que deseas eliminar '
                          '"$nombre" del inventario? Esta acción '
                          'no se puede deshacer.',
                          textAlign: TextAlign.center,
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, false);
                            },
                            child: const Text('CANCELAR'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, true);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('ELIMINAR'),
                          ),
                        ],
                      );
                    },
                  );

                  if (!context.mounted) return;

                  if (confirmar == true) {
                    Navigator.pop(context, 'eliminar');
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text(
                  'ELIMINAR PRODUCTO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Color(0xFFFFCDD2),
                    width: 1.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // VOLVER AL INVENTARIO
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'VOLVER AL INVENTARIO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: InventoryScreen.moradoOscuro,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TARJETA REUTILIZABLE DE INFORMACIÓN
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;
  final bool destacado;

  const _InfoCard({
    required this.icon,
    required this.titulo,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFECE7F2),
        ),
        boxShadow: [
          BoxShadow(
            color: InventoryScreen.moradoOscuro.withValues(
              alpha: 0.035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: InventoryScreen.moradoClaro,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: InventoryScreen.moradoOscuro,
              size: 21,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF777080),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  valor,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: destacado
                        ? InventoryScreen.moradoOscuro
                        : const Color(0xFF292333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
