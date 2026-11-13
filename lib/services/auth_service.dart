import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import 'preference_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final _dbHelper = DatabaseHelper();
  final _prefService = PreferenceService();

  static const String _keyToken = 'auth_session_token';
  static const String _keyUsername = 'auth_session_username';

  /// Hash password menggunakan algoritma SHA-256 (Mobile Security Standard)
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Proses Login dengan verifikasi hash password dan penyimpanan session token aman
  Future<bool> login(String username, String password) async {
    final user = await _dbHelper.getUserByUsername(username);
    if (user == null) return false;

    final inputHash = hashPassword(password);
    if (user.passwordHash == inputHash) {
      // Simpan session token dan username ke penyimpanan terenkripsi
      final dummyToken = 'SEC_SESSION_${DateTime.now().millisecondsSinceEpoch}_$username';
      await _secureStorage.write(key: _keyToken, value: dummyToken);
      await _secureStorage.write(key: _keyUsername, value: username);

      // Simpan ke preferensi untuk kemudahan input berikutnya
      await _prefService.saveLastUsername(username);
      return true;
    }
    return false;
  }

  /// Pendaftaran user baru dengan password yang di-hash
  Future<bool> register(String username, String password) async {
    final existingUser = await _dbHelper.getUserByUsername(username);
    if (existingUser != null) return false;

    final passwordHash = hashPassword(password);
    final newUser = User(username: username, passwordHash: passwordHash);
    await _dbHelper.insertUser(newUser);
    return true;
  }

  /// Cek apakah pengguna sudah memiliki sesi login aktif
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }

  /// Dapatkan nama pengguna yang sedang aktif dari secure storage
  Future<String?> getCurrentUsername() async {
    return await _secureStorage.read(key: _keyUsername);
  }

  /// Logout dengan menghapus sesi token dari Flutter Secure Storage
  Future<void> logout() async {
    await _secureStorage.delete(key: _keyToken);
    await _secureStorage.delete(key: _keyUsername);
  }
}
