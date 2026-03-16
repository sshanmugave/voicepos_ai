import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../services/app_state.dart';
import '../services/invoice_service.dart';
import 'invoice_screen.dart';

class BillSummaryScreen extends StatefulWidget {
  const BillSummaryScreen({super.key});

  @override
  State<BillSummaryScreen> createState() => _BillSummaryScreenState();
}

class _BillSummaryScreenState extends State<BillSummaryScreen> {
  PaymentMode _paymentMode = PaymentMode.cash;
  Customer? _selectedCustomer;
  OrderModel? _savedOrder;
  final TextEditingController _cashReceivedCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _whatsAppPhoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final total = context.read<AppState>().draftGrandTotal;
      _cashReceivedCtrl.text = total.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _cashReceivedCtrl.dispose();
    _notesCtrl.dispose();
    _customerNameCtrl.dispose();
    _whatsAppPhoneCtrl.dispose();
    super.dispose();
  }

  double _roundUp(double amount, double step) {
    return (amount / step).ceil() * step;
  }

  String? _normalizedPhone() {
    final digits = _whatsAppPhoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    if (digits.length < 10) return null;
    return digits;
  }

  Future<Customer?> _upsertOptionalCustomer(AppState appState) async {
    final name = _customerNameCtrl.text.trim();
    final phone = _normalizedPhone() ?? _whatsAppPhoneCtrl.text.trim();

    if (_selectedCustomer != null) {
      final hasName = name.isNotEmpty && name != _selectedCustomer!.name;
      final hasPhone = phone.isNotEmpty && phone != _selectedCustomer!.phone;
      if (hasName || hasPhone) {
        final updatedCustomer = _selectedCustomer!.copyWith(
          name: hasName ? name : _selectedCustomer!.name,
          phone: hasPhone ? phone : _selectedCustomer!.phone,
        );
        await appState.updateCustomer(updatedCustomer);
        final refreshed = appState.customers.firstWhere(
          (entry) => entry.id == updatedCustomer.id,
          orElse: () => updatedCustomer,
        );
        _selectedCustomer = refreshed;
      }
      return _selectedCustomer;
    }

    if (phone.isEmpty) {
      return null;
    }

    final created = Customer(
      id: 0,
      name: name.isNotEmpty ? name : 'Walk-in ${phone.substring(phone.length - 4)}',
      phone: phone,
      createdAt: DateTime.now(),
    );
    final id = await appState.addCustomer(created);
    final customer = appState.customers.firstWhere((entry) => entry.id == id);
    _selectedCustomer = customer;
    if (_customerNameCtrl.text.trim().isEmpty) {
      _customerNameCtrl.text = customer.name;
    }
    if (_whatsAppPhoneCtrl.text.trim().isEmpty) {
      _whatsAppPhoneCtrl.text = customer.phone;
    }
    return customer;
  }

  Future<void> _shareBillOnWhatsApp(AppState appState) async {
    final order = _savedOrder;
    if (order == null) return;

    final phone = _normalizedPhone();
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid customer WhatsApp number to share directly.'),
        ),
      );
      return;
    }

    await InvoiceService.shareViaWhatsApp(
      phone: phone,
      message: order.toBillText(appState.profile?.shopName ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = _savedOrder?.items ?? appState.draftItems;
    final grandTotal = _savedOrder?.grandTotal ?? appState.draftGrandTotal;
    final subtotal = _savedOrder?.subtotal ?? appState.draftSubtotal;
    final taxAmount = _savedOrder?.taxAmount ?? appState.draftTaxAmount;
    final cashReceived = double.tryParse(_cashReceivedCtrl.text.trim()) ?? 0;
    final cashShortfall = grandTotal - cashReceived;
    final changeAmount = cashReceived - grandTotal;
    final upiString =
      'upi://pay?pa=shanmuga007@oksbi&pn=${Uri.encodeComponent(appState.shopName)}&am=${grandTotal.toStringAsFixed(2)}';
    final confirmDisabled = _savedOrder != null ||
      items.isEmpty ||
      (_paymentMode == PaymentMode.credit && _selectedCustomer == null) ||
      (_paymentMode == PaymentMode.cash &&
        _cashReceivedCtrl.text.trim().isNotEmpty &&
        cashReceived < grandTotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Summary')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Order items ───
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Review',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text('${item.quantity}×',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ),
                                Expanded(child: Text(item.name)),
                                Text('₹${item.subtotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )),
                      const Divider(),
                      _SummaryRow(label: 'Subtotal', value: subtotal),
                      if (taxAmount > 0)
                        _SummaryRow(label: 'GST', value: taxAmount),
                      _SummaryRow(
                        label: 'Grand Total',
                        value: grandTotal,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Payment mode ───
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Mode',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      SegmentedButton<PaymentMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: PaymentMode.cash, label: Text('Cash')),
                          ButtonSegment(
                              value: PaymentMode.upi, label: Text('UPI')),
                          ButtonSegment(
                              value: PaymentMode.card, label: Text('Card')),
                          ButtonSegment(
                              value: PaymentMode.credit, label: Text('Credit')),
                        ],
                        selected: {_paymentMode},
                        onSelectionChanged: (s) {
                          setState(() => _paymentMode = s.first);
                          if (s.first == PaymentMode.cash &&
                              _cashReceivedCtrl.text.trim().isEmpty) {
                            _cashReceivedCtrl.text = grandTotal.toStringAsFixed(0);
                          }
                        },
                      ),

                      if (_paymentMode == PaymentMode.cash) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _cashReceivedCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Cash Received',
                            prefixText: '₹',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('Exact'),
                              onPressed: () {
                                _cashReceivedCtrl.text = grandTotal.toStringAsFixed(0);
                                setState(() {});
                              },
                            ),
                            ActionChip(
                              label: Text('₹${_roundUp(grandTotal, 10).toStringAsFixed(0)}'),
                              onPressed: () {
                                _cashReceivedCtrl.text =
                                    _roundUp(grandTotal, 10).toStringAsFixed(0);
                                setState(() {});
                              },
                            ),
                            ActionChip(
                              label: Text('₹${_roundUp(grandTotal, 50).toStringAsFixed(0)}'),
                              onPressed: () {
                                _cashReceivedCtrl.text =
                                    _roundUp(grandTotal, 50).toStringAsFixed(0);
                                setState(() {});
                              },
                            ),
                            ActionChip(
                              label: Text('₹${_roundUp(grandTotal, 100).toStringAsFixed(0)}'),
                              onPressed: () {
                                _cashReceivedCtrl.text =
                                    _roundUp(grandTotal, 100).toStringAsFixed(0);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cashShortfall > 0 ? 'Amount Due' : 'Change'),
                              Text(
                                '₹${(cashShortfall > 0 ? cashShortfall : changeAmount).abs().toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // UPI QR
                      if (_paymentMode == PaymentMode.upi) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: QrImageView(
                            data: upiString,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                            child: Text(
                                'Scan to pay ₹${grandTotal.toStringAsFixed(0)}')),
                      ],

                      // Credit → customer picker
                      if (_paymentMode == PaymentMode.credit) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Customer>(
                          initialValue: _selectedCustomer,
                          decoration: const InputDecoration(
                            labelText: 'Select Customer',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: appState.customers
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                        '${c.name} (₹${c.creditBalance.toStringAsFixed(0)} due)'),
                                  ))
                              .toList(),
                          onChanged: (c) => setState(() {
                            _selectedCustomer = c;
                            if ((c?.name ?? '').trim().isNotEmpty) {
                              _customerNameCtrl.text = c!.name.trim();
                            }
                            if ((c?.phone ?? '').trim().isNotEmpty) {
                              _whatsAppPhoneCtrl.text = c!.phone.trim();
                            }
                          }),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showAddCustomerDialog(context),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add New Customer'),
                        ),
                        if (_selectedCustomer != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Current due: ₹${_selectedCustomer!.creditBalance.toStringAsFixed(2)} • New due after bill: ₹${(_selectedCustomer!.creditBalance + grandTotal).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],

                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Payment Notes',
                          hintText: 'Optional note for invoice or order record',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customerNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          hintText: 'Optional',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _whatsAppPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Customer WhatsApp Number',
                          hintText: 'Optional, for direct bill sharing',
                          prefixIcon: const Icon(Icons.phone_android),
                          suffixIcon: _selectedCustomer != null &&
                                  (_selectedCustomer!.phone).trim().isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _whatsAppPhoneCtrl.text =
                                        _selectedCustomer!.phone.trim();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.download_for_offline_outlined),
                                  tooltip: 'Use selected customer number',
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ─── Confirm ───
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: confirmDisabled
                      ? null
                      : () async {
                          final appState = context.read<AppState>();
                          final optionalCustomer = await _upsertOptionalCustomer(
                            appState,
                          );
                          final notes = <String>[];
                          if (_notesCtrl.text.trim().isNotEmpty) {
                            notes.add(_notesCtrl.text.trim());
                          }
                          if (_paymentMode == PaymentMode.cash) {
                            final effectiveCash = _cashReceivedCtrl.text.trim().isEmpty
                                ? grandTotal
                                : cashReceived;
                            if (effectiveCash > 0) {
                              notes.add(
                                'Cash received ₹${effectiveCash.toStringAsFixed(2)}',
                              );
                            }
                            if (effectiveCash > grandTotal) {
                              notes.add(
                                'Change returned ₹${(effectiveCash - grandTotal).toStringAsFixed(2)}',
                              );
                            }
                          }
                          final order =
                              await appState.completeOrder(
                                    paymentMode: _paymentMode,
                                customerId: optionalCustomer?.id ?? _selectedCustomer?.id,
                                customerName: optionalCustomer?.name ??
                                  (_customerNameCtrl.text.trim().isNotEmpty
                                    ? _customerNameCtrl.text.trim()
                                    : _selectedCustomer?.name),
                                    notes: notes.join(' | '),
                                  );
                          setState(() => _savedOrder = order);
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(
                      _savedOrder == null ? 'Confirm Order' : 'Order Saved ✓'),
                ),
              ),

              // ─── Post-order actions ───
              if (_savedOrder != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  InvoiceScreen(
                                    order: _savedOrder!,
                                    customerPhone: _normalizedPhone(),
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Invoice'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareBillOnWhatsApp(appState),
                        icon: const Icon(Icons.share),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('New Bill'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCustomerDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final appState = context.read<AppState>();
              final customer = Customer(
                id: 0,
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                createdAt: DateTime.now(),
              );
              final id = await appState.addCustomer(customer);
              if (!mounted) return;
              final createdCustomer = appState
                  .customers
                  .firstWhere((entry) => entry.id == id);
              setState(() {
                _selectedCustomer = createdCustomer;
                _customerNameCtrl.text = createdCustomer.name.trim();
                if (createdCustomer.phone.trim().isNotEmpty) {
                  _whatsAppPhoneCtrl.text = createdCustomer.phone.trim();
                }
              });
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}