import '../../domain/interface_repositories/knowledge_document_repository.dart';
import '../datasources/knowledge_document_remote_datasource.dart';
import '../models/knowledge_document_model.dart';

class KnowledgeDocumentRepositoryImpl implements KnowledgeDocumentRepository {
  final KnowledgeDocumentRemoteDataSource remoteDataSource;

  KnowledgeDocumentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<KnowledgeDocumentModel>> getDocuments({required String token}) {
    return remoteDataSource.getDocuments(token: token);
  }

  @override
  Future<void> uploadDocument({
    required String token,
    required KnowledgeUploadFile file,
    String? title,
    required String accessScope,
  }) {
    return remoteDataSource.uploadDocument(
      token: token,
      file: file,
      title: title,
      accessScope: accessScope,
    );
  }

  @override
  Future<void> uploadDocumentsBatch({
    required String token,
    required List<KnowledgeUploadFile> files,
    required String accessScope,
  }) {
    return remoteDataSource.uploadDocumentsBatch(
      token: token,
      files: files,
      accessScope: accessScope,
    );
  }
}
