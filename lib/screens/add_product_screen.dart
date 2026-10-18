import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_inventario/screens/inventory_screen.dart';

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

  String? categoriaSeleccionada;

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

  // GUARDAR PRODUCTO CON VALIDACIÓN DE CÓDIGO DUPLICADO
  Future<void> guardarProducto() async {
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

    // Normalizar el código para comparar sin distinguir
    // mayúsculas, minúsculas ni espacios en los extremos.
    final codigoIngresado =
        codigoController.text.trim().toUpperCase();

    try {
      final preferencias = await SharedPreferences.getInstance();

      final datosGuardados =
          preferencias.getString('inventario_productos');

      if (datosGuardados != null) {
        final datosDecodificados = jsonDecode(datosGuardados);

        if (datosDecodificados is List) {
          final codigoDuplicado =
              datosDecodificados.any((elemento) {
            if (elemento is! Map) {
              return false;
            }

            final codigoExistente = elemento['codigo']
                    ?.toString()
                    .trim()
                    .toUpperCase() ??
                '';

            return codigoExistente == codigoIngresado;
          });

          if (codigoDuplicado) {
            if (!mounted) return;

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
        }
      }
    } catch (error) {
      debugPrint('Error al verificar el código: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo verificar el código. '
            'Intenta nuevamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;

    // Crear el producto si el código no está repetido.
    final producto = <String, dynamic>{
      'nombre': nombreController.text.trim(),
      'codigo': codigoController.text.trim(),
      'cantidad': int.parse(cantidadController.text.trim()),
      'categoria': categoriaSeleccionada!,
      'precio': double.parse(
        precioController.text.trim().replaceAll(',', '.'),
      ),
      'stockMinimo': int.parse(stockMinimoController.text.trim()),
    };

    Navigator.pop(context, producto);
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

      // FORMULARIO
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ENCABEZADO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(21),
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
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.add_box_rounded,
                          color: InventoryScreen.moradoOscuro,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registra un producto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: InventoryScreen.moradoOscuro,
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
                        textCapitalization: TextCapitalization.words,
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
                        titulo: 'Control de existencias',
                        descripcion:
                            'Define las unidades disponibles y '
                            'el nivel mínimo de stock.',
                        icono: Icons.inventory_outlined,
                      ),

                      const SizedBox(height: 23),

                      // CANTIDAD INICIAL
                      TextFormField(
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
                      ),

                      const SizedBox(height: 19),

                      // STOCK MÍNIMO
                      TextFormField(
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // TARJETA DE PRECIO
                Container(
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
                        titulo: 'Información de precio',
                        descripcion:
                            'Indica el precio por unidad del producto.',
                        icono: Icons.payments_outlined,
                      ),

                      const SizedBox(height: 23),

                      // PRECIO
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
                          ayuda: 'Puedes usar punto o coma decimal.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // BOTÓN GUARDAR
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: guardarProducto,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text(
                      'GUARDAR PRODUCTO',
                      style: TextStyle(
                        fontSize: 14,
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

                const SizedBox(height: 10),

                // BOTÓN CANCELAR
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text(
                      'CANCELAR',
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
        ),
      ),
    );
  }
}
