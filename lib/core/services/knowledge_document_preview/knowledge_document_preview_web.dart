// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openKnowledgeDocumentPreview({
  required Uint8List bytes,
  required String contentType,
  required String fileName,
}) async {
  final blob = html.Blob([bytes], contentType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  try {
    html.window.open(url, '_blank');
  } finally {
    Future<void>.delayed(const Duration(seconds: 30), () {
      html.Url.revokeObjectUrl(url);
    });
  }
}
