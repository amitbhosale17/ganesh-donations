import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'receipt_generator.dart';

/// Mobile printer service — image-based receipt printing and sharing.
/// Renders the receipt as a Flutter widget image so Marathi / Devanāgarī
/// text is handled correctly by the Flutter engine.
class PrinterServiceMobile {

  // ─── Print ────────────────────────────────────────────────────────────────

  Future<bool> printReceipt({
    required String receiptNo,
    required String donorName,
    String? donorPhone,
    String? donorAddress,
    String? donorPan,
    required double amount,
    required String method,
    required DateTime dateTime,
    required String organizationName,
    String? organizationAddress,
    String? logoUrl,
    String? registrationNo,
    String? presidentName,
    String? vicePresidentName,
    String? secretaryName,
    String? treasurerName,
    String? paymentStatus,
    List<String>? footerLines,
  }) async {
    try {
      debugPrint('📄 Generating graphical receipt image for printing...');

      // Render receipt as a Flutter widget image — same approach used by
      // Receipt Details › Print & Share, so Marathi/Devanāgarī text is
      // rendered correctly by the Flutter engine.
      final imageBytes = await ReceiptGenerator.generateReceiptImage(
        receiptNo: receiptNo,
        donorName: donorName,
        donorPhone: donorPhone ?? '',
        donorAddress: donorAddress ?? '',
        donorPan: donorPan ?? '',
        amount: amount,
        method: method,
        dateTime: dateTime,
        organizationName: organizationName,
        organizationAddress: organizationAddress ?? '',
        logoUrl: logoUrl,
        upiQrUrl: null, // skip QR for print to keep layout clean
        registrationNo: registrationNo,
        presidentName: presidentName,
        vicePresidentName: vicePresidentName,
        secretaryName: secretaryName,
        treasurerName: treasurerName,
        paymentStatus: paymentStatus ?? 'PAID',
        footerLines: footerLines ?? ['Thank you for your donation! 🙏'],
        width: 800,
      );

      if (imageBytes == null) {
        debugPrint('❌ Failed to generate receipt image');
        return false;
      }

      debugPrint('✅ Receipt image generated (${imageBytes.length} bytes), embedding in PDF...');

      // Wrap the image in an A4 PDF page — mirrors receipt_page.dart _handlePrint
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context ctx) =>
              pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'Receipt_$receiptNo.pdf',
        format: PdfPageFormat.a4,
      );

      debugPrint('🖨️ Print dialog opened');
      return true;
    } catch (e, st) {
      debugPrint('❌ Print error: $e\n$st');
      return false;
    }
  }

  /// Share receipt image (for WhatsApp, etc.)
  Future<bool> shareReceipt({
    required String receiptNo,
    required String donorName,
    String? donorPhone,
    String? donorAddress,
    String? donorPan,
    required double amount,
    required String method,
    required DateTime dateTime,
    required String organizationName,
    String? organizationAddress,
    String? logoUrl,
    String? upiQrUrl,
    String? registrationNo,
    String? presidentName,
    String? vicePresidentName,
    String? secretaryName,
    String? treasurerName,
    String? paymentStatus,
    List<String>? footerLines,
  }) async {
    try {
      debugPrint('📤 Generating receipt image for sharing...');
      
      // Generate receipt as image with UPI QR
      final imageBytes = await ReceiptGenerator.generateReceiptImage(
        receiptNo: receiptNo,
        donorName: donorName,
        donorPhone: donorPhone ?? '',
        donorAddress: donorAddress ?? '',
        donorPan: donorPan ?? '',
        amount: amount,
        method: method,
        dateTime: dateTime,
        organizationName: organizationName,
        organizationAddress: organizationAddress ?? '',
        logoUrl: logoUrl,
        upiQrUrl: upiQrUrl, // Include QR for sharing
        registrationNo: registrationNo,
        presidentName: presidentName,
        vicePresidentName: vicePresidentName,
        secretaryName: secretaryName,
        treasurerName: treasurerName,
        paymentStatus: paymentStatus ?? 'PAID',
        footerLines: footerLines ?? ['Thank you! 🙏'],
        width: 800,
      );

      if (imageBytes == null) {
        debugPrint('❌ Failed to generate receipt');
        return false;
      }

      debugPrint('✅ Generated receipt (${imageBytes.length} bytes)');

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/receipt_$receiptNo.png');
      await tempFile.writeAsBytes(imageBytes);
      
      debugPrint('💬 Opening share dialog...');
      
      // Share file
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Receipt: $receiptNo',
        text: 'Receipt for $donorName - ₹${amount.toStringAsFixed(2)}',
      );
      
      // Clean up temp file after delay
      Future.delayed(const Duration(seconds: 10), () {
        try {
          tempFile.delete();
        } catch (_) {}
      });

      debugPrint('✅ Share dialog opened');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Share error: $e');
      debugPrint('Stack: $stackTrace');
      return false;
    }
  }
}
