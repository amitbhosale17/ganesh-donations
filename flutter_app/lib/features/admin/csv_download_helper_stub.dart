// Stub for non-web platforms
import 'package:flutter/material.dart';

class CsvDownloadHelper {
  static void downloadCsv(dynamic response, String filename) {
    debugPrint('CSV download not available on this platform');
    // Could show a snackbar or dialog to the user
  }
}
