import '../models/business_type.dart';

class TemplateItem {
  const TemplateItem({
    required this.name,
    required this.category,
    required this.price,
    this.purchasePrice = 0,
    this.gstRate = 0,
    this.unit = 'pcs',
    this.stock = 100,
    this.lowStockThreshold = 10,
  });

  final String name;
  final String category;
  final double price;
  final double purchasePrice;
  final double gstRate;
  final String unit;
  final double stock;
  final double lowStockThreshold;
}

class BusinessTemplates {
  static List<TemplateItem> forType(BusinessType type) {
    switch (type) {
      case BusinessType.teaShop:
        return const [
          TemplateItem(name: 'Tea', category: 'Beverages', price: 12, unit: 'cup'),
          TemplateItem(name: 'Coffee', category: 'Beverages', price: 18, unit: 'cup'),
          TemplateItem(name: 'Vada', category: 'Snacks', price: 15),
          TemplateItem(name: 'Samosa', category: 'Snacks', price: 20),
          TemplateItem(name: 'Bun Butter Jam', category: 'Snacks', price: 30),
        ];
      case BusinessType.restaurant:
        return const [
          TemplateItem(name: 'Idli (2 pcs)', category: 'Breakfast', price: 30),
          TemplateItem(name: 'Dosa', category: 'Breakfast', price: 45),
          TemplateItem(name: 'Meals', category: 'Main Course', price: 120),
          TemplateItem(name: 'Biryani', category: 'Main Course', price: 180),
          TemplateItem(name: 'Parotta', category: 'Tiffin', price: 25),
        ];
      case BusinessType.salon:
        return const [
          TemplateItem(name: 'Haircut', category: 'Services', price: 150, unit: 'service'),
          TemplateItem(name: 'Shave', category: 'Services', price: 80, unit: 'service'),
          TemplateItem(name: 'Facial', category: 'Services', price: 500, unit: 'service'),
          TemplateItem(name: 'Hair Spa', category: 'Services', price: 700, unit: 'service'),
          TemplateItem(name: 'Beard Trim', category: 'Services', price: 120, unit: 'service'),
        ];
      case BusinessType.juiceShop:
        return const [
          TemplateItem(name: 'Orange Juice', category: 'Juices', price: 70, unit: 'glass'),
          TemplateItem(name: 'Apple Juice', category: 'Juices', price: 90, unit: 'glass'),
          TemplateItem(name: 'Milkshake', category: 'Shakes', price: 120, unit: 'glass'),
          TemplateItem(name: 'Watermelon Juice', category: 'Juices', price: 60, unit: 'glass'),
          TemplateItem(name: 'Mojito', category: 'Coolers', price: 80, unit: 'glass'),
        ];
      case BusinessType.bakery:
        return const [
          TemplateItem(name: 'Puff', category: 'Snacks', price: 25),
          TemplateItem(name: 'Cup Cake', category: 'Cakes', price: 40),
          TemplateItem(name: 'Bread Loaf', category: 'Breads', price: 45),
          TemplateItem(name: 'Cookies Pack', category: 'Biscuits', price: 60),
          TemplateItem(name: 'Black Forest Slice', category: 'Cakes', price: 90),
        ];
      case BusinessType.streetVendor:
        return const [
          TemplateItem(name: 'Sundal', category: 'Snacks', price: 30),
          TemplateItem(name: 'Pani Puri', category: 'Fast Food', price: 40),
          TemplateItem(name: 'Corn Cup', category: 'Snacks', price: 50),
          TemplateItem(name: 'Bajji', category: 'Snacks', price: 20),
          TemplateItem(name: 'Lemon Soda', category: 'Beverages', price: 30),
        ];
    }
  }
}
