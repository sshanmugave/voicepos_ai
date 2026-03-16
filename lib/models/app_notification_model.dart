class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      isRead: (map['is_read'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
