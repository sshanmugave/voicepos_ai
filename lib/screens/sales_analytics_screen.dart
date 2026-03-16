import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';

class SalesAnalyticsScreen extends StatelessWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final points = appState.recentDailySales;
    final summary = appState.recentDailySummary;
    final maxTotal = points.isEmpty
        ? 1.0
        : points.map((point) => point.total).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _MetricTile(
                    title: 'Today Revenue',
                    value: '₹${appState.todaySales.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                  ),
                  const SizedBox(width: 12),
                  _MetricTile(
                    title: 'Today Orders',
                    value: '${appState.todayOrderCount}',
                    icon: Icons.receipt_long,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Sales (Last 7 Days)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: points
                          .map(
                            (point) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      point.total > 0
                                          ? '₹${point.total.toStringAsFixed(0)}'
                                          : '-',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: maxTotal == 0
                                          ? 2
                                          : (point.total / maxTotal) * 120 + 2,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormat('E').format(point.day),
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most Sold Items (Today)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (appState.topSoldItems.isEmpty)
                    const Text('No item sales yet today.')
                  else
                    ...appState.topSoldItems.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.key)),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Insights',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...appState.smartInsights.map(
                    (insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.lightbulb_outline, size: 18),
                          ),
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
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Type AI',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...appState.businessTypeAiInsights.map(
                    (insight) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.analytics_outlined, size: 18),
                          ),
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
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Stock Alerts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (appState.aiReorderSuggestions.isEmpty)
                    const Text('No auto reorder alerts right now.')
                  else
                    ...appState.aiReorderSuggestions.take(4).map(
                      (s) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warning_amber_outlined),
                        title: Text(s.productName),
                        subtitle: Text(s.message),
                        trailing: FilledButton(
                          onPressed: s.supplier == null
                              ? null
                              : () => appState.confirmAIReorder(s),
                          child: const Text('Order'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date-wise Daily Sales Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Orders')),
                        DataColumn(label: Text('Revenue')),
                      ],
                      rows: summary
                          .map(
                            (row) => DataRow(
                              cells: [
                                DataCell(Text(DateFormat('dd MMM').format(row.day))),
                                DataCell(Text('${row.orderCount}')),
                                DataCell(Text('₹${row.total.toStringAsFixed(0)}')),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
