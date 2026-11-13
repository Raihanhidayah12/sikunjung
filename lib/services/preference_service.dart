import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String _keyLastUsername = 'last_logged_in_username';
  static const String _keyThemeMode = 'app_theme_mode';

  static final PreferenceService _instance = PreferenceService._internal();
  factory PreferenceService() => _instance;
  PreferenceService._internal();

  /// Simpan nama pengguna terakhir yang berhasil login
  Future<void> saveLastUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUsername, username);
  }

  /// Ambil nama pengguna terakhir yang login
  Future<String?> getLastUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastUsername);
  }

  /// Simpan pilihan tema (light, dark, system)
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  /// Ambil preferensi tema
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_keyThemeMode);
    if (modeName == 'dark') return ThemeMode.dark;
    if (modeName == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }
}
