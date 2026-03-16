enum PaymentMode { cash, upi, card, credit }

extension PaymentModeLabel on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.credit:
        return 'Credit';
    }
  }

  String get storageValue => name;

  static PaymentMode fromValue(String value) {
    switch (value) {
      case 'upi':
        return PaymentMode.upi;
      case 'card':
        return PaymentMode.card;
      case 'credit':
        return PaymentMode.credit;
      case 'online':
        return PaymentMode.upi;
      default:
        return PaymentMode.cash;
    }
  }
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.discountPercent = 0,
    this.gstRate = 0,
  });

  final int productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final double discountPercent;
  final double gstRate;

  double get lineTotal => unitPrice * quantity;
  double get discountAmount => lineTotal * discountPercent / 100;
  double get taxableAmount => lineTotal - discountAmount;
  double get gstAmount => taxableAmount * gstRate / 100;
  double get subtotal => taxableAmount + gstAmount;

  OrderItem copyWith({
    int? productId,
    String? name,
    double? unitPrice,
    int? quantity,
    double? discountPercent,
    double? gstRate,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      discountPercent: discountPercent ?? this.discountPercent,
      gstRate: gstRate ?? this.gstRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': name,
      'unit_price': unitPrice,
      'quantity': quantity,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      'gst_rate': gstRate,
      'gst_amount': gstAmount,
      'subtotal': subtotal,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['product_id'] as int,
      name: (map['product_name'] ?? map['name']) as String,
      unitPrice: (map['unit_price'] ?? map['unitPrice'] as num).toDouble(),
      quantity: map['quantity'] as int,
      discountPercent: (map['discount_percent'] as num?)?.toDouble() ?? 0,
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotal,
    this.discountAmount = 0,
    required this.taxAmount,
    required this.grandTotal,
    required this.paymentMode,
    this.paymentStatus = 'paid',
    this.notes = '',
    required this.createdAt,
  });

  final int id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final List<OrderItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;
  final PaymentMode paymentMode;
  final String paymentStatus;
  final String notes;
  final DateTime createdAt;

  int get totalQuantity => items.fold<int>(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'payment_mode': paymentMode.storageValue,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, List<OrderItem> items) {
    return OrderModel(
      id: map['id'] as int,
      invoiceNumber: (map['invoice_number'] ?? '') as String,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String?,
      items: items,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      grandTotal: (map['grand_total'] ?? map['total'] as num).toDouble(),
      paymentMode: PaymentModeLabel.fromValue(
        (map['payment_mode'] ?? map['paymentMode'] ?? 'cash') as String,
      ),
      paymentStatus: (map['payment_status'] as String?) ?? 'paid',
      notes: (map['notes'] as String?) ?? '',
      createdAt: DateTime.parse((map['created_at'] ?? map['createdAt']) as String),
    );
  }

  String toBillText(String shopName) {
    final buffer = StringBuffer()
      ..writeln('═══════════════════════════')
      ..writeln('  $shopName')
      ..writeln('  Invoice: $invoiceNumber')
      ..writeln('═══════════════════════════')
      ..writeln();

    for (final item in items) {
      buffer.writeln('${item.quantity}x ${item.name}  ₹${item.subtotal.toStringAsFixed(2)}');
    }

    buffer
      ..writeln()
      ..writeln('───────────────────────────')
      ..writeln('Subtotal:  ₹${subtotal.toStringAsFixed(2)}');

    if (discountAmount > 0) {
      buffer.writeln('Discount:  -₹${discountAmount.toStringAsFixed(2)}');
    }

    if (taxAmount > 0) {
      buffer.writeln('GST:       ₹${taxAmount.toStringAsFixed(2)}');
    }

    buffer
      ..writeln('Grand Total: ₹${grandTotal.toStringAsFixed(2)}')
      ..writeln('───────────────────────────')
      ..writeln('Payment: ${paymentMode.label}');

    if (customerName != null && customerName!.isNotEmpty) {
      buffer.writeln('Customer: $customerName');
    }

    if (notes.trim().isNotEmpty) {
      buffer.writeln('Notes: $notes');
    }

    buffer
      ..writeln()
      ..writeln('Thank you for your business!');

    return buffer.toString();
  }
}