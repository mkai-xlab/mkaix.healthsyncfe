import '../../data/datasources/knowledge_document_remote_datasource.dart';
import '../../data/models/knowledge_document_model.dart';

abstract class KnowledgeDocumentRepository {
  Future<List<KnowledgeDocumentModel>> getDocuments({required String token});

  Future<void> uploadDocument({
    required String token,
    required KnowledgeUploadFile file,
    String? title,
    required String accessScope,
  });

  Future<void> uploadDocumentsBatch({
    required String token,
    required List<KnowledgeUploadFile> files,
    required String accessScope,
  });

  Future<KnowledgeDocumentPreviewFile> previewDocument({
    required String token,
    required int id,
    required String fallbackFileName,
  });

  Future<KnowledgeDocumentPreviewFile> downloadDocument({
    required String token,
    required int id,
    required String fallbackFileName,
  });

  Future<void> deleteDocument({required String token, required int id});
}
