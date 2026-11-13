import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../database/database_helper.dart';
import '../models/kunjungan.dart';
import '../services/location_service.dart';
import '../services/network_service.dart';
import 'kunjungan_detail_screen.dart';

class PetaScreen extends StatefulWidget {
  const PetaScreen({super.key});

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  final MapController _mapController = MapController();
  final _dbHelper = DatabaseHelper();
  final _locationService = LocationService();
  final _networkService = NetworkService();

  List<Kunjungan> _kunjunganList = [];
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isOffline = false;

  static const LatLng _jakartaCenter = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() => _isLoading = true);

    final net = await _networkService.checkConnectivity();
    _isOffline = !_networkService.isConnected(net);

    final data = await _dbHelper.getAllKunjungan();
    final pos = await _locationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        _kunjunganList = data;
        _currentPosition = pos;
        _isLoading = false;
      });

      if (pos != null) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 13.0);
      } else if (data.isNotEmpty) {
        _mapController.move(LatLng(data.first.latitude, data.first.longitude), 12.5);
      }
    }
  }

  void _showCustomerSheet(Kunjungan k) {
    String distText = 'Menghitung...';
    if (_currentPosition != null) {
      final m = _locationService.calculateDistanceInMeters(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        k.latitude,
        k.longitude,
      );
      distText = _locationService.formatDistance(m);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.namaPelanggan,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kunjungan: ${k.tanggal}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      distText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      k.alamat,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Text(
                    k.noHp,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KunjunganDetailScreen(kunjungan: k),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Detail Lengkap'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _locationService.openGoogleMapsNavigation(
                          k.latitude,
                          k.longitude,
                          label: k.namaPelanggan,
                        );
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Rute Navigasi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Kunjungan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Perbarui Peta',
            onPressed: _loadMapData,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : (_kunjunganList.isNotEmpty
                            ? LatLng(_kunjunganList.first.latitude, _kunjunganList.first.longitude)
                            : _jakartaCenter),
                    initialZoom: 12.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sikunjung.app.sikunjung',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker Petugas (Biru dengan Lingkaran Animasi)
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 50,
                            height: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2563EB),
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Marker Kunjungan Pelanggan (Pin Merah Elegan)
                        ..._kunjunganList.map(
                          (item) => Marker(
                            point: LatLng(item.latitude, item.longitude),
                            width: 46,
                            height: 46,
                            child: GestureDetector(
                              onTap: () => _showCustomerSheet(item),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.place,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

          // Badge Jumlah Lokasi (Top Right)
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pin_drop, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Text(
                    '${_kunjunganList.length} Lokasi Terdata',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Offline Warning Banner
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber.shade900,
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peta tile online memerlukan internet. Marker GPS tetap ditampilkan.',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () async {
          final pos = await _locationService.getCurrentLocation();
          if (pos != null) {
            setState(() => _currentPosition = pos);
            _mapController.move(LatLng(pos.latitude, pos.longitude), 14.0);
          } else {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lokasi GPS tidak dapat diperoleh.')),
            );
          }
        },
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        tooltip: 'Pusatkan ke Posisi Saya',
        child: const Icon(Icons.my_location, size: 20),
      ),
    );
  }
}
