import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../services/auth_service.dart';
import '../services/network_service.dart';
import '../widgets/offline_banner.dart';
import '../widgets/stat_card.dart';
import 'kunjungan_list_screen.dart';
import 'kunjungan_form_screen.dart';
import 'peta_screen.dart';
import 'sensor_screen.dart';
import 'network_screen.dart';
import 'device_info_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dbHelper = DatabaseHelper();
  final _authService = AuthService();
  final _networkService = NetworkService();

  int _currentIndex = 0;
  String _currentUsername = 'Petugas';
  int _totalKunjungan = 0;
  int _kunjunganHariIni = 0;

  bool _isOffline = false;
  String _networkType = 'Memeriksa...';
  StreamSubscription<List<ConnectivityResult>>? _networkSub;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initNetworkMonitoring();
  }

  void _initNetworkMonitoring() {
    _networkService.checkConnectivity().then((results) {
      if (mounted) {
        setState(() {
          _isOffline = !_networkService.isConnected(results);
          _networkType = _networkService.getConnectionTypeName(results);
        });
      }
    });

    _networkSub = _networkService.onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOffline = !_networkService.isConnected(results);
          _networkType = _networkService.getConnectionTypeName(results);
        });
      }
    });
  }

  Future<void> _loadDashboardData() async {
    final username = await _authService.getCurrentUsername();
    final total = await _dbHelper.getTotalKunjunganCount();
    final hariIni = await _dbHelper.getKunjunganHariIniCount();

    if (mounted) {
      setState(() {
        _currentUsername = username ?? 'Petugas';
        _totalKunjungan = total;
        _kunjunganHariIni = hariIni;
      });
    }
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout, color: Colors.orange, size: 40),
        title: const Text('Konfirmasi Logout'),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Sesi login terenkripsi di Flutter Secure Storage akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showSecurityModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.indigo, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Dasar Keamanan Mobile (J.612000.008.01)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Penerapan Keamanan pada Aplikasi SiKunjung:\n\n'
                    '1. Penyimpanan Kredensial Terenkripsi:\n'
                    '   • Password tidak pernah disimpan dalam plain text, melainkan di-hash satu arah menggunakan algoritma SHA-256 (package crypto).\n'
                    '   • Token sesi disimpan di KeyStore Android / Keychain iOS melalui flutter_secure_storage yang terenkripsi hardware-level AES.\n\n'
                    '2. Pencegahan SQL Injection:\n'
                    '   • Seluruh operasi query database SQLite menggunakan parameterized queries (? placeholder dengan whereArgs).\n'
                    '   • Tidak menggunakan string concatenation mentah.\n\n'
                    '3. Validasi Input Berlapis:\n'
                    '   • Form login dan kunjungan divalidasi tipe data, panjang string, dan format regex nomor telepon.\n\n'
                    '4. Prinsip Least Privilege (Hak Akses Minimal):\n'
                    '   • Aplikasi hanya meminta izin runtime (Fine/Coarse Location) saat fitur GPS dibutuhkan, menggunakan permission_handler.\n\n'
                    '5. Mitigasi Ancaman Keamanan Mobile Standar OWASP:\n'
                    '   • Insecure Data Storage: Dimitigasi dengan hash SHA-256 dan flutter_secure_storage.\n'
                    '   • Insecure Communication: Menggunakan HTTPS TLS untuk pengunduhan peta.\n'
                    '   • Insufficient Session Expiration: Sesi otomatis dibersihkan saat tombol Logout ditekan.',
                    style: TextStyle(fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHomeView() {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Offline
            OfflineBanner(isOffline: _isOffline),

            // Header Sambutan
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $_currentUsername 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Petugas Lapangan SiKunjung',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status Bar Strip (Jaringan & GPS)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isOffline ? Icons.wifi_off : Icons.wifi,
                              size: 16,
                              color: _isOffline ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _networkType,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isOffline ? Colors.red : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              'GPS Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stat Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Kunjungan',
                      value: '$_totalKunjungan',
                      icon: Icons.assignment_turned_in,
                      color: Colors.indigo,
                      onTap: () {
                        setState(() => _currentIndex = 1);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Kunjungan Hari Ini',
                      value: '$_kunjunganHariIni',
                      icon: Icons.today,
                      color: Colors.teal,
                      onTap: () {
                        setState(() => _currentIndex = 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Grid Menu Utama
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Menu Utama Aplikasi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.list_alt,
                    title: 'Daftar Kunjungan',
                    subtitle: 'Lihat, cari, & kelola',
                    color: Colors.blue,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KunjunganListScreen()),
                      );
                      _loadDashboardData();
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.add_location_alt,
                    title: 'Catat Kunjungan',
                    subtitle: 'Input baru + GPS',
                    color: Colors.green,
                    onTap: () async {
                      final added = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const KunjunganFormScreen()),
                      );
                      if (added == true) _loadDashboardData();
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.map_outlined,
                    title: 'Peta Lokasi',
                    subtitle: 'Sebaran & Navigasi',
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PetaScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.sensors,
                    title: 'Sensor Perangkat',
                    subtitle: 'Kompas & Akselerometer',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SensorScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.signal_cellular_alt,
                    title: 'Status Jaringan',
                    subtitle: 'Deteksi Wi-Fi & Seluler',
                    color: Colors.amber.shade900,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NetworkScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.smartphone,
                    title: 'Info Perangkat',
                    subtitle: 'OS, Versi & Spesifikasi',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DeviceInfoScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Shortcut Security Explanation untuk Asesor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 1,
                color: Colors.indigo.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.shield, color: Colors.white),
                  ),
                  title: const Text(
                    'Informasi Keamanan Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Enkripsi SHA-256, Secure Storage & SQL Injection Prevention',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _showSecurityModal,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeView(),
      const KunjunganListScreen(),
      const PetaScreen(),
      const SensorScreen(),
      const DeviceInfoScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SiKunjung',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Keamanan Mobile',
            onPressed: _showSecurityModal,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            _loadDashboardData();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Kunjungan',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Sensor',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Info',
          ),
        ],
      ),
    );
  }
}
