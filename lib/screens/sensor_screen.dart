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

  AccelerometerEvent? _accEvent;
  GyroscopeEvent? _gyroEvent;
  MagnetometerEvent? _magEvent;

  double _compassDegrees = 0.0;
  String _cardinalText = 'U (Utara)';
  int _shakeCount = 0;
  DateTime _lastShake = DateTime.now();

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    try {
      _accSub = _sensorService.accelerometerStream.listen((event) {
        if (!mounted) return;
        setState(() => _accEvent = event);

        // Deteksi guncangan interaktif
        final now = DateTime.now();
        if (now.difference(_lastShake).inMilliseconds > 800) {
          if (_sensorService.isShakeDetected(x: event.x, y: event.y, z: event.z, threshold: 13.0)) {
            _lastShake = now;
            setState(() => _shakeCount++);
          }
        }
      });
    } catch (_) {}

    try {
      _gyroSub = _sensorService.gyroscopeStream.listen((event) {
        if (!mounted) return;
        setState(() => _gyroEvent = event);
      });
    } catch (_) {}

    try {
      _magSub = _sensorService.magnetometerStream.listen((event) {
        if (!mounted) return;
        final deg = _sensorService.calculateHeadingDegrees(event.x, event.y);
        final cardinal = _sensorService.getCardinalDirection(deg);
        setState(() {
          _magEvent = event;
          _compassDegrees = deg;
          _cardinalText = cardinal;
        });
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor & Telemetri'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Digital Compass Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kompas Magnetik',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.explore, size: 14, color: Color(0xFFD97706)),
                            SizedBox(width: 4),
                            Text(
                              'Magnetometer',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Kompas Dial Visual
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 3),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 8,
                              child: Text(
                                'U',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              child: Text(
                                'S',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              child: Text(
                                'T',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              child: Text(
                                'B',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Jarum Kompas Halus
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: -_compassDegrees * (3.141592653589793 / 180),
                        ),
                        duration: const Duration(milliseconds: 200),
                        builder: (_, angle, child) {
                          return Transform.rotate(
                            angle: angle,
                            child: const Icon(
                              Icons.navigation,
                              size: 72,
                              color: Color(0xFFEA580C),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_compassDegrees.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    _cardinalText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Shake Detector Test Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.vibration, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deteksi Goyang (Shake)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF14532D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Goyangkan perangkat untuk menguji accelerometer',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      '$_shakeCount x',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Sensor Gauge List
            _buildSensorBarCard(
              title: 'Akselerometer (Percepatan Linier)',
              unit: 'm/s²',
              color: const Color(0xFF2563EB),
              x: _accEvent?.x ?? 0.0,
              y: _accEvent?.y ?? 0.0,
              z: _accEvent?.z ?? 0.0,
              maxRange: 20.0,
            ),
            const SizedBox(height: 14),

            _buildSensorBarCard(
              title: 'Giroskop (Kecepatan Sudut)',
              unit: 'rad/s',
              color: const Color(0xFF7C3AED),
              x: _gyroEvent?.x ?? 0.0,
              y: _gyroEvent?.y ?? 0.0,
              z: _gyroEvent?.z ?? 0.0,
              maxRange: 6.0,
            ),
            const SizedBox(height: 14),

            _buildSensorBarCard(
              title: 'Magnetometer (Kerapatan Fluks Magnet)',
              unit: 'µT',
              color: const Color(0xFF0D9488),
              x: _magEvent?.x ?? 0.0,
              y: _magEvent?.y ?? 0.0,
              z: _magEvent?.z ?? 0.0,
              maxRange: 120.0,
            ),
            const SizedBox(height: 24),

            // 4. Informasi Spesifikasi Teknis (Clean Collapsible Card)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Color(0xFF64748B)),
                      SizedBox(width: 8),
                      Text(
                        'Ringkasan Spesifikasi Sensor',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20),
                  Text(
                    '• Accelerometer: Rentang ±2g s.d ±16g, sampling rate 50-200 Hz. Mendeteksi gaya gravitasi bumi dan guncangan pengguna.\n'
                    '• Gyroscope: Rentang ±250 s.d ±2000 °/s, mengukur orientasi rotasi 3 dimensi.\n'
                    '• Magnetometer: Rentang ±4800 µT, mengukur intensitas medan geomagnetik untuk kompas digital.\n'
                    '• GNSS / GPS: Frekuensi L1/L5 satelit, estimasi koordinat desimal akurasi 3-10 m.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorBarCard({
    required String title,
    required String unit,
    required Color color,
    required double x,
    required double y,
    required double z,
    required double maxRange,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAxisBar('X', x, maxRange, color),
          const SizedBox(height: 8),
          _buildAxisBar('Y', y, maxRange, color),
          const SizedBox(height: 8),
          _buildAxisBar('Z', z, maxRange, color),
        ],
      ),
    );
  }

  Widget _buildAxisBar(String axis, double val, double maxRange, Color color) {
    final progress = ((val / maxRange) + 1.0) / 2.0;
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            axis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 65,
          child: Text(
            val.toStringAsFixed(2),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
