import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  /// Stream data Accelerometer (satuan: m/s²)
  Stream<AccelerometerEvent> get accelerometerStream => accelerometerEventStream();

  /// Stream data Gyroscope (satuan: rad/s)
  Stream<GyroscopeEvent> get gyroscopeStream => gyroscopeEventStream();

  /// Stream data Magnetometer (satuan: µT - microTesla)
  Stream<MagnetometerEvent> get magnetometerStream => magnetometerEventStream();

  /// Menghitung arah kompas dalam derajat (0 - 360°) dari nilai Magnetometer
  double calculateHeadingDegrees(double x, double y) {
    // Heading = atan2(y, x) dalam radian
    double headingRad = math.atan2(y, x);
    double headingDeg = headingRad * (180 / math.pi);

    // Normalisasi rentang sudut ke 0 - 360°
    if (headingDeg < 0) {
      headingDeg += 360;
    }
    return headingDeg;
  }

  /// Menentukan nama arah mata angin dalam Bahasa Indonesia
  String getCardinalDirection(double degrees) {
    if (degrees >= 337.5 || degrees < 22.5) return 'U (Utara)';
    if (degrees >= 22.5 && degrees < 67.5) return 'TL (Timur Laut)';
    if (degrees >= 67.5 && degrees < 112.5) return 'T (Timur)';
    if (degrees >= 112.5 && degrees < 157.5) return 'TG (Tenggara)';
    if (degrees >= 157.5 && degrees < 202.5) return 'S (Selatan)';
    if (degrees >= 202.5 && degrees < 247.5) return 'BD (Barat Daya)';
    if (degrees >= 247.5 && degrees < 292.5) return 'B (Barat)';
    if (degrees >= 292.5 && degrees < 337.5) return 'BL (Barat Laut)';
    return 'U (Utara)';
  }

  /// Algoritma deteksi getaran/guncangan (Shake Detection) untuk fitur Shake to Refresh
  /// Threshold standar ~13 - 15 m/s² (melebihi gravitasi bumi 9.8 m/s²)
  bool isShakeDetected({
    required double x,
    required double y,
    required double z,
    double threshold = 15.0,
  }) {
    // Hitung magnitude vektor percepatan total dikurangi gravitasi bumi
    final magnitude = math.sqrt(x * x + y * y + z * z);
    final netAcceleration = (magnitude - 9.80665).abs();
    return netAcceleration > threshold;
  }
}
