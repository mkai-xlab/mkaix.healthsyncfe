import '../../data/datasources/knowledge_document_remote_datasource.dart';
import '../interface_repositories/knowledge_document_repository.dart';

class UploadKnowledgeDocumentsBatchUseCase {
  final KnowledgeDocumentRepository repository;

  UploadKnowledgeDocumentsBatchUseCase(this.repository);

  Future<void> execute({
    required String token,
    required List<KnowledgeUploadFile> files,
    required String accessScope,
  }) {
    return repository.uploadDocumentsBatch(
      token: token,
      files: files,
      accessScope: accessScope,
    );
  }
}
