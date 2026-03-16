class B2BProduct {
  const B2BProduct({
    required this.id,
    required this.businessType,
    required this.name,
    required this.supplierName,
    required this.unit,
    required this.price,
  });

  final int id;
  final String businessType;
  final String name;
  final String supplierName;
  final String unit;
  final double price;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_type': businessType,
      'name': name,
      'supplier_name': supplierName,
      'unit': unit,
      'price': price,
    };
  }

  factory B2BProduct.fromMap(Map<String, dynamic> map) {
    return B2BProduct(
      id: map['id'] as int,
      businessType: map['business_type'] as String,
      name: map['name'] as String,
      supplierName: map['supplier_name'] as String,
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }
}
