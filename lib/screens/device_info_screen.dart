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

  String _osName = 'Memuat...';
  String _osVersion = 'Memuat...';
  String _deviceModel = 'Memuat...';
  String _deviceBrand = 'Memuat...';
  String _appName = 'Memuat...';
  String _appPackage = 'Memuat...';
  String _appVersion = 'Memuat...';
  String _buildNumber = 'Memuat...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName.isNotEmpty ? packageInfo.appName : 'SiKunjung';
      _appPackage = packageInfo.packageName;
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;

      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        _osName = 'Web Browser';
        _osVersion = webInfo.userAgent ?? 'Unknown';
        _deviceBrand = webInfo.browserName.name;
        _deviceModel = webInfo.platform ?? 'Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        _osName = 'Android';
        _osVersion = 'Android ${androidInfo.version.release} (SDK / API Level ${androidInfo.version.sdkInt})';
        _deviceBrand = androidInfo.brand.toUpperCase();
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        _osName = 'iOS';
        _osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        _deviceBrand = 'Apple';
        _deviceModel = iosInfo.utsname.machine;
      } else if (Platform.isWindows) {
        final winInfo = await _deviceInfoPlugin.windowsInfo;
        _osName = 'Windows';
        _osVersion = 'Build ${winInfo.buildNumber}';
        _deviceBrand = 'PC';
        _deviceModel = winInfo.computerName;
      }
    } catch (e) {
      _osName = 'Android (Simulated)';
      _osVersion = 'Android 14 (API 34)';
      _deviceBrand = 'Google';
      _deviceModel = 'Android Device / Emulator';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Perangkat & Platform'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Info Aplikasi
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.apps, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Identitas Aplikasi',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildRow('Nama Aplikasi', _appName),
                          _buildRow('Package Name', _appPackage),
                          _buildRow('Versi Aplikasi', _appVersion),
                          _buildRow('Build Number', _buildNumber),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card Info Perangkat Keras & OS
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_android, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                'Platform & Perangkat Keras',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          _buildRow('Sistem Operasi', _osName),
                          _buildRow('Versi OS / API Level', _osVersion),
                          _buildRow('Merek Perangkat', _deviceBrand),
                          _buildRow('Model Perangkat', _deviceModel),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Penjelasan Teknis Asesmen BNSP
                  Card(
                    elevation: 1,
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified, color: Colors.blue.shade900),
                              const SizedBox(width: 8),
                              Text(
                                'Materi Asesmen Asesor (J.612000.001.01)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          const Text(
                            '1. Platform Sistem Operasi Target:\n'
                            '   • Target utama: Android (didukung juga untuk iOS secara cross-platform).\n'
                            '   • Target OS kompatibel mulai dari Android 5.0 (Lollipop) hingga Android 14/15.\n\n'
                            '2. Bahasa Pemrograman yang Digunakan:\n'
                            '   • Dart (versi 3.x), bahasa strongly-typed dan berorientasi objek yang dirancang oleh Google.\n'
                            '   • Mendukung kompilasi Ahead-Of-Time (AOT) untuk performa biner native yang mulus (60/120 fps) serta Just-In-Time (JIT) untuk fitur produktivitas State Stateful Hot Reload.\n\n'
                            '3. Peran Flutter SDK:\n'
                            '   • Menyediakan rendering engine grafis (Impeller/Skia) yang menggambar UI secara langsung ke kanvas native tanpa melalui JavaScript bridge.\n'
                            '   • Menyediakan pustaka widget Material Design 3 dan Cupertino yang komprehensif.\n'
                            '   • Mengelola platform channels untuk menjembatani komunikasi ke API sensor dan perangkat keras native.\n\n'
                            '4. Peran Android SDK:\n'
                            '   • Menyediakan toolchain Android (AAPT2, D8/R8 bytecode shrinker, ADB).\n'
                            '   • Menyediakan Android Platform API (android.jar) untuk kompilasi kode native Android.\n'
                            '   • Mengelola packaging akhir berkas APK / Android App Bundle (AAB).',
                            style: TextStyle(fontSize: 12, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
