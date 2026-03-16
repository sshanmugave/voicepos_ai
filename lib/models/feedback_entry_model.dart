class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.customerName,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final String customerName;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FeedbackEntry.fromMap(Map<String, dynamic> map) {
    return FeedbackEntry(
      id: map['id'] as int,
      customerName: map['customer_name'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
