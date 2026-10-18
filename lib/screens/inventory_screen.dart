import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  static const Color moradoClaro = Color(0xFFF1E8FF);
  static const Color moradoOscuro = Color(0xFF6A1B9A);
  static const Color fondo = Color(0xFFF6F4FA);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  static const String _claveProductos = 'inventario_productos';

  String textoBusqueda = '';
  bool _cargandoProductos = true;

  final TextEditingController busquedaController =
      TextEditingController();

  final List<Map<String, dynamic>> productos = [
    {
      'nombre': 'Arroz',
      'codigo': 'ARZ001',
      'cantidad': 25,
      'categoria': 'Alimentos',
      'stockMinimo': 5,
    },
    {
      'nombre': 'Café',
      'codigo': 'CAF001',
      'cantidad': 8,
      'categoria': 'Bebidas',
      'stockMinimo': 5,
    },
    {
      'nombre': 'Pan',
      'codigo': 'PAN001',
      'cantidad': 3,
      'categoria': 'Alimentos',
      'stockMinimo': 5,
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  // CARGAR PRODUCTOS GUARDADOS
  Future<void> _cargarProductos() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      final datosGuardados =
          preferencias.getString(_claveProductos);

      if (datosGuardados != null) {
        final datosDecodificados = jsonDecode(datosGuardados);

        if (datosDecodificados is List) {
          final productosGuardados = datosDecodificados
              .whereType<Map>()
              .map(
                (producto) =>
                    Map<String, dynamic>.from(producto),
              )
              .toList();

          if (!mounted) return;

          setState(() {
            productos
              ..clear()
              ..addAll(productosGuardados);
          });
        } else {
          debugPrint(
            'Los datos guardados no tienen el formato esperado.',
          );
        }
      } else {
        // Primera ejecución: guardar los productos de ejemplo.
        await _guardarProductos();
      }
    } catch (error, stackTrace) {
      debugPrint('Error al cargar productos: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _cargandoProductos = false;
        });
      }
    }
  }

  // GUARDAR INVENTARIO EN EL DISPOSITIVO
  Future<void> _guardarProductos() async {
    try {
      final preferencias = await SharedPreferences.getInstance();

      final guardadoCorrecto = await preferencias.setString(
        _claveProductos,
        jsonEncode(productos),
      );

      if (!guardadoCorrecto) {
        debugPrint('No se pudo guardar el inventario.');
      }
    } catch (error, stackTrace) {
      debugPrint('Error al guardar productos: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    busquedaController.dispose();
    super.dispose();
  }

  // ICONOS SEGÚN LA CATEGORÍA
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

  // ABRIR DETALLE, EDITAR O ELIMINAR
  Future<void> abrirDetalle(
    Map<String, dynamic> producto,
  ) async {
    final indiceReal = productos.indexOf(producto);

    if (indiceReal == -1) return;

    final resultado = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          producto: producto,
        ),
      ),
    );

    if (!mounted || resultado == null) return;

    if (indiceReal >= productos.length) return;

    if (resultado == 'eliminar') {
      setState(() {
        productos.removeAt(indiceReal);
      });

      await _guardarProductos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto eliminado correctamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (resultado is Map) {
      setState(() {
        productos[indiceReal] =
            Map<String, dynamic>.from(resultado);
      });

      await _guardarProductos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto actualizado correctamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // AGREGAR PRODUCTO
  Future<void> agregarProducto() async {
    final nuevoProducto = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );

    if (!mounted || nuevoProducto == null) return;

    if (nuevoProducto is Map) {
      setState(() {
        productos.add(
          Map<String, dynamic>.from(nuevoProducto),
        );
      });

      await _guardarProductos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto guardado correctamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ETIQUETAS DE CATEGORÍA Y ESTADO
  Widget construirEtiqueta({
    required String texto,
    required Color colorFondo,
    required Color colorTexto,
    IconData? icono,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
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
            Icon(
              icono,
              size: 13,
              color: colorTexto,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              color: colorTexto,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA VISUAL DEL PRODUCTO
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

    final nombre =
        producto['nombre']?.toString() ?? 'Sin nombre';
    final codigo =
        producto['codigo']?.toString() ?? 'Sin código';
    final categoria =
        producto['categoria']?.toString() ?? 'Otros';

    final colorEstado = bajoStock
        ? const Color(0xFF9A6700)
        : const Color(0xFF16834B);

    final fondoEstado = bajoStock
        ? const Color(0xFFFFF3D6)
        : const Color(0xFFE1F5E8);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFEAE4F1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => abrirDetalle(producto),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ICONO SEGÚN LA CATEGORÍA
              Container(
                width: 56,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF1E8FF),
                      Color(0xFFE4D4FA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  iconoCategoria(categoria),
                  color: InventoryScreen.moradoOscuro,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              // INFORMACIÓN DEL PRODUCTO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292333),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 15,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            codigo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        construirEtiqueta(
                          texto: categoria,
                          colorFondo: const Color(0xFFF2EDF8),
                          colorTexto: const Color(0xFF655574),
                        ),
                        construirEtiqueta(
                          texto: bajoStock
                              ? 'Stock bajo'
                              : 'Disponible',
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

              const SizedBox(width: 8),

              // CANTIDAD DISPONIBLE
              Container(
                constraints: const BoxConstraints(
                  minWidth: 58,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bajoStock
                      ? const Color(0xFFFFF8E8)
                      : const Color(0xFFF7F2FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      '$cantidad',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: bajoStock
                            ? const Color(0xFFB77900)
                            : InventoryScreen.moradoOscuro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'unidades',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade500,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ],
          ),
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

      // BARRA SUPERIOR
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
            tooltip: 'Notificaciones',
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: InventoryScreen.moradoOscuro,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No tienes notificaciones nuevas.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      // CONTENIDO PRINCIPAL
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BUSCADOR
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
                    vertical: 17,
                    horizontal: 16,
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

              const SizedBox(height: 23),

              // ENCABEZADO Y CONTADOR
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

              const SizedBox(height: 18),

              // LISTA DE PRODUCTOS
              Expanded(
                child: _cargandoProductos
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: InventoryScreen.moradoOscuro,
                        ),
                      )
                    : productosFiltrados.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
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
                                      onPressed: _cargandoProductos
                                          ? null
                                          : agregarProducto,
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Agregar producto'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            InventoryScreen.moradoOscuro,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 90),
                            itemCount: productosFiltrados.length,
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

      // BOTÓN NUEVO PRODUCTO
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
