import '../../data/datasources/knowledge_document_remote_datasource.dart';
import '../interface_repositories/knowledge_document_repository.dart';

class DownloadKnowledgeDocumentUseCase {
  final KnowledgeDocumentRepository repository;

  DownloadKnowledgeDocumentUseCase(this.repository);

  Future<KnowledgeDocumentPreviewFile> execute({
    required String token,
    required int id,
    required String fallbackFileName,
  }) {
    return repository.downloadDocument(
      token: token,
      id: id,
      fallbackFileName: fallbackFileName,
    );
  }
}
