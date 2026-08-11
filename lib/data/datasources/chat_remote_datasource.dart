import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/chat_answer_model.dart';

class ChatRemoteDataSource {
  final http.Client client;

  ChatRemoteDataSource(this.client);

  Future<ChatAnswerModel> ask({
    required String question,
    required String token,
    int? sessionId,
  }) async {
    final uri = Uri.parse(ApiConstants.chatAskEndpoint);
    debugPrint(
      '[Chat API request] POST $uri, '
      'Authorization=${token.trim().isEmpty ? 'missing' : 'Bearer ***'}',
      wrapWidth: 1024,
    );

    final response = await client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'question': question,
            if (sessionId != null) 'sessionId': sessionId,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_httpErrorMessage(response));
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw Exception('Dinh dang phan hoi AI chat khong hop le');
    }

    return ChatAnswerModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<List<ChatSessionModel>> getSessions({
    required String token,
    int page = 0,
    int size = 20,
  }) async {
    final uri = Uri.parse(
      ApiConstants.chatSessionsEndpoint,
    ).replace(queryParameters: {'page': '$page', 'size': '$size'});
    final decoded = await _getJson(uri: uri, token: token);
    return _extractList(decoded)
        .whereType<Map>()
        .map(
          (item) => ChatSessionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((session) => session.id > 0)
        .toList();
  }

  Future<ChatSessionModel> createSession({
    required String token,
    String? title,
    int? examinationId,
  }) async {
    final uri = Uri.parse(ApiConstants.chatSessionsEndpoint);
    final response = await client
        .post(
          uri,
          headers: _jsonHeaders(token),
          body: jsonEncode({
            if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
            if (examinationId != null) 'examinationId': examinationId,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_httpErrorMessage(response));
    }

    final decoded = _decode(response);
    if (decoded is! Map) {
      throw Exception('Dinh dang phien AI chat khong hop le');
    }
    return ChatSessionModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<ChatSessionModel> updateSession({
    required int sessionId,
    required String token,
    String? title,
    bool? active,
  }) async {
    final uri = Uri.parse(ApiConstants.chatSessionEndpoint(sessionId));
    final response = await client
        .patch(
          uri,
          headers: _jsonHeaders(token),
          body: jsonEncode({
            if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
            if (active != null) 'active': active,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_httpErrorMessage(response));
    }

    final decoded = _decode(response);
    if (decoded is! Map) {
      throw Exception('Dinh dang phien AI chat khong hop le');
    }
    return ChatSessionModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<List<ChatMessageModel>> getSessionMessages({
    required int sessionId,
    required String token,
    int page = 0,
    int size = 50,
  }) async {
    final uri = Uri.parse(
      ApiConstants.chatSessionMessagesEndpoint(sessionId),
    ).replace(queryParameters: {'page': '$page', 'size': '$size'});
    final decoded = await _getJson(uri: uri, token: token);
    return _extractList(decoded)
        .whereType<Map>()
        .map(
          (item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((message) => message.content.trim().isNotEmpty)
        .toList();
  }

  Future<Object?> _getJson({required Uri uri, required String token}) async {
    debugPrint(
      '[Chat API request] GET $uri, '
      'Authorization=${token.trim().isEmpty ? 'missing' : 'Bearer ***'}',
      wrapWidth: 1024,
    );

    final response = await client
        .get(uri, headers: _jsonHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_httpErrorMessage(response));
    }

    return _decode(response);
  }

  Map<String, String> _jsonHeaders(String token) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Object? _decode(http.Response response) {
    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  List<dynamic> _extractList(Object? decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['content', 'data', 'items', 'sessions', 'messages']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  String _httpErrorMessage(http.Response response) {
    final fallback = 'Khong the gui cau hoi AI (${response.statusCode})';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return fallback;
  }
}
