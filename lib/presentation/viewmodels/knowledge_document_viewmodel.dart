import 'package:flutter/foundation.dart';

import '../../data/datasources/knowledge_document_remote_datasource.dart';
import '../../data/models/knowledge_document_model.dart';
import '../../domain/usecases/get_knowledge_documents_usecase.dart';
import '../../domain/usecases/upload_knowledge_document_usecase.dart';
import '../../domain/usecases/upload_knowledge_documents_batch_usecase.dart';

class KnowledgeDocumentViewModel extends ChangeNotifier {
  final GetKnowledgeDocumentsUseCase getDocumentsUseCase;
  final UploadKnowledgeDocumentUseCase uploadDocumentUseCase;
  final UploadKnowledgeDocumentsBatchUseCase uploadDocumentsBatchUseCase;

  KnowledgeDocumentViewModel({
    required this.getDocumentsUseCase,
    required this.uploadDocumentUseCase,
    required this.uploadDocumentsBatchUseCase,
  });

  final List<KnowledgeDocumentModel> _documents = [];

  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedStatus = 'ALL';

  List<KnowledgeDocumentModel> get documents => List.unmodifiable(_documents);
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedStatus => _selectedStatus;

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
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await getDocumentsUseCase.execute(token: token);
      _documents
        ..clear()
        ..addAll(result);
    } catch (error) {
      _errorMessage = _friendlyError(error);
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
    _isLoading = false;
    _isUploading = false;
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
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
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

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) return 'Không thể xử lý tài liệu. Vui lòng thử lại.';
    return raw;
  }
}
