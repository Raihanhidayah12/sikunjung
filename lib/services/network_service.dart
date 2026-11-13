import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Stream perubahan konektivitas jaringan secara real-time
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Memeriksa status konektivitas saat ini
  Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      return [ConnectivityResult.none];
    }
  }

  /// Cek apakah perangkat memiliki koneksi internet aktif (WiFi, Seluler, Ethernet, atau VPN)
  bool isConnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);
  }

  /// Deskripsi ramah pengguna mengenai jenis koneksi
  String getConnectionTypeName(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return 'Tidak Ada Koneksi (Offline)';
    }
    if (results.contains(ConnectivityResult.wifi)) {
      return 'Koneksi Wi-Fi';
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return 'Jaringan Seluler (Mobile Data)';
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return 'Koneksi Ethernet LAN';
    }
    if (results.contains(ConnectivityResult.vpn)) {
      return 'Koneksi Virtual Private Network (VPN)';
    }
    return 'Terhubung (${results.first.name})';
  }
}
