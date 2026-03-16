import 'dart:math';

import 'package:sqflite/sqflite.dart';

/// Seeds one month of realistic South-Indian restaurant demo data.
/// Skips seeding if orders already exist (safe to call on every startup).
class MockDataSeeder {
  static Future<void> seed(Database db) async {
    // Skip if data already present
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM orders'),
        ) ??
        0;
    if (count > 0) return;

    final rng = Random(42);

    // ── Business Profile ──────────────────────────────────────────────────
    final existingProfile =
        await db.query('business_profile', limit: 1);
    if (existingProfile.isEmpty) {
      await db.insert('business_profile', {
        'shop_name': 'Sri Murugan Kadai',
        'owner_name': 'Murugan S',
        'gst_number': '33AABCS1429B1ZB',
        'phone': '9876543210',
        'address': '12, Main Street, Coimbatore - 641001',
        'logo_path': null,
      });
    }

    // ── Categories ────────────────────────────────────────────────────────
    final catIds = <String, int>{};
    final cats = {
      'Beverages': 'Hot & cold drinks',
      'Breakfast': 'Morning tiffin items',
      'Rice & Curries': 'Rice meals and curries',
      'Breads': 'Indian breads',
      'Snacks': 'Light snacks and bites',
      'Sweets': 'Desserts and sweets',
    };
    // Clear any minimal seed categories first
    await db.delete('categories');
    for (final e in cats.entries) {
      catIds[e.key] = await db.insert('categories', {
        'name': e.key,
        'description': e.value,
      });
    }

    // ── Products ──────────────────────────────────────────────────────────
    await db.delete('products');

    // {name, barcode, cat, buy, sell, gst, stock, unit, threshold, fav}
    final productDefs = [
      // Beverages
      _P('Tea', '100001', 'Beverages', 7, 10, 0, 500, 'cup', 50, fav: true),
      _P('Filter Coffee', '100002', 'Beverages', 10, 15, 0, 400, 'cup', 40,
          fav: true),
      _P('Masala Tea', '100003', 'Beverages', 10, 15, 0, 300, 'cup', 30),
      _P('Fresh Lime Soda', '100004', 'Beverages', 15, 25, 0, 200, 'glass', 20),
      _P('Buttermilk', '100005', 'Beverages', 8, 12, 0, 250, 'glass', 25),
      // Breakfast
      _P('Idli (2 pcs)', '200001', 'Breakfast', 12, 20, 5, 400, 'plate', 30,
          fav: true),
      _P('Plain Dosa', '200002', 'Breakfast', 15, 25, 5, 350, 'plate', 30,
          fav: true),
      _P('Masala Dosa', '200003', 'Breakfast', 22, 40, 5, 300, 'plate', 25,
          fav: true),
      _P('Medu Vada', '200004', 'Breakfast', 12, 20, 5, 300, 'plate', 25),
      _P('Pongal', '200005', 'Breakfast', 18, 30, 5, 200, 'plate', 20),
      _P('Upma', '200006', 'Breakfast', 15, 25, 5, 200, 'plate', 20),
      // Rice & Curries
      _P('Mini Meals', '300001', 'Rice & Curries', 60, 100, 5, 200, 'plate',
          20,
          fav: true),
      _P('Full Meals', '300002', 'Rice & Curries', 80, 130, 5, 150, 'plate',
          15),
      _P('Veg Fried Rice', '300003', 'Rice & Curries', 50, 80, 5, 150, 'plate',
          15),
      _P('Chicken Biryani', '300004', 'Rice & Curries', 100, 160, 5, 100,
          'plate', 10,
          fav: true),
      _P('Egg Biryani', '300005', 'Rice & Curries', 80, 130, 5, 100, 'plate',
          10),
      // Breads
      _P('Porota', '400001', 'Breads', 10, 15, 0, 300, 'pcs', 30, fav: true),
      _P('Chapati', '400002', 'Breads', 8, 12, 0, 250, 'pcs', 25),
      _P('Naan', '400003', 'Breads', 15, 25, 0, 200, 'pcs', 20),
      // Snacks
      _P('Samosa', '500001', 'Snacks', 10, 15, 0, 200, 'pcs', 20),
      _P('Mysore Bajji', '500002', 'Snacks', 8, 12, 0, 200, 'pcs', 20),
      _P('Bonda', '500003', 'Snacks', 8, 12, 0, 200, 'pcs', 20),
      // Sweets
      _P('Gulab Jamun', '600001', 'Sweets', 15, 25, 0, 150, 'pcs', 15),
      _P('Payasam', '600002', 'Sweets', 20, 35, 0, 100, 'cup', 10),
    ];

