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
    Color netColor = const Color(0xFFEF4444); // Red

    if (_results.contains(ConnectivityResult.wifi)) {
      netIcon = Icons.wifi_rounded;
      netColor = const Color(0xFF2563EB); // Blue
    } else if (_results.contains(ConnectivityResult.mobile)) {
      netIcon = Icons.signal_cellular_alt_rounded;
      netColor = const Color(0xFF10B981); // Green
    } else if (_results.contains(ConnectivityResult.ethernet)) {
      netIcon = Icons.lan_rounded;
      netColor = const Color(0xFF0D9488); // Teal
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Konektivitas'),
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
                    isOnline ? 'Terhubung' : 'Terputus (Offline)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: netColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      isOnline
                          ? 'Perangkat dapat memuat peta OpenStreetMap dan sinkronisasi data.'
                          : 'Aplikasi beroperasi dalam mode Offline-First. Data kunjungan tetap tersimpan lokal di SQLite.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Arsitektur Offline-First
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_done_outlined, color: Color(0xFF1D4ED8), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Arsitektur Offline-First',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SiKunjung dirancang agar petugas lapangan tetap dapat mencatat kunjungan dan merekam koordinat GPS di area terpencil (blank spot). Data otomatis tersimpan di SQLite lokal dan tidak akan hilang.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tabel Perbandingan Generasi Seluler
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Karakteristik Generasi Jaringan Seluler',
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
                  _buildGenRow(
                    '2G (GSM / GPRS / EDGE)',
                    'Kecepatan: ~100 - 384 Kbps | Latensi: 300 - 1000 ms\nCocok untuk panggilan suara dan SMS sederhana.',
                    false,
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildGenRow(
                    '3G (UMTS / HSPA+)',
                    'Kecepatan: ~2 - 42 Mbps | Latensi: 100 - 200 ms\nMendukung transfer data web dan email mobile.',
                    false,
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildGenRow(
                    '4G LTE (Direkomendasikan)',
                    'Kecepatan: ~50 - 300 Mbps | Latensi: 20 - 50 ms\nStandar ideal untuk aplikasi lapangan, peta tile real-time, dan GPS.',
                    true,
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildGenRow(
                    '5G NR (New Radio)',
                    'Kecepatan: 1 - 10 Gbps | Latensi: <1 - 10 ms\nKonektivitas ultra-low latency untuk IoT massal dan streaming berat.',
                    false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenRow(String title, String desc, bool isHighlighted) {
    return Container(
      color: isHighlighted ? const Color(0xFFF0FDF4) : Colors.transparent,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHighlighted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isHighlighted ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isHighlighted ? const Color(0xFF14532D) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isHighlighted ? const Color(0xFF166534) : const Color(0xFF64748B),
                    height: 1.35,
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
