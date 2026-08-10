import 'package:flutter/foundation.dart';

import '../../data/datasources/knowledge_document_remote_datasource.dart';
import '../../data/models/knowledge_document_model.dart';

class KnowledgeDocumentViewModel extends ChangeNotifier {
  final KnowledgeDocumentRemoteDataSource remoteDataSource;

  KnowledgeDocumentViewModel(this.remoteDataSource);

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
      final result = await remoteDataSource.getDocuments(token: token);
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
        await remoteDataSource.uploadDocument(
          token: token,
          file: files.first,
          title: title,
          accessScope: accessScope,
        );
      } else {
        await remoteDataSource.uploadDocumentsBatch(
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
