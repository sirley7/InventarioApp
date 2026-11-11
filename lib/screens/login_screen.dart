import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'inventory_screen.dart';
import 'register_screen.dart';

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
  bool iniciandoSesion = false;

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
        horizontal: 14,
        vertical: 16,
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

  Future<void> iniciarSesion() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      iniciandoSesion = true;
    });

    try {
      final usuario = await DatabaseHelper.instance.iniciarSesion(
        correo: correoController.text,
        contrasena: contrasenaController.text,
      );

      if (!mounted) return;

      if (usuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Correo electrónico o contraseña incorrectos.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const InventoryScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible iniciar sesión. Inténtalo nuevamente.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          iniciandoSesion = false;
        });
      }
    }
  }

  void irARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ancho = constraints.maxWidth;
            final alto = constraints.maxHeight;

            final pantallaPequena = alto < 650;
            final pantallaAncha = ancho >= 600;

            final margenHorizontal = pantallaAncha
                ? 32.0
                : ancho < 360
                    ? 12.0
                    : 20.0;

            final tamanoLogo = pantallaPequena ? 68.0 : 82.0;
            final tamanoIcono = pantallaPequena ? 38.0 : 44.0;
            final espacioTarjeta = pantallaPequena ? 18.0 : 26.0;

            return Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: margenHorizontal,
                  vertical: pantallaPequena ? 12 : 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: ancho < 360 ? 16 : 22,
                      vertical: pantallaPequena ? 20 : 28,
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
                            width: tamanoLogo,
                            height: tamanoLogo,
                            decoration: BoxDecoration(
                              color: moradoOscuro,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: moradoOscuro.withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.white,
                              size: tamanoIcono,
                            ),
                          ),

                          SizedBox(height: pantallaPequena ? 16 : 20),

                          // NOMBRE DE LA APLICACIÓN
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'INVENTARIOAPP',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: Color(0xFF30263B),
                              ),
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
                              height: 1.5,
                              color: Colors.blueGrey,
                            ),
                          ),

                          SizedBox(height: espacioTarjeta),

                          // CORREO ELECTRÓNICO
                          TextFormField(
                            controller: correoController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            autofillHints: const [
                              AutofillHints.email,
                            ],
                            decoration: decoracionCampo(
                              etiqueta: 'Correo electrónico',
                              ayuda: 'Ingresa tu correo',
                              icono: Icons.email_outlined,
                            ),
                            validator: validarCorreo,
                          ),

                          SizedBox(
                            height: pantallaPequena ? 14 : 18,
                          ),

                          // CONTRASEÑA
                          TextFormField(
                            controller: contrasenaController,
                            obscureText: !mostrarContrasena,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) {
                              if (!iniciandoSesion) iniciarSesion();
                            },
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

                          SizedBox(
                            height: pantallaPequena ? 20 : 26,
                          ),

                          // BOTÓN INICIAR SESIÓN
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: iniciandoSesion
                                  ? null
                                  : iniciarSesion,
                              icon: iniciandoSesion
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(
                                iniciandoSesion
                                    ? 'INGRESANDO...'
                                    : 'INICIAR SESIÓN',
                                style: const TextStyle(
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

                          SizedBox(
                            height: pantallaPequena ? 12 : 18,
                          ),

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
                                onPressed: irARegistro,
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

                          const SizedBox(height: 4),

                          // PIE DE PANTALLA
                          const Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment:
                                WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Icon(
                                Icons.inventory_outlined,
                                size: 15,
                                color: moradoOscuro,
                              ),
                              Text(
                                'Organiza tu inventario fácilmente',
                                textAlign: TextAlign.center,
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
            );
          },
        ),
      ),
    );
  }
}
