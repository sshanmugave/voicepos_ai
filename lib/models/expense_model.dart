class ExpenseCategory {
  static const rent = 'Rent';
  static const salary = 'Salary';
  static const electricity = 'Electricity';
  static const purchase = 'Stock Purchase';
  static const maintenance = 'Maintenance';
  static const transport = 'Transport';
  static const marketing = 'Marketing';
  static const other = 'Other';

  static const all = [
    rent,
    salary,
    electricity,
    purchase,
    maintenance,
    transport,
    marketing,
    other,
  ];
}

class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  final int id;
  final String category;
  final double amount;
  final String description;
  final DateTime createdAt;

  Expense copyWith({
    int? id,
    String? category,
    double? amount,
    String? description,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: (map['description'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
