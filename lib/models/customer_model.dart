class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.creditBalance = 0,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String phone;
  final double creditBalance;
  final DateTime createdAt;

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    double? creditBalance,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      creditBalance: creditBalance ?? this.creditBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'credit_balance': creditBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      creditBalance: (map['credit_balance'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
