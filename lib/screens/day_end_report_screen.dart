import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_state.dart';

class DayEndReportScreen extends StatelessWidget {
  const DayEndReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    final todayOrders = appState.todayOrders;
    final todaySales = appState.todaySales;
    final todayProfit = appState.todayProfit;
    final todayExpenses = appState.todayExpenseTotal;
    final netProfit = appState.todayNetProfit;

    // Payment breakdown
    final cashTotal = appState.cashTotal;
    final upiTotal = appState.upiTotal;
    final cardTotal = appState.cardTotal;
    final creditTotal = appState.creditTotal;

    // Top products
    final productCounts = <String, int>{};
    final productRevenue = <String, double>{};
    for (final order in todayOrders) {
      for (final item in order.items) {
        productCounts.update(item.name, (v) => v + item.quantity,
            ifAbsent: () => item.quantity);
        productRevenue.update(item.name, (v) => v + item.subtotal,
            ifAbsent: () => item.subtotal);
      }
    }

    final topProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Day-End Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReport(context, appState),
            tooltip: 'Share Report',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyReport(context, appState),
            tooltip: 'Copy to Clipboard',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    appState.shopName.isEmpty ? 'VoicePOS AI' : appState.shopName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily Summary - ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Key Metrics
            _SectionTitle(title: 'Key Metrics'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.receipt_long,
                    label: 'Orders',
                    value: '${todayOrders.length}',
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.currency_rupee,
                    label: 'Revenue',
                    value: '₹${todaySales.toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.trending_up,
                    label: 'Gross Profit',
                    value: '₹${todayProfit.toStringAsFixed(0)}',
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Net Profit',
                    value: '₹${netProfit.toStringAsFixed(0)}',
                    color: netProfit >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment Breakdown
            _SectionTitle(title: 'Payment Breakdown'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PaymentRow(
                      icon: Icons.payments,
                      label: 'Cash',
                      amount: cashTotal,
                      total: todaySales,
                      color: const Color(0xFFB85C38),
                    ),
                    const SizedBox(height: 12),
                    _PaymentRow(
                      icon: Icons.qr_code,
                      label: 'UPI',
                      amount: upiTotal,
                      total: todaySales,
                      color: const Color(0xFF2D7D7A),
                    ),
                    const SizedBox(height: 12),
                    _PaymentRow(
                      icon: Icons.credit_card,
                      label: 'Card',
                      amount: cardTotal,
                      total: todaySales,
                      color: const Color(0xFF5C6BC0),
                    ),
                    const SizedBox(height: 12),
                    _PaymentRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Credit',
                      amount: creditTotal,
                      total: todaySales,
                      color: const Color(0xFFFF8A65),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Expenses
            _SectionTitle(title: 'Expenses'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Expenses'),
                        Text(
                          '₹${todayExpenses.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    if (appState.todayExpenses.isNotEmpty) ...[
                      const Divider(height: 20),
                      ...appState.todayExpenses.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.category,
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  '₹${e.amount.toStringAsFixed(0)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Top Selling Products
            if (topProducts.isNotEmpty) ...[
              _SectionTitle(title: 'Top Selling Products'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: topProducts.take(5).map((entry) {
                      final revenue = productRevenue[entry.key] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.value}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry.key)),
                            Text(
                              '₹${revenue.toStringAsFixed(0)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Credit Outstanding
            if (appState.customersWithCredit.isNotEmpty) ...[
              _SectionTitle(title: 'Credit Outstanding'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Outstanding'),
                          Text(
                            '₹${appState.totalCreditOutstanding.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      ...appState.customersWithCredit.take(5).map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(c.name),
                                Text(
                                  '₹${c.creditBalance.toStringAsFixed(0)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Low Stock Alert
            if (appState.lowStockProducts.isNotEmpty) ...[
              _SectionTitle(title: 'Low Stock Alert'),
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: appState.lowStockProducts.take(5).map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p.name)),
                            Text(
                              '${p.stockQuantity.toStringAsFixed(0)} ${p.unit}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                'Generated by VoicePOS AI',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _generateReportText(AppState appState) {
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    final shopName = appState.shopName.isEmpty ? 'VoicePOS AI' : appState.shopName;

    final buffer = StringBuffer()
      ..writeln('═══════════════════════════')
      ..writeln('  $shopName')
      ..writeln('  Day-End Report')
      ..writeln('  $dateStr')
      ..writeln('═══════════════════════════')
      ..writeln()
      ..writeln('KEY METRICS')
      ..writeln('───────────────────────────')
      ..writeln('Orders:        ${appState.todayOrderCount}')
      ..writeln('Revenue:       ₹${appState.todaySales.toStringAsFixed(0)}')
      ..writeln('Gross Profit:  ₹${appState.todayProfit.toStringAsFixed(0)}')
      ..writeln('Expenses:      ₹${appState.todayExpenseTotal.toStringAsFixed(0)}')
      ..writeln('Net Profit:    ₹${appState.todayNetProfit.toStringAsFixed(0)}')
      ..writeln()
      ..writeln('PAYMENT BREAKDOWN')
      ..writeln('───────────────────────────')
      ..writeln('Cash:   ₹${appState.cashTotal.toStringAsFixed(0)}')
      ..writeln('UPI:    ₹${appState.upiTotal.toStringAsFixed(0)}')
      ..writeln('Card:   ₹${appState.cardTotal.toStringAsFixed(0)}')
      ..writeln('Credit: ₹${appState.creditTotal.toStringAsFixed(0)}');

    if (appState.customersWithCredit.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('CREDIT OUTSTANDING')
        ..writeln('───────────────────────────')
        ..writeln('Total: ₹${appState.totalCreditOutstanding.toStringAsFixed(0)}');
      for (final c in appState.customersWithCredit.take(5)) {
        buffer.writeln('  ${c.name}: ₹${c.creditBalance.toStringAsFixed(0)}');
      }
    }

    if (appState.lowStockProducts.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('LOW STOCK ALERT')
        ..writeln('───────────────────────────');
      for (final p in appState.lowStockProducts.take(5)) {
        buffer.writeln('  ${p.name}: ${p.stockQuantity.toStringAsFixed(0)} ${p.unit}');
      }
    }

    buffer
      ..writeln()
      ..writeln('═══════════════════════════')
      ..writeln('  Generated by VoicePOS AI');

    return buffer.toString();
  }

  void _shareReport(BuildContext context, AppState appState) {
    final text = _generateReportText(appState);
    SharePlus.instance.share(ShareParams(text: text, subject: 'Day-End Report - ${appState.shopName}'));
  }

  void _copyReport(BuildContext context, AppState appState) {
    final text = _generateReportText(appState);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double amount;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = total > 0 ? (amount / total * 100) : 0;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 50,
              child: Text(
                '${percent.toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? amount / total : 0,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
