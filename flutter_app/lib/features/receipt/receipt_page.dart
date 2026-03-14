import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../l10n/app_localizations.dart';
import '../../core/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../services/logo_cache_service.dart';
import 'receipt_widget_enhanced.dart';

class ReceiptPage extends StatefulWidget {
  final String receiptNo;
  final String donorName;
  final String? donorPhone;
  final String? donorAddress;
  final String? donorPan;
  final double amount;
  final String method;
  final DateTime dateTime;
  final String? organizationName;
  final String? organizationAddress;
  final bool isProvisional;
  final String? paymentStatus;
  /// When true, the print dialog is automatically triggered after the receipt
  /// is rendered on-screen — same reliable capture path as the manual Print button.
  final bool autoPrint;

  const ReceiptPage({
    super.key,
    required this.receiptNo,
    required this.donorName,
    this.donorPhone,
    this.donorAddress,
    this.donorPan,
    required this.amount,
    required this.method,
    required this.dateTime,
    this.organizationName,
    this.organizationAddress,
    this.isProvisional = false,
    this.paymentStatus = 'PAID',
    this.autoPrint = false,
  });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  /// GlobalKey on RepaintBoundary wrapping ReceiptWidget.
  /// Captures the on-screen widget as PNG — far more reliable than
  /// off-screen rendering: logos already loaded, no image pipeline issues.
  final GlobalKey _repaintKey = GlobalKey();

  /// Locally cached logo file — loaded in initState, null if not cached yet
  File? _logoFile;

  @override
  void initState() {
    super.initState();
    _initReceiptData();
  }

  /// Refresh tenant (footer_lines, logo_url, QR url, etc.) and download the
  /// logo so the first print/share capture always shows correct content.
  Future<void> _initReceiptData() async {
    // Refresh tenant first — gets latest footer_lines, logo_url, upi_qr_url
    await AuthService.refreshTenant();

    // Ensure logo is locally cached (download if new device / URL changed)
    final tenant = AuthService.getCurrentTenant();
    await LogoCacheService.cacheLogoFromTenant(tenant);

    // Reload cached file and rebuild so the widget shows fresh content
    final file = await LogoCacheService.getCachedLogoFile();
    if (mounted) {
      setState(() => _logoFile = file);
    }

    // Auto-print: give layout a moment to settle after the setState above
    if (widget.autoPrint && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _handlePrint(context);
    }
  }

  // ─── Image capture ────────────────────────────────────────────────────────

