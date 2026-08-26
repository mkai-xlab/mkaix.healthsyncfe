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

  @override
  Future<KnowledgeDocumentPreviewFile> previewDocument({
    required String token,
    required int id,
    required String fallbackFileName,
  }) {
    return remoteDataSource.previewDocument(
      token: token,
      id: id,
      fallbackFileName: fallbackFileName,
    );
  }

  @override
  Future<KnowledgeDocumentPreviewFile> downloadDocument({
    required String token,
    required int id,
    required String fallbackFileName,
  }) {
    return remoteDataSource.downloadDocument(
      token: token,
      id: id,
      fallbackFileName: fallbackFileName,
    );
  }

  @override
  Future<void> deleteDocument({required String token, required int id}) {
    return remoteDataSource.deleteDocument(token: token, id: id);
  }
}
