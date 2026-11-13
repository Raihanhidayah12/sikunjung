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
    _computeDistance();
  }

  Future<void> _computeDistance() async {
    setState(() => _isLoadingDistance = true);
    final userPos = await _locationService.getCurrentLocation();
    if (userPos != null) {
      final meters = _locationService.calculateDistanceInMeters(
        userPos.latitude,
        userPos.longitude,
        _kunjungan.latitude,
        _kunjungan.longitude,
      );
      if (mounted) {
        setState(() {
          _distanceText = _locationService.formatDistance(meters);
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

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        title: const Text('Hapus Data Kunjungan?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus data kunjungan ke "${_kunjungan.namaPelanggan}"?\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
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

    if (confirm == true) {
      if (_kunjungan.id != null) {
        await _dbHelper.deleteKunjungan(_kunjungan.id!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data kunjungan berhasil dihapus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _navigateToEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => KunjunganFormScreen(initialKunjungan: _kunjungan),
      ),
    );

    if (updated == true && mounted && _kunjungan.id != null) {
      final fresh = await _dbHelper.getKunjunganById(_kunjungan.id!);
      if (fresh != null) {
        setState(() {
          _kunjungan = fresh;
        });
        _computeDistance();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kunjungan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Data',
            onPressed: _navigateToEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Hapus Data',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card Nama & Status
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.store, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _kunjungan.namaPelanggan,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Tanggal: ${_kunjungan.tanggal}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card Jarak & Tombol Navigasi
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
                        const Icon(Icons.navigation, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'Jarak & Navigasi',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car, color: Colors.teal.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jarak dari posisi petugas:',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                _isLoadingDistance
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        _distanceText ?? 'Menghitung...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade900,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _computeDistance,
                            tooltip: 'Perbarui Jarak',
                          ),
                        ],
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
                      icon: const Icon(Icons.map),
                      label: const Text('Buka Rute di Google Maps'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card Detail Kontak & Alamat
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.location_on, color: Colors.white),
                      ),
                      title: const Text('Alamat Lengkap'),
                      subtitle: Text(_kunjungan.alamat),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.phone, color: Colors.white),
                      ),
                      title: const Text('Nomor HP / WhatsApp'),
                      subtitle: Text(_kunjungan.noHp),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.my_location, color: Colors.white),
                      ),
                      title: const Text('Titik Koordinat'),
                      subtitle: Text('${_kunjungan.latitude}, ${_kunjungan.longitude}'),
                    ),
                    if (_kunjungan.catatan.isNotEmpty) ...[
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.note_alt, color: Colors.white),
                        ),
                        title: const Text('Catatan Kunjungan'),
                        subtitle: Text(_kunjungan.catatan),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
