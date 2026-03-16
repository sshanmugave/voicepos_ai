import '../models/order_model.dart';
import '../models/product_model.dart';

class _CartItem {
  _CartItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  int quantity;
  double discountPercent = 0;

  OrderItem toOrderItem() {
    return OrderItem(
      productId: product.id,
      name: product.name,
      unitPrice: product.sellingPrice,
      quantity: quantity,
      discountPercent: discountPercent,
      gstRate: product.gstRate,
    );
  }
}

class BillingService {
  List<Product> _products = [];
  final Map<int, _CartItem> _cart = {};
  double _billDiscountAmount = 0;

  void setProducts(List<Product> products) {
    _products = List<Product>.from(products);
  }

  List<Product> get products => List<Product>.unmodifiable(_products);

  // ─── Cart Operations ───

  void addProduct(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;
    final existing = _cart[product.id];
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _cart[product.id] = _CartItem(product: product, quantity: quantity);
    }
  }

  void removeProduct(int productId) {
    _cart.remove(productId);
  }

  void incrementQuantity(int productId) {
    final item = _cart[productId];
    if (item != null) {
      item.quantity++;
    }
  }

  void decrementQuantity(int productId) {
    final item = _cart[productId];
    if (item == null) return;
    if (item.quantity <= 1) {
      _cart.remove(productId);
    } else {
      item.quantity--;
    }
  }

  void setQuantity(int productId, int quantity) {
    final item = _cart[productId];
    if (item == null) return;
    if (quantity <= 0) {
      _cart.remove(productId);
    } else {
      item.quantity = quantity;
    }
  }

  void setItemDiscount(int productId, double percent) {
    final item = _cart[productId];
    if (item != null) {
      item.discountPercent = percent.clamp(0, 100);
    }
  }

  void setBillDiscount(double amount) {
    _billDiscountAmount = amount.clamp(0, double.infinity);
  }

  double get billDiscountAmount => _billDiscountAmount;

  void clearDraft() {
    _cart.clear();
    _billDiscountAmount = 0;
  }

  // ─── Cart Getters ───

  bool get hasDraft => _cart.isNotEmpty;

  List<OrderItem> get draftItems {
    final items = _cart.values.map((c) => c.toOrderItem()).toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  int get totalItemCount =>
      _cart.values.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Sum of (unitPrice * quantity) for all items
  double get subtotal {
    return _cart.values.fold<double>(
      0,
      (sum, item) => sum + (item.product.sellingPrice * item.quantity),
    );
  }

  /// Sum of item-level discounts
  double get itemDiscountTotal {
    return _cart.values.fold<double>(0, (sum, item) {
      final lineTotal = item.product.sellingPrice * item.quantity;
      return sum + (lineTotal * item.discountPercent / 100);
    });
  }

  /// Sum of GST on (taxable amount = lineTotal - itemDiscount) for each item
  double get taxAmount {
    return _cart.values.fold<double>(0, (sum, item) {
      final lineTotal = item.product.sellingPrice * item.quantity;
      final taxable = lineTotal - (lineTotal * item.discountPercent / 100);
      return sum + (taxable * item.product.gstRate / 100);
    });
  }

  /// Grand total = subtotal - itemDiscounts + GST - billDiscount
  double get grandTotal {
    final gt = subtotal - itemDiscountTotal + taxAmount - _billDiscountAmount;
    return gt < 0 ? 0 : gt;
  }

  // ─── Build Order ───

  OrderModel buildOrder({
    required String invoiceNumber,
    required PaymentMode paymentMode,
    int? customerId,
    String? customerName,
    String notes = '',
  }) {
    final items = draftItems;
    return OrderModel(
      id: 0, // Will be assigned by DB
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      items: items,
      subtotal: subtotal,
      discountAmount: itemDiscountTotal + _billDiscountAmount,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
      paymentMode: paymentMode,
      paymentStatus: paymentMode == PaymentMode.credit ? 'pending' : 'paid',
      notes: notes,
      createdAt: DateTime.now(),
    );
  }
}