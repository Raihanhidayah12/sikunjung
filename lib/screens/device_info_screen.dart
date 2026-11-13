import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  String _osName = 'Android';
  String _osVersion = 'Android 15 (API Level 35)';
  String _deviceModel = 'Pixel Device';
  String _deviceBrand = 'Google';
  String _appName = 'SiKunjung';
  String _appPackage = 'com.sikunjung.app.sikunjung';
  String _appVersion = '1.0.0';
  String _buildNumber = '1';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecs();
  }

  Future<void> _loadSpecs() async {
    try {
      final pInfo = await PackageInfo.fromPlatform();
      _appName = pInfo.appName.isNotEmpty ? pInfo.appName : 'SiKunjung';
      _appPackage = pInfo.packageName;
      _appVersion = pInfo.version;
      _buildNumber = pInfo.buildNumber;

      if (kIsWeb) {
        final web = await _deviceInfoPlugin.webBrowserInfo;
        _osName = 'Web Engine';
        _osVersion = web.browserName.name;
        _deviceBrand = 'Browser';
        _deviceModel = web.platform ?? 'Web Client';
      } else if (Platform.isAndroid) {
        final android = await _deviceInfoPlugin.androidInfo;
        _osName = 'Android OS';
        _osVersion = 'Android ${android.version.release} (API ${android.version.sdkInt})';
        _deviceBrand = android.brand.toUpperCase();
        _deviceModel = '${android.manufacturer} ${android.model}';
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spesifikasi & Sistem'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Badge Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.verified, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _appName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Versi $_appVersion (Build $_buildNumber) • Stable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _appPackage,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 1: Hardware & Platform
                  _buildSectionHeader('Hardware & Platform OS'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildSpecTile('Sistem Operasi', _osName, Icons.android),
                        _buildDivider(),
                        _buildSpecTile('Versi & API Level', _osVersion, Icons.layers_outlined),
                        _buildDivider(),
                        _buildSpecTile('Merek Perangkat', _deviceBrand, Icons.branding_watermark_outlined),
                        _buildDivider(),
                        _buildSpecTile('Model Perangkat', _deviceModel, Icons.phone_android),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Arsitektur Software
                  _buildSectionHeader('Arsitektur Software & Kompilasi'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildSpecTile('Bahasa Pemrograman', 'Dart 3.x (Strongly-Typed, AOT)', Icons.code),
                        _buildDivider(),
                        _buildSpecTile('Framework UI', 'Flutter SDK (Impeller / Skia Engine)', Icons.widgets_outlined),
                        _buildDivider(),
                        _buildSpecTile('Build Pipeline', 'Android SDK Toolchain (Gradle & AAPT2)', Icons.build_circle_outlined),
                        _buildDivider(),
                        _buildSpecTile('Data Persistence', 'SQLite Local Engine (sqflite)', Icons.storage),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Keamanan Data & Proteksi
                  _buildSectionHeader('Protokol Keamanan Aplikasi'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildSpecTile('Proteksi Password', 'Kriptografi Hash SHA-256 (One-Way)', Icons.lock_outline),
                        _buildDivider(),
                        _buildSpecTile('Penyimpanan Sesi', 'Hardware Keystore (AES Encrypted)', Icons.security),
                        _buildDivider(),
                        _buildSpecTile('Database Protection', 'Parameterized Queries (Anti SQLi)', Icons.shield_outlined),
                        _buildDivider(),
                        _buildSpecTile('Izin Lokasi (GPS)', 'Runtime Permission (Least Privilege)', Icons.my_location),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSpecTile(String title, String val, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 50, color: Color(0xFFF1F5F9));
  }
}
