import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/business_profile_model.dart';
import '../models/order_model.dart';
import '../services/app_state.dart';
import '../services/invoice_service.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({
    super.key,
    required this.order,
    this.customerPhone,
  });

  final OrderModel order;
  final String? customerPhone;

  Future<String?> _askPhoneNumber(BuildContext context) async {
    final controller = TextEditingController(text: customerPhone ?? '');
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Customer WhatsApp Number'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Enter customer number',
              prefixText: '+91 ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.read<AppState>().profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            onPressed: () async {
              var phone = customerPhone?.trim();
              if (phone == null || phone.isEmpty) {
                phone = await _askPhoneNumber(context);
              }
              if (phone == null || phone.isEmpty) {
                return;
              }
              await InvoiceService.shareViaWhatsApp(
                phone: phone,
                message: order.toBillText(profile?.shopName ?? ''),
              );
            },
            icon: const Icon(Icons.share),
            tooltip: 'Share via WhatsApp',
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => InvoiceService.generatePdf(
          order: order,
          profile: profile ?? const BusinessProfile(shopName: ''),
        ),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
