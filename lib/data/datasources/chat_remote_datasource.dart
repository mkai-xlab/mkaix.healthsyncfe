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
          body: jsonEncode({'question': question}),
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
