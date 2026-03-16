class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.phone,
    required this.password,
    required this.createdAt,
  });

  final int id;
  final String? email;
  final String? phone;
  final String password;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'password': password,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      password: map['password'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
