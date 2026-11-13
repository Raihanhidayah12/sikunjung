import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/kunjungan.dart';
import '../services/location_service.dart';
import 'kunjungan_form_screen.dart';

class KunjunganDetailScreen extends StatefulWidget {
  final Kunjungan kunjungan;

  const KunjunganDetailScreen({super.key, required this.kunjungan});

  @override
  State<KunjunganDetailScreen> createState() => _KunjunganDetailScreenState();
}

class _KunjunganDetailScreenState extends State<KunjunganDetailScreen> {
  late Kunjungan _kunjungan;
  final _locationService = LocationService();
  final _dbHelper = DatabaseHelper();

  String? _distanceText;
  bool _isLoadingDistance = true;

  @override
  void initState() {
    super.initState();
    _kunjungan = widget.kunjungan;
    _calcDistance();
  }

  Future<void> _calcDistance() async {
    setState(() => _isLoadingDistance = true);
    final pos = await _locationService.getCurrentLocation();
    if (pos != null) {
      final m = _locationService.calculateDistanceInMeters(
        pos.latitude,
        pos.longitude,
        _kunjungan.latitude,
        _kunjungan.longitude,
      );
      if (mounted) {
        setState(() {
          _distanceText = _locationService.formatDistance(m);
          _isLoadingDistance = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _distanceText = 'Lokasi GPS belum tersedia';
          _isLoadingDistance = false;
        });
      }
    }
  }

  Future<void> _deleteKunjungan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data Kunjungan?'),
        content: Text('Kunjungan ke "${_kunjungan.namaPelanggan}" akan dihapus permanen.'),
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

    if (confirm == true && _kunjungan.id != null) {
      await _dbHelper.deleteKunjungan(_kunjungan.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data kunjungan telah dihapus.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _editKunjungan() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KunjunganFormScreen(initialKunjungan: _kunjungan),
      ),
    );

    if (updated == true && _kunjungan.id != null) {
      final fresh = await _dbHelper.getKunjunganById(_kunjungan.id!);
      if (fresh != null && mounted) {
        setState(() => _kunjungan = fresh);
        _calcDistance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rincian Kunjungan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Ubah Data',
            onPressed: _editKunjungan,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            tooltip: 'Hapus Data',
            onPressed: _deleteKunjungan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile Card
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        _kunjungan.namaPelanggan.isNotEmpty
                            ? _kunjungan.namaPelanggan[0].toUpperCase()
                            : 'K',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _kunjungan.namaPelanggan,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Kunjungan: ${_kunjungan.tanggal}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Distance & Navigation Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimasi Jarak dari Posisi Anda',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _calcDistance,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Hitung Ulang',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _isLoadingDistance
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Menghitung jarak GPS...', style: TextStyle(fontSize: 13)),
                          ],
                        )
                      : Text(
                          _distanceText ?? 'Tidak diketahui',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      _locationService.openGoogleMapsNavigation(
                        _kunjungan.latitude,
                        _kunjungan.longitude,
                        label: _kunjungan.namaPelanggan,
                      );
                    },
                    icon: const Icon(Icons.directions_car, size: 18),
                    label: const Text('Buka Rute di Google Maps'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact & Location Details
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildDetailTile(
                    title: 'Alamat Pelanggan',
                    content: _kunjungan.alamat,
                    icon: Icons.location_on_outlined,
                  ),
                  const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                  _buildDetailTile(
                    title: 'Nomor Kontak',
                    content: _kunjungan.noHp,
                    icon: Icons.phone_outlined,
                  ),
                  const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                  _buildDetailTile(
                    title: 'Koordinat GPS',
                    content: '${_kunjungan.latitude}, ${_kunjungan.longitude}',
                    icon: Icons.gps_fixed,
                  ),
                  if (_kunjungan.catatan.isNotEmpty) ...[
                    const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9)),
                    _buildDetailTile(
                      title: 'Catatan Kunjungan',
                      content: _kunjungan.catatan,
                      icon: Icons.notes_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
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
