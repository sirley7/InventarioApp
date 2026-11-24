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

  // Inicialización del servicio.
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

  // Solicitar permiso para mostrar notificaciones.
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

  // Comprobar si Android permite mostrar notificaciones.
  Future<bool> verificarPermisos() async {
    await inicializar();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    return await androidPlugin.areNotificationsEnabled() ?? false;
  }

  // Configuración visual de las notificaciones.
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
      icon: _iconoNotificacion,
      color: const Color(0xFF6A1B9A),
      styleInformation: BigTextStyleInformation(
        textoExpandido,
        contentTitle: 'Productos con stock bajo',
        summaryText: 'InventarioApp',
      ),
    );
  }

  // Mostrar notificación individual de stock bajo.
  Future<void> mostrarNotificacionStockBajo({
    required String nombreProducto,
    required int cantidad,
    required int stockMinimo,
  }) async {
    await inicializar();

    if (!await verificarPermisos()) {
      debugPrint('Permiso de notificaciones no concedido.');
      return;
    }

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

  // Revisar todos los productos del inventario.
  Future<void> revisarInventario(
    List<Map<String, dynamic>> productos,
  ) async {
    await inicializar();

    if (!await verificarPermisos()) {
      debugPrint('No se pueden mostrar alertas: permiso denegado.');
      return;
    }

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
      debugPrint('No hay productos con stock bajo.');
      return;
    }

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

    debugPrint(
      'Notificación enviada. Productos con stock bajo: '
      '${productosBajoStock.length}',
    );
  }

  // Notificación de prueba para verificar Android.
  Future<void> probarNotificacion() async {
    await inicializar();

    final permiso = await verificarPermisos();

    debugPrint('Permiso de notificaciones: $permiso');

    if (!permiso) {
      debugPrint('Las notificaciones no están autorizadas.');
      return;
    }

    await _notifications.show(
      id: 9999,
      title: 'Prueba de InventarioApp',
      body: 'Las notificaciones están funcionando correctamente.',
      notificationDetails: NotificationDetails(
        android: _configuracionNotificacion(
          textoExpandido:
              'Prueba de notificaciones de InventarioApp.',
        ),
      ),
    );

    debugPrint('Notificación de prueba enviada.');
  }
}

