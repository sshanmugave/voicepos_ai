import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../utils/stock_prediction.dart';
import 'billing_screen.dart';
import 'credit_collection_screen.dart';
import 'day_end_report_screen.dart';
import 'sales_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final alerts = appState.stockAlerts;
    final total = appState.todaySales;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Quick Actions ──
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const _QuickBillingPage()),
                    ),
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Quick Add Bill'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.receipt_long,
                    label: 'Sales History',
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.summarize,
                    label: 'Day Report',
                    color: Colors.teal,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DayEndReportScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Credit Due',
                    color: Colors.orange,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreditCollectionScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Summary cards ──
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                    title: 'Today Sales',
                    value: '₹${total.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                    color: Colors.green),
                _MetricCard(
                    title: 'Orders',
                    value: '${appState.todayOrderCount}',
                    icon: Icons.receipt,
                    color: theme.colorScheme.primary),
                _MetricCard(
                    title: 'Profit',
                    value: '₹${appState.todayProfit.toStringAsFixed(0)}',
                    icon: Icons.trending_up,
                    color: Colors.teal),
                _MetricCard(
                    title: 'Expenses',
                    value: '₹${appState.todayExpenseTotal.toStringAsFixed(0)}',
                    icon: Icons.money_off,
                    color: Colors.red),
                _MetricCard(
                    title: 'Net Profit',
                    value: '₹${appState.todayNetProfit.toStringAsFixed(0)}',
                    icon: Icons.account_balance,
                    color: appState.todayNetProfit >= 0 ? Colors.green : Colors.red),
                _MetricCard(
                    title: 'Credit Due',
                    value: '₹${appState.totalCreditOutstanding.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.orange),
              ],
            ),
            const SizedBox(height: 20),

            // ── Payment split bar ──
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Split',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 18,
                        child: total == 0
                            ? const ColoredBox(
                                color: Color(0xFFE8DED2),
                                child: SizedBox.expand())
                            : Row(
                                children: [
                                  _BarSegment(
                                      ratio: appState.cashTotal / total,
                                      color: const Color(0xFFB85C38)),
                                  _BarSegment(
                                      ratio: appState.upiTotal / total,
                                      color: const Color(0xFF2D7D7A)),
                                  _BarSegment(
                                      ratio: appState.cardTotal / total,
                                      color: const Color(0xFF5C6BC0)),
                                  _BarSegment(
                                      ratio: appState.creditTotal / total,
                                      color: const Color(0xFFFF8A65)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        _Legend(
                            color: const Color(0xFFB85C38),
                            label:
                                'Cash ₹${appState.cashTotal.toStringAsFixed(0)}'),
                        _Legend(
                            color: const Color(0xFF2D7D7A),
                            label:
                                'UPI ₹${appState.upiTotal.toStringAsFixed(0)}'),
                        _Legend(
                            color: const Color(0xFF5C6BC0),
                            label:
                                'Card ₹${appState.cardTotal.toStringAsFixed(0)}'),
                        _Legend(
                            color: const Color(0xFFFF8A65),
                            label:
                                'Credit ₹${appState.creditTotal.toStringAsFixed(0)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Most Sold Today ──
            if (appState.todayOrderCount > 0)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[600], size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Most Sold Today',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              )),
                          Text(appState.mostSoldItem,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (appState.todayOrderCount > 0) const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Insights',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...appState.smartInsights.map(
                      (insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(insight)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Stock alerts ──
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Stock Alerts',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (alerts.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${alerts.length}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (alerts.isEmpty)
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[400]),
                          const SizedBox(width: 8),
                          const Text('All products have healthy stock levels.'),
                        ],
                      )
                    else
                      ...alerts.take(5).map(
                        (alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFB85C38), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  alert.message,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── AI Restock Plan ──
            _AiRestockCard(recommendations: appState.restockRecommendations),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    this.icon,
    this.color,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 44) / 2;
    return SizedBox(
      width: width,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (color ?? Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              if (icon != null) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarSegment extends StatelessWidget {
  const _BarSegment({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (ratio <= 0) return const SizedBox.shrink();
    return Flexible(
      flex: (ratio * 1000).round(),
      child: ColoredBox(color: color, child: const SizedBox.expand()),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _AiRestockCard extends StatefulWidget {
  const _AiRestockCard({required this.recommendations});
  final List<RestockRecommendation> recommendations;

  @override
  State<_AiRestockCard> createState() => _AiRestockCardState();
}

class _AiRestockCardState extends State<_AiRestockCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recs = widget.recommendations;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.purple, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Restock Plan',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Based on last 7-day sales velocity',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                  if (recs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${recs.length}',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 14),
              if (recs.isEmpty)
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[400]),
                    const SizedBox(width: 8),
                    const Text('All products are sufficiently stocked.'),
                  ],
                )
              else
                ...recs.take(8).map((rec) {
                  final urgencyColor = rec.urgency == 'critical'
                      ? Colors.red
                      : rec.urgency == 'soon'
                          ? Colors.orange
                          : Colors.blue;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: urgencyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            rec.urgency == 'critical'
                                ? Icons.warning_rounded
                                : rec.urgency == 'soon'
                                    ? Icons.schedule
                                    : Icons.shopping_cart_outlined,
                            color: urgencyColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rec.productName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: urgencyColor
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      rec.urgencyLabel,
                                      style: TextStyle(
                                        color: urgencyColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Stock: ${rec.currentStock.toStringAsFixed(0)} ${rec.unit}  •  '
                                'Avg ${rec.avgDailyUsage.toStringAsFixed(1)}/day  •  '
                                'Buy ≈ ${rec.suggestedQty.toStringAsFixed(0)} ${rec.unit}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickBillingPage extends StatelessWidget {
  const _QuickBillingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Billing')),
      body: const BillingScreen(),
    );
  }
}