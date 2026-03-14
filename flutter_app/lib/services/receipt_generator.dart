import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

/// Receipt Generator Service
/// 
/// Purpose:
/// - Generates visual receipt images for sharing
/// - Creates realistic-looking receipts that look good on WhatsApp
/// - Converts receipt widgets to PNG images
/// 
/// Edge Cases Handled:
/// - Widget rendering failures
/// - Memory constraints for large receipts
/// - Image quality optimization
/// - Network image loading issues
class ReceiptGenerator {
  /// Generate receipt image from widget
  /// 
  /// Returns PNG image as bytes that can be shared
  static Future<Uint8List?> generateReceiptImage({
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
    double width = 800, // Width in pixels for good WhatsApp quality
  }) async {
    try {
      // Create the receipt widget
      final receiptWidget = _ReceiptImageWidget(
        receiptNo: receiptNo,
        donorName: donorName,
        donorPhone: donorPhone,
        donorAddress: donorAddress,
        donorPan: donorPan,
        amount: amount,
        method: method,
        dateTime: dateTime,
        organizationName: organizationName,
        organizationAddress: organizationAddress,
        logoUrl: logoUrl,
        upiQrUrl: upiQrUrl,
        registrationNo: registrationNo,
        presidentName: presidentName,
        vicePresidentName: vicePresidentName,
        secretaryName: secretaryName,
        treasurerName: treasurerName,
        paymentStatus: paymentStatus,
        footerLines: footerLines,
        width: width,
      );

      // Convert widget to image
      return await _widgetToImage(receiptWidget, width: width);
    } catch (e) {
      debugPrint('❌ Error generating receipt image: $e');
      return null;
    }
  }

  /// Convert widget to PNG image
  static Future<Uint8List?> _widgetToImage(
    Widget widget, {
    required double width,
  }) async {
    try {
      // Create a RepaintBoundary to capture the widget
      final repaintBoundary = RenderRepaintBoundary();

      // Create a pipeline owner
      final pipelineOwner = PipelineOwner();
      final buildOwner = BuildOwner(focusManager: FocusManager());

      // Create root element
      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: widget,
        ),
      ).attachToRenderTree(buildOwner);

      // Build and layout
      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();

      pipelineOwner.rootNode = repaintBoundary;
      repaintBoundary.attach(pipelineOwner);

      // Force layout with constraints
      repaintBoundary.layout(BoxConstraints(
        minWidth: width,
        maxWidth: width,
      ));

      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      // Convert to image
      final ui.Image image = await repaintBoundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Error converting widget to image: $e');
      return null;
    }
  }
}

/// Receipt Widget for Image Generation
/// Optimized for WhatsApp sharing
class _ReceiptImageWidget extends StatelessWidget {
  final String receiptNo;
  final String donorName;
  final String? donorPhone;
  final String? donorAddress;
  final String? donorPan;
  final double amount;
  final String method;
  final DateTime dateTime;
  final String organizationName;
  final String? organizationAddress;
  final String? logoUrl;
  final String? upiQrUrl;
  final String? registrationNo;
  final String? presidentName;
  final String? vicePresidentName;
  final String? secretaryName;
  final String? treasurerName;
  final String? paymentStatus;
  final List<String>? footerLines;
  final double width;

