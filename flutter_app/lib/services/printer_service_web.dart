import 'dart:html' as html;
import 'package:flutter/material.dart';

class PrinterService {
  /// Print receipt using browser's print dialog
  /// This works for both desktop and mobile browsers
  static Future<bool> printReceipt({
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
      final printContent = _generatePrintableReceipt(
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
        registrationNo: registrationNo,
        presidentName: presidentName,
        vicePresidentName: vicePresidentName,
        secretaryName: secretaryName,
        treasurerName: treasurerName,
        paymentStatus: paymentStatus,
        footerLines: footerLines,
      );

      // Create a blob with the HTML content
      final blob = html.Blob([printContent], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Open in new window and print
      final printWindow = html.window.open(url, '_blank', 'width=300,height=600');
      
      if (printWindow == null) {
        html.Url.revokeObjectUrl(url);
        return false;
      }

      // Wait for content to load, then print and close
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Clean up
      html.Url.revokeObjectUrl(url);
      
      return true;
    } catch (e) {
      debugPrint('Print error: $e');
      return false;
    }
  }

  static String _generatePrintableReceipt({
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
  }) {
    final formattedDate = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    String statusBadge = '';
    String statusColor = '#4CAF50';
    
    if (paymentStatus != null) {
      switch (paymentStatus) {
        case 'PAID':
          statusBadge = '<div style="background: #4CAF50; color: white; padding: 4px 8px; border-radius: 4px; text-align: center; margin: 10px 0; font-weight: bold;">✓ PAID</div>';
          statusColor = '#4CAF50';
          break;
        case 'PENDING':
          statusBadge = '<div style="background: #FF9800; color: white; padding: 4px 8px; border-radius: 4px; text-align: center; margin: 10px 0; font-weight: bold;">⏳ PENDING</div>';
          statusColor = '#FF9800';
          break;
        case 'CANCELLED':
          statusBadge = '<div style="background: #F44336; color: white; padding: 4px 8px; border-radius: 4px; text-align: center; margin: 10px 0; font-weight: bold;">✗ CANCELLED</div>';
          statusColor = '#F44336';
          break;
      }
    }
    
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    @page {
      size: 80mm auto;
      margin: 0;
    }
    body {
      font-family: Arial, sans-serif;
      width: 80mm;
      margin: 0;
      padding: 10px;
      font-size: 12px;
    }
    .header {
      text-align: center;
      margin-bottom: 15px;
      border-bottom: 2px solid #000;
      padding-bottom: 10px;
    }
    .logo {
      max-width: 60px;
      max-height: 60px;
      margin-bottom: 5px;
    }
    .org-name {
      font-size: 16px;
      font-weight: bold;
      margin: 5px 0;
    }
    .org-address {
      font-size: 10px;
      color: #666;
    }
    .receipt-title {
      font-size: 14px;
      font-weight: bold;
      text-align: center;
      margin: 10px 0;
      text-decoration: underline;
    }
    .receipt-no {
      text-align: center;
      font-size: 11px;
      margin-bottom: 10px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      margin: 5px 0;
      padding: 3px 0;
    }
    .info-label {
      font-weight: bold;
      flex: 0 0 40%;
    }
    .info-value {
      flex: 0 0 58%;
      text-align: right;
    }
    .amount-row {
      border-top: 2px dashed #000;
      border-bottom: 2px dashed #000;
      padding: 10px 0;
      margin: 10px 0;
      font-size: 14px;
      font-weight: bold;
    }
    .footer {
      margin-top: 15px;
      text-align: center;
      font-size: 10px;
      border-top: 1px solid #000;
      padding-top: 10px;
    }
    .officials {
      margin-top: 15px;
      font-size: 9px;
      border-top: 1px dashed #000;
      padding-top: 8px;
    }
    .official-item {
      margin: 3px 0;
    }
  </style>
</head>
<body>
  <div class="header">
    ${logoUrl != null ? '<img src="$logoUrl" class="logo" />' : ''}
    <div class="org-name">$organizationName</div>
    ${organizationAddress != null ? '<div class="org-address">$organizationAddress</div>' : ''}
    ${registrationNo != null ? '<div class="org-address">Reg. No: $registrationNo</div>' : ''}
  </div>

  <div class="receipt-title">DONATION RECEIPT</div>
  <div class="receipt-no">Receipt No: $receiptNo</div>
  
  $statusBadge

  <div class="info-row">
    <span class="info-label">Name:</span>
    <span class="info-value">$donorName</span>
  </div>
  ${donorPhone != null ? '<div class="info-row"><span class="info-label">Phone:</span><span class="info-value">$donorPhone</span></div>' : ''}
  ${donorAddress != null ? '<div class="info-row"><span class="info-label">Address:</span><span class="info-value">$donorAddress</span></div>' : ''}
  ${donorPan != null ? '<div class="info-row"><span class="info-label">PAN:</span><span class="info-value">$donorPan</span></div>' : ''}
  
  <div class="info-row">
    <span class="info-label">Date:</span>
    <span class="info-value">$formattedDate $formattedTime</span>
  </div>
  
  <div class="info-row">
    <span class="info-label">Method:</span>
    <span class="info-value">$method</span>
  </div>

  <div class="amount-row">
    <div class="info-row">
      <span class="info-label">Amount:</span>
      <span class="info-value" style="color: $statusColor;">₹ ${amount.toStringAsFixed(2)}</span>
    </div>
  </div>

  ${presidentName != null || vicePresidentName != null || secretaryName != null || treasurerName != null ? '''
  <div class="officials">
    <div style="text-align: center; font-weight: bold; margin-bottom: 5px;">Office Bearers</div>
    ${presidentName != null ? '<div class="official-item">President: $presidentName</div>' : ''}
    ${vicePresidentName != null ? '<div class="official-item">Vice President: $vicePresidentName</div>' : ''}
    ${secretaryName != null ? '<div class="official-item">Secretary: $secretaryName</div>' : ''}
    ${treasurerName != null ? '<div class="official-item">Treasurer: $treasurerName</div>' : ''}
  </div>
  ''' : ''}

  <div class="footer">
    ${footerLines?.join('<br>') ?? 'Thank you for your donation! 🙏'}
  </div>

  <script>
    window.onload = function() {
      window.print();
    };
    window.onafterprint = function() {
      window.close();
    };
  </script>
</body>
</html>
''';
  }
}
