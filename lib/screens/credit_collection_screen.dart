import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/customer_model.dart';
import '../services/app_state.dart';

class CreditCollectionScreen extends StatefulWidget {
  const CreditCollectionScreen({super.key});

  @override
  State<CreditCollectionScreen> createState() => _CreditCollectionScreenState();
}

class _CreditCollectionScreenState extends State<CreditCollectionScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    
    var customers = appState.customersWithCredit;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      customers = customers.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q);
      }).toList();
    }

    final totalOutstanding = appState.totalCreditOutstanding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Collection'),
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Column(
              children: [
                Text(
                  'Total Outstanding',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${totalOutstanding.toStringAsFixed(0)}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${customers.length} customers with pending dues',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Customer list
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending credits!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All customers have cleared their dues',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: customers.length,
                    itemBuilder: (_, i) => _CreditCard(
                      customer: customers[i],
                      rank: i + 1,
                      onCollect: () => _showCollectDialog(customers[i]),
                      onRemind: () => _sendReminder(customers[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showCollectDialog(Customer customer) {
    final amountCtrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collect Payment',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'From: ${customer.name}',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              Text(
                'Outstanding: ₹${customer.creditBalance.toStringAsFixed(0)}',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Amount Received',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick amounts
              Text(
                'Quick Amount',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Full Amount'),
                    onPressed: () {
                      amountCtrl.text = customer.creditBalance.toStringAsFixed(0);
                    },
                  ),
                  ActionChip(
                    label: const Text('Half'),
                    onPressed: () {
                      amountCtrl.text = (customer.creditBalance / 2).toStringAsFixed(0);
                    },
                  ),
                  ...[ 100, 500, 1000].map((amt) => ActionChip(
                    label: Text('₹$amt'),
                    onPressed: () {
                      amountCtrl.text = amt.toString();
                    },
                  )),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final amount = double.tryParse(amountCtrl.text);
                        if (amount != null && amount > 0) {
                          _collectPayment(customer, amount);
                          Navigator.of(ctx).pop();
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Collect'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _collectPayment(Customer customer, double amount) {
    final newBalance = (customer.creditBalance - amount).clamp(0.0, double.infinity);
    context.read<AppState>().updateCustomerCredit(customer.id, newBalance);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Collected ₹${amount.toStringAsFixed(0)} from ${customer.name}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendReminder(Customer customer) async {
    if (customer.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this customer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final appState = context.read<AppState>();
    final shopName = appState.shopName.isEmpty ? 'our shop' : appState.shopName;
    
    final message = Uri.encodeComponent(
      'Hi ${customer.name},\n\n'
      'This is a friendly reminder that you have a pending balance of ₹${customer.creditBalance.toStringAsFixed(0)} at $shopName.\n\n'
      'Please visit us to clear your dues.\n\n'
      'Thank you!',
    );

    final phone = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappUrl = 'https://wa.me/91$phone?text=$message';

    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to SMS
        final smsUrl = 'sms:$phone?body=$message';
        final smsUri = Uri.parse(smsUrl);
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send reminder'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({
    required this.customer,
    required this.rank,
    required this.onCollect,
    required this.onRemind,
  });

  final Customer customer;
  final int rank;
  final VoidCallback onCollect;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getRankColor(rank),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (customer.phone.isNotEmpty)
                        Text(
                          customer.phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${customer.creditBalance.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    Text(
                      'Due',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRemind,
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Remind'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCollect,
                    icon: const Icon(Icons.payments, size: 18),
                    label: const Text('Collect'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.red;
    if (rank == 2) return Colors.orange;
    if (rank == 3) return Colors.amber;
    return Colors.grey;
  }
}
