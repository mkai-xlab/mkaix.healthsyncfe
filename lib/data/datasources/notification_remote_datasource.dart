import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final http.Client client;

  NotificationRemoteDataSource(this.client);

  Future<List<NotificationEntity>> getNotifications({
    required String token,
  }) async {
    return _getNotificationList(
      uri: Uri.parse(ApiConstants.notificationsEndpoint),
      token: token,
    );
  }

  Future<List<NotificationEntity>> getUnreadNotifications({
    required String token,
  }) async {
    return _getNotificationList(
      uri: Uri.parse(ApiConstants.notificationsUnreadEndpoint),
      token: token,
    );
  }

  Future<List<NotificationEntity>> _getNotificationList({
    required Uri uri,
    required String token,
  }) async {
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

  Future<int> markAllAsRead({required String token}) async {
    final uri = Uri.parse(ApiConstants.markAllNotificationsReadEndpoint);
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
        'Khong the danh dau tat ca thong bao da doc (${response.statusCode})',
      );
    }

    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) return 0;
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return _parseInt(decoded['updatedCount']);
    }
    return 0;
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
