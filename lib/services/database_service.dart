import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/business_profile_model.dart';
import '../models/business_type.dart';
import '../models/app_notification_model.dart';
import '../models/app_user_model.dart';
import '../models/b2b_order_model.dart';
import '../models/b2b_product_model.dart';
import '../models/category_model.dart';
import '../models/customer_model.dart';
import '../models/expense_model.dart';
import '../models/feedback_entry_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/salon_visit_model.dart';
import '../utils/business_templates.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'voicepos_ai.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add expenses table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');
      // Add is_favorite column to products
      await db.execute(
        'ALTER TABLE products ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
      );
      // Add purchase_cost to order_items for profit tracking
      await db.execute(
        'ALTER TABLE order_items ADD COLUMN purchase_cost REAL DEFAULT 0',
      );
    }

    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE business_profile ADD COLUMN business_type TEXT NOT NULL DEFAULT "restaurant"',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS salon_visits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          customer_name TEXT NOT NULL,
          service TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id)
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_salon_visits_customer_id ON salon_visits (customer_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_salon_visits_created_at ON salon_visits (created_at)',
      );
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT,
          phone TEXT,
          password TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS b2b_products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          business_type TEXT NOT NULL,
          name TEXT NOT NULL,
          supplier_name TEXT NOT NULL,
          unit TEXT NOT NULL,
          price REAL NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS b2b_orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          supplier_name TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit_price REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'requested',
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS feedback_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_name TEXT NOT NULL,
          message TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await _seedB2BProducts(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE business_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL,
        business_type TEXT NOT NULL DEFAULT 'restaurant',
        owner_name TEXT DEFAULT '',
        gst_number TEXT DEFAULT '',
        phone TEXT DEFAULT '',
        address TEXT DEFAULT '',
        logo_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        category_id INTEGER,
        purchase_price REAL NOT NULL DEFAULT 0,
        selling_price REAL NOT NULL,
        gst_rate REAL NOT NULL DEFAULT 0,
        stock_quantity REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'pcs',
        low_stock_threshold REAL NOT NULL DEFAULT 5,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        credit_balance REAL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL,
        customer_id INTEGER,
        subtotal REAL NOT NULL DEFAULT 0,
        discount_amount REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        grand_total REAL NOT NULL,
        payment_mode TEXT NOT NULL DEFAULT 'cash',
        payment_status TEXT NOT NULL DEFAULT 'paid',
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        purchase_cost REAL DEFAULT 0,
        quantity INTEGER NOT NULL,
        discount_percent REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        gst_rate REAL DEFAULT 0,
        gst_amount REAL DEFAULT 0,
        subtotal REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE salon_visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        service TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        change_type TEXT NOT NULL,
        quantity_change REAL NOT NULL,
        balance_after REAL NOT NULL,
        reference_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE app_users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT,
        phone TEXT,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE b2b_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        business_type TEXT NOT NULL,
        name TEXT NOT NULL,
        supplier_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE b2b_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        supplier_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'requested',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE feedback_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_products_barcode ON products (barcode)',
    );
    await db.execute(
      'CREATE INDEX idx_orders_created_at ON orders (created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_order_items_order_id ON order_items (order_id)',
    );
    await db.execute(
      'CREATE INDEX idx_salon_visits_customer_id ON salon_visits (customer_id)',
    );
    await db.execute(
      'CREATE INDEX idx_inventory_log_product ON inventory_log (product_id)',
    );

    await _seedB2BProducts(db);

  }

  Future<void> _seedB2BProducts(Database db) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM b2b_products'),
        ) ??
        0;
    if (count > 0) return;

    final items = <Map<String, Object>>[
      {'business_type': 'teaShop', 'name': 'Tea Powder', 'supplier_name': 'Tea Market Co', 'unit': 'kg', 'price': 350.0},
      {'business_type': 'teaShop', 'name': 'Milk', 'supplier_name': 'Fresh Dairy Ltd', 'unit': 'L', 'price': 60.0},
      {'business_type': 'teaShop', 'name': 'Sugar', 'supplier_name': 'Sweet Bulk Mart', 'unit': 'kg', 'price': 48.0},
      {'business_type': 'restaurant', 'name': 'Rice', 'supplier_name': 'Agro Supply Hub', 'unit': 'kg', 'price': 56.0},
      {'business_type': 'restaurant', 'name': 'Cooking Oil', 'supplier_name': 'Kitchen Essentials', 'unit': 'L', 'price': 150.0},
      {'business_type': 'restaurant', 'name': 'Spices', 'supplier_name': 'Masala Bazaar', 'unit': 'kg', 'price': 420.0},
      {'business_type': 'salon', 'name': 'Shampoo', 'supplier_name': 'SalonPro Distributors', 'unit': 'bottle', 'price': 220.0},
      {'business_type': 'salon', 'name': 'Razor Blades', 'supplier_name': 'Grooming Supply Co', 'unit': 'pack', 'price': 95.0},
      {'business_type': 'juiceShop', 'name': 'Mango', 'supplier_name': 'Fresh Farms', 'unit': 'kg', 'price': 110.0},
      {'business_type': 'juiceShop', 'name': 'Ice Cubes', 'supplier_name': 'CoolIce Depot', 'unit': 'kg', 'price': 18.0},
      {'business_type': 'bakery', 'name': 'Flour', 'supplier_name': 'BakeRaw Traders', 'unit': 'kg', 'price': 52.0},
      {'business_type': 'bakery', 'name': 'Yeast', 'supplier_name': 'BakeRaw Traders', 'unit': 'pack', 'price': 85.0},
      {'business_type': 'streetVendor', 'name': 'Packaging Cups', 'supplier_name': 'StreetPack India', 'unit': 'bundle', 'price': 140.0},
      {'business_type': 'streetVendor', 'name': 'Snacks Mix', 'supplier_name': 'StreetPack India', 'unit': 'kg', 'price': 210.0},
    ];

    for (final item in items) {
      await db.insert('b2b_products', item);
    }
  }

  // ─── Business Profile ───

  Future<BusinessProfile?> getBusinessProfile() async {
    final db = await database;
    final rows = await db.query('business_profile', limit: 1);
    if (rows.isEmpty) return null;
    return BusinessProfile.fromMap(rows.first);
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    final db = await database;
    final existing = await db.query('business_profile', limit: 1);
    if (existing.isEmpty) {
      await db.insert('business_profile', {
        'shop_name': profile.shopName,
        'business_type': profile.businessType.storageValue,
        'owner_name': profile.ownerName,
        'gst_number': profile.gstNumber,
        'phone': profile.phone,
        'address': profile.address,
        'logo_path': profile.logoPath,
      });
    } else {
      await db.update(
        'business_profile',
        {
          'shop_name': profile.shopName,
          'business_type': profile.businessType.storageValue,
          'owner_name': profile.ownerName,
          'gst_number': profile.gstNumber,
          'phone': profile.phone,
          'address': profile.address,
          'logo_path': profile.logoPath,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<bool> hasBusinessData() async {
    final db = await database;
    final products = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;
    final orders = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM orders'),
        ) ??
        0;
    final customers = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM customers'),
        ) ??
        0;
    return products > 0 || orders > 0 || customers > 0;
  }

  Future<void> clearBusinessData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('order_items');
      await txn.delete('orders');
      await txn.delete('inventory_log');
      await txn.delete('expenses');
      await txn.delete('salon_visits');
      await txn.delete('customers');
      await txn.delete('products');
      await txn.delete('categories');
    });
  }

  // ─── App Users / Auth ───

  Future<AppUser?> getUserById(int userId) async {
    final db = await database;
    final rows = await db.query(
      'app_users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<int> registerUser({
    String? email,
    String? phone,
    required String password,
  }) async {
    final db = await database;

    if ((email ?? '').trim().isNotEmpty) {
      final existing = await db.query(
        'app_users',
        where: 'LOWER(email) = ?',
        whereArgs: [email!.trim().toLowerCase()],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw Exception('Email already registered');
      }
    }

    if ((phone ?? '').trim().isNotEmpty) {
      final normalized = phone!.trim();
      final existing = await db.query(
        'app_users',
        where: 'phone = ?',
        whereArgs: [normalized],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw Exception('Phone already registered');
      }
    }

    return db.insert('app_users', {
      'email': (email ?? '').trim().isEmpty ? null : email!.trim().toLowerCase(),
      'phone': (phone ?? '').trim().isEmpty ? null : phone!.trim(),
      'password': password,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<AppUser?> authenticateUser({
    required String identifier,
    required String password,
  }) async {
    final db = await database;
    final id = identifier.trim();
    final rows = await db.query(
      'app_users',
      where: 'LOWER(email) = ? OR phone = ?',
      whereArgs: [id.toLowerCase(), id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final user = AppUser.fromMap(rows.first);
    if (user.password != password) return null;
    return user;
  }

  // ─── B2B Marketplace ───

  Future<List<B2BProduct>> getB2BProducts({String? businessType}) async {
    final db = await database;
    final rows = await db.query(
      'b2b_products',
      where: businessType != null ? 'business_type = ?' : null,
      whereArgs: businessType != null ? [businessType] : null,
      orderBy: 'name ASC',
    );
    return rows.map(B2BProduct.fromMap).toList();
  }

  Future<int> insertB2BOrder({
    required int productId,
    required String productName,
    required String supplierName,
    required double quantity,
    required double unitPrice,
    String status = 'requested',
  }) async {
    final db = await database;
    return db.insert('b2b_orders', {
      'product_id': productId,
      'product_name': productName,
      'supplier_name': supplierName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<B2BOrder>> getB2BOrders({int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      'b2b_orders',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(B2BOrder.fromMap).toList();
  }

  Future<void> updateB2BOrderStatus(int orderId, String status) async {
    final db = await database;
    await db.update(
      'b2b_orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // ─── Notifications ───

  Future<int> insertNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final db = await database;
    return db.insert('app_notifications', {
      'title': title,
      'message': message,
      'type': type,
      'is_read': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AppNotification>> getNotifications({int limit = 300}) async {
    final db = await database;
    final rows = await db.query(
      'app_notifications',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> markNotificationRead(int id) async {
    final db = await database;
    await db.update(
      'app_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearNotifications() async {
    final db = await database;
    await db.delete('app_notifications');
  }

  // ─── Feedback ───

  Future<int> insertFeedback({
    required String customerName,
    required String message,
  }) async {
    final db = await database;
    return db.insert('feedback_entries', {
      'customer_name': customerName,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<FeedbackEntry>> getFeedbackEntries({int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      'feedback_entries',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(FeedbackEntry.fromMap).toList();
  }

  // ─── Categories ───

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(String name, {String description = ''}) async {
    final db = await database;
    return db.insert('categories', {
      'name': name,
      'description': description,
    });
  }

  Future<void> updateCategory(int id, String name) async {
    final db = await database;
    await db.update(
      'categories',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    // Unlink any products that belong to this category
    await db.update(
      'products',
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [id],
    );
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Products ───

  Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    final map = product.toMap();
    map.remove('id');
    return db.insert('products', map);
  }

  Future<void> seedBusinessTemplateItems(BusinessType type) async {
    final db = await database;
    final existingProducts = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;
    if (existingProducts > 0) return;

    final templates = BusinessTemplates.forType(type);
    final now = DateTime.now().toIso8601String();
    final categoryIds = <String, int>{};

    await db.transaction((txn) async {
      for (final item in templates) {
        if (!categoryIds.containsKey(item.category)) {
          final existingCategory = await txn.query(
            'categories',
            columns: ['id'],
            where: 'name = ?',
            whereArgs: [item.category],
            limit: 1,
          );
          if (existingCategory.isNotEmpty) {
            categoryIds[item.category] = existingCategory.first['id'] as int;
          } else {
            categoryIds[item.category] = await txn.insert('categories', {
              'name': item.category,
              'description': '${type.label} default category',
            });
          }
        }

        await txn.insert('products', {
          'name': item.name,
          'barcode': null,
          'category_id': categoryIds[item.category],
          'purchase_price': item.purchasePrice,
          'selling_price': item.price,
          'gst_rate': item.gstRate,
          'stock_quantity': item.stock,
          'unit': item.unit,
          'low_stock_threshold': item.lowStockThreshold,
          'is_favorite': 1,
          'created_at': now,
        });
      }
    });
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> updateProductStock(int productId, double newQuantity) async {
    final db = await database;
    await db.update(
      'products',
      {'stock_quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT * FROM products WHERE stock_quantity <= low_stock_threshold ORDER BY stock_quantity ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  // ─── Customers ───

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final rows = await db.query('customers', orderBy: 'name ASC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    final map = customer.toMap();
    map.remove('id');
    return db.insert('customers', map);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    final map = customer.toMap();
    map.remove('created_at');
    await db.update(
      'customers',
      map,
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> insertSalonVisit({
    required int customerId,
    required String customerName,
    required String service,
  }) async {
    final db = await database;
    return db.insert('salon_visits', {
      'customer_id': customerId,
      'customer_name': customerName,
      'service': service,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<SalonVisit>> getSalonVisits({int? customerId, int limit = 200}) async {
    final db = await database;
    final rows = await db.query(
      'salon_visits',
      where: customerId != null ? 'customer_id = ?' : null,
      whereArgs: customerId != null ? [customerId] : null,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(SalonVisit.fromMap).toList();
  }

  Future<void> updateCustomerCredit(int customerId, double newBalance) async {
    final db = await database;
    await db.update(
      'customers',
      {'credit_balance': newBalance},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  // ─── Orders ───

  Future<int> insertOrder(OrderModel order) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final orderId = await txn.insert('orders', {
        'invoice_number': order.invoiceNumber,
        'customer_id': order.customerId,
        'subtotal': order.subtotal,
        'discount_amount': order.discountAmount,
        'tax_amount': order.taxAmount,
        'grand_total': order.grandTotal,
        'payment_mode': order.paymentMode.storageValue,
        'payment_status': order.paymentStatus,
        'notes': order.notes,
        'created_at': order.createdAt.toIso8601String(),
      });

      for (final item in order.items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': item.productId,
          'product_name': item.name,
          'unit_price': item.unitPrice,
          'quantity': item.quantity,
          'discount_percent': item.discountPercent,
          'discount_amount': item.discountAmount,
          'gst_rate': item.gstRate,
          'gst_amount': item.gstAmount,
          'subtotal': item.subtotal,
        });

        // Deduct stock
        await txn.rawUpdate(
          'UPDATE products SET stock_quantity = MAX(0, stock_quantity - ?) WHERE id = ?',
          [item.quantity, item.productId],
        );

        // Get updated stock for log
        final stockRows = await txn.query(
          'products',
          columns: ['stock_quantity'],
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        final balanceAfter = stockRows.isNotEmpty
            ? (stockRows.first['stock_quantity'] as num).toDouble()
            : 0.0;

        await txn.insert('inventory_log', {
          'product_id': item.productId,
          'change_type': 'sale',
          'quantity_change': -item.quantity.toDouble(),
          'balance_after': balanceAfter,
          'reference_id': order.invoiceNumber,
          'created_at': order.createdAt.toIso8601String(),
        });
      }

      return orderId;
    });
  }

  Future<List<OrderModel>> getOrders({int limit = 100}) async {
    final db = await database;
    final orderRows = await db.query(
      'orders',
      orderBy: 'created_at DESC',
      limit: limit,
    );

    final orders = <OrderModel>[];
    for (final orderMap in orderRows) {
      final orderId = orderMap['id'] as int;
      final itemRows = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemRows.map(OrderItem.fromMap).toList();

      // Get customer name if exists
      String? customerName;
      final customerId = orderMap['customer_id'] as int?;
      if (customerId != null) {
        final cRows = await db.query(
          'customers',
          columns: ['name'],
          where: 'id = ?',
          whereArgs: [customerId],
          limit: 1,
        );
        if (cRows.isNotEmpty) {
          customerName = cRows.first['name'] as String;
        }
      }

      final mutableMap = Map<String, dynamic>.from(orderMap);
      mutableMap['customer_name'] = customerName;
      orders.add(OrderModel.fromMap(mutableMap, items));
    }

    return orders;
  }

  Future<List<OrderModel>> getTodayOrders() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final tomorrowStart = DateTime(now.year, now.month, now.day + 1).toIso8601String();

    final orderRows = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [todayStart, tomorrowStart],
      orderBy: 'created_at DESC',
    );

    final orders = <OrderModel>[];
    for (final orderMap in orderRows) {
      final orderId = orderMap['id'] as int;
      final itemRows = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemRows.map(OrderItem.fromMap).toList();
      orders.add(OrderModel.fromMap(orderMap, items));
    }

    return orders;
  }

  Future<int> getOrderCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final count = await getOrderCount();
    final seq = (count + 1).toString().padLeft(3, '0');
    return 'INV-$dateStr-$seq';
  }

  // ─── Inventory Log ───

  Future<void> insertInventoryLog({
    required int productId,
    required String changeType,
    required double quantityChange,
    required double balanceAfter,
    String? referenceId,
  }) async {
    final db = await database;
    await db.insert('inventory_log', {
      'product_id': productId,
      'change_type': changeType,
      'quantity_change': quantityChange,
      'balance_after': balanceAfter,
      'reference_id': referenceId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> restockProduct(int productId, double amount) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
        [amount, productId],
      );

      final rows = await txn.query(
        'products',
        columns: ['stock_quantity'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      final balanceAfter =
          rows.isNotEmpty ? (rows.first['stock_quantity'] as num).toDouble() : 0.0;

      await txn.insert('inventory_log', {
        'product_id': productId,
        'change_type': 'restock',
        'quantity_change': amount,
        'balance_after': balanceAfter,
        'reference_id': null,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // ─── Favorites ───

  Future<void> toggleFavorite(int productId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'products',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<List<Product>> getFavoriteProducts() async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'is_favorite = 1',
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  // ─── Expenses ───

  Future<List<Expense>> getExpenses({int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'expenses',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getTodayExpenses() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final tomorrowStart = DateTime(now.year, now.month, now.day + 1).toIso8601String();

    final rows = await db.query(
      'expenses',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [todayStart, tomorrowStart],
      orderBy: 'created_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final map = expense.toMap();
    map.remove('id');
    return db.insert('expenses', map);
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Profit Analytics ───

  Future<Map<String, double>> getProfitSummary({DateTime? from, DateTime? to}) async {
    final db = await database;
    
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (from != null && to != null) {
      whereClause = 'o.created_at >= ? AND o.created_at < ?';
      whereArgs = [from.toIso8601String(), to.toIso8601String()];
    }

    final query = '''
      SELECT 
        SUM(oi.subtotal) as total_revenue,
        SUM(oi.purchase_cost * oi.quantity) as total_cost,
        SUM(oi.quantity) as total_units
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      ${whereClause != null ? 'WHERE $whereClause' : ''}
    ''';

    final rows = await db.rawQuery(query, whereArgs);
    
    if (rows.isEmpty) {
      return {'revenue': 0, 'cost': 0, 'profit': 0, 'units': 0};
    }

    final revenue = (rows.first['total_revenue'] as num?)?.toDouble() ?? 0;
    final cost = (rows.first['total_cost'] as num?)?.toDouble() ?? 0;
    final units = (rows.first['total_units'] as num?)?.toDouble() ?? 0;

    return {
      'revenue': revenue,
      'cost': cost,
      'profit': revenue - cost,
      'units': units,
    };
  }

  // ─── Orders with Date Filtering ───

  Future<List<OrderModel>> getOrdersByDateRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;
    final orderRows = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'created_at DESC',
    );

    final orders = <OrderModel>[];
    for (final orderMap in orderRows) {
      final orderId = orderMap['id'] as int;
      final itemRows = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      final items = itemRows.map(OrderItem.fromMap).toList();

      String? customerName;
      final customerId = orderMap['customer_id'] as int?;
      if (customerId != null) {
        final cRows = await db.query(
          'customers',
          columns: ['name'],
          where: 'id = ?',
          whereArgs: [customerId],
          limit: 1,
        );
        if (cRows.isNotEmpty) {
          customerName = cRows.first['name'] as String;
        }
      }

      final mutableMap = Map<String, dynamic>.from(orderMap);
      mutableMap['customer_name'] = customerName;
      orders.add(OrderModel.fromMap(mutableMap, items));
    }

    return orders;
  }

  // ─── Frequently Bought Together ───

  Future<Map<String, List<String>>> getFrequentlyBoughtTogether() async {
    final db = await database;
    
    // Get order items with their order IDs
    final rows = await db.rawQuery('''
      SELECT order_id, product_name FROM order_items
      ORDER BY order_id
    ''');

    // Group products by order
    final orderProducts = <int, List<String>>{};
    for (final row in rows) {
      final orderId = row['order_id'] as int;
      final productName = row['product_name'] as String;
      orderProducts.putIfAbsent(orderId, () => []).add(productName);
    }

    // Count co-occurrences
    final coOccurrence = <String, Map<String, int>>{};
    for (final products in orderProducts.values) {
      if (products.length < 2) continue;
      for (int i = 0; i < products.length; i++) {
        for (int j = 0; j < products.length; j++) {
          if (i != j) {
            coOccurrence.putIfAbsent(products[i], () => {});
            coOccurrence[products[i]]!.update(
              products[j],
              (v) => v + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }
    }

    // Get top 3 co-purchased products for each product
    final result = <String, List<String>>{};
    for (final entry in coOccurrence.entries) {
      final sorted = entry.value.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      result[entry.key] = sorted.take(3).map((e) => e.key).toList();
    }

    return result;
  }

  // ─── Data Export ───

  Future<String> exportOrdersToCSV({DateTime? from, DateTime? to}) async {
    final orders = from != null && to != null
        ? await getOrdersByDateRange(from: from, to: to)
        : await getOrders(limit: 10000);

    final buffer = StringBuffer();
    buffer.writeln('Invoice,Date,Customer,Items,Subtotal,Discount,Tax,Grand Total,Payment Mode,Status');

    for (final order in orders) {
      final itemNames = order.items.map((i) => '${i.quantity}x ${i.name}').join('; ');
      buffer.writeln(
        '${order.invoiceNumber},'
        '${order.createdAt.toIso8601String()},'
        '${order.customerName ?? "Walk-in"},'
        '"$itemNames",'
        '${order.subtotal.toStringAsFixed(2)},'
        '${order.discountAmount.toStringAsFixed(2)},'
        '${order.taxAmount.toStringAsFixed(2)},'
        '${order.grandTotal.toStringAsFixed(2)},'
        '${order.paymentMode.label},'
        '${order.paymentStatus}',
      );
    }

    return buffer.toString();
  }

  Future<String> exportProductsToCSV() async {
    final products = await getProducts();

    final buffer = StringBuffer();
    buffer.writeln('Name,Barcode,Category,Purchase Price,Selling Price,GST %,Stock,Unit,Low Stock Threshold');

    for (final p in products) {
      buffer.writeln(
        '"${p.name}",'
        '${p.barcode ?? ""},'
        '${p.categoryId ?? ""},'
        '${p.purchasePrice.toStringAsFixed(2)},'
        '${p.sellingPrice.toStringAsFixed(2)},'
        '${p.gstRate.toStringAsFixed(2)},'
        '${p.stockQuantity.toStringAsFixed(2)},'
        '${p.unit},'
        '${p.lowStockThreshold.toStringAsFixed(2)}',
      );
    }

    return buffer.toString();
  }

  Future<String> exportExpensesToCSV({DateTime? from, DateTime? to}) async {
    final db = await database;
    
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (from != null && to != null) {
      whereClause = 'created_at >= ? AND created_at < ?';
      whereArgs = [from.toIso8601String(), to.toIso8601String()];
    }

    final rows = await db.query(
      'expenses',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final expenses = rows.map(Expense.fromMap).toList();

    final buffer = StringBuffer();
    buffer.writeln('Date,Category,Amount,Description');

    for (final e in expenses) {
      buffer.writeln(
        '${e.createdAt.toIso8601String()},'
        '${e.category},'
        '${e.amount.toStringAsFixed(2)},'
        '"${e.description}"',
      );
    }

    return buffer.toString();
  }
}
