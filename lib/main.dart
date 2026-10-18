
import 'package:flutter/material.dart';
import 'screens/inventory_screen.dart';

void main() {
  runApp(const InventarioApp());
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  static const Color moradoClaro = Color(0xFFF1E8FF);
  static const Color moradoOscuro = Color(0xFF6A1B9A);
  static const Color fondo = Color(0xFFF6F4FA);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InventarioApp',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: fondo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: moradoOscuro,
          primary: moradoOscuro,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController correoController =
      TextEditingController();

  final TextEditingController contrasenaController =
      TextEditingController();

  bool mostrarContrasena = false;

  static const Color moradoOscuro = Color(0xFF6A1B9A);
  static const Color fondo = Color(0xFFF6F4FA);

  @override
  void dispose() {
    correoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  InputDecoration decoracionCampo({
    required String etiqueta,
    required String ayuda,
    required IconData icono,
    Widget? sufijo,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      hintText: ayuda,
      prefixIcon: Icon(
        icono,
        color: moradoOscuro,
      ),
      suffixIcon: sufijo,
      filled: true,
      fillColor: const Color(0xFFFAF9FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4DCEC),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4DCEC),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: moradoOscuro,
          width: 1.8,
        ),
      ),
    );
  }

  String? validarCorreo(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }

    final formatoValido = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!formatoValido.hasMatch(valor.trim())) {
      return 'Ingresa un correo electrónico válido.';
    }

    return null;
  }

  String? validarContrasena(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Ingresa tu contraseña.';
    }

    return null;
  }

  void iniciarSesion() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 440,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  30,
                  24,
                  22,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: const Color(0xFFECE6F2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: moradoOscuro.withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // LOGO
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: moradoOscuro,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: moradoOscuro.withValues(alpha: 0.20),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // NOMBRE DE LA APLICACIÓN
                      const Text(
                        'INVENTARIOAPP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: Color(0xFF30263B),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // DESCRIPCIÓN
                      const Text(
                        'Gestiona tus productos de forma\n'
                        'simple y ordenada',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.blueGrey,
                        ),
                      ),

                      // ESPACIO ANTES DEL FORMULARIO
                      const SizedBox(height: 22),

                      // CORREO ELECTRÓNICO
                      TextFormField(
                        controller: correoController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: decoracionCampo(
                          etiqueta: 'Correo electrónico',
                          ayuda: 'Ingresa tu correo',
                          icono: Icons.email_outlined,
                        ),
                        validator: validarCorreo,
                      ),

                      const SizedBox(height: 18),

                      // CONTRASEÑA
                      TextFormField(
                        controller: contrasenaController,
                        obscureText: !mostrarContrasena,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => iniciarSesion(),
                        decoration: decoracionCampo(
                          etiqueta: 'Contraseña',
                          ayuda: 'Ingresa tu contraseña',
                          icono: Icons.lock_outline,
                          sufijo: IconButton(
                            tooltip: mostrarContrasena
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                            icon: Icon(
                              mostrarContrasena
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () {
                              setState(() {
                                mostrarContrasena =
                                    !mostrarContrasena;
                              });
                            },
                          ),
                        ),
                        validator: validarContrasena,
                      ),

                      const SizedBox(height: 26),

                      // BOTÓN INICIAR SESIÓN
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: iniciarSesion,
                          icon: const Icon(
                            Icons.login_rounded,
                          ),
                          label: const Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: moradoOscuro,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // REGISTRO
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes una cuenta?',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Pantalla de registro pendiente.',
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: moradoOscuro,
                            ),
                            child: const Text(
                              'REGÍSTRATE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // PIE DE PANTALLA
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_outlined,
                            size: 15,
                            color: moradoOscuro,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Organiza tu inventario fácilmente',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
