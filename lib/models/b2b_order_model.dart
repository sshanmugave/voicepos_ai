class B2BOrder {
  const B2BOrder({
    required this.id,
    required this.productId,
    required this.productName,
    required this.supplierName,
    required this.quantity,
    required this.unitPrice,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final String productName;
  final String supplierName;
  final double quantity;
  final double unitPrice;
  final String status;
  final DateTime createdAt;

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'supplier_name': supplierName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory B2BOrder.fromMap(Map<String, dynamic> map) {
    return B2BOrder(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      supplierName: map['supplier_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
