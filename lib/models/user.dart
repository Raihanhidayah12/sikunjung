class User {
  final int? id;
  final String username;
  final String passwordHash;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'username': username,
      'password_hash': passwordHash,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: (map['username'] ?? '') as String,
      passwordHash: (map['password_hash'] ?? '') as String,
    );
  }
}
