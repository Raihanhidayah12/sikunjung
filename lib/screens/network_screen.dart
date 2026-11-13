import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/network_service.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final _networkService = NetworkService();
  List<ConnectivityResult> _connectivityResults = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialNetwork();
    _subscription = _networkService.onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _connectivityResults = results;
        });
      }
    });
  }

  Future<void> _checkInitialNetwork() async {
    final results = await _networkService.checkConnectivity();
    if (mounted) {
      setState(() {
        _connectivityResults = results;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = _networkService.isConnected(_connectivityResults);
    final statusText = _networkService.getConnectionTypeName(_connectivityResults);

    IconData iconData = Icons.wifi_off;
    Color statusColor = Colors.red;

    if (_connectivityResults.contains(ConnectivityResult.wifi)) {
      iconData = Icons.wifi;
      statusColor = Colors.blue;
    } else if (_connectivityResults.contains(ConnectivityResult.mobile)) {
      iconData = Icons.signal_cellular_alt;
      statusColor = Colors.green;
    } else if (_connectivityResults.contains(ConnectivityResult.ethernet)) {
      iconData = Icons.lan;
      statusColor = Colors.teal;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Jaringan Seluler & Wi-Fi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card Real-time
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      child: Icon(iconData, size: 48, color: statusColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isOnline ? 'Terhubung ke Internet' : 'Mode Offline',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isOnline
                          ? 'Perangkat dapat memuat peta OpenStreetMap online dan fitur jaringan.'
                          : 'Aplikasi beroperasi dalam mode Offline-First. Data kunjungan tetap aman tersimpan di SQLite lokal.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Petunjuk Pengujian untuk Asesor
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
                        const Icon(Icons.science_outlined, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          'Skenario Pengujian Asesor',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      '1. Matikan Wi-Fi atau aktifkan Mode Pesawat (Airplane Mode).\n'
                      '2. Status jaringan akan langsung berubah menjadi "Offline" secara real-time.\n'
                      '3. Banner peringatan offline akan muncul di Dashboard.\n'
                      '4. Coba lakukan input data kunjungan baru (Tetap berhasil tersimpan ke SQLite).\n'
                      '5. Buka halaman Peta (Tampil pesan banner penanganan offline).\n'
                      '6. Nyalakan kembali Wi-Fi/data seluler untuk memverifikasi perubahan status.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Teori Generasi Jaringan Seluler (Standar Asesmen BNSP)
            Card(
              elevation: 2,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Materi Generasi Jaringan Seluler (SKKNI)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildGenTile(
                      '2G (GSM / GPRS / EDGE)',
                      'Kecepatan: ~100 - 384 Kbps | Latensi: 300 - 1000 ms\n'
                      'Karakteristik: Komunikasi suara dan SMS, transfer data lambat.',
                    ),
                    _buildGenTile(
                      '3G (UMTS / HSPA+)',
                      'Kecepatan: ~2 - 42 Mbps | Latensi: 100 - 200 ms\n'
                      'Karakteristik: Mulai mendukung browsing web, video call resolusi rendah.',
                    ),
                    _buildGenTile(
                      '4G LTE',
                      'Kecepatan: ~50 - 300 Mbps | Latensi: 20 - 50 ms\n'
                      'Karakteristik: Standar utama komputasi mobile modern, streaming HD, peta interaktif, dan API cepat.',
                    ),
                    _buildGenTile(
                      '5G (New Radio)',
                      'Kecepatan: 1 - 10 Gbps | Latensi: <1 - 10 ms (Ultra-low latency)\n'
                      'Karakteristik: Mendukung massive IoT, smart city, cloud gaming, dan telemedicine.',
                    ),
                    const Divider(),
                    Text(
                      'Kesesuaian untuk Aplikasi SiKunjung:\n'
                      'Jaringan 4G LTE adalah pilihan paling ideal untuk operasional lapangan karena kestabilan sinyal dan kecepatan memuat peta OpenStreetMap. Namun dengan arsitektur Offline-First (SQLite), SiKunjung tetap berfungsi penuh 100% untuk pencatatan transaksi di wilayah tanpa sinyal seluler.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blueGrey.shade900),
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

  Widget _buildGenTile(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
