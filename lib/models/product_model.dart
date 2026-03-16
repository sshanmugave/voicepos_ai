class Product {
  const Product({
    required this.id,
    required this.name,
    this.barcode,
    this.categoryId,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.gstRate,
    required this.stockQuantity,
    required this.unit,
    required this.lowStockThreshold,
    this.isFavorite = false,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? barcode;
  final int? categoryId;
  final double purchasePrice;
  final double sellingPrice;
  final double gstRate;
  final double stockQuantity;
  final String unit;
  final double lowStockThreshold;
  final bool isFavorite;
  final DateTime createdAt;

  bool get isLowStock => stockQuantity <= lowStockThreshold;

  double get gstAmount => sellingPrice * gstRate / 100;

  double get priceWithGst => sellingPrice + gstAmount;

  /// Profit margin per unit (selling - purchase)
  double get profitPerUnit => sellingPrice - purchasePrice;

  /// Profit margin percentage
  double get profitMarginPercent =>
      purchasePrice > 0 ? (profitPerUnit / purchasePrice) * 100 : 0;

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    int? categoryId,
    double? purchasePrice,
    double? sellingPrice,
    double? gstRate,
    double? stockQuantity,
    String? unit,
    double? lowStockThreshold,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      gstRate: gstRate ?? this.gstRate,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category_id': categoryId,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'gst_rate': gstRate,
      'stock_quantity': stockQuantity,
      'unit': unit,
      'low_stock_threshold': lowStockThreshold,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      categoryId: map['category_id'] as int?,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      gstRate: (map['gst_rate'] as num).toDouble(),
      stockQuantity: (map['stock_quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      lowStockThreshold: (map['low_stock_threshold'] as num).toDouble(),
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
