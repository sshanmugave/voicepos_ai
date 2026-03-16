import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense_model.dart';
import '../services/app_state.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = ExpenseCategory.other;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final expenses = appState.todayExpenses;
    final totalExpense = appState.todayExpenseTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showExpenseHistory(context),
            tooltip: 'View History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Today's summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Column(
              children: [
                Text(
                  "Today's Expenses",
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${totalExpense.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${expenses.length} transactions',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Category breakdown
          if (expenses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'By Category',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildCategoryBreakdown(expenses, theme),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Expenses list
          Expanded(
            child: expenses.isEmpty
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
                          'No expenses today',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add an expense',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: expenses.length,
                    itemBuilder: (_, i) => _ExpenseCard(
                      expense: expenses[i],
                      onDelete: () => _deleteExpense(expenses[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  List<Widget> _buildCategoryBreakdown(List<Expense> expenses, ThemeData theme) {
    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }

    return byCategory.entries.map((entry) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_categoryIcon(entry.key), size: 16),
            const SizedBox(width: 6),
            Text(
              '${entry.key}: ₹${entry.value.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showAddExpenseDialog() {
    _amountCtrl.clear();
    _descCtrl.clear();
    _selectedCategory = ExpenseCategory.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Expense',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text(
                    'Category',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategory.all.map((cat) {
                      final selected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _categoryIcon(cat),
                              size: 16,
                              color: selected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 4),
                            Text(cat),
                          ],
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setModalState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick amounts
                  Text(
                    'Quick Amount',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [100, 200, 500, 1000, 2000, 5000].map((amt) {
                      return ActionChip(
                        label: Text('₹$amt'),
                        onPressed: () {
                          _amountCtrl.text = amt.toString();
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _saveExpense(ctx),
                      icon: const Icon(Icons.check),
                      label: const Text('Save Expense'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _saveExpense(BuildContext dialogContext) {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final expense = Expense(
      id: 0,
      category: _selectedCategory,
      amount: amount,
      description: _descCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    context.read<AppState>().addExpense(expense);
    Navigator.of(dialogContext).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ₹${amount.toStringAsFixed(0)} expense'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteExpense(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<AppState>().deleteExpense(id);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExpenseHistory(BuildContext context) {
    // Show past expenses with date picker
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => _ExpenseHistory(scrollController: scrollCtrl),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case ExpenseCategory.rent:
        return Icons.home_outlined;
      case ExpenseCategory.salary:
        return Icons.people_outline;
      case ExpenseCategory.electricity:
        return Icons.bolt_outlined;
      case ExpenseCategory.purchase:
        return Icons.shopping_cart_outlined;
      case ExpenseCategory.maintenance:
        return Icons.build_outlined;
      case ExpenseCategory.transport:
        return Icons.local_shipping_outlined;
      case ExpenseCategory.marketing:
        return Icons.campaign_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.errorContainer,
          child: Icon(
            _categoryIcon(expense.category),
            color: theme.colorScheme.error,
          ),
        ),
        title: Text(expense.category),
        subtitle: expense.description.isNotEmpty
            ? Text(
                expense.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                timeFormat.format(expense.createdAt),
                style: theme.textTheme.bodySmall,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${expense.amount.toStringAsFixed(0)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: theme.colorScheme.error,
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case ExpenseCategory.rent:
        return Icons.home_outlined;
      case ExpenseCategory.salary:
        return Icons.people_outline;
      case ExpenseCategory.electricity:
        return Icons.bolt_outlined;
      case ExpenseCategory.purchase:
        return Icons.shopping_cart_outlined;
      case ExpenseCategory.maintenance:
        return Icons.build_outlined;
      case ExpenseCategory.transport:
        return Icons.local_shipping_outlined;
      case ExpenseCategory.marketing:
        return Icons.campaign_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }
}

class _ExpenseHistory extends StatefulWidget {
  const _ExpenseHistory({required this.scrollController});

  final ScrollController scrollController;

  @override
  State<_ExpenseHistory> createState() => _ExpenseHistoryState();
}

class _ExpenseHistoryState extends State<_ExpenseHistory> {
  DateTimeRange? _dateRange;
  List<Expense> _expenses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day + 1),
    );
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (_dateRange == null) return;
    setState(() => _isLoading = true);

    final expenses = await context.read<AppState>().getExpensesByDateRange(
      _dateRange!.start,
      _dateRange!.end,
    );

    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

  double get _total => _expenses.fold<double>(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Expense History',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: _pickDateRange,
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end.subtract(const Duration(days: 1)))}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_expenses.length} transactions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '₹${_total.toStringAsFixed(0)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 24),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _expenses.isEmpty
                  ? const Center(child: Text('No expenses found'))
                  : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _expenses.length,
                      itemBuilder: (_, i) {
                        final e = _expenses[i];
                        return ListTile(
                          dense: true,
                          leading: Text(
                            DateFormat('dd/MM').format(e.createdAt),
                            style: theme.textTheme.bodySmall,
                          ),
                          title: Text(e.category),
                          subtitle: e.description.isNotEmpty
                              ? Text(
                                  e.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Text(
                            '₹${e.amount.toStringAsFixed(0)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = DateTimeRange(
          start: picked.start,
          end: picked.end.add(const Duration(days: 1)),
        );
      });
      _loadExpenses();
    }
  }
}
