import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/kunjungan.dart';
import '../services/location_service.dart';

class KunjunganFormScreen extends StatefulWidget {
  final Kunjungan? initialKunjungan;

  const KunjunganFormScreen({super.key, this.initialKunjungan});

  @override
  State<KunjunganFormScreen> createState() => _KunjunganFormScreenState();
}

class _KunjunganFormScreenState extends State<KunjunganFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  final _locationService = LocationService();

  late TextEditingController _namaController;
  late TextEditingController _alamatController;
  late TextEditingController _noHpController;
  late TextEditingController _catatanController;
  late TextEditingController _tanggalController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  bool _isGettingLocation = false;
  String? _accuracyInfo;
  bool _isSaving = false;

  bool get _isEditMode => widget.initialKunjungan != null;

  @override
  void initState() {
    super.initState();
    final k = widget.initialKunjungan;
    _namaController = TextEditingController(text: k?.namaPelanggan ?? '');
    _alamatController = TextEditingController(text: k?.alamat ?? '');
    _noHpController = TextEditingController(text: k?.noHp ?? '');
    _catatanController = TextEditingController(text: k?.catatan ?? '');
    _tanggalController = TextEditingController(
      text: k?.tanggal ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _latController = TextEditingController(
      text: k != null ? k.latitude.toString() : '',
    );
    _lngController = TextEditingController(
      text: k != null ? k.longitude.toString() : '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _noHpController.dispose();
    _catatanController.dispose();
    _tanggalController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    try {
      initial = DateFormat('yyyy-MM-dd').parse(_tanggalController.text);
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _accuracyInfo = null;
    });

    final position = await _locationService.getCurrentLocation();

    setState(() {
      _isGettingLocation = false;
    });

    if (!mounted) return;

    if (position != null) {
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
        _accuracyInfo = 'Akurasi: ±${position.accuracy.toStringAsFixed(1)} m';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi GPS berhasil diambil (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})'),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.location_off, color: Colors.amber, size: 40),
          title: const Text('Izin Lokasi / GPS Tidak Aktif'),
          content: const Text(
            'Pastikan GPS perangkat telah diaktifkan dan aplikasi telah diberikan izin akses lokasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinat lokasi (Latitude & Longitude) wajib diisi. Silakan tekan tombol Ambil Lokasi GPS.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final kunjungan = Kunjungan(
      id: widget.initialKunjungan?.id,
      namaPelanggan: _namaController.text.trim(),
      alamat: _alamatController.text.trim(),
      noHp: _noHpController.text.trim(),
      catatan: _catatanController.text.trim(),
      latitude: lat,
      longitude: lng,
      tanggal: _tanggalController.text.trim(),
    );

    if (_isEditMode) {
      await _dbHelper.updateKunjungan(kunjungan);
    } else {
      await _dbHelper.insertKunjungan(kunjungan);
    }

    setState(() => _isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode
            ? 'Data kunjungan berhasil diperbarui'
            : 'Data kunjungan berhasil disimpan ke SQLite'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Kunjungan' : 'Tambah Kunjungan'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Informasi Pelanggan
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
                          Icon(Icons.person_pin, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Informasi Pelanggan',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Pelanggan / Toko *',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama pelanggan tidak boleh kosong';
                          }
                          if (val.trim().length < 3) {
                            return 'Nama minimal 3 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _alamatController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Lengkap *',
                          prefixIcon: Icon(Icons.home_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Alamat tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _noHpController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor HP / WhatsApp *',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          hintText: '0812xxxxxxxx',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nomor HP tidak boleh kosong';
                          }
                          if (!RegExp(r'^[0-9+]{8,16}$').hasMatch(val.trim())) {
                            return 'Format nomor HP tidak valid (hanya angka)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Kunjungan *',
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar),
                            onPressed: _pickDate,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            (val == null || val.isEmpty) ? 'Tanggal wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Kunjungan',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                          border: OutlineInputBorder(),
                          hintText: 'Hasil pembicaraan, kebutuhan produk, dll.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card Lokasi GPS & Navigasi
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.gps_fixed, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                'Titik Koordinat GPS',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _isGettingLocation ? null : _fetchCurrentLocation,
                            icon: _isGettingLocation
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location, size: 16),
                            label: Text(_isGettingLocation ? 'Mencari...' : 'Ambil Lokasi'),
                          ),
                        ],
                      ),
                      if (_accuracyInfo != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _accuracyInfo!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Latitude *',
                                prefixIcon: Icon(Icons.explore_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Harus diisi';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Harus angka';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(
                                labelText: 'Longitude *',
                                prefixIcon: Icon(Icons.explore_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Harus diisi';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Harus angka';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Koordinat direkam otomatis oleh geolocator saat menekan tombol "Ambil Lokasi".',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveData,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Menyimpan...'
                      : (_isEditMode ? 'Perbarui Kunjungan' : 'Simpan Kunjungan'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
