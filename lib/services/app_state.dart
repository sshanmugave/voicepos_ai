import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification_model.dart';
import '../models/app_user_model.dart';
import '../models/b2b_order_model.dart';
import '../models/b2b_product_model.dart';
import '../models/business_profile_model.dart';
import '../models/business_type.dart';
import '../models/category_model.dart' as category_model;
import '../models/customer_model.dart';
import '../models/expense_model.dart';
import '../models/feedback_entry_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/salon_visit_model.dart';
import '../utils/app_localizations.dart';
import '../utils/demo_datasets.dart';
import '../utils/stock_prediction.dart' show StockAlert, StockPrediction, RestockRecommendation;
import 'billing_service.dart';
import 'database_service.dart';
import 'voice_service.dart';

class AppState extends ChangeNotifier {
  static const _prefLanguageKey = 'selected_language';
  static const _prefUserIdKey = 'session_user_id';
  static const _prefDemoModeKey = 'demo_mode_enabled';

  final DatabaseService _db = DatabaseService.instance;
  final BillingService billingService = BillingService();
  final VoiceService voiceService = VoiceService();

  bool _isInitialized = false;
  BusinessProfile? _profile;
  List<Product> _products = <Product>[];
  List<category_model.Category> _categories = <category_model.Category>[];
  List<Customer> _customers = <Customer>[];
  List<OrderModel> _orders = <OrderModel>[];
  List<Expense> _expenses = <Expense>[];
  List<SalonVisit> _salonVisits = <SalonVisit>[];
  List<B2BProduct> _b2bProducts = <B2BProduct>[];
  List<B2BOrder> _b2bOrders = <B2BOrder>[];
  List<AppNotification> _notifications = <AppNotification>[];
  List<FeedbackEntry> _feedbackEntries = <FeedbackEntry>[];
  AppUser? _currentUser;
  Map<String, List<String>> _frequentlyBoughtTogether = {};
  String _recognizedText = '';
  String _selectedLanguageCode = AppLocalizations.fallbackLanguage;
  bool _hasSelectedLanguage = false;
  bool _isListening = false;
  bool _isDarkMode = false;
  bool _gstEnabled = true;
  bool _isDemoMode = false;

  bool get isInitialized => _isInitialized;
  BusinessProfile? get profile => _profile;
  String get shopName => _profile?.shopName ?? '';
  List<Product> get products => List<Product>.unmodifiable(_products);
  List<Product> get favoriteProducts => _products.where((p) => p.isFavorite).toList();
  List<category_model.Category> get categories =>
      List<category_model.Category>.unmodifiable(_categories);
  List<Customer> get customers => List<Customer>.unmodifiable(_customers);
  List<OrderModel> get orders => List<OrderModel>.unmodifiable(_orders);
  List<Expense> get expenses => List<Expense>.unmodifiable(_expenses);
  List<SalonVisit> get salonVisits => List<SalonVisit>.unmodifiable(_salonVisits);
  List<B2BProduct> get b2bProducts => List<B2BProduct>.unmodifiable(_b2bProducts);
  List<B2BOrder> get b2bOrders => List<B2BOrder>.unmodifiable(_b2bOrders);
  List<AppNotification> get notifications => List<AppNotification>.unmodifiable(_notifications);
  List<FeedbackEntry> get feedbackEntries => List<FeedbackEntry>.unmodifiable(_feedbackEntries);
  Map<String, List<String>> get frequentlyBoughtTogether => _frequentlyBoughtTogether;
  List<OrderItem> get draftItems => billingService.draftItems;
  double get draftSubtotal => billingService.subtotal;
  double get draftTaxAmount => billingService.taxAmount;
  double get draftDiscountAmount => billingService.billDiscountAmount;
  double get draftGrandTotal => billingService.grandTotal;
  bool get hasDraft => billingService.hasDraft;
  String get recognizedText => _recognizedText;
  String get selectedLanguageCode => _selectedLanguageCode;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  bool get isListening => _isListening;
  bool get isDarkMode => _isDarkMode;
  bool get gstEnabled => _gstEnabled;
  bool get isDemoMode => _isDemoMode;
  BusinessType get businessType => _profile?.businessType ?? BusinessType.restaurant;
  bool get isSalonBusiness => businessType == BusinessType.salon;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLanguageSelected => _hasSelectedLanguage;

