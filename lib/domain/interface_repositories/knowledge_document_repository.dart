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
}
