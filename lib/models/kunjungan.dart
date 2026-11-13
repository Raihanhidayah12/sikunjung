class Kunjungan {
  final int? id;
  final String namaPelanggan;
  final String alamat;
  final String noHp;
  final String catatan;
  final double latitude;
  final double longitude;
  final String tanggal;

  Kunjungan({
    this.id,
    required this.namaPelanggan,
    required this.alamat,
    required this.noHp,
    required this.catatan,
    required this.latitude,
    required this.longitude,
    required this.tanggal,
  });

  /// Convert Model ke Map untuk disimpan di SQLite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nama_pelanggan': namaPelanggan,
      'alamat': alamat,
      'no_hp': noHp,
      'catatan': catatan,
      'latitude': latitude,
      'longitude': longitude,
      'tanggal': tanggal,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Factory untuk membuat Model Kunjungan dari Map SQLite
  factory Kunjungan.fromMap(Map<String, dynamic> map) {
    return Kunjungan(
      id: map['id'] as int?,
      namaPelanggan: (map['nama_pelanggan'] ?? '') as String,
      alamat: (map['alamat'] ?? '') as String,
      noHp: (map['no_hp'] ?? '') as String,
      catatan: (map['catatan'] ?? '') as String,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      tanggal: (map['tanggal'] ?? '') as String,
    );
  }

  Kunjungan copyWith({
    int? id,
    String? namaPelanggan,
    String? alamat,
    String? noHp,
    String? catatan,
    double? latitude,
    double? longitude,
    String? tanggal,
  }) {
    return Kunjungan(
      id: id ?? this.id,
      namaPelanggan: namaPelanggan ?? this.namaPelanggan,
      alamat: alamat ?? this.alamat,
      noHp: noHp ?? this.noHp,
      catatan: catatan ?? this.catatan,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tanggal: tanggal ?? this.tanggal,
    );
  }
}
