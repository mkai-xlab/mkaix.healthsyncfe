import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../domain/entities/audit_log_page_entity.dart';
import '../models/audit_log_model.dart';

class AuditLogRemoteDataSource {
  final http.Client client;

  const AuditLogRemoteDataSource(this.client);

  Future<AuditLogPageEntity> getAuditLogs({
    required String token,
    int page = 0,
    int size = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };

    final uri = Uri.parse(
      ApiConstants.auditLogsEndpoint,
    ).replace(queryParameters: queryParams);

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
        'Không thể tải nhật ký hoạt động (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is List) {
      final logs = decoded
          .whereType<Map>()
          .map(
            (item) => AuditLogModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return AuditLogPageEntity(
        content: logs,
        totalElements: logs.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: logs.length,
        isLast: true,
      );
    }

    if (decoded is! Map) {
      throw Exception('Định dạng nhật ký hoạt động không hợp lệ');
    }

    final pageData = Map<String, dynamic>.from(decoded);
    final content = pageData['content'];
    final logs = content is List
        ? content
              .whereType<Map>()
              .map(
                (item) =>
                    AuditLogModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <AuditLogModel>[];

    return AuditLogPageEntity(
      content: logs,
      totalElements: _parseInt(pageData['totalElements'], logs.length),
      totalPages: _parseInt(pageData['totalPages'], 1),
      pageNumber: _parseInt(pageData['pageNumber'] ?? pageData['number'], page),
      pageSize: _parseInt(pageData['pageSize'] ?? pageData['size'], size),
      isLast: pageData['isLast'] as bool? ?? pageData['last'] as bool? ?? true,
    );
  }

  static int _parseInt(Object? value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
