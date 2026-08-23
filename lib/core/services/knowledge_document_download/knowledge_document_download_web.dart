// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadKnowledgeDocument({
  required Uint8List bytes,
  required String contentType,
  required String fileName,
}) async {
  final blob = html.Blob([bytes], contentType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  try {
    html.document.body?.append(anchor);
    anchor.click();
  } finally {
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
