import 'dart:typed_data';

import 'knowledge_document_download/knowledge_document_download_stub.dart'
    if (dart.library.html) 'knowledge_document_download/knowledge_document_download_web.dart'
    as download;

Future<void> downloadKnowledgeDocument({
  required Uint8List bytes,
  required String contentType,
  required String fileName,
}) {
  return download.downloadKnowledgeDocument(
    bytes: bytes,
    contentType: contentType,
    fileName: fileName,
  );
}
