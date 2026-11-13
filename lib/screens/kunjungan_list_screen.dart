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

  StreamSubscription<AccelerometerEvent>? _accSub;
  DateTime _lastShake = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initShake();
  }

  void _initShake() {
    try {
      _accSub = _sensorService.accelerometerStream.listen((event) {
        final now = DateTime.now();
        if (now.difference(_lastShake).inMilliseconds > 2000) {
          if (_sensorService.isShakeDetected(x: event.x, y: event.y, z: event.z, threshold: 14.0)) {
            _lastShake = now;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.vibration, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('Goyangan terdeteksi! Memperbarui data kunjungan...'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF0D9488),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
              _loadData();
            }
          }
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final q = _searchController.text.trim();
    final list = await _dbHelper.getAllKunjungan(searchQuery: q.isNotEmpty ? q : null);

    final userPos = await _locationService.getCurrentLocation();
    final dists = <int, String>{};

    if (userPos != null) {
      for (final item in list) {
        if (item.id != null) {
          final m = _locationService.calculateDistanceInMeters(
            userPos.latitude,
            userPos.longitude,
            item.latitude,
            item.longitude,
          );
          dists[item.id!] = _locationService.formatDistance(m);
        }
      }
    }

    if (mounted) {
      setState(() {
        _kunjunganList = list;
        _distanceMap = dists;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(Kunjungan k) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data Kunjungan?'),
        content: Text('Kunjungan ke "${k.namaPelanggan}" akan dihapus dari database lokal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && k.id != null) {
      await _dbHelper.deleteKunjungan(k.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data kunjungan berhasil dihapus.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Segarkan',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextFormField(
              controller: _searchController,
              onChanged: (_) => _loadData(),
              decoration: InputDecoration(
                hintText: 'Cari pelanggan, alamat, atau no HP...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadData();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Shake Tip Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.vibration, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Goyangkan perangkat (shake) untuk memuat ulang data',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ListView with Refresh Indicator
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _kunjunganList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_late_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 14),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Belum ada data kunjungan'
                                  : 'Tidak ada hasil untuk "${_searchController.text}"',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 6, bottom: 80),
                          itemCount: _kunjunganList.length,
                          itemBuilder: (context, index) {
                            final item = _kunjunganList[index];
                            final dist = item.id != null ? _distanceMap[item.id!] : null;

                            return KunjunganCard(
                              kunjungan: item,
                              distanceText: dist,
                              onTap: () async {
                                final res = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => KunjunganDetailScreen(kunjungan: item),
                                  ),
                                );
                                if (res == true) _loadData();
                              },
                              onNavigate: () {
                                _locationService.openGoogleMapsNavigation(
                                  item.latitude,
                                  item.longitude,
                                  label: item.namaPelanggan,
                                );
                              },
                              onEdit: () async {
                                final res = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => KunjunganFormScreen(initialKunjungan: item),
                                  ),
                                );
                                if (res == true) _loadData();
                              },
                              onDelete: () => _deleteItem(item),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const KunjunganFormScreen()),
          );
          if (res == true) _loadData();
        },
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt, size: 20),
        label: const Text(
          'Catat Kunjungan',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
