// Web-specific CSV download using dart:html
import 'dart:html' as html;

class CsvDownloadHelper {
  static void downloadCsv(dynamic response, String filename) {
    final blob = html.Blob([response.data], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
