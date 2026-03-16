import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/b2b_product_model.dart';
import '../services/app_state.dart';

class B2BMarketplaceScreen extends StatelessWidget {
  const B2BMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final products = appState.b2bProducts;

    return Scaffold(
      appBar: AppBar(title: const Text('B2B Marketplace')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: appState.refreshB2B,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No supplier products available for this business type yet.'),
                )
              else
                ...products.map((product) => _B2BCard(product: product)),
              const SizedBox(height: 16),
              Text(
                'Order History',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (appState.b2bOrders.isEmpty)
                const Card(child: ListTile(title: Text('No B2B orders yet')))
              else
                ...appState.b2bOrders.take(10).map(
                      (order) => Card(
                        child: ListTile(
                          title: Text(order.productName),
                          subtitle: Text(
                            '${order.supplierName} • ${order.quantity.toStringAsFixed(1)} x ₹${order.unitPrice.toStringAsFixed(0)}',
                          ),
                          trailing: Text(order.status),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _B2BCard extends StatelessWidget {
  const _B2BCard({required this.product});

  final B2BProduct product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.local_shipping_outlined),
        title: Text(product.name),
        subtitle: Text('${product.supplierName} • ₹${product.price.toStringAsFixed(0)}/${product.unit}'),
        trailing: FilledButton(
          onPressed: () => _showOrderDialog(context),
          child: const Text('Order'),
        ),
      ),
    );
  }

  Future<void> _showOrderDialog(BuildContext context) async {
    final qtyCtrl = TextEditingController(text: '10');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Order ${product.name}'),
          content: TextField(
            controller: qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Quantity (${product.unit})'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (qty <= 0) return;
                await context.read<AppState>().placeB2BOrder(
                      product: product,
                      quantity: qty,
                    );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Confirm Order'),
            ),
          ],
        );
      },
    );
  }
}
