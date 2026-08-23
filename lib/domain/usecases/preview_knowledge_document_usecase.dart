import '../../data/datasources/knowledge_document_remote_datasource.dart';
import '../interface_repositories/knowledge_document_repository.dart';

class PreviewKnowledgeDocumentUseCase {
  final KnowledgeDocumentRepository repository;

  PreviewKnowledgeDocumentUseCase(this.repository);

  Future<KnowledgeDocumentPreviewFile> execute({
    required String token,
    required int id,
    required String fallbackFileName,
  }) {
    return repository.previewDocument(
      token: token,
      id: id,
      fallbackFileName: fallbackFileName,
    );
  }
}
