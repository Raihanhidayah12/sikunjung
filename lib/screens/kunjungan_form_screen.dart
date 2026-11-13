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
  String? _accuracyBadge;
  bool _isSaving = false;

  bool get _isEdit => widget.initialKunjungan != null;

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
    _latController = TextEditingController(text: k != null ? k.latitude.toString() : '');
    _lngController = TextEditingController(text: k != null ? k.longitude.toString() : '');
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

  Future<void> _fetchGPS() async {
    setState(() {
      _isGettingLocation = true;
      _accuracyBadge = null;
    });

    final pos = await _locationService.getCurrentLocation();

    setState(() => _isGettingLocation = false);
    if (!mounted) return;

    if (pos != null) {
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
        _accuracyBadge = 'Akurasi GPS: ±${pos.accuracy.toStringAsFixed(1)} m';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Koordinat GPS berhasil diperoleh (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})'),
          backgroundColor: const Color(0xFF0D9488),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendapatkan lokasi. Pastikan GPS dan izin lokasi aktif.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tekan tombol "Ambil Lokasi GPS" untuk merekam koordinat.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final item = Kunjungan(
      id: widget.initialKunjungan?.id,
      namaPelanggan: _namaController.text.trim(),
      alamat: _alamatController.text.trim(),
      noHp: _noHpController.text.trim(),
      catatan: _catatanController.text.trim(),
      latitude: lat,
      longitude: lng,
      tanggal: _tanggalController.text.trim(),
    );

    if (_isEdit) {
      await _dbHelper.updateKunjungan(item);
    } else {
      await _dbHelper.insertKunjungan(item);
    }

    setState(() => _isSaving = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEdit ? 'Data kunjungan berhasil diperbarui.' : 'Data kunjungan berhasil disimpan.'),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Kunjungan' : 'Catat Kunjungan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Customer Data
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
                    const Text(
                      'Informasi Pelanggan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pelanggan / Usaha *',
                        prefixIcon: Icon(Icons.business_outlined, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Nama minimal 3 karakter'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _alamatController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Lengkap *',
                        prefixIcon: Icon(Icons.home_outlined, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _noHpController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Kontak (WhatsApp / Telepon) *',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        if (!RegExp(r'^[0-9+]{8,16}$').hasMatch(v.trim())) {
                          return 'Format nomor tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Kunjungan *',
                        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          onPressed: _pickDate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _catatanController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Kunjungan',
                        prefixIcon: Icon(Icons.notes_rounded, size: 20),
                        hintText: 'Hasil diskusi, kebutuhan produk, dll.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 2: GPS Coordinates
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
                          'Titik Lokasi Lapangan (GPS)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (_accuracyBadge != null)
                          Text(
                            _accuracyBadge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _isGettingLocation ? null : _fetchGPS,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(_isGettingLocation ? 'Merekam Sinyal GPS...' : 'Ambil Titik Lokasi Terkini'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              prefixIcon: Icon(Icons.explore_outlined, size: 18),
                            ),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Angka valid' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              prefixIcon: Icon(Icons.explore_outlined, size: 18),
                            ),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Angka valid' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Perbarui Kunjungan' : 'Simpan Kunjungan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
