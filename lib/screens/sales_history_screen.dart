import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../services/app_state.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  DateTimeRange? _selectedRange;
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  PaymentMode? _paymentFilter;

  @override
  void initState() {
    super.initState();
    // Default to today
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day + 1),
    );
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (_selectedRange == null) return;
    
    setState(() => _isLoading = true);
    
    final appState = context.read<AppState>();
    final orders = await appState.getOrdersByDateRange(
      _selectedRange!.start,
      _selectedRange!.end,
    );
    
    setState(() {
      _filteredOrders = orders;
      _isLoading = false;
    });
  }

  List<OrderModel> get _displayedOrders {
    var orders = _filteredOrders;
    
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      orders = orders.where((o) {
        return o.invoiceNumber.toLowerCase().contains(q) ||
            (o.customerName?.toLowerCase().contains(q) ?? false) ||
            o.items.any((i) => i.name.toLowerCase().contains(q));
      }).toList();
    }
    
    if (_paymentFilter != null) {
      orders = orders.where((o) => o.paymentMode == _paymentFilter).toList();
    }
    
    return orders;
  }

  double get _totalSales =>
      _displayedOrders.fold<double>(0, (sum, o) => sum + o.grandTotal);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range and summary
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDateRange,
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedRange != null
                                  ? '${dateFormat.format(_selectedRange!.start)} - ${dateFormat.format(_selectedRange!.end.subtract(const Duration(days: 1)))}'
                                  : 'Select dates',
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${_totalSales.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick filters
                Row(
                  children: [
                    _QuickDateChip(
                      label: 'Today',
                      onTap: () => _setQuickRange(0),
                      selected: _isToday,
                    ),
                    const SizedBox(width: 8),
                    _QuickDateChip(
                      label: 'Yesterday',
                      onTap: () => _setQuickRange(1),
                      selected: _isYesterday,
                    ),
                    const SizedBox(width: 8),
                    _QuickDateChip(
                      label: 'This Week',
                      onTap: _setThisWeek,
                      selected: _isThisWeek,
                    ),
                    const SizedBox(width: 8),
                    _QuickDateChip(
                      label: 'This Month',
                      onTap: _setThisMonth,
                      selected: _isThisMonth,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search and filters
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search invoice, customer, product...',
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
                const SizedBox(width: 8),
                PopupMenuButton<PaymentMode?>(
                  icon: Icon(
                    Icons.filter_list,
                    color: _paymentFilter != null ? theme.colorScheme.primary : null,
                  ),
                  tooltip: 'Filter by payment',
                  onSelected: (v) => setState(() => _paymentFilter = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('All Payments')),
                    const PopupMenuDivider(),
                    ...PaymentMode.values.map((m) => PopupMenuItem(
                      value: m,
                      child: Row(
                        children: [
                          Icon(_paymentIcon(m), size: 18),
                          const SizedBox(width: 8),
                          Text(m.label),
                        ],
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),

          // Orders count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_displayedOrders.length} orders',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const Spacer(),
                if (_paymentFilter != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _paymentFilter = null),
                    icon: const Icon(Icons.clear, size: 16),
                    label: Text(_paymentFilter!.label),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No orders found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _displayedOrders.length,
                        itemBuilder: (_, i) => _OrderCard(order: _displayedOrders[i]),
                      ),
          ),
        ],
      ),
    );
  }

  bool get _isToday {
    if (_selectedRange == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _selectedRange!.start == today &&
        _selectedRange!.end == today.add(const Duration(days: 1));
  }

  bool get _isYesterday {
    if (_selectedRange == null) return false;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return _selectedRange!.start == yesterday &&
        _selectedRange!.end == yesterday.add(const Duration(days: 1));
  }

  bool get _isThisWeek {
    if (_selectedRange == null) return false;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _selectedRange!.start == start;
  }

  bool get _isThisMonth {
    if (_selectedRange == null) return false;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return _selectedRange!.start == monthStart;
  }

  void _setQuickRange(int daysAgo) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day - daysAgo);
    setState(() {
      _selectedRange = DateTimeRange(
        start: date,
        end: date.add(const Duration(days: 1)),
      );
    });
    _loadOrders();
  }

  void _setThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    setState(() {
      _selectedRange = DateTimeRange(
        start: DateTime(weekStart.year, weekStart.month, weekStart.day),
        end: DateTime(now.year, now.month, now.day + 1),
      );
    });
    _loadOrders();
  }

  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _selectedRange = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month, now.day + 1),
      );
    });
    _loadOrders();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedRange = DateTimeRange(
          start: picked.start,
          end: picked.end.add(const Duration(days: 1)),
        );
      });
      _loadOrders();
    }
  }

  IconData _paymentIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.payments_outlined;
      case PaymentMode.upi:
        return Icons.qr_code;
      case PaymentMode.card:
        return Icons.credit_card;
      case PaymentMode.credit:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? theme.colorScheme.onPrimary : null,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('dd MMM');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showOrderDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.invoiceNumber,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(order.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(order.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _paymentIcon(order.paymentMode),
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.paymentMode.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (order.customerName != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.customerName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '₹${order.grandTotal.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                order.invoiceNumber,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              if (order.customerName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(order.customerName!),
                  ],
                ),
              ],
              const Divider(height: 24),
              Text(
                'Items',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: order.items.length,
                  itemBuilder: (_, i) {
                    final item = order.items[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text('${item.quantity}x'),
                          const SizedBox(width: 12),
                          Expanded(child: Text(item.name)),
                          Text('₹${item.subtotal.toStringAsFixed(0)}'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              _SummaryRow(label: 'Subtotal', value: order.subtotal),
              if (order.discountAmount > 0)
                _SummaryRow(
                  label: 'Discount',
                  value: -order.discountAmount,
                  isNegative: true,
                ),
              if (order.taxAmount > 0)
                _SummaryRow(label: 'GST', value: order.taxAmount),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Grand Total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${order.grandTotal.toStringAsFixed(0)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_paymentIcon(order.paymentMode), size: 20),
                    const SizedBox(width: 8),
                    Text(order.paymentMode.label),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.paymentStatus == 'paid'
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: order.paymentStatus == 'paid'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.notes,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _paymentIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.payments_outlined;
      case PaymentMode.upi:
        return Icons.qr_code;
      case PaymentMode.card:
        return Icons.credit_card;
      case PaymentMode.credit:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isNegative = false,
  });

  final String label;
  final double value;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            '${isNegative ? '-' : ''}₹${value.abs().toStringAsFixed(0)}',
            style: TextStyle(
              color: isNegative ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
