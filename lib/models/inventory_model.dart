class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
  });

  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double lowStockThreshold;

  bool get isLow => quantity <= lowStockThreshold;

  InventoryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    double? lowStockThreshold,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      lowStockThreshold: (map['lowStockThreshold'] as num).toDouble(),
    );
  }
}