// Stub file for non-web platforms
class PrinterService {
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
    // Printing not available on mobile platforms
    return false;
  }
}