    final productIds = <String, int>{}; // name -> id
    final productInfo =
        <int, Map<String, dynamic>>{}; // id -> {sell, gst, buy, name}
    final createdAt = DateTime.now()
        .subtract(const Duration(days: 35))
        .toIso8601String();

    for (final p in productDefs) {
      final id = await db.insert('products', {
        'name': p.name,
        'barcode': p.barcode,
        'category_id': catIds[p.cat],
        'purchase_price': p.buy,
        'selling_price': p.sell,
        'gst_rate': p.gst,
        'stock_quantity': p.stock,
        'unit': p.unit,
        'low_stock_threshold': p.threshold,
        'is_favorite': p.fav ? 1 : 0,
        'created_at': createdAt,
      });
      productIds[p.name] = id;
      productInfo[id] = {
        'sell': p.sell.toDouble(),
        'gst': p.gst.toDouble(),
        'buy': p.buy.toDouble(),
        'name': p.name,
      };
    }

    // ── Customers ─────────────────────────────────────────────────────────
    final customerDefs = [
      {'name': 'Ravi Kumar', 'phone': '9876543210', 'credit': 350.0},
      {'name': 'Priya Devi', 'phone': '9123456789', 'credit': 180.0},
      {'name': 'Senthil M', 'phone': '9988776655', 'credit': 500.0},
      {'name': 'Kavitha S', 'phone': '9871234560', 'credit': 0.0},
      {'name': 'Arjun T', 'phone': '9765432101', 'credit': 250.0},
    ];
    final customerIds = <int>[];
    for (final c in customerDefs) {
      final id = await db.insert('customers', {
        'name': c['name'],
        'phone': c['phone'],
        'credit_balance': c['credit'],
        'created_at': createdAt,
      });
      customerIds.add(id);
    }

    // ── Expenses (over the past month) ────────────────────────────────────
    final today = DateTime.now();
    String day(int d) =>
        today.subtract(Duration(days: d)).toIso8601String();

    final expenseDefs = [
      {'cat': 'Stock Purchase', 'amt': 5000.0, 'desc': 'Weekly raw materials', 'date': day(29)},
      {'cat': 'Rent', 'amt': 12000.0, 'desc': 'Monthly shop rent', 'date': day(27)},
      {'cat': 'Electricity', 'amt': 2500.0, 'desc': 'Monthly electricity bill', 'date': day(25)},
      {'cat': 'Salary', 'amt': 8000.0, 'desc': 'Cook salary', 'date': day(23)},
      {'cat': 'Salary', 'amt': 7000.0, 'desc': 'Helper salary', 'date': day(23)},
      {'cat': 'Stock Purchase', 'amt': 4500.0, 'desc': 'Weekly raw materials', 'date': day(22)},
      {'cat': 'Maintenance', 'amt': 1200.0, 'desc': 'Kitchen equipment repair', 'date': day(18)},
      {'cat': 'Transport', 'amt': 800.0, 'desc': 'Vegetable delivery charges', 'date': day(16)},
      {'cat': 'Stock Purchase', 'amt': 5500.0, 'desc': 'Weekly raw materials', 'date': day(15)},
      {'cat': 'Stock Purchase', 'amt': 4800.0, 'desc': 'Weekly raw materials', 'date': day(8)},
      {'cat': 'Salary', 'amt': 8000.0, 'desc': 'Cook salary', 'date': day(7)},
      {'cat': 'Salary', 'amt': 7000.0, 'desc': 'Helper salary', 'date': day(7)},
      {'cat': 'Marketing', 'amt': 1500.0, 'desc': 'Pamphlet printing & distribution', 'date': day(5)},
      {'cat': 'Electricity', 'amt': 2800.0, 'desc': 'Advance electricity payment', 'date': day(1)},
    ];
    for (final e in expenseDefs) {
      await db.insert('expenses', {
        'category': e['cat'],
        'amount': e['amt'],
        'description': e['desc'],
        'created_at': e['date'],
      });
    }

    // ── Orders (30 days) ──────────────────────────────────────────────────
    final breakfastPool = [
      'Tea', 'Filter Coffee', 'Masala Tea',
      'Idli (2 pcs)', 'Plain Dosa', 'Masala Dosa',
      'Medu Vada', 'Pongal', 'Upma',
    ];
    final lunchPool = [
      'Mini Meals', 'Full Meals', 'Veg Fried Rice',
      'Chicken Biryani', 'Egg Biryani', 'Porota',
      'Filter Coffee', 'Buttermilk',
    ];
    final snackPool = [
      'Tea', 'Filter Coffee', 'Masala Tea',
      'Samosa', 'Mysore Bajji', 'Bonda',
    ];
    final dinnerPool = [
      'Porota', 'Chapati', 'Naan',
      'Chicken Biryani', 'Egg Biryani', 'Veg Fried Rice',
      'Filter Coffee', 'Tea',
    ];

