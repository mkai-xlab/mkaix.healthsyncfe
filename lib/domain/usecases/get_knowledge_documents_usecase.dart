import '../../data/models/knowledge_document_model.dart';
import '../interface_repositories/knowledge_document_repository.dart';

class GetKnowledgeDocumentsUseCase {
  final KnowledgeDocumentRepository repository;

  GetKnowledgeDocumentsUseCase(this.repository);

  Future<List<KnowledgeDocumentModel>> execute({required String token}) {
    return repository.getDocuments(token: token);
  }
}
