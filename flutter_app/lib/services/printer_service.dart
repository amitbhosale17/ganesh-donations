// Platform-specific printer service
// Import the mobile implementation by default, web for browser
import 'printer_service_mobile.dart' if (dart.library.html) 'printer_service_web.dart' as platform;

/// Printer Service - Platform-aware printing and sharing
class PrinterService {
  /// Print receipt - Opens native print dialog
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
  }) {
    return platform.PrinterServiceMobile().printReceipt(
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
  }

  /// Share receipt image - Opens share dialog (WhatsApp, etc.)
  static Future<bool> shareReceipt({
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
  }) {
    return platform.PrinterServiceMobile().shareReceipt(
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
    );
  }
}
