import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Manages caching the organisation logo to the local device.
///
/// Flow:
///   1. After login / tenant refresh, call [cacheLogoFromTenant].
///   2. It compares the stored URL with the new one.
///      - Same URL + file already exists → skip download.
///      - Different URL or file missing  → download and overwrite.
///   3. [getCachedLogoFile] returns the local File (or null if not cached).
///   4. On logout, call [clearCache].
class LogoCacheService {
  static const _storage = FlutterSecureStorage();
  static const _cachedLogoUrlKey = 'cached_logo_url';
  static const _logoFileName = 'org_logo.png';

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Downloads and caches the tenant logo locally.
  /// Safe to call fire-and-forget — errors are swallowed silently.
  static Future<void> cacheLogoFromTenant(Map<String, dynamic>? tenant) async {
    final logoUrl = tenant?['logo_url'] as String?;
    if (logoUrl == null || logoUrl.isEmpty) return;

    try {
      final cachedUrl = await _storage.read(key: _cachedLogoUrlKey);
      final localFile = await _getLocalLogoFile();

      // Nothing to do if URL unchanged and file already on disk
      if (cachedUrl == logoUrl && await localFile.exists()) {
        debugPrint('LogoCache: up-to-date, skipping download');
        return;
      }

      debugPrint('LogoCache: downloading $logoUrl');
      final dio = Dio();
      final response = await dio.get<List<int>>(
        logoUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data != null && response.data!.isNotEmpty) {
        await localFile.writeAsBytes(response.data!);
        await _storage.write(key: _cachedLogoUrlKey, value: logoUrl);
        debugPrint('LogoCache: saved to ${localFile.path}');
      }
    } catch (e) {
      // Non-critical — receipt will fall back to CachedNetworkImage
      debugPrint('LogoCache: download failed: $e');
    }
  }

  /// Returns the cached [File] if it exists on disk, otherwise null.
  static Future<File?> getCachedLogoFile() async {
    try {
      final file = await _getLocalLogoFile();
      if (await file.exists()) return file;
    } catch (e) {
      debugPrint('LogoCache: getCachedLogoFile error: $e');
    }
    return null;
  }

  /// Deletes the cached logo and stored URL (call on logout).
  static Future<void> clearCache() async {
    try {
      final file = await _getLocalLogoFile();
      if (await file.exists()) await file.delete();
      await _storage.delete(key: _cachedLogoUrlKey);
      debugPrint('LogoCache: cache cleared');
    } catch (_) {}
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  static Future<File> _getLocalLogoFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_logoFileName');
  }
}
