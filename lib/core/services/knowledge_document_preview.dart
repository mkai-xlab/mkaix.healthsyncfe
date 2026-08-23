import 'dart:typed_data';

import 'knowledge_document_preview/knowledge_document_preview_stub.dart'
    if (dart.library.html) 'knowledge_document_preview/knowledge_document_preview_web.dart'
    as preview;

Future<void> openKnowledgeDocumentPreview({
  required Uint8List bytes,
  required String contentType,
  required String fileName,
}) {
  return preview.openKnowledgeDocumentPreview(
    bytes: bytes,
    contentType: contentType,
    fileName: fileName,
  );
}
