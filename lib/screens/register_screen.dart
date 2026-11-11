import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  final confirmarContrasenaController = TextEditingController();

  bool mostrarContrasena = false;
  bool mostrarConfirmacion = false;
  bool registrando = false;

  static const Color moradoOscuro = Color(0xFF6A1B9A);
  static const Color fondo = Color(0xFFF6F4FA);

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    contrasenaController.dispose();
    confirmarContrasenaController.dispose();
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
      prefixIcon: Icon(icono, color: moradoOscuro),
      suffixIcon: sufijo,
      filled: true,
      fillColor: const Color(0xFFFAF9FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4DCEC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4DCEC)),
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

  String? validarNombre(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa tu nombre completo.';
    }

    if (valor.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres.';
    }

    return null;
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
      return 'Ingresa una contraseña.';
    }

    if (valor.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(valor) ||
        !RegExp(r'[a-z]').hasMatch(valor) ||
        !RegExp(r'[0-9]').hasMatch(valor)) {
      return 'Usa mayúsculas, minúsculas y números.';
    }

    return null;
  }

  String? validarConfirmacion(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Confirma tu contraseña.';
    }

    if (valor != contrasenaController.text) {
      return 'Las contraseñas no coinciden.';
    }

    return null;
  }

  Future<void> registrarUsuario() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      registrando = true;
    });

    try {
      final id = await DatabaseHelper.instance.registrarUsuario(
        nombre: nombreController.text,
        correo: correoController.text,
        contrasena: contrasenaController.text,
      );

      if (!mounted) return;

      if (id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este correo electrónico ya está registrado.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada correctamente!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible crear la cuenta. Inténtalo nuevamente.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          registrando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: fondo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: moradoOscuro,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pantallaPequena = constraints.maxHeight < 700;

            return Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 22,
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
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: moradoOscuro,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),

                          const SizedBox(height: 18),

                          const Text(
                            'CREAR CUENTA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: Color(0xFF30263B),
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Regístrate para comenzar a utilizar\n'
                            'InventarioApp',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.blueGrey,
                            ),
                          ),

                          const SizedBox(height: 26),

                          TextFormField(
                            controller: nombreController,
                            textCapitalization:
                                TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: decoracionCampo(
                              etiqueta: 'Nombre completo',
                              ayuda: 'Ingresa tu nombre',
                              icono: Icons.person_outline,
                            ),
                            validator: validarNombre,
                          ),

                          const SizedBox(height: 16),

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

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: contrasenaController,
                            obscureText: !mostrarContrasena,
                            textInputAction: TextInputAction.next,
                            decoration: decoracionCampo(
                              etiqueta: 'Contraseña',
                              ayuda: 'Mínimo 8 caracteres',
                              icono: Icons.lock_outline,
                              sufijo: IconButton(
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

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: confirmarContrasenaController,
                            obscureText: !mostrarConfirmacion,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!registrando) registrarUsuario();
                            },
                            decoration: decoracionCampo(
                              etiqueta: 'Confirmar contraseña',
                              ayuda: 'Repite tu contraseña',
                              icono: Icons.lock_reset_outlined,
                              sufijo: IconButton(
                                icon: Icon(
                                  mostrarConfirmacion
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.blueGrey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    mostrarConfirmacion =
                                        !mostrarConfirmacion;
                                  });
                                },
                              ),
                            ),
                            validator: validarConfirmacion,
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: registrando
                                  ? null
                                  : registrarUsuario,
                              icon: registrando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_add_alt_1_rounded,
                                    ),
                              label: Text(
                                registrando
                                    ? 'CREANDO CUENTA...'
                                    : 'REGISTRARSE',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: moradoOscuro,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    moradoOscuro.withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment:
                                WrapCrossAlignment.center,
                            children: [
                              const Text(
                                '¿Ya tienes una cuenta?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'INICIA SESIÓN',
                                  style: TextStyle(
                                    color: moradoOscuro,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
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
