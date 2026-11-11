import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

  static const String _iconoNotificacion = 'ic_stat_inventario';

  static const String _canalId = 'canal_stock_bajo';
  static const String _canalNombre = 'Alertas de inventario';

  Future<void> inicializar() async {
    if (_inicializado) return;

    const androidSettings = AndroidInitializationSettings(
      _iconoNotificacion,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );

    _inicializado = true;
  }

  Future<bool> solicitarPermisos() async {
    await inicializar();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    final permisoConcedido =
        await androidPlugin.requestNotificationsPermission();

    return permisoConcedido ?? false;
  }

  AndroidNotificationDetails _configuracionNotificacion({
    required String textoExpandido,
  }) {
    return AndroidNotificationDetails(
      _canalId,
      _canalNombre,
      channelDescription:
          'Notificaciones cuando los productos tienen existencias bajas.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,

      // Icono pequeño blanco para Android.
      icon: _iconoNotificacion,

      // Color morado de la aplicación.
      color: const Color(0xFF6A1B9A),

      // Mensaje ampliado.
      styleInformation: BigTextStyleInformation(
        textoExpandido,
        contentTitle: 'Productos con stock bajo',
        summaryText: 'InventarioApp',
      ),
    );
  }

  Future<void> mostrarNotificacionStockBajo({
    required String nombreProducto,
    required int cantidad,
    required int stockMinimo,
  }) async {
    await inicializar();

    final detalle =
        'Revisa: $nombreProducto. '
        'Stock: $cantidad (mínimo: $stockMinimo).';

    final notificationDetails = NotificationDetails(
      android: _configuracionNotificacion(
        textoExpandido: detalle,
      ),
    );

    await _notifications.show(
      id: 1001,
      title: 'Productos con stock bajo',
      body: detalle,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> revisarInventario(
    List<Map<String, dynamic>> productos,
  ) async {
    await inicializar();

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

    if (productosBajoStock.isEmpty) return;

    final detalles = productosBajoStock.map((producto) {
      final nombre = producto['nombre']?.toString() ?? 'Producto';

      final cantidad = int.tryParse(
            producto['cantidad']?.toString() ?? '',
          ) ??
          0;

      final stockMinimo = int.tryParse(
            producto['stockMinimo']?.toString() ?? '',
          ) ??
          5;

      return '• $nombre. '
          'Stock: $cantidad (mínimo: $stockMinimo).';
    }).join('\n');

    final primerProducto = productosBajoStock.first;

    final nombrePrimero =
        primerProducto['nombre']?.toString() ?? 'Producto';

    final cantidadPrimera = int.tryParse(
          primerProducto['cantidad']?.toString() ?? '',
        ) ??
        0;

    final minimoPrimero = int.tryParse(
          primerProducto['stockMinimo']?.toString() ?? '',
        ) ??
        5;

    final mensaje = productosBajoStock.length == 1
        ? 'Revisa: $nombrePrimero. '
            'Stock: $cantidadPrimera (mínimo: $minimoPrimero).'
        : 'Hay ${productosBajoStock.length} productos '
            'que necesitan revisión.';

    final notificationDetails = NotificationDetails(
      android: _configuracionNotificacion(
        textoExpandido: detalles,
      ),
    );

    await _notifications.show(
      id: 1002,
      title: 'Productos con stock bajo',
      body: mensaje,
      notificationDetails: notificationDetails,
    );
  }
}
