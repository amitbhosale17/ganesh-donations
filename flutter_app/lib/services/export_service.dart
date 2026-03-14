import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/api_client.dart';

class ExportService {
  /// Get Downloads directory path
  static Future<String> getDownloadsPath() async {
    if (Platform.isAndroid) {
      // Android Downloads folder
      return '/storage/emulated/0/Download';
    } else if (Platform.isIOS) {
      // iOS Documents folder (accessible via Files app)
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } else {
      // Desktop/Web fallback
      final directory = await getDownloadsDirectory();
      return directory?.path ?? '';
    }
  }

  /// Request storage permission (Android only)
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      
      final result = await Permission.storage.request();
      if (result.isGranted) return true;
      
      // Try manageExternalStorage permission for Android 11+
      if (await Permission.manageExternalStorage.isGranted) return true;
      
      final manageResult = await Permission.manageExternalStorage.request();
      return manageResult.isGranted;
    }
    return true; // iOS doesn't need permission for app documents
  }

  /// Export donations to CSV in Downloads folder
  static Future<Map<String, dynamic>> exportDonationsToCSV({
    String? startDate,
    String? endDate,
    String? method,
    String? paymentStatus,
  }) async {
    try {
      // Request permission
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        return {
          'success': false,
          'error': 'Storage permission denied',
        };
      }

      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (method != null) queryParams['method'] = method;
      if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;

      // Download CSV from API with extended timeout for large datasets
      final response = await ApiClient.dio.get(
        '/donations/export.csv',
        queryParameters: queryParams,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 5), // Handle large exports
        ),
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error': 'Failed to download CSV',
        };
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'donations_$timestamp.csv';

      // Get Downloads path
      final downloadsPath = await getDownloadsPath();
      final filePath = '$downloadsPath/$fileName';

      // Write file with comprehensive error handling
      try {
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        return {
          'success': true,
          'filePath': filePath,
          'fileName': fileName,
        };
      } on FileSystemException catch (e) {
        if (e.message.contains('No space left') || e.message.contains('ENOSPC')) {
          return {
            'success': false,
            'error': 'Storage full. Please free up space and try again.',
          };
        } else if (e.message.contains('Permission denied') || e.message.contains('EACCES')) {
          return {
            'success': false,
            'error': 'Cannot write to Downloads folder. Please check app permissions.',
          };
        } else {
          return {
            'success': false,
            'error': 'File write failed: ${e.message}',
          };
        }
      }
    } catch (e) {
      print('Error exporting CSV: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete exported file
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}
