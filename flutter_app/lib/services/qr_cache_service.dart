import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Manages caching the UPI QR code image to the local device.
///
/// Behaviour mirrors [LogoCacheService]:
///   1. Call [cacheQrFromTenant] after login / tenant refresh.
///   2. Same URL + file already exists → skip download.
///      Different URL or file missing  → download and overwrite.
///   3. [getCachedQrFile] returns the local [File] (or null if not cached).
///   4. On logout, call [clearCache].
///
/// Why cache?
///   The API is hosted on Render's free tier, whose ephemeral filesystem is
///   wiped on every redeploy/restart.  Even after migrating uploads to
///   Cloudinary, the CDN URL stays valid forever — but keeping a local copy
///   means the QR screen works 100% offline too.
class QrCacheService {
  static const _storage = FlutterSecureStorage();
  static const _cachedQrUrlKey = 'cached_upi_qr_url';
  static const _qrFileName = 'upi_qr.png';

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Downloads and caches the tenant UPI QR code locally.
  /// Safe to call fire-and-forget — errors are swallowed silently.
  static Future<void> cacheQrFromTenant(Map<String, dynamic>? tenant) async {
    final qrUrl = tenant?['upi_qr_url'] as String?;
    if (qrUrl == null || qrUrl.isEmpty) return;

    try {
      final cachedUrl = await _storage.read(key: _cachedQrUrlKey);
      final localFile = await _getLocalQrFile();

      if (cachedUrl == qrUrl && await localFile.exists()) {
        debugPrint('QrCache: up-to-date, skipping download');
        return;
      }

      debugPrint('QrCache: downloading $qrUrl');
      final dio = Dio();
      final response = await dio.get<List<int>>(
        qrUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null && response.data!.isNotEmpty) {
        await localFile.writeAsBytes(response.data!);
        await _storage.write(key: _cachedQrUrlKey, value: qrUrl);
        debugPrint('QrCache: saved to ${localFile.path}');
      }
    } catch (e) {
      debugPrint('QrCache: download failed: $e');
    }
  }

  /// Returns the cached [File] if it exists on disk, otherwise null.
  static Future<File?> getCachedQrFile() async {
    try {
      final file = await _getLocalQrFile();
      if (await file.exists()) return file;
    } catch (e) {
      debugPrint('QrCache: getCachedQrFile error: $e');
    }
    return null;
  }

  /// Deletes the cached QR image and stored URL (call on logout).
  static Future<void> clearCache() async {
    try {
      final file = await _getLocalQrFile();
      if (await file.exists()) await file.delete();
      await _storage.delete(key: _cachedQrUrlKey);
      debugPrint('QrCache: cache cleared');
    } catch (_) {}
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  static Future<File> _getLocalQrFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_qrFileName');
  }
}
