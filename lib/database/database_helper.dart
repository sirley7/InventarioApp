import 'dart:convert';
import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  // Configuración para proteger las contraseñas.
  static final Pbkdf2 _algoritmoContrasena = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  // Obtener la conexión a la base de datos.
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();

    await _cargarDatosIniciales(_database!);

    return _database!;
  }

  // Inicializar SQLite.
  Future<Database> _initDatabase() async {
    final ruta = join(
      await getDatabasesPath(),
      'inventario.db',
    );

    return await openDatabase(
      ruta,
      version: 2,

      // Crear las tablas cuando la base de datos es nueva.
      onCreate: (db, version) async {
        await _crearTablaProductos(db);
        await _crearTablaUsuarios(db);
      },

      // Actualizar la base de datos existente sin borrar productos.
      onUpgrade: (db, versionAnterior, versionNueva) async {
        if (versionAnterior < 2) {
          await _crearTablaUsuarios(db);
        }
      },
    );
  }

  // TABLA DE PRODUCTOS.
  Future<void> _crearTablaProductos(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        codigo TEXT NOT NULL UNIQUE,
        cantidad INTEGER NOT NULL,
        categoria TEXT NOT NULL,
        precio REAL NOT NULL DEFAULT 0,
        stockMinimo INTEGER NOT NULL DEFAULT 5,
        imagen TEXT
      )
    ''');
  }

  // TABLA DE USUARIOS.
  Future<void> _crearTablaUsuarios(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL COLLATE NOCASE UNIQUE,
        contrasenaHash TEXT NOT NULL,
        salt TEXT NOT NULL,
        fechaRegistro TEXT NOT NULL
      )
    ''');
  }

  // CARGAR PRODUCTOS EXISTENTES.
  Future<void> _cargarDatosIniciales(Database db) async {
    final resultado = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM productos',
    );

    final total = resultado.first['total'] as int;

    if (total > 0) return;

    final preferencias = await SharedPreferences.getInstance();

    final datosGuardados =
        preferencias.getString('inventario_productos');

    if (datosGuardados != null) {
      try {
        final List<dynamic> productos = jsonDecode(datosGuardados);

        if (productos.isNotEmpty) {
          await db.transaction((txn) async {
            for (final producto in productos) {
              await txn.insert(
                'productos',
                {
                  'nombre': producto['nombre'],
                  'codigo': producto['codigo'],
                  'cantidad': producto['cantidad'],
                  'categoria': producto['categoria'],
                  'precio': producto['precio'] ?? 0,
                  'stockMinimo': producto['stockMinimo'] ?? 5,
                  'imagen': producto['imagen'],
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          });

          return;
        }
      } catch (e) {
        // Si no se pueden recuperar los datos anteriores,
        // se cargarán los productos iniciales.
      }
    }

    await db.transaction((txn) async {
      final productosIniciales = [
        {
          'nombre': 'Arroz',
          'codigo': 'ARZ001',
          'cantidad': 25,
          'categoria': 'Alimentos',
          'precio': 0.0,
          'stockMinimo': 5,
          'imagen': null,
        },
        {
          'nombre': 'Café',
          'codigo': 'CAF001',
          'cantidad': 8,
          'categoria': 'Bebidas',
          'precio': 0.0,
          'stockMinimo': 5,
          'imagen': null,
        },
      ];

      for (final producto in productosIniciales) {
        await txn.insert('productos', producto);
      }
    });
  }

  // =====================================================
  // FUNCIONES DE USUARIOS
  // =====================================================

  // Generar una sal aleatoria para cada contraseña.
  List<int> _generarSalt() {
    final aleatorio = Random.secure();

    return List<int>.generate(
      16,
      (_) => aleatorio.nextInt(256),
    );
  }

  // Generar el hash de una contraseña.
  Future<String> _generarHash(
    String contrasena,
    List<int> salt,
  ) async {
    final clave = await _algoritmoContrasena.deriveKeyFromPassword(
      password: contrasena,
      nonce: salt,
    );

    final bytes = await clave.extractBytes();

    return base64Encode(bytes);
  }

  // Comparar dos hashes sin detenerse en la primera diferencia.
  bool _compararHashes(String hash1, String hash2) {
    final bytes1 = base64Decode(hash1);
    final bytes2 = base64Decode(hash2);

    if (bytes1.length != bytes2.length) return false;

    var diferencia = 0;

    for (var i = 0; i < bytes1.length; i++) {
      diferencia |= bytes1[i] ^ bytes2[i];
    }

    return diferencia == 0;
  }

  // Comprobar si un correo ya está registrado.
  Future<bool> correoExiste(String correo) async {
    final db = await database;

    final correoNormalizado = correo.trim().toLowerCase();

    final resultado = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correoNormalizado],
    );

    return resultado.isNotEmpty;
  }

  // Registrar un usuario nuevo.
  // Devuelve el ID del usuario o null si el correo ya existe.
  Future<int?> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final db = await database;

    final nombreNormalizado = nombre.trim();
    final correoNormalizado = correo.trim().toLowerCase();

    if (await correoExiste(correoNormalizado)) {
      return null;
    }

    final salt = _generarSalt();

    final hash = await _generarHash(
      contrasena,
      salt,
    );

    try {
      final id = await db.insert(
        'usuarios',
        {
          'nombre': nombreNormalizado,
          'correo': correoNormalizado,
          'contrasenaHash': hash,
          'salt': base64Encode(salt),
          'fechaRegistro': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return id;
    } on DatabaseException {
      // También se controla un posible registro duplicado
      // si dos operaciones ocurren al mismo tiempo.
      return null;
    }
  }

  // Iniciar sesión.
  // Devuelve los datos del usuario si las credenciales son correctas.
  // Devuelve null si no coinciden.
  Future<Map<String, dynamic>?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final db = await database;

    final correoNormalizado = correo.trim().toLowerCase();

    final resultado = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correoNormalizado],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    final usuario = resultado.first;

    try {
      final salt = base64Decode(
        usuario['salt'] as String,
      );

      final hashGuardado =
          usuario['contrasenaHash'] as String;

      final hashIngresado = await _generarHash(
        contrasena,
        salt,
      );

      if (!_compararHashes(hashGuardado, hashIngresado)) {
        return null;
      }

      // No devolver el hash ni la sal a la pantalla.
      return {
        'id': usuario['id'],
        'nombre': usuario['nombre'],
        'correo': usuario['correo'],
        'fechaRegistro': usuario['fechaRegistro'],
      };
    } catch (e) {
      return null;
    }
  }

  // =====================================================
  // FUNCIONES DE PRODUCTOS
  // =====================================================

  // Consultar todos los productos.
  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    final db = await database;

    return await db.query(
      'productos',
      orderBy: 'nombre ASC',
    );
  }

  // Registrar un producto.
  Future<int> insertarProducto(
    Map<String, dynamic> producto,
  ) async {
    final db = await database;

    return await db.insert(
      'productos',
      producto,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Actualizar un producto.
  Future<int> actualizarProducto(
    Map<String, dynamic> producto,
  ) async {
    final db = await database;

    return await db.update(
      'productos',
      producto,
      where: 'id = ?',
      whereArgs: [producto['id']],
    );
  }

  // Eliminar un producto.
  Future<int> eliminarProducto(int id) async {
    final db = await database;

    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Comprobar si un código ya existe.
  Future<bool> codigoExiste(String codigo) async {
    final db = await database;

    final resultado = await db.query(
      'productos',
      where: 'codigo = ?',
      whereArgs: [codigo],
    );

    return resultado.isNotEmpty;
  }

  // Cerrar la conexión.
  Future<void> cerrarBaseDatos() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}