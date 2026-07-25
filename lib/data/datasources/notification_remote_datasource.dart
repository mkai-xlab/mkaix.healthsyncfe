import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final http.Client client;

  NotificationRemoteDataSource(this.client);

  Future<List<NotificationEntity>> getUnreadNotifications({
    required String token,
  }) async {
    final uri = Uri.parse(ApiConstants.notificationsUnreadEndpoint);
    debugPrint(
      '[Notification API request] GET $uri, '
      'Authorization=${token.trim().isEmpty ? 'missing' : 'Bearer ***'}',
      wrapWidth: 1024,
    );

    final response = await client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải danh sách thông báo (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw Exception('Định dạng danh sách thông báo không hợp lệ');
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => NotificationModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> markAsRead({required int id, required String token}) async {
    final uri = Uri.parse(ApiConstants.markNotificationReadEndpoint(id));
    debugPrint(
      '[Notification API request] PUT $uri, '
      'Authorization=${token.trim().isEmpty ? 'missing' : 'Bearer ***'}',
      wrapWidth: 1024,
    );

    final response = await client
        .put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Không thể đánh dấu thông báo đã đọc (${response.statusCode})',
      );
    }
  }
}