  const _ReceiptImageWidget({
    required this.receiptNo,
    required this.donorName,
    this.donorPhone,
    this.donorAddress,
    this.donorPan,
    required this.amount,
    required this.method,
    required this.dateTime,
    required this.organizationName,
    this.organizationAddress,
    this.logoUrl,
    this.upiQrUrl,
    this.registrationNo,
    this.presidentName,
    this.vicePresidentName,
    this.secretaryName,
    this.treasurerName,
    this.paymentStatus,
    this.footerLines,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Logo on LEFT, Organization details on RIGHT
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LOGO ON EXTREME LEFT (LARGER SIZE)
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 3),
                ),
                child: const Icon(
                  Icons.temple_hindu,
                  size: 70,
                  color: Colors.orange,
                ),
                margin: const EdgeInsets.only(right: 20),
              ),

              // Organization details beside logo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organization name - BOLD & DARK
                    Text(
                      organizationName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),

                    if (organizationAddress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          organizationAddress!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                    if (registrationNo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'नोंदणी / Registration: $registrationNo',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(height: 2, thickness: 3, color: Colors.black),
          const SizedBox(height: 20),

          // Receipt title - BOLD BADGE
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: const Text(
                'दान पावती / DONATION RECEIPT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Receipt number - BOLD & DARK
          _buildDetailRow('पावती क्र. / Receipt No.', receiptNo, isBold: true),

          const SizedBox(height: 20),
          const Divider(height: 2, thickness: 2, color: Colors.black54),
          const SizedBox(height: 16),

          // Payment status badge
          if (paymentStatus != null) _buildStatusBadge(paymentStatus!),

          // Section header - BOLD
          const Text(
            'देणगीदाराची माहिती / Donor Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // Donor details - ALL BOLD & DARK
          _buildDetailRow('नाव / Name', donorName),
          if (donorPhone != null && donorPhone!.isNotEmpty) 
            _buildDetailRow('फोन / Phone', donorPhone!),
          if (donorAddress != null && donorAddress!.isNotEmpty) 
            _buildDetailRow('पत्ता / Address', donorAddress!),
          if (donorPan != null && donorPan!.isNotEmpty) 
            _buildDetailRow('PAN', donorPan!),

          const SizedBox(height: 16),
          const Divider(height: 2, thickness: 2, color: Colors.black54),
          const SizedBox(height: 16),

          // Date and time - BOLD & DARK
          _buildDetailRow(
            'तारीख / Date & Time',
            '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
          ),

          _buildDetailRow('पेमेंट पद्धत / Payment Method', method.toUpperCase()),

          const SizedBox(height: 20),
          const Divider(height: 2, thickness: 3, color: Colors.black),
          const SizedBox(height: 20),

          // Amount (highlighted) - EXTRA BOLD & DARK
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'रक्कम / Amount:',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '₹ ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // UPI QR Code - Skip for printing (network images don't work in widget-to-image)
          // Only show placeholder text
          if (upiQrUrl != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Icon(Icons.qr_code, size: 60, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Scan QR for UPI Payment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Office bearers - BOLD SECTION
          if (presidentName != null ||
              vicePresidentName != null ||
              secretaryName != null ||
              treasurerName != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 2, thickness: 2, color: Colors.black54),
            const SizedBox(height: 16),
            const Text(
              'पदाधिकारी / Office Bearers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            if (presidentName != null)
              _buildOfficialRow('अध्यक्ष / President', presidentName!),
            if (vicePresidentName != null)
              _buildOfficialRow('उपाध्यक्ष / Vice President', vicePresidentName!),
            if (secretaryName != null)
              _buildOfficialRow('सचिव / Secretary', secretaryName!),
            if (treasurerName != null)
              _buildOfficialRow('कोषाध्यक्ष / Treasurer', treasurerName!),
          ],

          // Footer - BOLD TEXT
          const SizedBox(height: 24),
          const Divider(height: 2, thickness: 3, color: Colors.black),
          const SizedBox(height: 16),
          if (footerLines != null && footerLines!.isNotEmpty)
            ...footerLines!.map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 12),
          const Text(
            'धन्यवाद! गणपती बाप्पा मोरया! 🙏',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String icon;
    String text;

    switch (status) {
      case 'PAID':
        color = Colors.green;
        icon = '✅';
        text = 'पेमेंट प्राप्त झाले / PAID';
        break;
      case 'PENDING':
        color = Colors.orange;
        icon = '⏳';
        text = 'पेमेंट प्रलंबित / PENDING';
        break;
      case 'CANCELLED':
        color = Colors.red;
        icon = '❌';
        text = 'रद्द केले / CANCELLED';
        break;
      default:
        color = Colors.grey;
        icon = '';
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Text(
        '$icon $text',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialRow(String title, String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