  Future<Uint8List?> _captureReceiptImage() async {
    try {
      // Small delay to ensure widget fully rendered and network images loaded
      await Future.delayed(const Duration(milliseconds: 400));
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('RepaintBoundary not found');
        return null;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      debugPrint('Captured receipt: ${bytes?.length} bytes');
      return bytes;
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  // ─── Print ────────────────────────────────────────────────────────────────

  Future<void> _handlePrint(BuildContext context) async {
    // Refresh tenant so footer_lines / logo are up-to-date, then rebuild the
    // widget before capturing — this fixes footer missing on first attempt.
    await AuthService.refreshTenant();
    if (mounted) {
      setState(() {});
      // One frame for the widget tree to rebuild with fresh data
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Preparing receipt for printing...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      final imageBytes = await _captureReceiptImage();
      if (imageBytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Could not capture receipt.\nTry using Share instead.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Share Instead',
                textColor: Colors.white,
                onPressed: () => _handleShare(context),
              ),
            ),
          );
        }
        return;
      }

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
        name: 'Receipt_${widget.receiptNo}.pdf',
        format: PdfPageFormat.a4,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Print dialog opened! Select your printer to print.')),
            ]),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Print error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e\nTry using Share instead.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Share Instead',
              textColor: Colors.white,
              onPressed: () => _handleShare(context),
            ),
          ),
        );
      }
    }
  }

  // ─── Share ────────────────────────────────────────────────────────────────

  Future<void> _handleShare(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Refresh tenant + rebuild so footer_lines / logo are current before capture
    await AuthService.refreshTenant();
    if (mounted) {
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating receipt image...')),
      );
    }

    try {
      // Capture the on-screen receipt as PNG (reliable — widget already rendered)
      final imageBytes = await _captureReceiptImage();
      if (imageBytes == null) {
        await _fallbackToTextShare(context);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile =
          File('${tempDir.path}/receipt_${widget.receiptNo}.png');
      try {
        await tempFile.writeAsBytes(imageBytes);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save receipt: $e')),
          );
        }
        await _fallbackToTextShare(context);
        return;
      }

      if (widget.donorPhone != null && widget.donorPhone!.isNotEmpty) {
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.shareReceipt),
            content: Text('${l10n.shareViaWhatsapp}\n${widget.donorPhone}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'whatsapp'),
                child: Text(l10n.whatsappToDonor),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'other'),
                child: Text(l10n.otherApps),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        );

        if (choice == null) {
          try {
            await tempFile.delete();
          } catch (_) {}
          return;
        }

        if (choice == 'whatsapp') {
          await _shareImageToWhatsApp(context, widget.donorPhone!, tempFile);
        } else {
          await Share.shareXFiles(
            [XFile(tempFile.path)],
            subject: '${l10n.receiptNo}: ${widget.receiptNo}',
          );
        }
      } else {
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: '${l10n.receiptNo}: ${widget.receiptNo}',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.receiptSharedSuccessfully)),
        );
      }

      Future.delayed(const Duration(seconds: 5), () {
        try {
          tempFile.delete();
        } catch (_) {}
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorOccurred}: $e')),
        );
      }
      await _fallbackToTextShare(context);
    }
  }

  /// Last-resort fallback: share as formatted text if image capture fails
  Future<void> _fallbackToTextShare(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final tenant = AuthService.getCurrentTenant();
    final orgName =
        widget.organizationName ?? tenant?['name'] ?? 'Organization';
    final orgAddress =
        widget.organizationAddress ?? tenant?['address'] ?? '';
    // Use configurable header_text set by admin in Settings
    // e.g. 'Shivaji Maharaj Jayanti!', 'Ganpati Bappa Morya!', 'Eid Mubarak!'
    final headerLine =
        (tenant?['header_text']?.toString().isNotEmpty == true)
            ? tenant!['header_text'] as String
            : l10n.thankYou;

    final statusLine = widget.paymentStatus == 'PAID'
        ? 'Payment Received'
        : widget.paymentStatus == 'PENDING'
            ? 'Payment Pending'
            : widget.paymentStatus == 'CANCELLED'
                ? 'Cancelled'
                : '';

    final receiptText = '''
*$orgName*
$orgAddress

${l10n.receiptNo}: ${widget.receiptNo}
${l10n.date}: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.dateTime)}

${l10n.donor}: ${widget.donorName}
${widget.donorPhone?.isNotEmpty == true ? '${l10n.phone}: ${widget.donorPhone}' : ''}
${widget.donorAddress?.isNotEmpty == true ? '${l10n.address}: ${widget.donorAddress}' : ''}
${widget.donorPan?.isNotEmpty == true ? 'PAN: ${widget.donorPan}' : ''}

${l10n.amount}: Rs.${widget.amount.toStringAsFixed(2)}
${l10n.method}: ${widget.method.toUpperCase()}
$statusLine

$headerLine
${l10n.thankYou}!
${tenant?['footer_text'] ?? ''}
''';

    try {
      await Share.share(receiptText,
          subject: '${l10n.receiptNo}: ${widget.receiptNo}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _shareImageToWhatsApp(
      BuildContext context, String phoneNumber, File imageFile) async {
    try {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        subject: 'Receipt: ${widget.receiptNo}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tenant = AuthService.getCurrentTenant();

    // Footer greeting: use tenant header_text (set in Admin -> Settings)
    // Examples: 'Ganpati Bappa Morya', 'Shivaji Maharaj Jayanti', 'Eid Mubarak'
    final List<String> footerLines;
    final rawFooterLines = tenant?['footer_lines'];
    if (rawFooterLines is List && rawFooterLines.isNotEmpty) {
      footerLines = rawFooterLines.map((e) => e.toString()).toList();
    } else if (tenant?['header_text']?.toString().isNotEmpty == true) {
      footerLines = [tenant!['header_text'] as String, l10n.thankYou];
    } else {
      footerLines = [l10n.thankYou];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receiptDetails),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: Column(
        children: [
          if (widget.isProvisional)
            Container(
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(Icons.offline_bolt, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tatpurti Pavati (Offline Mode)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                // RepaintBoundary with GlobalKey:
                // Captures the visible receipt as screenshot for print & share.
                // The widget is already rendered on-screen so logos/images load
                // reliably - avoids all off-screen rendering pitfalls.
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: ReceiptWidget(
                    orgName: widget.organizationName ??
                        tenant?['name'] ??
                        'Organization',
                    orgAddress:
                        widget.organizationAddress ?? tenant?['address'],
                    logoUrl: tenant?['logo_url'],
                    logoFile: _logoFile,
                    registrationNo: tenant?['registration_no'],
                    presidentName: tenant?['president_name'],
                    vicePresidentName: tenant?['vice_president_name'],
                    secretaryName: tenant?['secretary_name'],
                    treasurerName: tenant?['treasurer_name'],
                    receiptNo: widget.receiptNo,
                    dateTime: widget.dateTime,
                    donorName: widget.donorName,
                    donorPhone: widget.donorPhone,
                    donorAddress: widget.donorAddress,
                    donorPan: widget.donorPan,
                    amount: widget.amount,
                    method: widget.method,
                    footerText: tenant?['footer_text'],
                    footerLines: footerLines,
                    paymentStatus: widget.paymentStatus,
                    footerLeftImageUrl: tenant?['footer_left_image_url'],
                    footerRightImageUrl: tenant?['footer_right_image_url'],
                    footerLeftImageName: tenant?['footer_left_image_name'],
                    footerLeftImageDesignation: tenant?['footer_left_image_designation'],
                    footerRightImageName: tenant?['footer_right_image_name'],
                    footerRightImageDesignation: tenant?['footer_right_image_designation'],
                    footerLeftEnabled: tenant?['footer_left_image_enabled'] != false,
                    footerRightEnabled: tenant?['footer_right_image_enabled'] != false,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: l10n.printReceipt,
                          onPressed:
                              (widget.paymentStatus == 'CANCELLED' ||
                                      widget.paymentStatus == 'PENDING')
                                  ? null
                                  : () => _handlePrint(context),
                          icon: Icons.print,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: l10n.shareReceipt,
                          onPressed:
                              (widget.paymentStatus == 'CANCELLED' ||
                                      widget.paymentStatus == 'PENDING')
                                  ? null
                                  : () => _handleShare(context),
                          icon: Icons.share,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                    child: Text(l10n.backToHome),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
