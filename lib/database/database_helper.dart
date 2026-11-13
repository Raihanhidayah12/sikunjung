import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/kunjungan.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        'sikunjung.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sikunjung.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel users untuk security dan autentikasi
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL
      )
    ''');

    // 2. Tabel kunjungan
    await db.execute('''
      CREATE TABLE kunjungan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pelanggan TEXT NOT NULL,
        alamat TEXT NOT NULL,
        no_hp TEXT NOT NULL,
        catatan TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        tanggal TEXT NOT NULL
      )
    ''');

    // Seed data pengguna awal (password di-hash dengan SHA-256)
    final adminHash = sha256.convert(utf8.encode('admin123')).toString();
    final petugasHash = sha256.convert(utf8.encode('petugas123')).toString();

    await db.insert('users', {
      'username': 'admin',
      'password_hash': adminHash,
    });
    await db.insert('users', {
      'username': 'petugas',
      'password_hash': petugasHash,
    });

    // Seed minimal 3 data kunjungan awal hasil uji sesuai kriteria BNSP
    final initialKunjungan = [
      Kunjungan(
        namaPelanggan: 'PT Sumber Rejeki Makmur',
        alamat: 'Jl. Jend. Sudirman No. 45, Jakarta Pusat',
        noHp: '081234567890',
        catatan: 'Survey lokasi instalasi perangkat jaringan baru',
        latitude: -6.2088,
        longitude: 106.8456,
        tanggal: DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
      ),
      Kunjungan(
        namaPelanggan: 'Toko Elektronik Berkah Jaya',
        alamat: 'Jl. MH Thamrin No. 12, Jakarta Pusat',
        noHp: '081987654321',
        catatan: 'Verifikasi kesiapan perangkat POS dan cek sinyal seluler',
        latitude: -6.1944,
        longitude: 106.8229,
        tanggal: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
      ),
      Kunjungan(
        namaPelanggan: 'CV Maju Mandiri Solusindo',
        alamat: 'Jl. Gatot Subroto Kav. 22, Jakarta Selatan',
        noHp: '085211223344',
        catatan: 'Maintenance berkala dan konsultasi upgrade sistem',
        latitude: -6.2305,
        longitude: 106.8198,
        tanggal: DateTime.now().toIso8601String().substring(0, 10),
      ),
    ];

    for (final item in initialKunjungan) {
      await db.insert('kunjungan', item.toMap());
    }
  }

  // --- CRUD OPERASI KUNJUNGAN (Parameterized Queries) ---

  /// Tambah data kunjungan (Insert)
  Future<int> insertKunjungan(Kunjungan kunjungan) async {
    final db = await database;
    return await db.insert(
      'kunjungan',
      kunjungan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil semua data kunjungan atau berdasarkan query pencarian (Query)
  /// Menggunakan parameterized query untuk keamanan dari SQL Injection
  Future<List<Kunjungan>> getAllKunjungan({String? searchQuery}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final queryParam = '%${searchQuery.trim()}%';
      maps = await db.query(
        'kunjungan',
        where: 'nama_pelanggan LIKE ? OR alamat LIKE ? OR no_hp LIKE ?',
        whereArgs: [queryParam, queryParam, queryParam],
        orderBy: 'id DESC',
      );
    } else {
      maps = await db.query(
        'kunjungan',
        orderBy: 'id DESC',
      );
    }

    return maps.map((map) => Kunjungan.fromMap(map)).toList();
  }

  /// Ambil data kunjungan berdasarkan ID
  Future<Kunjungan?> getKunjunganById(int id) async {
    final db = await database;
    final maps = await db.query(
      'kunjungan',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Kunjungan.fromMap(maps.first);
    }
    return null;
  }

  /// Perbarui data kunjungan (Update)
  Future<int> updateKunjungan(Kunjungan kunjungan) async {
    final db = await database;
    return await db.update(
      'kunjungan',
      kunjungan.toMap(),
      where: 'id = ?',
      whereArgs: [kunjungan.id],
    );
  }

  /// Hapus data kunjungan (Delete)
  Future<int> deleteKunjungan(int id) async {
    final db = await database;
    return await db.delete(
      'kunjungan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hitung total jumlah kunjungan
  Future<int> getTotalKunjunganCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM kunjungan');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Hitung jumlah kunjungan hari ini
  Future<int> getKunjunganHariIniCount() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM kunjungan WHERE tanggal LIKE ?',
      ['$today%'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- CRUD OPERASI USER (Security & Auth) ---

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }
}
