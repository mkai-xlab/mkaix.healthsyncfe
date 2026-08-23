import 'package:flutter/foundation.dart';

import '../../data/datasources/knowledge_document_remote_datasource.dart';
import '../../data/models/knowledge_document_model.dart';
import '../../domain/usecases/delete_knowledge_document_usecase.dart';
import '../../domain/usecases/download_knowledge_document_usecase.dart';
import '../../domain/usecases/get_knowledge_documents_usecase.dart';
import '../../domain/usecases/preview_knowledge_document_usecase.dart';
import '../../domain/usecases/upload_knowledge_document_usecase.dart';
import '../../domain/usecases/upload_knowledge_documents_batch_usecase.dart';

class KnowledgeDocumentViewModel extends ChangeNotifier {
  static const _sessionExpiredMessage =
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  static const _genericDocumentErrorMessage =
      'Không thể xử lý tài liệu. Vui lòng thử lại.';

  final GetKnowledgeDocumentsUseCase getDocumentsUseCase;
  final UploadKnowledgeDocumentUseCase uploadDocumentUseCase;
  final UploadKnowledgeDocumentsBatchUseCase uploadDocumentsBatchUseCase;
  final DeleteKnowledgeDocumentUseCase deleteDocumentUseCase;
  final PreviewKnowledgeDocumentUseCase previewDocumentUseCase;
  final DownloadKnowledgeDocumentUseCase downloadDocumentUseCase;

  KnowledgeDocumentViewModel({
    required this.getDocumentsUseCase,
    required this.uploadDocumentUseCase,
    required this.uploadDocumentsBatchUseCase,
    required this.deleteDocumentUseCase,
    required this.previewDocumentUseCase,
    required this.downloadDocumentUseCase,
  });

  final List<KnowledgeDocumentModel> _documents = [];
  final Set<int> _deletingDocumentIds = {};
  final Set<int> _previewingDocumentIds = {};
  final Set<int> _downloadingDocumentIds = {};

  bool _isLoading = false;
  bool _isUploading = false;
  String? _loadErrorMessage;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedStatus = 'ALL';

  List<KnowledgeDocumentModel> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get loadErrorMessage => _loadErrorMessage;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;
  bool isDeletingDocument(int id) => _deletingDocumentIds.contains(id);
  bool isPreviewingDocument(int id) => _previewingDocumentIds.contains(id);
  bool isDownloadingDocument(int id) => _downloadingDocumentIds.contains(id);

  List<KnowledgeDocumentModel> get filteredDocuments {
    final query = _searchQuery.trim().toLowerCase();
    return _documents.where((document) {
      final matchesQuery =
          query.isEmpty ||
          document.displayName.toLowerCase().contains(query) ||
          document.sourceType.toLowerCase().contains(query) ||
          document.accessScope.toLowerCase().contains(query);
      final matchesStatus =
          _selectedStatus == 'ALL' ||
          document.status.toUpperCase() == _selectedStatus;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  List<String> get availableStatuses {
    final statuses =
        _documents
            .map((document) => document.status.trim().toUpperCase())
            .where((status) => status.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['ALL', ...statuses];
  }

  Future<void> loadDocuments(String token) async {
    if (token.trim().isEmpty) {
      _errorMessage = _sessionExpiredMessage;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _loadErrorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await getDocumentsUseCase.execute(token: token);
      _documents
        ..clear()
        ..addAll(result);
    } catch (error) {
      _loadErrorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    _selectedStatus = value;
    notifyListeners();
  }

  void reset() {
    _documents.clear();
    _deletingDocumentIds.clear();
    _previewingDocumentIds.clear();
    _downloadingDocumentIds.clear();
    _isLoading = false;
    _isUploading = false;
    _loadErrorMessage = null;
    _errorMessage = null;
    _searchQuery = '';
    _selectedStatus = 'ALL';
    notifyListeners();
  }

  Future<bool> uploadDocuments({
    required String token,
    required List<KnowledgeUploadFile> files,
    String? title,
    required String accessScope,
  }) async {
    if (files.isEmpty || _isUploading) return false;
    if (token.trim().isEmpty) {
      _errorMessage = _sessionExpiredMessage;
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (files.length == 1) {
        await uploadDocumentUseCase.execute(
          token: token,
          file: files.first,
          title: title,
          accessScope: accessScope,
        );
      } else {
        await uploadDocumentsBatchUseCase.execute(
          token: token,
          files: files,
          accessScope: accessScope,
        );
      }
      await loadDocuments(token);
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      notifyListeners();
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDocument({required String token, required int id}) async {
    if (_deletingDocumentIds.contains(id)) return false;
    if (token.trim().isEmpty) {
      _errorMessage = _sessionExpiredMessage;
      notifyListeners();
      return false;
    }

    _deletingDocumentIds.add(id);
    _errorMessage = null;
    notifyListeners();

    try {
      await deleteDocumentUseCase.execute(token: token, id: id);
      _documents.removeWhere((document) => document.id == id);
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _deletingDocumentIds.remove(id);
      notifyListeners();
    }
  }

  Future<KnowledgeDocumentPreviewFile?> previewDocument({
    required String token,
    required KnowledgeDocumentModel document,
  }) async {
    if (_previewingDocumentIds.contains(document.id)) return null;
    if (token.trim().isEmpty) {
      _errorMessage = _sessionExpiredMessage;
      notifyListeners();
      return null;
    }

    _previewingDocumentIds.add(document.id);
    _errorMessage = null;
    notifyListeners();

    try {
      return await previewDocumentUseCase.execute(
        token: token,
        id: document.id,
        fallbackFileName: document.previewFileName,
      );
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return null;
    } finally {
      _previewingDocumentIds.remove(document.id);
      notifyListeners();
    }
  }

  Future<KnowledgeDocumentPreviewFile?> downloadDocument({
    required String token,
    required KnowledgeDocumentModel document,
  }) async {
    if (_downloadingDocumentIds.contains(document.id)) return null;
    if (token.trim().isEmpty) {
      _errorMessage = _sessionExpiredMessage;
      notifyListeners();
      return null;
    }

    _downloadingDocumentIds.add(document.id);
    _errorMessage = null;
    notifyListeners();

    try {
      return await downloadDocumentUseCase.execute(
        token: token,
        id: document.id,
        fallbackFileName: document.previewFileName,
      );
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return null;
    } finally {
      _downloadingDocumentIds.remove(document.id);
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) return _genericDocumentErrorMessage;
    return raw;
  }
}
