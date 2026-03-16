import '../models/order_model.dart';

class PriceCalculator {
  static double subtotalFromItems(Iterable<OrderItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  static double totalDiscountFromItems(Iterable<OrderItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.discountAmount);
  }

  static double totalGstFromItems(Iterable<OrderItem> items) {
    return items.fold<double>(0, (sum, item) => sum + item.gstAmount);
  }

  static double grandTotalFromItems(Iterable<OrderItem> items, {double billDiscount = 0}) {
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal) - billDiscount;
    return total < 0 ? 0 : total;
  }

  static int quantityFromItems(Iterable<OrderItem> items) {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  static String mostSoldItemName(Iterable<OrderModel> orders) {
    final counts = <String, int>{};
    for (final order in orders) {
      for (final item in order.items) {
        counts.update(item.name, (value) => value + item.quantity,
            ifAbsent: () => item.quantity);
      }
    }

    if (counts.isEmpty) {
      return 'No sales yet';
    }

    final bestEntry = counts.entries.reduce(
      (current, next) => current.value >= next.value ? current : next,
    );
    return '${bestEntry.key} (${bestEntry.value})';
  }
}