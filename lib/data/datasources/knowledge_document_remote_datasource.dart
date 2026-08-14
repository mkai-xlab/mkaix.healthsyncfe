import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/knowledge_document_model.dart';

class KnowledgeDocumentRemoteDataSource {
  final http.Client client;

  const KnowledgeDocumentRemoteDataSource(this.client);

  Future<List<KnowledgeDocumentModel>> getDocuments({
    required String token,
  }) async {
    final response = await client.get(
      Uri.parse(ApiConstants.knowledgeDocumentsEndpoint),
      headers: _headers(token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_httpErrorMessage(response));
    }

    final decoded = _decode(response);
    final items = _extractList(decoded);
    return items
        .whereType<Map>()
        .map(
          (item) =>
              KnowledgeDocumentModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> uploadDocument({
    required String token,
    required KnowledgeUploadFile file,
    String? title,
    required String accessScope,
  }) async {
    final uri = Uri.parse(ApiConstants.knowledgeDocumentUploadEndpoint).replace(
      queryParameters: {
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'accessScope': accessScope,
      },
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeader(token))
      ..files.add(await _multipartFile('file', file));

    await _sendMultipart(request);
  }

  Future<void> uploadDocumentsBatch({
    required String token,
    required List<KnowledgeUploadFile> files,
    required String accessScope,
  }) async {
    final uri = Uri.parse(
      ApiConstants.knowledgeDocumentBatchUploadEndpoint,
    ).replace(queryParameters: {'accessScope': accessScope});

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeader(token));
    for (final file in files) {
      request.files.add(await _multipartFile('files', file));
    }

    await _sendMultipart(request);
  }

  Future<void> _sendMultipart(http.MultipartRequest request) async {
    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_httpErrorMessage(response));
    }
  }

  Future<http.MultipartFile> _multipartFile(
    String field,
    KnowledgeUploadFile file,
  ) async {
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        field,
        file.bytes!,
        filename: file.name,
      );
    }
    if (file.path != null && file.path!.isNotEmpty) {
      return http.MultipartFile.fromPath(
        field,
        file.path!,
        filename: file.name,
      );
    }
    throw Exception('Không thể đọc dữ liệu file ${file.name}');
  }

  Map<String, String> _headers(String token) {
    return {'Accept': 'application/json', ..._authHeader(token)};
  }

  Map<String, String> _authHeader(String token) {
    return {'Authorization': 'Bearer $token'};
  }

  Object? _decode(http.Response response) {
    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  List<dynamic> _extractList(Object? decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['content', 'data', 'items', 'documents']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  String _httpErrorMessage(http.Response response) {
    final fallback = 'Không thể xử lý tài liệu (${response.statusCode})';
    try {
      final decoded = _decode(response);
      if (decoded is Map) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return fallback;
  }
}

class KnowledgeUploadFile {
  final String name;
  final int size;
  final String? path;
  final List<int>? bytes;

  const KnowledgeUploadFile({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
  });
}
