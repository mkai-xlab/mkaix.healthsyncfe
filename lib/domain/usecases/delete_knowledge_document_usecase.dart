import '../interface_repositories/knowledge_document_repository.dart';

class DeleteKnowledgeDocumentUseCase {
  final KnowledgeDocumentRepository repository;

  DeleteKnowledgeDocumentUseCase(this.repository);

  Future<void> execute({required String token, required int id}) {
    return repository.deleteDocument(token: token, id: id);
  }
}