  String tr(String key) => AppLocalizations.tr(_selectedLanguageCode, key);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLanguage = prefs.getString(_prefLanguageKey);
    _hasSelectedLanguage = storedLanguage != null && storedLanguage.isNotEmpty;
    _selectedLanguageCode = storedLanguage ?? AppLocalizations.fallbackLanguage;
    _isDemoMode = prefs.getBool(_prefDemoModeKey) ?? false;

    // Trigger DB creation / migration
    await _db.database;

    final userId = prefs.getInt(_prefUserIdKey);
    if (userId != null) {
      _currentUser = await _db.getUserById(userId);
    }

    _profile = await _db.getBusinessProfile();
    _products = await _db.getProducts();
    _categories = await _db.getCategories();
    _customers = await _db.getCustomers();
    _orders = await _db.getOrders();
    _expenses = await _db.getTodayExpenses();
    _salonVisits = await _db.getSalonVisits();
    _b2bProducts = await _db.getB2BProducts();
    _b2bOrders = await _db.getB2BOrders();
    _notifications = await _db.getNotifications();
    _feedbackEntries = await _db.getFeedbackEntries();
    _frequentlyBoughtTogether = await _db.getFrequentlyBoughtTogether();

    billingService.setProducts(_products);

    _isInitialized = true;
    notifyListeners();
  }

  // ─── Business Profile ───

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    await _db.saveBusinessProfile(profile);
    await _db.seedBusinessTemplateItems(profile.businessType);
    _profile = await _db.getBusinessProfile();
    _products = await _db.getProducts();
    _categories = await _db.getCategories();
    billingService.setProducts(_products);
    notifyListeners();
  }

  Future<void> saveShopName(String name) async {
    final newProfile = (_profile ?? const BusinessProfile(shopName: ''))
        .copyWith(shopName: name.trim());
    await saveBusinessProfile(newProfile);
  }

  Future<bool> hasBusinessData() => _db.hasBusinessData();

  Future<void> clearBusinessData() async {
    await _db.clearBusinessData();
    _products = await _db.getProducts();
    _categories = await _db.getCategories();
    _customers = await _db.getCustomers();
    _orders = await _db.getOrders();
    _expenses = await _db.getTodayExpenses();
    _salonVisits = await _db.getSalonVisits();
    billingService.clearDraft();
    billingService.setProducts(_products);
    notifyListeners();
  }

  // ─── Language / Demo Mode / Auth ───

  Future<void> setLanguage(String languageCode) async {
    _selectedLanguageCode = languageCode;
    _hasSelectedLanguage = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageKey, languageCode);
    notifyListeners();
  }

  Future<void> toggleDemoMode() async {
    _isDemoMode = !_isDemoMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDemoModeKey, _isDemoMode);
    if (_isDemoMode) {
      await _db.insertNotification(
        title: 'Demo Mode Enabled',
        message: 'Mock AI predictions and alerts are active.',
        type: 'demo',
      );
      _notifications = await _db.getNotifications();
    }
    notifyListeners();
  }

  Future<String?> registerUser({
    required String identifier,
    required String password,
  }) async {
    final id = identifier.trim();
    if (id.isEmpty || password.trim().isEmpty) {
      return 'Identifier and password are required';
    }
    final isEmail = id.contains('@');
    try {
      final userId = await _db.registerUser(
        email: isEmail ? id : null,
        phone: isEmail ? null : id,
        password: password.trim(),
      );
      _currentUser = await _db.getUserById(userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefUserIdKey, userId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> loginUser({
    required String identifier,
    required String password,
  }) async {
    final id = identifier.trim();
    if (id.isEmpty || password.trim().isEmpty) {
      return 'Identifier and password are required';
    }
    final user = await _db.authenticateUser(
      identifier: id,
      password: password.trim(),
    );
    if (user == null) {
      return 'Invalid login credentials';
    }
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefUserIdKey, user.id);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUserIdKey);
    notifyListeners();
  }

  // ─── Products ───

  Future<void> addProduct(Product product) async {
    final id = await _db.insertProduct(product);
    _products = await _db.getProducts();
    billingService.setProducts(_products);

    // Log initial stock
    if (product.stockQuantity > 0) {
      await _db.insertInventoryLog(
        productId: id,
        changeType: 'initial',
        quantityChange: product.stockQuantity,
        balanceAfter: product.stockQuantity,
      );
    }
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    _products = await _db.getProducts();
    billingService.setProducts(_products);
    notifyListeners();
  }

  Future<void> restockProduct(int productId, double amount) async {
    if (amount <= 0) return;
    await _db.restockProduct(productId, amount);
    _products = await _db.getProducts();
    billingService.setProducts(_products);
    notifyListeners();
  }

  Future<Product?> lookupBarcode(String barcode) async {
    return _db.getProductByBarcode(barcode);
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final q = query.toLowerCase();
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.barcode?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  // ─── Categories ───

  Future<int> addCategory(String name) async {
    final id = await _db.insertCategory(name);
    _categories = await _db.getCategories();
    notifyListeners();
    return id;
  }

  Future<void> updateCategory(int id, String name) async {
    await _db.updateCategory(id, name);
    _categories = await _db.getCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    _categories = await _db.getCategories();
    _products = await _db.getProducts();
    billingService.setProducts(_products);
    notifyListeners();
  }

  // ─── Customers ───

  Future<int> addCustomer(Customer customer) async {
    final id = await _db.insertCustomer(customer);
    _customers = await _db.getCustomers();
    notifyListeners();
    return id;
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.updateCustomer(customer);
    _customers = await _db.getCustomers();
    notifyListeners();
  }

  Future<void> addSalonVisit({
    required int customerId,
    required String customerName,
    required String service,
  }) async {
    await _db.insertSalonVisit(
      customerId: customerId,
      customerName: customerName,
      service: service,
    );
    _salonVisits = await _db.getSalonVisits();
    notifyListeners();
  }

  List<SalonVisit> salonVisitsForCustomer(int customerId) {
    return _salonVisits.where((visit) => visit.customerId == customerId).toList();
  }

  Future<void> updateCustomerCredit(int customerId, double newBalance) async {
    await _db.updateCustomerCredit(customerId, newBalance);
    _customers = await _db.getCustomers();
    notifyListeners();
  }

  // ─── Billing ───

  void addProductToCart(Product product) {
    final effective = _gstEnabled
        ? product
        : Product(
            id: product.id,
            name: product.name,
            barcode: product.barcode,
            categoryId: product.categoryId,
            purchasePrice: product.purchasePrice,
            sellingPrice: product.sellingPrice,
            gstRate: 0,
            stockQuantity: product.stockQuantity,
            unit: product.unit,
            lowStockThreshold: product.lowStockThreshold,
            isFavorite: product.isFavorite,
            createdAt: product.createdAt,
          );
    billingService.addProduct(effective);
    notifyListeners();
  }

  void removeProductFromCart(int productId) {
    billingService.removeProduct(productId);
    notifyListeners();
  }

  void incrementCartItem(int productId) {
    billingService.incrementQuantity(productId);
    notifyListeners();
  }

  void decrementCartItem(int productId) {
    billingService.decrementQuantity(productId);
    notifyListeners();
  }

  void setCartItemQuantity(int productId, int quantity) {
    billingService.setQuantity(productId, quantity);
    notifyListeners();
  }

  void setItemDiscount(int productId, double percent) {
    billingService.setItemDiscount(productId, percent);
    notifyListeners();
  }

  void setBillDiscount(double amount) {
    billingService.setBillDiscount(amount);
    notifyListeners();
  }

  Future<OrderModel> completeOrder({
    required PaymentMode paymentMode,
    int? customerId,
    String? customerName,
    String notes = '',
  }) async {
    final invoiceNumber = await _db.generateInvoiceNumber();

    final order = billingService.buildOrder(
      invoiceNumber: invoiceNumber,
      paymentMode: paymentMode,
      customerId: customerId,
      customerName: customerName,
      notes: notes,
    );

    final orderId = await _db.insertOrder(order);

    if (isSalonBusiness && customerId != null) {
      final service = order.items.isNotEmpty
          ? order.items
              .map((item) => item.name)
              .take(2)
              .join(', ')
          : 'Service';
      await _db.insertSalonVisit(
        customerId: customerId,
        customerName: customerName ?? 'Customer',
        service: service,
      );
    }

    // If credit payment, update customer balance
    if (paymentMode == PaymentMode.credit && customerId != null) {
      final customer = _customers.firstWhere((c) => c.id == customerId);
      await _db.updateCustomerCredit(
        customerId,
        customer.creditBalance + order.grandTotal,
      );
    }

    // Refresh data
    _products = await _db.getProducts();
    _orders = await _db.getOrders();
    _customers = await _db.getCustomers();
    _salonVisits = await _db.getSalonVisits();
    billingService.setProducts(_products);
    billingService.clearDraft();
    _recognizedText = '';

    notifyListeners();

    // Return order with actual DB id
    return OrderModel(
      id: orderId,
      invoiceNumber: order.invoiceNumber,
      customerId: order.customerId,
      customerName: order.customerName,
      items: order.items,
      subtotal: order.subtotal,
      discountAmount: order.discountAmount,
      taxAmount: order.taxAmount,
      grandTotal: order.grandTotal,
      paymentMode: order.paymentMode,
      paymentStatus: order.paymentStatus,
      notes: order.notes,
      createdAt: order.createdAt,
    );
  }

  Future<void> clearDraft() async {
    billingService.clearDraft();
    _recognizedText = '';
    notifyListeners();
  }

  // ─── Voice ───

  Future<void> startVoiceCapture() async {
    _recognizedText = '';
    _isListening = await voiceService.startListening((recognized) {
      _recognizedText = recognized;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> stopVoiceCapture() async {
    await voiceService.stopListening();
    _isListening = false;
    if (_recognizedText.trim().isNotEmpty) {
      applyVoiceOrder(_recognizedText);
    }
    notifyListeners();
  }

  void applyVoiceOrder(String text) {
    _recognizedText = text;
    final parsed = voiceService.parseOrderText(text, _products);
    for (final entry in parsed.entries) {
      final product = _products.firstWhere(
        (p) => p.name.toLowerCase() == entry.key.toLowerCase(),
      );
      billingService.addProduct(product, quantity: entry.value);
    }
    notifyListeners();
  }

  // ─── Dashboard ───

  List<OrderModel> get todayOrders {
    final now = DateTime.now();
    return _orders.where((order) {
      return order.createdAt.year == now.year &&
          order.createdAt.month == now.month &&
          order.createdAt.day == now.day;
    }).toList();
  }

  double get todaySales =>
      todayOrders.fold<double>(0, (sum, order) => sum + order.grandTotal);

  int get todayOrderCount => todayOrders.length;

  double paymentTotal(PaymentMode mode) => todayOrders
      .where((o) => o.paymentMode == mode)
      .fold<double>(0, (sum, o) => sum + o.grandTotal);

  double get cashTotal => paymentTotal(PaymentMode.cash);
  double get upiTotal => paymentTotal(PaymentMode.upi);
  double get cardTotal => paymentTotal(PaymentMode.card);
  double get creditTotal => paymentTotal(PaymentMode.credit);

  String get mostSoldItem {
    final counts = <String, int>{};
    for (final order in todayOrders) {
      for (final item in order.items) {
        counts.update(item.name, (v) => v + item.quantity,
            ifAbsent: () => item.quantity);
      }
    }
    if (counts.isEmpty) return 'No sales yet';
    final best = counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return '${best.key} (${best.value})';
  }

  List<DailySalesPoint> get recentDailySales {
    final now = DateTime.now();
    final points = <DailySalesPoint>[];
    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final nextDay = day.add(const Duration(days: 1));
      final dayOrders = _orders.where((order) {
        return order.createdAt.isAfter(day.subtract(const Duration(seconds: 1))) &&
            order.createdAt.isBefore(nextDay);
      }).toList();
      final total = dayOrders.fold<double>(0, (sum, order) => sum + order.grandTotal);
      points.add(DailySalesPoint(day: day, total: total));
    }
    return points;
  }

  List<DailySalesSummary> get recentDailySummary {
    final now = DateTime.now();
    final rows = <DailySalesSummary>[];
    for (var i = 13; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final nextDay = day.add(const Duration(days: 1));
      final dayOrders = _orders.where((order) {
        return order.createdAt.isAfter(day.subtract(const Duration(seconds: 1))) &&
            order.createdAt.isBefore(nextDay);
      }).toList();
      final total = dayOrders.fold<double>(0, (sum, order) => sum + order.grandTotal);
      rows.add(
        DailySalesSummary(
          day: day,
          orderCount: dayOrders.length,
          total: total,
        ),
      );
    }
    return rows;
  }

  List<MapEntry<String, int>> get topSoldItems {
    final counts = <String, int>{};
    for (final order in todayOrders) {
      for (final item in order.items) {
        counts.update(item.name, (v) => v + item.quantity, ifAbsent: () => item.quantity);
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  List<String> get smartInsights {
    final insights = <String>[];
    if (todayOrders.isEmpty) {
      insights.add('No sales yet today. Start by creating your first bill.');
      return insights;
    }

    final topItem = topSoldItems.isNotEmpty ? topSoldItems.first : null;
    if (topItem != null) {
      insights.add('${topItem.key} is the most sold item today (${topItem.value} sold).');
    }

    final hourBuckets = <int, int>{};
    for (final order in todayOrders) {
      hourBuckets.update(order.createdAt.hour, (v) => v + 1, ifAbsent: () => 1);
    }
    final peak = hourBuckets.entries.reduce((a, b) => a.value >= b.value ? a : b);
    insights.add('Peak sales time is ${_formatHourRange(peak.key)}.');

    insights.add(
      'Average order value today is ₹${(todaySales / todayOrderCount).toStringAsFixed(0)}.',
    );
    return insights;
  }

  List<String> get businessTypeAiInsights {
    final demoRows = _isDemoMode ? DemoDatasets.buildSalesData(businessType) : const <DemoSalesRow>[];
    switch (businessType) {
      case BusinessType.teaShop:
        return [
          'Evening tea demand increases by 25%. Prepare more milk and samosas.',
          'Peak tea selling hours: 5 PM - 8 PM.',
          if (demoRows.isNotEmpty) 'Demo signal: Tea demand is consistently high in evening slots.',
        ];
      case BusinessType.restaurant:
        return [
          'Chicken biryani sells 40% more on weekends.',
          'Track rice, oil and spice stock every morning.',
          'Reduce waste by lowering last-hour prep quantity.',
        ];
      case BusinessType.salon:
        return [
          'Haircuts peak between 6 PM - 9 PM.',
          'Weekend staffing should be 20% higher.',
          'Facial and grooming combos improve average ticket size.',
        ];
      case BusinessType.juiceShop:
        return [
          'Mango juice demand increases in summer.',
          'Pre-cut fruit demand is highest after 3 PM.',
          'Keep extra cups and ice in late afternoon.',
        ];
      case BusinessType.bakery:
        return [
          'Buns sell 30% more in the morning.',
          'Bake in two batches to reduce unsold items.',
          'High-margin items: cup cakes and premium breads.',
        ];
      case BusinessType.streetVendor:
        return [
          'Peak sales are in evening rush hours.',
          'Restock packaging before 5 PM daily.',
          'Fast-selling items should have backup stock near cart.',
        ];
    }
  }

  String _formatHourRange(int hour) {
    String format(int value) {
      final normalized = value % 24;
      final h = normalized % 12 == 0 ? 12 : normalized % 12;
      final suffix = normalized < 12 ? 'AM' : 'PM';
      return '$h $suffix';
    }
    return '${format(hour)} - ${format(hour + 1)}';
  }

  // ─── Theme ───

  List<StockAlert> get stockAlerts =>
      StockPrediction.buildAlerts(products: _products, orders: todayOrders);

  List<RestockRecommendation> get restockRecommendations =>
      StockPrediction.buildRestockRecommendations(
        products: _products,
        orders: _orders,
      );

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleGst() {
    _gstEnabled = !_gstEnabled;
    notifyListeners();
  }

  // ─── Favorites ───

  Future<void> toggleFavorite(int productId) async {
    final product = _products.firstWhere((p) => p.id == productId);
    await _db.toggleFavorite(productId, !product.isFavorite);
    _products = await _db.getProducts();
    billingService.setProducts(_products);
    notifyListeners();
  }

  // ─── Expenses ───

  List<Expense> get todayExpenses {
    final now = DateTime.now();
    return _expenses.where((e) {
      return e.createdAt.year == now.year &&
          e.createdAt.month == now.month &&
          e.createdAt.day == now.day;
    }).toList();
  }

  double get todayExpenseTotal =>
      todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);

  Future<void> addExpense(Expense expense) async {
    await _db.insertExpense(expense);
    _expenses = await _db.getTodayExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(id);
    _expenses = await _db.getTodayExpenses();
    notifyListeners();
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime from, DateTime to) async {
    return _db.getExpenses(limit: 10000).then((all) => all.where((e) {
      return e.createdAt.isAfter(from.subtract(const Duration(seconds: 1))) &&
          e.createdAt.isBefore(to);
    }).toList());
  }

  // ─── Profit & Analytics ───

  double get todayProfit {
    double profit = 0;
    for (final order in todayOrders) {
      for (final item in order.items) {
        final product = _products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(
            id: 0,
            name: '',
            purchasePrice: 0,
            sellingPrice: item.unitPrice,
            gstRate: 0,
            stockQuantity: 0,
            unit: 'pcs',
            lowStockThreshold: 0,
            createdAt: DateTime.now(),
          ),
        );
        profit += (item.unitPrice - product.purchasePrice) * item.quantity;
      }
    }
    return profit;
  }

  double get todayNetProfit => todayProfit - todayExpenseTotal;

  // ─── Credit Collection ───

  List<Customer> get customersWithCredit =>
      _customers.where((c) => c.creditBalance > 0).toList()
        ..sort((a, b) => b.creditBalance.compareTo(a.creditBalance));

  double get totalCreditOutstanding =>
      customersWithCredit.fold<double>(0, (sum, c) => sum + c.creditBalance);

  // ─── B2B / Notifications / Feedback ───

  Future<void> refreshB2B() async {
    _b2bProducts = await _db.getB2BProducts(
      businessType: businessType.storageValue,
    );
    _b2bOrders = await _db.getB2BOrders();
    notifyListeners();
  }

  Future<int> placeB2BOrder({
    required B2BProduct product,
    required double quantity,
  }) async {
    final orderId = await _db.insertB2BOrder(
      productId: product.id,
      productName: product.name,
      supplierName: product.supplierName,
      quantity: quantity,
      unitPrice: product.price,
      status: 'confirmed',
    );
    await _db.insertNotification(
      title: 'Order Confirmation',
      message:
          'Ordered ${quantity.toStringAsFixed(1)} ${product.unit} of ${product.name} from ${product.supplierName}.',
      type: 'order-confirmation',
    );
    _b2bOrders = await _db.getB2BOrders();
    _notifications = await _db.getNotifications();
    notifyListeners();
    return orderId;
  }

  Future<void> markNotificationRead(int id) async {
    await _db.markNotificationRead(id);
    _notifications = await _db.getNotifications();
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    await _db.clearNotifications();
    _notifications = await _db.getNotifications();
    notifyListeners();
  }

  Future<void> addFeedback({
    required String customerName,
    required String message,
  }) async {
    await _db.insertFeedback(customerName: customerName, message: message);
    _feedbackEntries = await _db.getFeedbackEntries();
    notifyListeners();
  }

  List<AIReorderSuggestion> get aiReorderSuggestions {
    final suggestions = <AIReorderSuggestion>[];
    for (final lowStock in lowStockProducts.take(8)) {
      final supplier = _b2bProducts.where((item) {
        final a = item.name.toLowerCase();
        final b = lowStock.name.toLowerCase();
        return a.contains(b) || b.contains(a);
      }).cast<B2BProduct?>().firstWhere((_) => true, orElse: () => null);

      final suggestedQty = (lowStock.lowStockThreshold * 2).clamp(5, 200).toDouble();
      suggestions.add(
        AIReorderSuggestion(
          productName: lowStock.name,
          currentStock: lowStock.stockQuantity,
          suggestedQuantity: suggestedQty,
          supplier: supplier,
          message: supplier == null
              ? '${lowStock.name} stock is below threshold. Add supplier in B2B marketplace.'
              : '${lowStock.name} stock is low. Suggested supplier: ${supplier.supplierName}. Order ${suggestedQty.toStringAsFixed(0)} ${supplier.unit}?',
        ),
      );
    }
    return suggestions;
  }

  Future<void> confirmAIReorder(AIReorderSuggestion suggestion) async {
    final supplier = suggestion.supplier;
    if (supplier == null) return;
    await placeB2BOrder(
      product: supplier,
      quantity: suggestion.suggestedQuantity,
    );
    await _db.insertNotification(
      title: 'AI Reorder Completed',
      message:
          '${suggestion.productName} reorder sent to ${supplier.supplierName}.',
      type: 'stock-alert',
    );
    _notifications = await _db.getNotifications();
    notifyListeners();
  }

  // ─── Data Export ───

  Future<String> exportOrdersCSV({DateTime? from, DateTime? to}) =>
      _db.exportOrdersToCSV(from: from, to: to);

  Future<String> exportProductsCSV() => _db.exportProductsToCSV();

  Future<String> exportExpensesCSV({DateTime? from, DateTime? to}) =>
      _db.exportExpensesToCSV(from: from, to: to);

  // ─── Order History ───

  Future<List<OrderModel>> getOrdersByDateRange(DateTime from, DateTime to) =>
      _db.getOrdersByDateRange(from: from, to: to);

  // ─── Suggestions ───

  List<String> getSuggestionsFor(String productName) {
    return _frequentlyBoughtTogether[productName] ?? [];
  }
}

class DailySalesPoint {
  const DailySalesPoint({required this.day, required this.total});

  final DateTime day;
  final double total;
}

class DailySalesSummary {
  const DailySalesSummary({
    required this.day,
    required this.orderCount,
    required this.total,
  });

  final DateTime day;
  final int orderCount;
  final double total;
}

class AIReorderSuggestion {
  const AIReorderSuggestion({
    required this.productName,
    required this.currentStock,
    required this.suggestedQuantity,
    required this.supplier,
    required this.message,
  });

  final String productName;
  final double currentStock;
  final double suggestedQuantity;
  final B2BProduct? supplier;
  final String message;
}