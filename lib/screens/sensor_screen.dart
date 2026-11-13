import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/sensor_service.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final _sensorService = SensorService();

  // Nilai Sensor
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  MagnetometerEvent? _magnetometerEvent;

  double _compassHeading = 0.0;
  String _cardinalDirection = 'U (Utara)';

  // Error/Availability state
  bool _accAvailable = true;
  bool _gyroAvailable = true;
  bool _magAvailable = true;

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  @override
  void initState() {
    super.initState();
    _startListeningSensors();
  }

  void _startListeningSensors() {
    try {
      _accSub = _sensorService.accelerometerStream.listen(
        (event) {
          if (mounted) setState(() => _accelerometerEvent = event);
        },
        onError: (_) {
          if (mounted) setState(() => _accAvailable = false);
        },
      );
    } catch (_) {
      setState(() => _accAvailable = false);
    }

    try {
      _gyroSub = _sensorService.gyroscopeStream.listen(
        (event) {
          if (mounted) setState(() => _gyroEvent = event);
        },
        onError: (_) {
          if (mounted) setState(() => _gyroAvailable = false);
        },
      );
    } catch (_) {
      setState(() => _gyroAvailable = false);
    }

    try {
      _magSub = _sensorService.magnetometerStream.listen(
        (event) {
          final heading = _sensorService.calculateHeadingDegrees(event.x, event.y);
          final cardinal = _sensorService.getCardinalDirection(heading);
          if (mounted) {
            setState(() {
              _magnetometerEvent = event;
              _compassHeading = heading;
              _cardinalDirection = cardinal;
            });
          }
        },
        onError: (_) {
          if (mounted) setState(() => _magAvailable = false);
        },
      );
    } catch (_) {
      setState(() => _magAvailable = false);
    }
  }

  set _gyroEvent(GyroscopeEvent event) => _gyroscopeEvent = event;

  @override
  void dispose() {
    _accSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }

  Widget _buildAxisProgress(String axis, double value, double maxVal, Color color, String unit) {
    final clamped = (value / maxVal).clamp(-1.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              axis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (clamped + 1.0) / 2.0,
                color: color,
                backgroundColor: Colors.grey.shade200,
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              '${value.toStringAsFixed(2)} $unit',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Perangkat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. KOMPAS DIGITAL DARI MAGNETOMETER
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.explore, color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        Text(
                          'Kompas Digital (Magnetometer)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.deepOrange.shade200, width: 3),
                            gradient: RadialGradient(
                              colors: [Colors.orange.shade50, Colors.white],
                            ),
                          ),
                        ),
                        // Jarum Kompas Berputar Sesuai Heading
                        Transform.rotate(
                          angle: (_compassHeading * (3.141592653589793 / 180) * -1),
                          child: const Icon(
                            Icons.navigation,
                            size: 80,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_compassHeading.toStringAsFixed(1)}°',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    Text(
                      _cardinalDirection,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dihitung dengan rumus atan2(y, x) dari sensor Magnetometer.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. ACCELEROMETER
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
                        const Icon(Icons.speed, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Accelerometer (Percepatan)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Satuan: m/s² (Meter per detik kuadrat)',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    if (!_accAvailable)
                      const Text('Sensor Accelerometer tidak terdeteksi pada perangkat ini.',
                          style: TextStyle(color: Colors.red))
                    else if (_accelerometerEvent == null)
                      const Text('Menunggu data accelerometer...')
                    else ...[
                      _buildAxisProgress('X', _accelerometerEvent!.x, 20.0, Colors.red, 'm/s²'),
                      _buildAxisProgress('Y', _accelerometerEvent!.y, 20.0, Colors.green, 'm/s²'),
                      _buildAxisProgress('Z', _accelerometerEvent!.z, 20.0, Colors.blue, 'm/s²'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. GYROSCOPE
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
                        const Icon(Icons.rotate_right, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          'Gyroscope (Kecepatan Sudut)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Satuan: rad/s (Radian per detik)',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    if (!_gyroAvailable)
                      const Text('Sensor Gyroscope tidak terdeteksi pada perangkat ini.',
                          style: TextStyle(color: Colors.red))
                    else if (_gyroscopeEvent == null)
                      const Text('Menunggu data gyroscope...')
                    else ...[
                      _buildAxisProgress('X', _gyroscopeEvent!.x, 5.0, Colors.red, 'rad/s'),
                      _buildAxisProgress('Y', _gyroscopeEvent!.y, 5.0, Colors.green, 'rad/s'),
                      _buildAxisProgress('Z', _gyroscopeEvent!.z, 5.0, Colors.purple, 'rad/s'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. MAGNETOMETER
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
                        const Icon(Icons.waves, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'Magnetometer (Medan Magnet)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Satuan: µT (MicroTesla)',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    if (!_magAvailable)
                      const Text('Sensor Magnetometer tidak terdeteksi pada perangkat ini.',
                          style: TextStyle(color: Colors.red))
                    else if (_magnetometerEvent == null)
                      const Text('Menunggu data magnetometer...')
                    else ...[
                      _buildAxisProgress('X', _magnetometerEvent!.x, 100.0, Colors.red, 'µT'),
                      _buildAxisProgress('Y', _magnetometerEvent!.y, 100.0, Colors.green, 'µT'),
                      _buildAxisProgress('Z', _magnetometerEvent!.z, 100.0, Colors.teal, 'µT'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. SPESIFIKASI TEKNIS SENSOR UNTUK ASESOR
            Card(
              elevation: 1,
              color: Colors.blueGrey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book, color: Colors.blueGrey.shade800),
                        const SizedBox(width: 8),
                        Text(
                          'Penjelasan Teknis Sensor (Standar BNSP)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text(
                      '1. Accelerometer:\n'
                      '   • Fungsi: Mengukur percepatan linier termasuk gaya gravitasi pada 3 sumbu.\n'
                      '   • Satuan: m/s².\n'
                      '   • Sampling Rate: 50-200 Hz, Rentang ukur: ±2g hingga ±16g.\n'
                      '   • Penerapan: Deteksi orientasi layar, langkah kaki, dan Shake-to-Refresh.\n\n'
                      '2. Gyroscope:\n'
                      '   • Fungsi: Mengukur kecepatan sudut rotasi perangkat.\n'
                      '   • Satuan: rad/s (radian/detik) atau °/s.\n'
                      '   • Penerapan: Stabilisasi kamera, game gerak, navigasi inersia.\n\n'
                      '3. Magnetometer:\n'
                      '   • Fungsi: Mengukur intensitas dan arah medan magnet bumi.\n'
                      '   • Satuan: µT (MicroTesla).\n'
                      '   • Penerapan: Kompas digital dan kalibrasi arah navigasi peta.\n\n'
                      '4. GPS (Global Positioning System):\n'
                      '   • Fungsi: Sensor penentu koordinat global dari sinyal satelit GNSS.\n'
                      '   • Satuan: Derajat desimal latitude & longitude.\n'
                      '   • Akurasi: 3 - 15 meter tergantung kondisi cuaca dan visibilitas langit.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
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
