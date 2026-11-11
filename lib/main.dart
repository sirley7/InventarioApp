import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.instance.inicializar();
    await NotificationService.instance.solicitarPermisos();
  } catch (error) {
    debugPrint('Error al inicializar las notificaciones: $error');
  }

  runApp(const InventarioApp());
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

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