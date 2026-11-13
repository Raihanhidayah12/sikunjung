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

  // Titik default (Monas Jakarta) jika GPS belum didapatkan
  static const LatLng _defaultCenter = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
    _checkNetworkAndLoad();
  }

  Future<void> _checkNetworkAndLoad() async {
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
        _mapController.move(LatLng(data.first.latitude, data.first.longitude), 12.0);
      }
    }
  }

  void _showMarkerDetails(Kunjungan k) {
    String distanceText = 'Menghitung...';
    if (_currentPosition != null) {
      final meters = _locationService.calculateDistanceInMeters(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        k.latitude,
        k.longitude,
      );
      distanceText = _locationService.formatDistance(meters);
    } else {
      distanceText = 'Posisi Anda belum terbaca';
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.store, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.namaPelanggan,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tanggal: ${k.tanggal}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      distanceText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(k.alamat, maxLines: 2, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(k.noHp),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KunjunganDetailScreen(kunjungan: k),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Detail'),
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
                      icon: const Icon(Icons.navigation),
                      label: const Text('Navigasi'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
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
        title: const Text('Peta Sebaran Kunjungan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui Peta',
            onPressed: _checkNetworkAndLoad,
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
                            : _defaultCenter),
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sikunjung.app.sikunjung',
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker Petugas (Biru)
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lokasi Petugas Saat Ini'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_pin_circle,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Marker Kunjungan Pelanggan (Merah)
                        ..._kunjunganList.map(
                          (item) => Marker(
                            point: LatLng(item.latitude, item.longitude),
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => _showMarkerDetails(item),
                              child: Tooltip(
                                message: item.namaPelanggan,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 26,
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

          // Peringatan Offline pada Peta jika internet mati
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode Offline: Peta OpenStreetMap memerlukan internet untuk unduh tile, namun titik marker tetap tampil.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Info Jumlah Marker
          Positioned(
            top: _isOffline ? 48 : 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pin_drop, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    '${_kunjunganList.length} Lokasi',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'my_loc',
            tooltip: 'Pusatkan ke Lokasi Saya',
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
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
