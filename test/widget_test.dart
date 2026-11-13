import 'package:flutter_test/flutter_test.dart';
import 'package:sikunjung/models/kunjungan.dart';
import 'package:sikunjung/models/user.dart';
import 'package:sikunjung/services/auth_service.dart';

void main() {
  group('Unit 2: Model & Database Data Persistence Tests', () {
    test('Kunjungan toMap and fromMap should correctly serialize and deserialize', () {
      final kunjungan = Kunjungan(
        id: 1,
        namaPelanggan: 'PT Maju Bersama',
        alamat: 'Jl. Merdeka No. 10',
        noHp: '081234567890',
        catatan: 'Survey lapangan',
        latitude: -6.200000,
        longitude: 106.816666,
        tanggal: '2026-11-13',
      );

      final map = kunjungan.toMap();
      expect(map['nama_pelanggan'], 'PT Maju Bersama');
      expect(map['latitude'], -6.200000);
      expect(map['longitude'], 106.816666);

      final fromMap = Kunjungan.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.namaPelanggan, 'PT Maju Bersama');
      expect(fromMap.noHp, '081234567890');
    });

    test('User model toMap and fromMap validation', () {
      final user = User(
        id: 1,
        username: 'petugas',
        passwordHash: 'hash_test_123',
      );

      final map = user.toMap();
      expect(map['username'], 'petugas');
      expect(map['password_hash'], 'hash_test_123');

      final fromMap = User.fromMap(map);
      expect(fromMap.username, 'petugas');
      expect(fromMap.passwordHash, 'hash_test_123');
    });
  });

  group('Unit 5: Mobile Security SHA-256 Tests', () {
    test('Password hashing with SHA-256 should be deterministic and not plain text', () {
      final authService = AuthService();
      const plainPassword = 'admin123';
      final hash = authService.hashPassword(plainPassword);

      expect(hash, isNot(equals(plainPassword)));
      expect(hash.length, 64); // Panjang hash SHA-256 adalah 64 karakter hex
      expect(authService.hashPassword(plainPassword), hash);
    });
  });
}
