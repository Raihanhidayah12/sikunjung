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
  List<ConnectivityResult> _results = [ConnectivityResult.none];
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _checkNetwork();
    _sub = _networkService.onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() => _results = results);
      }
    });
  }

  Future<void> _checkNetwork() async {
    final res = await _networkService.checkConnectivity();
    if (mounted) {
      setState(() => _results = res);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _networkService.isConnected(_results);
    final statusText = _networkService.getConnectionTypeName(_results);

    IconData netIcon = Icons.wifi_off_rounded;
    Color netColor = const Color(0xFFEF4444);

    if (_results.contains(ConnectivityResult.wifi)) {
      netIcon = Icons.wifi_rounded;
      netColor = const Color(0xFF2563EB);
    } else if (_results.contains(ConnectivityResult.mobile)) {
      netIcon = Icons.signal_cellular_alt_rounded;
      netColor = const Color(0xFF10B981);
    } else if (_results.contains(ConnectivityResult.ethernet)) {
      netIcon = Icons.lan_rounded;
      netColor = const Color(0xFF0D9488);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Jaringan & Koneksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: netColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(netIcon, size: 36, color: netColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isOnline ? 'Terhubung' : 'Mode Offline Aktif',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: netColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Diagnostik Layanan Lapangan
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Kesiapan Layanan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildServiceTile(
                    title: 'Pencatatan Data Lapangan',
                    subtitle: 'Aktif (Penyimpanan Lokal)',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF16A34A),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildServiceTile(
                    title: 'Perekaman Titik GPS',
                    subtitle: 'Siap via Satelit GNSS',
                    icon: Icons.gps_fixed,
                    color: const Color(0xFF16A34A),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildServiceTile(
                    title: 'Peta Digital (Tile Map)',
                    subtitle: isOnline ? 'Tersedia Online' : 'Memerlukan Koneksi Data',
                    icon: isOnline ? Icons.map_outlined : Icons.cloud_off_outlined,
                    color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildServiceTile(
                    title: 'Jaringan yang Didukung',
                    subtitle: '4G LTE / 3G / 2G / Wi-Fi',
                    icon: Icons.cell_tower,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Refresh Status
            FilledButton.tonalIcon(
              onPressed: _checkNetwork,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Perbarui Status Koneksi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