    // Payment distribution: heavily cash, some UPI, tiny card/credit
    final payModes = [
      'cash', 'cash', 'cash', 'cash', 'cash',
      'upi', 'upi', 'upi',
      'card',
      'credit',
    ];

    int invoiceSeq = 0;

    for (int dayOffset = 29; dayOffset >= 0; dayOffset--) {
      final orderDate = today.subtract(Duration(days: dayOffset));
      final isWeekend = orderDate.weekday == DateTime.saturday ||
          orderDate.weekday == DateTime.sunday;
      final dailyOrderCount =
          isWeekend ? rng.nextInt(15) + 25 : rng.nextInt(10) + 15;

      for (int o = 0; o < dailyOrderCount; o++) {
        invoiceSeq++;
        final d = orderDate;
        final dateStr =
            '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
        final invoiceNumber =
            'INV-$dateStr-${invoiceSeq.toString().padLeft(4, '0')}';

        // Time slot: 0=breakfast 1=lunch 2=snack 3=dinner
        final slot = rng.nextInt(4);
        final List<String> pool;
        final int hour;
        switch (slot) {
          case 0:
            pool = breakfastPool;
            hour = 7 + rng.nextInt(3);
          case 1:
            pool = lunchPool;
            hour = 11 + rng.nextInt(3);
          case 2:
            pool = snackPool;
            hour = 15 + rng.nextInt(3);
          default:
            pool = dinnerPool;
            hour = 18 + rng.nextInt(3);
        }
        final minute = rng.nextInt(60);
        final orderTime = DateTime(
            d.year, d.month, d.day, hour, minute);

        // Pick 2-4 unique items
        final shuffled = List<String>.from(pool)..shuffle(rng);
        final numItems = rng.nextInt(3) + 2;
        final chosenItems = shuffled.take(numItems).toList();

        // Payment mode
        final payMode = payModes[rng.nextInt(payModes.length)];

        // Customer (sometimes registered, always walk-in for non-credit)
        int? customerId;
        if (payMode == 'credit') {
          customerId = customerIds[rng.nextInt(customerIds.length)];
        } else if (rng.nextInt(6) == 0) {
          customerId = customerIds[rng.nextInt(customerIds.length)];
        }

        // Build order items
        double subtotal = 0;
        double taxTotal = 0;
        final itemRows = <Map<String, dynamic>>[];

        for (final name in chosenItems) {
          final pId = productIds[name];
          if (pId == null) continue;
          final info = productInfo[pId]!;
          final qty = rng.nextInt(3) + 1;
          final sell = info['sell'] as double;
          final gst = info['gst'] as double;
          final buy = info['buy'] as double;
          final lineTotal = sell * qty;
          final itemGst = lineTotal * gst / 100;
          subtotal += lineTotal;
          taxTotal += itemGst;
          itemRows.add({
            'product_id': pId,
            'product_name': name,
            'unit_price': sell,
            'purchase_cost': buy,
            'quantity': qty,
            'discount_percent': 0.0,
            'discount_amount': 0.0,
            'gst_rate': gst,
            'gst_amount': itemGst,
            'subtotal': lineTotal + itemGst,
          });
        }

        if (itemRows.isEmpty) continue;

        final grandTotal = subtotal + taxTotal;
        final orderId = await db.insert('orders', {
          'invoice_number': invoiceNumber,
          'customer_id': customerId,
          'subtotal': subtotal,
          'discount_amount': 0.0,
          'tax_amount': taxTotal,
          'grand_total': grandTotal,
          'payment_mode': payMode,
          'payment_status': 'paid',
          'notes': '',
          'created_at': orderTime.toIso8601String(),
        });

        for (final item in itemRows) {
          await db.insert('order_items', {'order_id': orderId, ...item});
        }
      }
    }
  }
}

/// Small data holder to keep product definitions readable.
class _P {
  const _P(
    this.name,
    this.barcode,
    this.cat,
    this.buy,
    this.sell,
    this.gst,
    this.stock,
    this.unit,
    this.threshold, {
    this.fav = false,
  });

  final String name;
  final String barcode;
  final String cat;
  final num buy;
  final num sell;
  final num gst;
  final num stock;
  final String unit;
  final num threshold;
  final bool fav;
}
