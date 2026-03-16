import 'package:flutter/material.dart';

import '../models/product_model.dart';

class InventoryTile extends StatelessWidget {
  const InventoryTile({
    super.key,
    required this.product,
    required this.onRestock,
  });

  final Product product;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor =
        product.isLowStock ? colorScheme.error : colorScheme.primary;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 56,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.stockQuantity.toStringAsFixed(product.unit == 'pcs' ? 0 : 2)} ${product.unit}',
                  ),
                  Text(
                    product.isLowStock ? 'Low stock' : 'Stock healthy',
                    style: TextStyle(color: badgeColor),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: onRestock,
              child: const Text('Restock'),
            ),
          ],
        ),
      ),
    );
  }
}