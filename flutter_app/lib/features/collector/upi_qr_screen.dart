import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/auth_service.dart';
import '../../services/qr_cache_service.dart';

class UpiQrScreen extends StatefulWidget {
  final double amount;
  final String donorName;

  const UpiQrScreen({
    super.key,
    required this.amount,
    required this.donorName,
  });

  @override
  State<UpiQrScreen> createState() => _UpiQrScreenState();
}

class _UpiQrScreenState extends State<UpiQrScreen> {
  File? _qrFile;
  String? _qrUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initQr();
  }

  /// Refresh tenant from server so we always have the latest upi_qr_url,
  /// then ensure the image is cached locally (downloads if URL changed or
  /// cache was wiped when Render restarted).
  Future<void> _initQr() async {
    // Always refresh tenant — Render restarts wipe local files AND the
    // old URL may have pointed to a now-deleted local file on the server.
    await AuthService.refreshTenant();

    final tenant = AuthService.getCurrentTenant();
    final qrUrl = tenant?['upi_qr_url'] as String?;

    // Download / refresh local cache
    await QrCacheService.cacheQrFromTenant(tenant);

    final file = await QrCacheService.getCachedQrFile();

    if (mounted) {
      setState(() {
        _qrUrl = qrUrl;
        _qrFile = file;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanQrCode),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : (_qrUrl == null
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  size: 100, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'UPI QR कोड सेट केलेला नाही',
                                style: TextStyle(fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'कृपया ॲडमिनला विनंती करा',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.scanQrCode,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '₹${widget.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                widget.donorName,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                // Prefer local cached file; fall back to network URL
                                child: _qrFile != null
                                    ? Image.file(
                                        _qrFile!,
                                        width: 300,
                                        height: 300,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            _networkQrWidget(),
                                      )
                                    : _networkQrWidget(),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Google Pay, PhonePe, Paytm वापरून',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _qrUrl == null
                      ? null
                      : () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: Text(
                    '✓ ${l10n.confirmPayment}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkQrWidget() {
    if (_qrUrl == null) return const Icon(Icons.error, size: 100, color: Colors.red);
    return CachedNetworkImage(
      imageUrl: _qrUrl!,
      width: 300,
      height: 300,
      fit: BoxFit.contain,
      placeholder: (context, url) => const SizedBox(
        width: 300,
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => const SizedBox(
        width: 300,
        height: 300,
        child: Icon(Icons.error, size: 100, color: Colors.red),
      ),
    );
  }
}
