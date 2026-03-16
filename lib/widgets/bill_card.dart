import 'package:flutter/material.dart';

import '../models/order_model.dart';

class BillCard extends StatelessWidget {
  const BillCard({
    super.key,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.grandTotal,
    this.title = 'Current Bill',
  });

  final List<OrderItem> items;
  final double subtotal;
  final double taxAmount;
  final double grandTotal;
  final String title;

  @override
  Widget build(BuildContext context) {
    final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$itemCount items',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text(
                'Add items manually or use voice billing to start the bill.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.name)),
                      Text(
                        '₹${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            if (items.isNotEmpty) ...[
              const Divider(height: 28),
              Row(
                children: [
                  const Text('Subtotal'),
                  const Spacer(),
                  Text('₹${subtotal.toStringAsFixed(2)}'),
                ],
              ),
              if (taxAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Text('GST'),
                      const Spacer(),
                      Text('₹${taxAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
            ],
            const Divider(height: 28),
            Row(
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '₹${grandTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}