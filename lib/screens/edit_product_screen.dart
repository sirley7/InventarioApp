
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'inventory_screen.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> producto;

  const EditProductScreen({
    super.key,
    required this.producto,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nombreController;
  late final TextEditingController codigoController;
  late final TextEditingController cantidadController;
  late final TextEditingController precioController;
  late final TextEditingController stockMinimoController;

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
  void initState() {
    super.initState();

    nombreController = TextEditingController(
      text: widget.producto['nombre']?.toString() ?? '',
    );

    codigoController = TextEditingController(
      text: widget.producto['codigo']?.toString() ?? '',
    );

    cantidadController = TextEditingController(
      text: (widget.producto['cantidad'] ?? 0).toString(),
    );

    precioController = TextEditingController(
      text: (widget.producto['precio'] ?? 0).toString(),
    );

    stockMinimoController = TextEditingController(
      text: (widget.producto['stockMinimo'] ?? 5).toString(),
    );

    final categoriaActual =
        widget.producto['categoria']?.toString();

    categoriaSeleccionada = categorias.contains(categoriaActual)
        ? categoriaActual
        : 'Otros';
  }

  @override
  void dispose() {
    nombreController.dispose();
    codigoController.dispose();
    cantidadController.dispose();
    precioController.dispose();
    stockMinimoController.dispose();
    super.dispose();
  }

  // DECORACIÓN UNIFORME PARA LOS CAMPOS
  InputDecoration decoracionCampo({
    required String etiqueta,
    required String ayuda,
    required IconData icono,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      hintText: ayuda,
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
        vertical: 18,
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

    if (numero == null || !numero.isFinite) {
      return 'Ingresa un precio válido.';
    }

    if (numero < 0) {
      return 'El precio no puede ser negativo.';
    }

    return null;
  }

  // TÍTULO DE SECCIÓN
  Widget tituloSeccion(
    String titulo,
    String descripcion,
    IconData icono,
  ) {
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
                  height: 1.4,
                  color: Color(0xFF777080),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TARJETA DE CADA SECCIÓN
  Widget tarjetaSeccion({
    required Widget child,
    bool compacto = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compacto ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
      child: child,
    );
  }

  // CAMPO DE CANTIDAD
  Widget campoCantidad() {
    return TextFormField(
      controller: cantidadController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: decoracionCampo(
        etiqueta: 'Cantidad disponible',
        ayuda: 'Unidades actuales',
        icono: Icons.numbers_rounded,
      ),
      validator: (valor) => validarEntero(
        valor,
        'la cantidad',
      ),
    );
  }

  // CAMPO DE STOCK MÍNIMO
  Widget campoStockMinimo() {
    return TextFormField(
      controller: stockMinimoController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: decoracionCampo(
        etiqueta: 'Stock mínimo',
        ayuda: 'Nivel para alertar por pocas unidades',
        icono: Icons.warning_amber_rounded,
      ),
      validator: (valor) => validarEntero(
        valor,
        'el stock mínimo',
      ),
    );
  }

  // GUARDAR CAMBIOS
  void guardarCambios() {
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

    // Conserva los demás datos del producto original.
    final productoActualizado = <String, dynamic>{
      ...widget.producto,
      'nombre': nombreController.text.trim(),
      'codigo': codigoController.text.trim(),
      'cantidad': int.parse(cantidadController.text.trim()),
      'categoria': categoriaSeleccionada!,
      'precio': double.parse(
        precioController.text.trim().replaceAll(',', '.'),
      ),
      'stockMinimo': int.parse(stockMinimoController.text.trim()),
    };

    Navigator.pop(context, productoActualizado);
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
          'Editar producto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: Color(0xFF292333),
          ),
        ),
      ),

      // DISEÑO RESPONSIVE
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;
            final esAncho = ancho >= 700;
            final esPequeno = ancho < 400;

            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                esAncho ? 32 : 18,
                esPequeno ? 14 : 20,
                esAncho ? 32 : 18,
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
                            esPequeno ? 15 : 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF1E8FF),
                                Color(0xFFE5D5FF),
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
                                width: esPequeno ? 48 : 58,
                                height: esPequeno ? 48 : 58,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  color: InventoryScreen.moradoOscuro,
                                  size: esPequeno ? 29 : 34,
                                ),
                              ),
                              SizedBox(width: esPequeno ? 10 : 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Modificar información',
                                      style: TextStyle(
                                        color:
                                            InventoryScreen.moradoOscuro,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Actualiza los datos de tu producto.',
                                      style: TextStyle(
                                        color: Color(0xFF655574),
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // INFORMACIÓN GENERAL
                        tarjetaSeccion(
                          compacto: esPequeno,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              tituloSeccion(
                                'Información general',
                                'Identifica el producto y su categoría.',
                                Icons.inventory_2_outlined,
                              ),
                              const SizedBox(height: 23),

                              TextFormField(
                                controller: nombreController,
                                textCapitalization:
                                    TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: decoracionCampo(
                                  etiqueta: 'Nombre del producto',
                                  ayuda: 'Ej. Arroz',
                                  icono: Icons.shopping_bag_outlined,
                                ),
                                validator: (valor) => validarTexto(
                                  valor,
                                  'el nombre del producto',
                                ),
                              ),

                              const SizedBox(height: 19),

                              TextFormField(
                                controller: codigoController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textInputAction: TextInputAction.next,
                                decoration: decoracionCampo(
                                  etiqueta: 'Código del producto',
                                  ayuda: 'Ej. ARZ001',
                                  icono: Icons.qr_code_rounded,
                                ),
                                validator: (valor) => validarTexto(
                                  valor,
                                  'el código',
                                ),
                              ),

                              const SizedBox(height: 19),

                              DropdownButtonFormField<String>(
                                initialValue: categoriaSeleccionada,
                                isExpanded: true,
                                decoration: decoracionCampo(
                                  etiqueta: 'Categoría',
                                  ayuda: 'Selecciona una categoría',
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
                                validator: (valor) {
                                  if (valor == null) {
                                    return 'Selecciona una categoría.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // CONTROL DE EXISTENCIAS
                        tarjetaSeccion(
                          compacto: esPequeno,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              tituloSeccion(
                                'Control de existencias',
                                'Define las unidades y el nivel mínimo de stock.',
                                Icons.inventory_outlined,
                              ),
                              const SizedBox(height: 23),

                              if (esAncho)
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: campoCantidad(),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: campoStockMinimo(),
                                    ),
                                  ],
                                )
                              else ...[
                                campoCantidad(),
                                const SizedBox(height: 19),
                                campoStockMinimo(),
                              ],

                              const SizedBox(height: 14),

                              const Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: Color(0xFF777080),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'El producto tendrá stock bajo cuando '
                                      'la cantidad sea igual o inferior al mínimo.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF777080),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // INFORMACIÓN DE PRECIO
                        tarjetaSeccion(
                          compacto: esPequeno,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              tituloSeccion(
                                'Información de precio',
                                'Actualiza el precio por unidad.',
                                Icons.payments_outlined,
                              ),
                              const SizedBox(height: 23),

                              TextFormField(
                                controller: precioController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                                decoration: decoracionCampo(
                                  etiqueta: 'Precio unitario',
                                  ayuda: 'Ej. 12500 o 12500,50',
                                  icono: Icons.attach_money_rounded,
                                ),
                                validator: validarPrecio,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // GUARDAR CAMBIOS
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: guardarCambios,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text(
                              'GUARDAR CAMBIOS',
                              style: TextStyle(
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

                        // CANCELAR
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
