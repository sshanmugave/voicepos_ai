class SalonVisit {
  const SalonVisit({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.service,
    required this.createdAt,
  });

  final int id;
  final int customerId;
  final String customerName;
  final String service;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'service': service,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SalonVisit.fromMap(Map<String, dynamic> map) {
    return SalonVisit(
      id: map['id'] as int,
      customerId: map['customer_id'] as int,
      customerName: map['customer_name'] as String,
      service: map['service'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
