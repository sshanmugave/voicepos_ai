import '../models/business_type.dart';

class DemoSalesRow {
  const DemoSalesRow({
    required this.date,
    required this.item,
    required this.quantity,
    required this.price,
    required this.businessType,
  });

  final DateTime date;
  final String item;
  final int quantity;
  final double price;
  final BusinessType businessType;
}

class DemoDatasets {
  static List<DemoSalesRow> buildSalesData(BusinessType type) {
    final now = DateTime.now();
    final rows = <DemoSalesRow>[];
    final items = _itemsFor(type);
    for (var d = 0; d < 730; d++) {
      final day = now.subtract(Duration(days: d));
      for (var i = 0; i < items.length; i++) {
        final qty = ((i + 2) * ((day.weekday % 3) + 1) * (d % 5 + 1)) % 150 + 20;
        final price = 20 + (i * 15);
        rows.add(
          DemoSalesRow(
            date: DateTime(day.year, day.month, day.day),
            item: items[i],
            quantity: qty,
            price: price.toDouble(),
            businessType: type,
          ),
        );
      }
    }
    return rows;
  }

  static List<String> _itemsFor(BusinessType type) {
    switch (type) {
      case BusinessType.teaShop:
        return const ['Tea', 'Coffee', 'Samosa'];
      case BusinessType.restaurant:
        return const ['Biryani', 'Meals', 'Dosa'];
      case BusinessType.salon:
        return const ['Haircut', 'Shave', 'Facial'];
      case BusinessType.juiceShop:
        return const ['Orange Juice', 'Apple Juice', 'Milkshake'];
      case BusinessType.bakery:
        return const ['Buns', 'Bread', 'Cup Cake'];
      case BusinessType.streetVendor:
        return const ['Sundal', 'Pani Puri', 'Bajji'];
    }
  }
}
