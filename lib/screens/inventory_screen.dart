import 'dart:io';

import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import 'login_screen.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  static const Color moradoClaro = Color(0xFFF1E8FF);
  static const Color moradoOscuro = Color(0xFF6A1B9A);
  static const Color fondo = Color(0xFFF6F4FA);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String textoBusqueda = '';
  bool _cargandoProductos = true;
  bool _primeraRevisionNotificaciones = true;
  bool _revisandoNotificaciones = false;

  final TextEditingController busquedaController =
      TextEditingController();

  final List<Map<String, dynamic>> productos = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  // CONFIRMAR CIERRE DE SESIÓN
  Future<void> _confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás segura de que deseas cerrar tu sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: InventoryScreen.moradoOscuro,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // CARGAR PRODUCTOS DESDE SQLITE
  Future<void> _cargarProductos() async {
    try {
      final productosGuardados =
          await DatabaseHelper.instance.obtenerProductos();

      if (!mounted) return;

      setState(() {
        productos
          ..clear()
          ..addAll(productosGuardados);
      });

      // Revisar el inventario automáticamente al entrar.
      if (_primeraRevisionNotificaciones) {
        _primeraRevisionNotificaciones = false;
        await _revisarInventario(silencioso: true);
      }
    } catch (error, stackTrace) {
      debugPrint('Error al cargar productos desde SQLite: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _cargandoProductos = false;
        });
      }
    }
  }

  // REVISAR PRODUCTOS CON EXISTENCIAS BAJAS
  Future<void> _revisarInventario({
    bool silencioso = false,
  }) async {
    if (_revisandoNotificaciones) return;

    _revisandoNotificaciones = true;

    try {
      final productosBajoStock = productos.where((producto) {
        final cantidad = int.tryParse(
              producto['cantidad']?.toString() ?? '',
            ) ??
            0;

        final stockMinimo = int.tryParse(
              producto['stockMinimo']?.toString() ?? '',
            ) ??
            5;

        return cantidad <= stockMinimo;
      }).toList();

      if (productosBajoStock.isEmpty) {
        if (!silencioso && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '¡Excelente! No tienes productos con stock bajo.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await NotificationService.instance.revisarInventario(
        productos,
      );

      if (!silencioso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se encontraron ${productosBajoStock.length} '
              '${productosBajoStock.length == 1 ? 'producto con stock bajo' : 'productos con stock bajo'}. '
              'Revisa las notificaciones del dispositivo.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Error al revisar las notificaciones: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!silencioso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudieron generar las notificaciones.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _revisandoNotificaciones = false;
    }
  }

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
  }

  IconData iconoCategoria(String categoria) {
    switch (categoria.trim().toLowerCase()) {
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
        return Icons.chair_alt_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Future<void> abrirDetalle(
    Map<String, dynamic> producto,
  ) async {
    final resultado = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          producto: producto,
        ),
      ),
    );

    if (!mounted || resultado == null) return;

    try {
      if (resultado == 'eliminar') {
        final id = producto['id'] as int;
        await DatabaseHelper.instance.eliminarProducto(id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto eliminado correctamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (resultado is Map) {
        final productoActualizado =
            Map<String, dynamic>.from(resultado);

        productoActualizado['id'] = producto['id'];

        await DatabaseHelper.instance.actualizarProducto(
          productoActualizado,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto actualizado correctamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await _cargarProductos();
    } catch (error, stackTrace) {
      debugPrint('Error al actualizar el inventario: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el producto.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> agregarProducto() async {
    final nuevoProducto = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );

    if (!mounted || nuevoProducto == null) return;

    if (nuevoProducto is Map) {
      try {
        final producto = Map<String, dynamic>.from(nuevoProducto);

        producto.remove('id');

        await DatabaseHelper.instance.insertarProducto(producto);
        await _cargarProductos();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto guardado correctamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (error, stackTrace) {
        debugPrint('Error al guardar el producto en SQLite: $error');
        debugPrintStack(stackTrace: stackTrace);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar. Verifica que el código no exista.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget construirEtiqueta({
    required String texto,
    required Color colorFondo,
    required Color colorTexto,
    IconData? icono,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 13, color: colorTexto),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: colorTexto,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget construirTarjetaProducto(
    Map<String, dynamic> producto,
  ) {
    final cantidad = int.tryParse(
          producto['cantidad']?.toString() ?? '',
        ) ??
        0;

    final stockMinimo = int.tryParse(
          producto['stockMinimo']?.toString() ?? '',
        ) ??
        5;

    final bajoStock = cantidad <= stockMinimo;

    final nombre = producto['nombre']?.toString() ?? 'Sin nombre';
    final codigo = producto['codigo']?.toString() ?? 'Sin código';
    final categoria = producto['categoria']?.toString() ?? 'Otros';

    final colorEstado = bajoStock
        ? const Color(0xFF9A6700)
        : const Color(0xFF16834B);

    final fondoEstado = bajoStock
        ? const Color(0xFFFFF3D6)
        : const Color(0xFFE1F5E8);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFEAE4F1),
        ),
      ),
      child: InkWell(
        onTap: () => abrirDetalle(producto),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compacto = constraints.maxWidth < 310;
              final anchoIcono = compacto ? 44.0 : 52.0;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: anchoIcono,
                    height: anchoIcono + 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF1E8FF),
                          Color(0xFFE4D4FA),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _ImagenProductoInventario(
                      rutaImagen: producto['imagen']?.toString(),
                      icono: iconoCategoria(categoria),
                      tamanoIcono: compacto ? 23 : 27,
                    ),
                  ),
                  SizedBox(width: compacto ? 8 : 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF292333),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.qr_code_2_rounded,
                              size: 14,
                              color: Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                codigo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            construirEtiqueta(
                              texto: categoria,
                              colorFondo: const Color(0xFFF2EDF8),
                              colorTexto: const Color(0xFF655574),
                            ),
                            construirEtiqueta(
                              texto: bajoStock ? 'Stock bajo' : 'Disponible',
                              colorFondo: fondoEstado,
                              colorTexto: colorEstado,
                              icono: bajoStock
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compacto ? 5 : 8),
                  Container(
                    constraints: BoxConstraints(
                      minWidth: compacto ? 48 : 56,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: compacto ? 4 : 6,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: bajoStock
                          ? const Color(0xFFFFF8E8)
                          : const Color(0xFFF7F2FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$cantidad',
                            style: TextStyle(
                              fontSize: compacto ? 18 : 21,
                              fontWeight: FontWeight.bold,
                              color: bajoStock
                                  ? const Color(0xFFB77900)
                                  : InventoryScreen.moradoOscuro,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'unid.',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.black54,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget construirListaVacia() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: InventoryScreen.moradoClaro,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: InventoryScreen.moradoOscuro,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No se encontraron productos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              textoBusqueda.trim().isEmpty
                  ? 'Agrega tu primer producto al inventario.'
                  : 'Prueba con otro nombre o código.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            if (textoBusqueda.trim().isEmpty) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _cargandoProductos ? null : agregarProducto,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar producto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: InventoryScreen.moradoOscuro,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busqueda = textoBusqueda.trim().toLowerCase();

    final productosFiltrados = productos.where((producto) {
      final nombre =
          producto['nombre']?.toString().toLowerCase() ?? '';
      final codigo =
          producto['codigo']?.toString().toLowerCase() ?? '';

      return nombre.contains(busqueda) ||
          codigo.contains(busqueda);
    }).toList();

    return Scaffold(
      backgroundColor: InventoryScreen.fondo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(
              Icons.inventory_2_rounded,
              color: InventoryScreen.moradoOscuro,
              size: 26,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'INVENTARIOAPP',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: InventoryScreen.moradoOscuro,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Revisar notificaciones',
            icon: _revisandoNotificaciones
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: InventoryScreen.moradoOscuro,
                    ),
                  )
                : const Icon(
                    Icons.notifications_none_rounded,
                    color: InventoryScreen.moradoOscuro,
                  ),
            onPressed: _revisandoNotificaciones
                ? null
                : () => _revisarInventario(),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones de cuenta',
            icon: const Icon(
              Icons.account_circle_outlined,
              color: InventoryScreen.moradoOscuro,
              size: 27,
            ),
            onSelected: (opcion) {
              if (opcion == 'cerrar_sesion') {
                _confirmarCerrarSesion();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'cerrar_sesion',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                    SizedBox(width: 10),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, screenConstraints) {
            final ancho = screenConstraints.maxWidth;

            final margenHorizontal = ancho < 360
                ? 10.0
                : ancho < 600
                    ? 16.0
                    : 24.0;

            final margenSuperior = ancho < 600 ? 14.0 : 24.0;

            final columnas = ancho >= 1100
                ? 3
                : ancho >= 720
                    ? 2
                    : 1;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    margenHorizontal,
                    margenSuperior,
                    margenHorizontal,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: busquedaController,
                        onChanged: (texto) {
                          setState(() {
                            textoBusqueda = texto;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o código',
                          hintStyle: const TextStyle(
                            color: Colors.black45,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: InventoryScreen.moradoOscuro,
                          ),
                          suffixIcon: textoBusqueda.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    busquedaController.clear();
                                    setState(() {
                                      textoBusqueda = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: Color(0xFFEAE5F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(
                              color: InventoryScreen.moradoOscuro,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: ancho < 600 ? 20 : 28),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Mis productos',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF292333),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: InventoryScreen.moradoClaro,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${productosFiltrados.length} '
                              '${productosFiltrados.length == 1 ? 'producto' : 'productos'}',
                              style: const TextStyle(
                                color: InventoryScreen.moradoOscuro,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Consulta y administra tus existencias',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _cargandoProductos
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: InventoryScreen.moradoOscuro,
                                ),
                              )
                            : productosFiltrados.isEmpty
                                ? construirListaVacia()
                                : columnas == 1
                                    ? ListView.builder(
                                        padding: const EdgeInsets.only(
                                          bottom: 90,
                                        ),
                                        itemCount:
                                            productosFiltrados.length,
                                        itemBuilder: (context, index) {
                                          return construirTarjetaProducto(
                                            productosFiltrados[index],
                                          );
                                        },
                                      )
                                    : GridView.builder(
                                        padding: const EdgeInsets.only(
                                          bottom: 90,
                                          top: 2,
                                        ),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: columnas,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 2,
                                          mainAxisExtent: 126,
                                        ),
                                        itemCount:
                                            productosFiltrados.length,
                                        itemBuilder: (context, index) {
                                          return construirTarjetaProducto(
                                            productosFiltrados[index],
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: InventoryScreen.moradoOscuro,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: _cargandoProductos ? null : agregarProducto,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuevo producto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// IMAGEN DEL PRODUCTO EN LA TARJETA DEL INVENTARIO
class _ImagenProductoInventario extends StatelessWidget {
  final String? rutaImagen;
  final IconData icono;
  final double tamanoIcono;

  const _ImagenProductoInventario({
    required this.rutaImagen,
    required this.icono,
    required this.tamanoIcono,
  });

  Widget _construirIcono() {
    return Icon(
      icono,
      color: InventoryScreen.moradoOscuro,
      size: tamanoIcono,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ruta = rutaImagen?.trim() ?? '';
    final tieneImagen =
        ruta.isNotEmpty && File(ruta).existsSync();

    if (!tieneImagen) {
      return _construirIcono();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(
        File(ruta),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _construirIcono();
        },
      ),
    );
  }
}
