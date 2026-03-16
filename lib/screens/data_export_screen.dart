import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/order_model.dart';
import '../services/app_state.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  DateTimeRange? _selectedRange;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Export your data as CSV files. You can open them in Excel, Google Sheets, or any spreadsheet app.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date range for orders/expenses
            Text(
              'Date Range (for Sales & Expenses)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedRange != null
                            ? '${dateFormat.format(_selectedRange!.start)} - ${dateFormat.format(_selectedRange!.end.subtract(const Duration(days: 1)))}'
                            : 'Select dates',
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quick range buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Today'),
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _selectedRange = DateTimeRange(
                        start: DateTime(now.year, now.month, now.day),
                        end: DateTime(now.year, now.month, now.day + 1),
                      );
                    });
                  },
                ),
                ActionChip(
                  label: const Text('This Week'),
                  onPressed: () {
                    final now = DateTime.now();
                    final weekStart = now.subtract(Duration(days: now.weekday - 1));
                    setState(() {
                      _selectedRange = DateTimeRange(
                        start: DateTime(weekStart.year, weekStart.month, weekStart.day),
                        end: DateTime(now.year, now.month, now.day + 1),
                      );
                    });
                  },
                ),
                ActionChip(
                  label: const Text('This Month'),
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _selectedRange = DateTimeRange(
                        start: DateTime(now.year, now.month, 1),
                        end: DateTime(now.year, now.month, now.day + 1),
                      );
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Last Month'),
                  onPressed: () {
                    final now = DateTime.now();
                    final lastMonth = DateTime(now.year, now.month - 1, 1);
                    final lastMonthEnd = DateTime(now.year, now.month, 1);
                    setState(() {
                      _selectedRange = DateTimeRange(
                        start: lastMonth,
                        end: lastMonthEnd,
                      );
                    });
                  },
                ),
                ActionChip(
                  label: const Text('All Time'),
                  onPressed: () {
                    setState(() {
                      _selectedRange = DateTimeRange(
                        start: DateTime(2020, 1, 1),
                        end: DateTime.now().add(const Duration(days: 1)),
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Export options
            Text(
              'Export Options',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _ExportOptionCard(
              icon: Icons.receipt_long,
              title: 'Sales / Orders',
              subtitle: 'Invoice details, items, amounts, payment modes',
              isLoading: _isExporting,
              onExport: () => _exportData('orders'),
            ),
            const SizedBox(height: 12),

            _ExportOptionCard(
              icon: Icons.picture_as_pdf,
              title: 'Sales Report (PDF)',
              subtitle: 'Daily summary with totals and payment split',
              isLoading: _isExporting,
              onExport: _exportSalesPdf,
            ),
            const SizedBox(height: 12),

            _ExportOptionCard(
              icon: Icons.inventory_2,
              title: 'Products',
              subtitle: 'Product list with prices, stock levels, categories',
              isLoading: _isExporting,
              onExport: () => _exportData('products'),
            ),
            const SizedBox(height: 12),

            _ExportOptionCard(
              icon: Icons.money_off,
              title: 'Expenses',
              subtitle: 'All expenses with categories and descriptions',
              isLoading: _isExporting,
              onExport: () => _exportData('expenses'),
            ),
            const SizedBox(height: 12),

            _ExportOptionCard(
              icon: Icons.people,
              title: 'Customers',
              subtitle: 'Customer list with credit balances',
              isLoading: _isExporting,
              onExport: () => _exportData('customers'),
            ),
            const SizedBox(height: 24),

            // All-in-one export
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              child: InkWell(
                onTap: _isExporting ? null : _exportAll,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_zip_outlined,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export All Data',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Export everything as multiple CSV files',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isExporting)
                        const CircularProgressIndicator()
                      else
                        Icon(
                          Icons.download,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    }
  }

  Future<void> _exportData(String type) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final appState = context.read<AppState>();
      String csvContent;
      String fileName;

      switch (type) {
        case 'orders':
          csvContent = await appState.exportOrdersCSV(
            from: _selectedRange?.start,
            to: _selectedRange?.end,
          );
          fileName = 'orders_${_dateRangeString()}.csv';
          break;
        case 'products':
          csvContent = await appState.exportProductsCSV();
          fileName = 'products_${DateTime.now().millisecondsSinceEpoch}.csv';
          break;
        case 'expenses':
          csvContent = await appState.exportExpensesCSV(
            from: _selectedRange?.start,
            to: _selectedRange?.end,
          );
          fileName = 'expenses_${_dateRangeString()}.csv';
          break;
        case 'customers':
          csvContent = _exportCustomers(appState);
          fileName = 'customers_${DateTime.now().millisecondsSinceEpoch}.csv';
          break;
        default:
          throw Exception('Unknown export type');
      }

      await _shareFile(csvContent, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportAll() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final appState = context.read<AppState>();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final files = <XFile>[];
      final tempDir = await getTemporaryDirectory();

      // Orders
      final ordersCSV = await appState.exportOrdersCSV(
        from: _selectedRange?.start,
        to: _selectedRange?.end,
      );
      final ordersFile = File('${tempDir.path}/orders_$timestamp.csv');
      await ordersFile.writeAsString(ordersCSV);
      files.add(XFile(ordersFile.path));

      // Products
      final productsCSV = await appState.exportProductsCSV();
      final productsFile = File('${tempDir.path}/products_$timestamp.csv');
      await productsFile.writeAsString(productsCSV);
      files.add(XFile(productsFile.path));

      // Expenses
      final expensesCSV = await appState.exportExpensesCSV(
        from: _selectedRange?.start,
        to: _selectedRange?.end,
      );
      final expensesFile = File('${tempDir.path}/expenses_$timestamp.csv');
      await expensesFile.writeAsString(expensesCSV);
      files.add(XFile(expensesFile.path));

      // Customers
      final customersCSV = _exportCustomers(appState);
      final customersFile = File('${tempDir.path}/customers_$timestamp.csv');
      await customersFile.writeAsString(customersCSV);
      files.add(XFile(customersFile.path));

      await SharePlus.instance.share(
        ShareParams(
          files: files,
          subject: 'VoicePOS Data Export',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportSalesPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final appState = context.read<AppState>();
      final from = _selectedRange?.start ?? DateTime.now();
      final to = _selectedRange?.end ?? DateTime.now().add(const Duration(days: 1));
      final orders = await appState.getOrdersByDateRange(from, to);
      final bytes = await _buildSalesPdfBytes(appState.shopName, orders, from, to);
      final fileName = 'sales_report_${_dateRangeString()}.pdf';
      await _shareBytesFile(bytes, fileName, mimeType: 'application/pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<Uint8List> _buildSalesPdfBytes(
    String shopName,
    List<OrderModel> orders,
    DateTime from,
    DateTime to,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');

    final totalSales = orders.fold<double>(0, (sum, o) => sum + o.grandTotal);
    final cashTotal = orders
        .where((o) => o.paymentMode.name == 'cash')
      .fold<double>(0, (sum, o) => sum + o.grandTotal);
    final upiTotal = orders
        .where((o) => o.paymentMode.name == 'upi')
      .fold<double>(0, (sum, o) => sum + o.grandTotal);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text(
            shopName.isEmpty ? 'Smart Billing Sales Report' : '$shopName - Sales Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Period: ${dateFormat.format(from)} to ${dateFormat.format(to.subtract(const Duration(days: 1)))}'),
          pw.SizedBox(height: 12),
          pw.Text('Total Orders: ${orders.length}'),
          pw.Text('Total Revenue: ₹${totalSales.toStringAsFixed(2)}'),
          pw.Text('Cash: ₹${cashTotal.toStringAsFixed(2)} | UPI: ₹${upiTotal.toStringAsFixed(2)}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Invoice', 'Date', 'Amount', 'Payment'],
            data: orders
                .map(
                  (o) => [
                    o.invoiceNumber,
                    DateFormat('dd/MM/yyyy HH:mm').format(o.createdAt),
                    '₹${o.grandTotal.toStringAsFixed(2)}',
                    o.paymentMode.label,
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _shareBytesFile(
    Uint8List bytes,
    String fileName, {
    String? mimeType,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        text: fileName,
      ),
    );
  }

  String _exportCustomers(AppState appState) {
    final buffer = StringBuffer();
    buffer.writeln('Name,Phone,Credit Balance,Created At');

    for (final c in appState.customers) {
      buffer.writeln(
        '"${c.name}",'
        '${c.phone},'
        '${c.creditBalance.toStringAsFixed(2)},'
        '${c.createdAt.toIso8601String()}',
      );
    }

    return buffer.toString();
  }

  Future<void> _shareFile(String content, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(content);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'VoicePOS Export: $fileName',
      ),
    );
  }

  String _dateRangeString() {
    if (_selectedRange == null) return 'all';
    final format = DateFormat('yyyyMMdd');
    return '${format.format(_selectedRange!.start)}_${format.format(_selectedRange!.end)}';
  }
}

class _ExportOptionCard extends StatelessWidget {
  const _ExportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onExport,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: isLoading ? null : onExport,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.share,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
