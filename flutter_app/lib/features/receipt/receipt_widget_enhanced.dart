import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class ReceiptWidget extends StatelessWidget {
  final String orgName;
  final String? orgAddress;
  final String? logoUrl;
  final File? logoFile; // local cached file — takes priority over logoUrl
  final String? registrationNo;
  final String? presidentName;
  final String? vicePresidentName;
  final String? secretaryName;
  final String? treasurerName;
  final String receiptNo;
  final DateTime dateTime;
  final String donorName;
  final String? donorPhone;
  final String? donorAddress;
  final String? donorPan;
  final double amount;
  final String method;
  final String? footerText;
  final List<String> footerLines;
  final String? paymentStatus; // NEW: Payment status
  /// Optional portrait photo shown bottom-left (politician / reputed person)
  final String? footerLeftImageUrl;
  /// Optional portrait photo shown bottom-right (president / mandal head)
  final String? footerRightImageUrl;
  /// Caption under the left portrait (e.g. person's name)
  final String? footerLeftImageName;
  /// Designation under the left portrait (e.g. "Chief Guest", "MLA")
  final String? footerLeftImageDesignation;
  /// Caption under the right portrait (e.g. president's name)
  final String? footerRightImageName;
  /// Designation under the right portrait (e.g. "President", "Adhyaksha")
  final String? footerRightImageDesignation;
  /// Whether the left portrait is enabled (shown) in the receipt
  final bool footerLeftEnabled;
  /// Whether the right portrait is enabled (shown) in the receipt
  final bool footerRightEnabled;

  const ReceiptWidget({
    super.key,
    required this.orgName,
    this.orgAddress,
    this.logoUrl,
    this.logoFile,
    this.registrationNo,
    this.presidentName,
    this.vicePresidentName,
    this.secretaryName,
    this.treasurerName,
    required this.receiptNo,
    required this.dateTime,
    required this.donorName,
    this.donorPhone,
    this.donorAddress,
    this.donorPan,
    required this.amount,
    required this.method,
    this.footerText,
    required this.footerLines,
    this.paymentStatus = 'PAID', // Default to PAID
    this.footerLeftImageUrl,
    this.footerRightImageUrl,
    this.footerLeftImageName,
    this.footerLeftImageDesignation,
    this.footerRightImageName,
    this.footerRightImageDesignation,
    this.footerLeftEnabled = true,
    this.footerRightEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER SECTION
          _buildHeader(),
          
          const SizedBox(height: 12),
          const Divider(thickness: 2),
          const SizedBox(height: 12),
          
          // RECEIPT TITLE
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'दान पावती / DONATION RECEIPT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // RECEIPT DETAILS
          _buildRow('पावती क्र. / Receipt No.', receiptNo, isBold: true),
          const SizedBox(height: 6),
          _buildRow(
            'तारीख / Date',
            DateFormat('dd MMM yyyy, HH:mm').format(dateTime),
          ),
          
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          
          // DONOR DETAILS
          const Text(
            'देणगीदाराची माहिती / Donor Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildRow('नाव / Name', donorName),
          
          if (donorPhone != null && donorPhone!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildRow('फोन / Phone', donorPhone!),
          ],
          
          if (donorAddress != null && donorAddress!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildRow('पत्ता / Address', donorAddress!, maxLines: 2),
          ],
          
          if (donorPan != null && donorPan!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildRow('PAN', donorPan!),
          ],
          
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          
          // AMOUNT SECTION
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.orange.shade50],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'रक्कम / Amount:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'पेमेंट / Payment:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      method.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                // Show payment status badge for all statuses
                if (paymentStatus != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: paymentStatus == 'PAID'
                          ? Colors.green.shade100
                          : paymentStatus == 'PENDING' 
                              ? Colors.orange.shade200 
                              : Colors.red.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          paymentStatus == 'PAID'
                              ? Icons.check_circle
                              : paymentStatus == 'PENDING' 
                                  ? Icons.schedule 
                                  : Icons.cancel,
                          size: 20,
                          color: paymentStatus == 'PAID'
                              ? Colors.green.shade900
                              : paymentStatus == 'PENDING' 
                                  ? Colors.orange.shade900 
                                  : Colors.red.shade900,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          paymentStatus == 'PAID'
                              ? '✅ पेमेंट प्राप्त / Payment Received'
                              : paymentStatus == 'PENDING' 
                                  ? '⏳ पेमेंट प्रलंबित / Payment Pending' 
                                  : '❌ रद्द केले / Cancelled',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: paymentStatus == 'PAID'
                                ? Colors.green.shade900
                                : paymentStatus == 'PENDING' 
                                    ? Colors.orange.shade900 
                                    : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 14),
          const Divider(thickness: 2),
          const SizedBox(height: 12),
          
          // PORTRAIT IMAGES — shown just above the footer
          if ((footerLeftImageUrl != null && footerLeftEnabled) ||
              (footerRightImageUrl != null && footerRightEnabled)) ...[
            ..._buildFooterPortraits(),
            const SizedBox(height: 8),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
          ],
          
          // FOOTER SECTION
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Build logo widget (prefer local cached file → network URL → fallback icon)
    Widget logoWidget;
    if (logoFile != null && logoFile!.existsSync()) {
      logoWidget = Container(
        height: 110,
        width: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange, width: 3),
        ),
        child: ClipOval(
          child: Image.file(logoFile!, fit: BoxFit.cover),
        ),
      );
    } else if (logoUrl != null && logoUrl!.isNotEmpty) {
      logoWidget = Container(
        height: 110,
        width: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange, width: 3),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: logoUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Icon(Icons.account_balance, size: 55),
          ),
        ),
      );
    } else {
      logoWidget = Container(
        height: 110,
        width: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange, width: 3),
          color: Colors.orange.shade50,
        ),
        child: const Icon(Icons.account_balance, size: 55, color: Colors.orange),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left column — prominent logo
        logoWidget,
        const SizedBox(width: 16),
        // Right column — tenant details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orgName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (orgAddress != null && orgAddress!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  orgAddress!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
              if (registrationNo != null && registrationNo!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  'नोंदणी क्र.: $registrationNo',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Officials
        if (presidentName != null ||
            vicePresidentName != null ||
            secretaryName != null ||
            treasurerName != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'पदाधिकारी / Officials',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                if (presidentName != null && presidentName!.isNotEmpty)
                  _buildOfficialRow('अध्यक्ष / President', presidentName!),
                if (vicePresidentName != null && vicePresidentName!.isNotEmpty)
                  _buildOfficialRow('उपाध्यक्ष / Vice President', vicePresidentName!),
                if (secretaryName != null && secretaryName!.isNotEmpty)
                  _buildOfficialRow('सचिव / Secretary', secretaryName!),
                if (treasurerName != null && treasurerName!.isNotEmpty)
                  _buildOfficialRow('खजिनदार / Treasurer', treasurerName!),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        
        // Footer Text
        if (footerText != null && footerText!.isNotEmpty) ...[
          Text(
            footerText!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
        ],
        
        // Footer Lines
        ...footerLines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            )),
        
        const SizedBox(height: 8),
        
        // Digital Signature
        Text(
          'This is a computer generated receipt',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade400,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Builds the portrait row directly above the receipt footer.
  /// - Both enabled  → two-column centred layout.
  /// - Only one enabled → single portrait left-aligned (whichever is on).
  List<Widget> _buildFooterPortraits() {
    final bool showLeft  = footerLeftImageUrl  != null && footerLeftEnabled;
    final bool showRight = footerRightImageUrl != null && footerRightEnabled;

    if (!showLeft && !showRight) return [];

    if (showLeft && showRight) {
      // Two portraits — standard side-by-side centred layout
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPortraitCard(
              imageUrl: footerLeftImageUrl!,
              name: footerLeftImageName,
              designation: footerLeftImageDesignation,
              alignment: CrossAxisAlignment.center,
            ),
            _buildPortraitCard(
              imageUrl: footerRightImageUrl!,
              name: footerRightImageName,
              designation: footerRightImageDesignation,
              alignment: CrossAxisAlignment.center,
            ),
          ],
        ),
      ];
    }

    // Only one portrait — always render it on the left side
    final String  singleUrl         = showLeft ? footerLeftImageUrl!        : footerRightImageUrl!;
    final String? singleName        = showLeft ? footerLeftImageName        : footerRightImageName;
    final String? singleDesignation = showLeft ? footerLeftImageDesignation : footerRightImageDesignation;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortraitCard(
            imageUrl: singleUrl,
            name: singleName,
            designation: singleDesignation,
            alignment: CrossAxisAlignment.start,
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    ];
  }

  Widget _buildPortraitCard({
    required String imageUrl,
    String? name,
    String? designation,
    CrossAxisAlignment alignment = CrossAxisAlignment.center,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange.shade400, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person, size: 52, color: Colors.grey),
              ),
            ),
          ),
          if (name != null && name.isNotEmpty) ...[  
            const SizedBox(height: 4),
            SizedBox(
              width: 120,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (designation != null && designation.isNotEmpty) ...[  
            const SizedBox(height: 2),
            SizedBox(
              width: 120,
              child: Text(
                designation,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOfficialRow(String title, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
