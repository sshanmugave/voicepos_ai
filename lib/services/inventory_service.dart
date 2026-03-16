import '../models/product_model.dart';
import 'database_service.dart';

class InventoryService {
  final DatabaseService _db = DatabaseService.instance;

  Future<List<Product>> getProducts() => _db.getProducts();

  Future<List<Product>> getLowStockProducts() => _db.getLowStockProducts();

  Future<void> restockProduct(int productId, double amount) =>
      _db.restockProduct(productId, amount);

  Future<List<Product>> searchProducts(String query) =>
      _db.searchProducts(query);

  Future<Product?> findByBarcode(String barcode) =>
      _db.getProductByBarcode(barcode);
}