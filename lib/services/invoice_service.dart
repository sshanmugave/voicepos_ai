import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

import '../models/business_profile_model.dart';
import '../models/order_model.dart';

class InvoiceService {
  static Future<Uint8List> generatePdf({
    required OrderModel order,
    required BusinessProfile profile,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pw.ImageProvider? logoImage;
    if (profile.logoPath != null && profile.logoPath!.isNotEmpty) {
      final logoFile = File(profile.logoPath!);
      if (await logoFile.exists()) {
        final bytes = await logoFile.readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header ───
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      margin: const pw.EdgeInsets.only(right: 16),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          profile.shopName,
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (profile.address.isNotEmpty)
                          pw.Text(profile.address, style: const pw.TextStyle(fontSize: 10)),
                        if (profile.phone.isNotEmpty)
                          pw.Text('Phone: ${profile.phone}', style: const pw.TextStyle(fontSize: 10)),
                        if (profile.gstNumber.isNotEmpty)
                          pw.Text('GSTIN: ${profile.gstNumber}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.brown,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Invoice: ${order.invoiceNumber}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Date: ${dateFormat.format(order.createdAt)}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2, color: PdfColors.brown),
              pw.SizedBox(height: 8),

              // ─── Customer Info ───
              if (order.customerName != null && order.customerName!.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text('Customer: ${order.customerName}', style: const pw.TextStyle(fontSize: 11)),
                ),

              if (order.customerName != null && order.customerName!.isNotEmpty)
                pw.SizedBox(height: 12),

              // ─── Items Table ───
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.brown50),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                },
                headers: ['Item', 'Qty', 'Rate', 'Disc%', 'GST%', 'GST Amt', 'Amount'],
                data: order.items.map((item) {
                  return [
                    item.name,
                    '${item.quantity}',
                    _currency(item.unitPrice),
                    item.discountPercent > 0 ? '${item.discountPercent.toStringAsFixed(1)}%' : '-',
                    item.gstRate > 0 ? '${item.gstRate.toStringAsFixed(1)}%' : '-',
                    item.gstAmount > 0 ? _currency(item.gstAmount) : '-',
                    _currency(item.subtotal),
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 16),

              // ─── Summary ───
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', _currency(order.subtotal)),
                      if (order.discountAmount > 0)
                        _summaryRow('Discount', '-${_currency(order.discountAmount)}'),
                      if (order.taxAmount > 0) ...[
                        _summaryRow('CGST', _currency(order.taxAmount / 2)),
                        _summaryRow('SGST', _currency(order.taxAmount / 2)),
                      ],
                      pw.Divider(thickness: 1),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Grand Total',
                              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                          pw.Text(_currency(order.grandTotal),
                              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              // ─── Payment Info ───
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment: ${order.paymentMode.label}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text('Status: ${order.paymentStatus.toUpperCase()}',
                        style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),

              if (order.notes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Notes',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(order.notes, style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // ─── Footer ───
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static String _currency(double amount) {
    return '\u20B9${amount.toStringAsFixed(2)}';
  }

  static Future<void> shareViaWhatsApp({
    required String message,
    String? phone,
  }) async {
    final encodedMessage = Uri.encodeComponent(message);
    final cleanPhone = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final normalizedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;

    final appUri = normalizedPhone.isEmpty
        ? Uri.parse('whatsapp://send?text=$encodedMessage')
        : Uri.parse('whatsapp://send?phone=$normalizedPhone&text=$encodedMessage');
    final webUri = normalizedPhone.isEmpty
        ? Uri.parse('https://wa.me/?text=$encodedMessage')
        : Uri.parse('https://wa.me/$normalizedPhone?text=$encodedMessage');

    try {
      final openedApp = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedApp) return;
    } catch (_) {
      // Fallback handled below.
    }

    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}
