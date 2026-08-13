import '../../data/datasources/knowledge_document_remote_datasource.dart';
import '../interface_repositories/knowledge_document_repository.dart';

class UploadKnowledgeDocumentUseCase {
  final KnowledgeDocumentRepository repository;

  UploadKnowledgeDocumentUseCase(this.repository);

  Future<void> execute({
    required String token,
    required KnowledgeUploadFile file,
    String? title,
    required String accessScope,
  }) {
    return repository.uploadDocument(
      token: token,
      file: file,
      title: title,
      accessScope: accessScope,
    );
  }
}
