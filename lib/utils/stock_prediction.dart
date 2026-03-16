import '../models/order_model.dart';
import '../models/product_model.dart';

class StockAlert {
  const StockAlert({required this.name, required this.message});

  final String name;
  final String message;
}

class RestockRecommendation {
  const RestockRecommendation({
    required this.productName,
    required this.currentStock,
    required this.unit,
    required this.avgDailyUsage,
    required this.daysRemaining,
    required this.suggestedQty,
    required this.urgency, // 'critical' | 'soon' | 'plan'
  });

  final String productName;
  final double currentStock;
  final String unit;
  final double avgDailyUsage;
  final double daysRemaining;
  final double suggestedQty;
  final String urgency;

  String get urgencyLabel {
    switch (urgency) {
      case 'critical':
        return 'Out today';
      case 'soon':
        return 'Out in ${daysRemaining.toStringAsFixed(1)} days';
      default:
        return 'Plan for next week';
    }
  }
}

class StockPrediction {
  static List<StockAlert> buildAlerts({
    required List<Product> products,
    required List<OrderModel> orders,
  }) {
    final usage = _averageUsagePerDay(orders);
    final alerts = <StockAlert>[];

    for (final product in products) {
      final dailyUsage = usage[product.name] ?? 0;

      if (dailyUsage > 0 && product.stockQuantity <= dailyUsage) {
        alerts.add(
          StockAlert(
            name: product.name,
            message: '${product.name} stock will run out tomorrow (${product.stockQuantity.toStringAsFixed(0)} left, avg ${dailyUsage.toStringAsFixed(1)}/day).',
          ),
        );
      } else if (product.isLowStock) {
        alerts.add(
          StockAlert(
            name: product.name,
            message: '${product.name} is below the low stock threshold (${product.stockQuantity.toStringAsFixed(0)} ${product.unit} remaining).',
          ),
        );
      }
    }

    return alerts;
  }

  /// AI-powered restock recommendations based on the last 7 days of sales velocity.
  /// Returns products ranked by urgency (critical → soon → plan-ahead).
  static List<RestockRecommendation> buildRestockRecommendations({
    required List<Product> products,
    required List<OrderModel> orders,
  }) {
    // Use up to last 7 days of orders
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentOrders =
        orders.where((o) => o.createdAt.isAfter(sevenDaysAgo)).toList();

    final usage = _averageUsagePerDay(recentOrders);
    final recommendations = <RestockRecommendation>[];

    for (final product in products) {
      final dailyUsage = usage[product.name] ?? 0;
      if (dailyUsage <= 0) continue; // product never sold recently — skip

      final daysRemaining = dailyUsage > 0
          ? product.stockQuantity / dailyUsage
          : double.infinity;

      if (daysRemaining > 14) continue; // plenty of stock — skip

      // Suggest enough for 7 days ahead
      final suggestedQty = (dailyUsage * 7 - product.stockQuantity)
          .clamp(dailyUsage, dailyUsage * 14);

      final urgency = daysRemaining <= 1
          ? 'critical'
          : daysRemaining <= 3
              ? 'soon'
              : 'plan';

      recommendations.add(RestockRecommendation(
        productName: product.name,
        currentStock: product.stockQuantity,
        unit: product.unit,
        avgDailyUsage: dailyUsage,
        daysRemaining: daysRemaining,
        suggestedQty: suggestedQty,
        urgency: urgency,
      ));
    }

    // Sort: critical first, then soon, then plan; within each group by daysRemaining asc
    const order = ['critical', 'soon', 'plan'];
    recommendations.sort((a, b) {
      final ua = order.indexOf(a.urgency);
      final ub = order.indexOf(b.urgency);
      if (ua != ub) return ua.compareTo(ub);
      return a.daysRemaining.compareTo(b.daysRemaining);
    });

    return recommendations;
  }

  static Map<String, double> _averageUsagePerDay(List<OrderModel> orders) {
    if (orders.isEmpty) return {};

    final usageTotals = <String, double>{};
    final daySet = <String>{};

    for (final order in orders) {
      final dayKey = '${order.createdAt.year}-${order.createdAt.month}-${order.createdAt.day}';
      daySet.add(dayKey);

      for (final item in order.items) {
        usageTotals.update(
          item.name,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity.toDouble(),
        );
      }
    }

    final totalDays = daySet.isEmpty ? 1 : daySet.length;
    return {
      for (final entry in usageTotals.entries) entry.key: entry.value / totalDays,
    };
  }
}