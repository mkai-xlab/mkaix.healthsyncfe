// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

String _createPdfObjectUrl(Uint8List bytes) {
  final blob = html.Blob([bytes], 'application/pdf');
  return html.Url.createObjectUrlFromBlob(blob);
}

Future<void> previewPdf(Uint8List bytes, {required String fileName}) async {
  final url = _createPdfObjectUrl(bytes);
  html.window.open(url, '_blank');
}

Future<void> downloadPdf(Uint8List bytes, {required String fileName}) async {
  final url = _createPdfObjectUrl(bytes);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
