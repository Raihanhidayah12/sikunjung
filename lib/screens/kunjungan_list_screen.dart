import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../database/database_helper.dart';
import '../models/kunjungan.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';
import '../widgets/kunjungan_card.dart';
import 'kunjungan_detail_screen.dart';
import 'kunjungan_form_screen.dart';

class KunjunganListScreen extends StatefulWidget {
  const KunjunganListScreen({super.key});

  @override
  State<KunjunganListScreen> createState() => _KunjunganListScreenState();
}

class _KunjunganListScreenState extends State<KunjunganListScreen> {
  final _dbHelper = DatabaseHelper();
  final _locationService = LocationService();
  final _sensorService = SensorService();

  final _searchController = TextEditingController();
  List<Kunjungan> _kunjunganList = [];
  Map<int, String> _distanceMap = {};
  bool _isLoading = true;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initShakeDetector();
  }

  /// Inisialisasi fitur Shake-to-Refresh menggunakan sensor Accelerometer (Unit 6)
  void _initShakeDetector() {
    try {
      _accelerometerSubscription = _sensorService.accelerometerStream.listen((event) {
        final now = DateTime.now();
        // Debounce getaran agar tidak trigger berkali-kali dalam 2 detik
        if (now.difference(_lastShakeTime).inMilliseconds > 2000) {
          if (_sensorService.isShakeDetected(x: event.x, y: event.y, z: event.z, threshold: 14.0)) {
            _lastShakeTime = now;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.vibration, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Guncangan terdeteksi! Memperbarui data kunjungan...'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.teal.shade800,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _loadData();
            }
          }
        }
      });
    } catch (_) {
      // Sensor tidak tersedia pada beberapa emulator
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final query = _searchController.text.trim();
    final data = await _dbHelper.getAllKunjungan(searchQuery: query.isNotEmpty ? query : null);

    // Hitung jarak dari posisi sekarang jika GPS aktif
    final userPos = await _locationService.getCurrentLocation();
    final distances = <int, String>{};

    if (userPos != null) {
      for (final item in data) {
        if (item.id != null) {
          final meters = _locationService.calculateDistanceInMeters(
            userPos.latitude,
            userPos.longitude,
            item.latitude,
            item.longitude,
          );
          distances[item.id!] = _locationService.formatDistance(meters);
        }
      }
    }

    if (mounted) {
      setState(() {
        _kunjunganList = data;
        _distanceMap = distances;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteKunjungan(Kunjungan k) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        title: const Text('Hapus Data Kunjungan?'),
        content: Text('Hapus kunjungan ke "${k.namaPelanggan}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && k.id != null) {
      await _dbHelper.deleteKunjungan(k.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data kunjungan berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadData();
    }
  }

  Future<void> _openForm({Kunjungan? initial}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KunjunganFormScreen(initialKunjungan: initial),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openDetail(Kunjungan k) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KunjunganDetailScreen(kunjungan: k),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kunjungan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Data',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Cari pelanggan, alamat, atau no HP...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _loadData();
                    },
                  ),
              ],
              onChanged: (_) => _loadData(),
              elevation: const WidgetStatePropertyAll(1),
            ),
          ),

          // Petunjuk Shake to Refresh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.screen_rotation, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Tips: Goyangkan perangkat (shake) untuk me-refresh data',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // List Kunjungan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _kunjunganList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Belum ada data kunjungan'
                                  : 'Tidak ditemukan hasil untuk "${_searchController.text}"',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _kunjunganList.length,
                          itemBuilder: (context, index) {
                            final item = _kunjunganList[index];
                            final dist = item.id != null ? _distanceMap[item.id!] : null;

                            return KunjunganCard(
                              kunjungan: item,
                              distanceText: dist,
                              onTap: () => _openDetail(item),
                              onNavigate: () {
                                _locationService.openGoogleMapsNavigation(
                                  item.latitude,
                                  item.longitude,
                                  label: item.namaPelanggan,
                                );
                              },
                              onEdit: () => _openForm(initial: item),
                              onDelete: () => _deleteKunjungan(item),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Tambah Kunjungan'),
      ),
    );
  }
}
