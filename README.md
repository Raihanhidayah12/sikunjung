# SiKunjung - Sistem Informasi Kunjungan Lapangan

Aplikasi Mobile Berbasis Flutter untuk Pencatatan Kunjungan Lapangan, Pemetaan Pelanggan, dan Pelaporan Real-Time.

Proyek ini disusun dan disesuaikan untuk memenuhi seluruh **7 Unit Standar Kompetensi Kerja Nasional Indonesia (SKKNI)** Skema Sertifikasi **Junior Mobile Programmer (SKK-017-07/2024)** oleh Badan Nasional Sertifikasi Profesi (BNSP).

---

## 📱 Ringkasan Fitur & Pemenuhan Unit SKKNI

| No | Kode Unit | Judul Unit Kompetensi | Implementasi pada SiKunjung |
|---|---|---|---|
| 1 | **J.612000.001.01** | Mengembangkan Aplikasi Mobile Menggunakan Bahasa Pemrograman Tertentu | Menggunakan Flutter SDK (Stable 3.44.6) & Dart 3.12.2, clean architecture (`models`, `database`, `services`, `screens`, `widgets`), terintegrasi Android SDK (API 21 - API 35) & halaman Info Perangkat. |
| 2 | **J.612000.003.01** | Mengembangkan Basis Data pada Perangkat Mobile | Database lokal SQLite (`sqflite`), tabel `kunjungan` (8 kolom) & `users` (3 kolom), parameterized query aman SQLi, serta `shared_preferences` untuk pengaturan akun. |
| 3 | **J.612000.006.01** | Mengembangkan Fitur LBS pada Perangkat Mobile | GPS GNSS presisi tinggi (`geolocator`), Peta interaktif OpenStreetMap (`flutter_map`), kalkulasi jarak geodesik Haversine/Vincenty, dan intent rute Google Maps (`url_launcher`). |
| 4 | **J.612000.007.01** | Mengembangkan Antarmuka Pengguna (UI) pada Mobile | Desain modern Material 3, responsif terhadap berbagai ukuran layar, transisi `IndexedStack` tanpa jeda, dialog konfirmasi modal & SnackBar interaktif. |
| 5 | **J.612000.008.01** | Menerapkan Keamanan pada Perangkat Mobile | Kriptografi hash SHA-256 (`crypto`) satu arah untuk kata sandi, Android Hardware Keystore (`flutter_secure_storage`) untuk token sesi, sanitasi regex input, dan logout instan. |
| 6 | **J.612000.022.01** | Mengakses Sensor pada Perangkat Mobile | Integrasi sensor gerak (`sensors_plus`): Accelerometer, Gyroscope, Magnetometer, kompas digital real-time dengan rumus `atan2(y, x)`, dan gesture Shake-to-Refresh (>14 m/s²). |
| 7 | **J.612000.025.01** | Memanfaatkan Jaringan Seluler pada Mobile | Monitoring status koneksi real-time (`connectivity_plus`), arsitektur Offline-First (tetap berfungsi tanpa koneksi internet), dan analisis komparasi generasi seluler (2G/3G/4G/5G). |

---

## 🛠️ Struktur Direktori Proyek

```
sikunjung/
├── android/                  # Konfigurasi native Android (Gradle, Manifest, Permissions)
├── assets/                   # Aset gambar & database awal (seeds)
├── lib/
│   ├── database/             # SQLite DatabaseHelper (CRUD, Schema, Migration)
│   ├── models/               # Data Transfer Objects: Kunjungan, User
│   ├── screens/              # UI Screens (Splash, Login, Dashboard, Form, Peta, Sensor, dll)
│   ├── services/             # Logic Services (Auth, Location, Sensor, Network, Prefs)
│   ├── widgets/              # Reusable UI Components (Cards, OfflineBanner, dll)
│   └── main.dart             # Application Entrypoint & Material 3 Theme Configuration
├── pubspec.yaml              # Dependensi paket Flutter
└── README.md
```

---

## 🔑 Kredensial Pengujian (Demo)

- **Akun Petugas Lapangan:**
  - Username: `petugas`
  - Password: `petugas123`
- **Akun Administrator:**
  - Username: `admin`
  - Password: `admin123`

---

## 🚀 Cara Menjalankan Aplikasi

1. Pastikan Flutter SDK dan Android SDK sudah terpasang:
   ```bash
   flutter doctor
   ```
2. Jalankan aplikasi pada perangkat Android atau Android Emulator:
   ```bash
   flutter run
   ```
3. Melakukan build file instalasi APK rilis:
   ```bash
   flutter build apk --release
   ```
   *File APK rilis biner akan tercipta di `build/app/outputs/flutter-apk/app-release.apk`.*
