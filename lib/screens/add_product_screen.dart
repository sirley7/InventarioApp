import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:mi_inventario/screens/inventory_screen.dart';
import 'package:mi_inventario/database/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final codigoController = TextEditingController();
  final cantidadController = TextEditingController();
  final precioController = TextEditingController();
  final stockMinimoController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String? categoriaSeleccionada;
  String? imagenSeleccionada;
  bool _guardando = false;
  bool _seleccionandoImagen = false;

  final List<String> categorias = [
    'Alimentos',
    'Bebidas',
    'Limpieza',
    'Tecnología',
    'Hogar',
    'Otros',
  ];

  @override
  void dispose() {
    nombreController.dispose();
    codigoController.dispose();
    cantidadController.dispose();
    precioController.dispose();
    stockMinimoController.dispose();
    super.dispose();
  }

  // ESTILO UNIFORME PARA LOS CAMPOS
  InputDecoration decoracionCampo({
    required String etiqueta,
    required IconData icono,
    String? ayuda,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      helperMaxLines: 2,
      labelStyle: const TextStyle(
        color: Color(0xFF777080),
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: InventoryScreen.moradoOscuro,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icono,
        color: InventoryScreen.moradoOscuro,
        size: 22,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 19,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE8E1EF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFE8E1EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: InventoryScreen.moradoOscuro,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // VALIDAR TEXTO
  String? validarTexto(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa $campo.';
    }

    return null;
  }

  // VALIDAR NÚMEROS ENTEROS
  String? validarEntero(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa $campo.';
    }

    final numero = int.tryParse(valor.trim());

    if (numero == null) {
      return 'Ingresa un número entero válido.';
    }

    if (numero < 0) {
      return 'El valor no puede ser negativo.';
    }

    return null;
  }

  // VALIDAR PRECIO
  String? validarPrecio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa el precio.';
    }

    final numero = double.tryParse(
      valor.trim().replaceAll(',', '.'),
    );

    if (numero == null || !numero.isFinite || numero < 0) {
      return 'Ingresa un precio válido.';
    }

    return null;
  }

  // TÍTULOS DE LAS SECCIONES
  Widget construirTituloSeccion({
    required String titulo,
    required String descripcion,
    required IconData icono,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: InventoryScreen.moradoClaro,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icono,
            color: InventoryScreen.moradoOscuro,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF292333),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777080),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // COPIAR LA IMAGEN A UNA CARPETA PERMANENTE DE LA APLICACIÓN
  Future<String> guardarImagenPermanentemente(XFile imagen) async {
    final directorio = await getApplicationDocumentsDirectory();

    final extension = p.extension(imagen.path).isNotEmpty
        ? p.extension(imagen.path)
        : '.jpg';

    final nombreArchivo =
        'producto_${DateTime.now().microsecondsSinceEpoch}$extension';

    final rutaDestino = p.join(
      directorio.path,
      nombreArchivo,
    );

    final archivoPermanente = await File(imagen.path).copy(
      rutaDestino,
    );

    return archivoPermanente.path;
  }

  // MOSTRAR OPCIONES PARA SELECCIONAR UNA FOTOGRAFÍA
  Future<void> mostrarOpcionesImagen() async {
    if (_seleccionandoImagen || _guardando) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seleccionar fotografía',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF292333),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: InventoryScreen.moradoOscuro,
                  ),
                  title: const Text('Tomar fotografía'),
                  onTap: () {
                    Navigator.pop(context);
                    seleccionarImagen(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: InventoryScreen.moradoOscuro,
                  ),
                  title: const Text('Elegir de la galería'),
                  onTap: () {
                    Navigator.pop(context);
                    seleccionarImagen(ImageSource.gallery);
                  },
                ),
                if (imagenSeleccionada != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Quitar fotografía',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        imagenSeleccionada = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // SELECCIONAR IMAGEN Y GUARDARLA PERMANENTEMENTE
  Future<void> seleccionarImagen(ImageSource origen) async {
    if (_seleccionandoImagen || _guardando) return;

    setState(() {
      _seleccionandoImagen = true;
    });

    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: origen,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (!mounted) return;

      if (imagen != null) {
        // Copiar la fotografía desde la ubicación temporal
        // hasta el almacenamiento privado de InventarioApp.
        final rutaPermanente =
            await guardarImagenPermanentemente(imagen);

        if (!mounted) return;

        setState(() {
          imagenSeleccionada = rutaPermanente;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fotografía guardada correctamente en el dispositivo.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PlatformException catch (error) {
      debugPrint('Error de permisos o selección de imagen: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible acceder a la cámara o galería. '
            'Verifica los permisos del dispositivo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      debugPrint('Error al guardar fotografía: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible guardar la fotografía. Intenta nuevamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _seleccionandoImagen = false;
        });
      }
    }
  }

  // SECCIÓN PARA AGREGAR Y VISUALIZAR LA FOTOGRAFÍA
  Widget construirSeccionImagen() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFECE7F2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          construirTituloSeccion(
            titulo: 'Fotografía del producto',
            descripcion:
                'Agrega una imagen desde la cámara o la galería.',
            icono: Icons.photo_camera_outlined,
          ),
          const SizedBox(height: 20),
          if (imagenSeleccionada != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(imagenSeleccionada!),
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 160,
                    color: InventoryScreen.moradoClaro,
                    alignment: Alignment.center,
                    child: const Text(
                      'No se pudo mostrar la fotografía.',
                      style: TextStyle(
                        color: InventoryScreen.moradoOscuro,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 155,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE8E1EF),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 42,
                    color: InventoryScreen.moradoOscuro,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No has agregado una fotografía',
                    style: TextStyle(
                      color: Color(0xFF777080),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _seleccionandoImagen || _guardando
                  ? null
                  : mostrarOpcionesImagen,
              icon: _seleccionandoImagen
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _seleccionandoImagen
                    ? 'SELECCIONANDO...'
                    : imagenSeleccionada == null
                        ? 'AGREGAR FOTOGRAFÍA'
                        : 'CAMBIAR FOTOGRAFÍA',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: InventoryScreen.moradoOscuro,
                side: const BorderSide(
                  color: Color(0xFFD8C5EF),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CAMPO DE CANTIDAD
  Widget construirCampoCantidad() {
    return TextFormField(
      controller: cantidadController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (valor) => validarEntero(
        valor,
        'la cantidad inicial',
      ),
      decoration: decoracionCampo(
        etiqueta: 'Cantidad inicial',
        icono: Icons.numbers_rounded,
        ayuda: 'Número de unidades disponibles',
      ),
    );
  }

  // CAMPO DE STOCK MÍNIMO
  Widget construirCampoStockMinimo() {
    return TextFormField(
      controller: stockMinimoController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (valor) => validarEntero(
        valor,
        'el stock mínimo',
      ),
      decoration: decoracionCampo(
        etiqueta: 'Stock mínimo',
        icono: Icons.warning_amber_rounded,
        ayuda: 'Nivel para identificar stock bajo',
      ),
    );
  }

  // GUARDAR PRODUCTO CON VALIDACIÓN DE CÓDIGO DUPLICADO EN SQLITE
  Future<void> guardarProducto() async {
    if (_guardando) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría.'),
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    final codigoIngresado =
        codigoController.text.trim().toUpperCase();

    try {
      final codigoDuplicado =
          await DatabaseHelper.instance.codigoExiste(
        codigoIngresado,
      );

      if (!mounted) return;

      if (codigoDuplicado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ya existe un producto con ese código. '
              'Ingresa un código diferente.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final producto = <String, dynamic>{
        'nombre': nombreController.text.trim(),
        'codigo': codigoIngresado,
        'cantidad': int.parse(cantidadController.text.trim()),
        'categoria': categoriaSeleccionada!,
        'precio': double.parse(
          precioController.text.trim().replaceAll(',', '.'),
        ),
        'stockMinimo': int.parse(stockMinimoController.text.trim()),
        'imagen': imagenSeleccionada,
      };

      Navigator.pop(context, producto);
    } catch (error) {
      debugPrint('Error al guardar producto: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar el producto. Intenta nuevamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InventoryScreen.fondo,

      // BARRA SUPERIOR
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: InventoryScreen.moradoOscuro,
          ),
        ),
        title: const Text(
          'Nuevo producto',
          style: TextStyle(
            color: Color(0xFF292333),
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),

      // CUERPO RESPONSIVE
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final anchoPantalla = constraints.maxWidth;
            final esPantallaAncha = anchoPantalla >= 700;
            final esPantallaPequena = anchoPantalla < 400;

            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                esPantallaAncha ? 32 : 18,
                esPantallaPequena ? 14 : 20,
                esPantallaAncha ? 32 : 18,
                30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 850,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ENCABEZADO
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            esPantallaPequena ? 15 : 21,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF1E8FF),
                                Color(0xFFE8DCFA),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE5D8F5),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: esPantallaPequena ? 48 : 58,
                                height: esPantallaPequena ? 48 : 58,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: Icon(
                                  Icons.add_box_rounded,
                                  color: InventoryScreen.moradoOscuro,
                                  size: esPantallaPequena ? 27 : 32,
                                ),
                              ),
                              SizedBox(
                                width: esPantallaPequena ? 10 : 15,
                              ),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Registra un producto',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            InventoryScreen.moradoOscuro,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Completa los datos para agregarlo '
                                      'a tu inventario.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF655574),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        // TARJETA DE INFORMACIÓN GENERAL
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            esPantallaPequena ? 14 : 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFECE7F2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              construirTituloSeccion(
                                titulo: 'Información general',
                                descripcion:
                                    'Identifica el producto y selecciona '
                                    'su categoría.',
                                icono: Icons.inventory_2_outlined,
                              ),

                              const SizedBox(height: 23),

                              // NOMBRE
                              TextFormField(
                                controller: nombreController,
                                textCapitalization:
                                    TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: (valor) => validarTexto(
                                  valor,
                                  'el nombre del producto',
                                ),
                                decoration: decoracionCampo(
                                  etiqueta: 'Nombre del producto',
                                  icono: Icons.inventory_2_outlined,
                                ),
                              ),

                              const SizedBox(height: 19),

                              // CÓDIGO
                              TextFormField(
                                controller: codigoController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.next,
                                validator: (valor) =>
                                    validarTexto(valor, 'el código'),
                                decoration: decoracionCampo(
                                  etiqueta: 'Código del producto',
                                  icono: Icons.qr_code_rounded,
                                  ayuda: 'Ejemplo: ARZ001',
                                ),
                              ),

                              const SizedBox(height: 19),

                              // CATEGORÍA
                              DropdownButtonFormField<String>(
                                initialValue: categoriaSeleccionada,
                                isExpanded: true,
                                validator: (valor) {
                                  if (valor == null) {
                                    return 'Selecciona una categoría.';
                                  }
                                  return null;
                                },
                                decoration: decoracionCampo(
                                  etiqueta: 'Categoría',
                                  icono: Icons.category_outlined,
                                ),
                                items: categorias.map((categoria) {
                                  return DropdownMenuItem<String>(
                                    value: categoria,
                                    child: Text(categoria),
                                  );
                                }).toList(),
                                onChanged: (valor) {
                                  setState(() {
                                    categoriaSeleccionada = valor;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // TARJETA DE EXISTENCIAS
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            esPantallaPequena ? 14 : 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFECE7F2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              construirTituloSeccion(
                                titulo: 'Control de existencias',
                                descripcion:
                                    'Define las unidades disponibles y '
                                    'el nivel mínimo de stock.',
                                icono: Icons.inventory_outlined,
                              ),

                              const SizedBox(height: 23),

                              if (esPantallaAncha)
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: construirCampoCantidad(),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: construirCampoStockMinimo(),
                                    ),
                                  ],
                                )
                              else ...[
                                construirCampoCantidad(),
                                const SizedBox(height: 19),
                                construirCampoStockMinimo(),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // TARJETA DE PRECIO
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            esPantallaPequena ? 14 : 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFECE7F2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              construirTituloSeccion(
                                titulo: 'Información de precio',
                                descripcion:
                                    'Indica el precio por unidad del producto.',
                                icono: Icons.payments_outlined,
                              ),

                              const SizedBox(height: 23),

                              TextFormField(
                                controller: precioController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: validarPrecio,
                                decoration: decoracionCampo(
                                  etiqueta: 'Precio por unidad',
                                  icono: Icons.attach_money_rounded,
                                  ayuda:
                                      'Puedes usar punto o coma decimal.',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // SECCIÓN DE FOTOGRAFÍA
                        construirSeccionImagen(),

                        const SizedBox(height: 28),

                        // BOTÓN GUARDAR
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _guardando || _seleccionandoImagen
                                ? null
                                : guardarProducto,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _guardando
                                  ? 'GUARDANDO...'
                                  : 'GUARDAR PRODUCTO',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  InventoryScreen.moradoOscuro,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // BOTÓN CANCELAR
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton.icon(
                            onPressed: _guardando
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text(
                              'CANCELAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  InventoryScreen.moradoOscuro,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

