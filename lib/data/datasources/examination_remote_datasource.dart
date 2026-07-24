import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../domain/entities/examination_entity.dart';
import '../../domain/entities/examination_page_entity.dart';
import '../models/examination_model.dart';

abstract class ExaminationRemoteDataSource {
  Future<ExaminationPageEntity> getExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
  });

  Future<List<ExaminationEntity>> getExaminations({required String token});

  Future<List<ExaminationEntity>> getDoctorExaminations({
    required int doctorId,
    required String token,
  });

  Future<List<ExaminationEntity>> getPatientExaminations({
    required String patientId,
    required String token,
  });
}

class ExaminationRemoteDataSourceImpl implements ExaminationRemoteDataSource {
  final http.Client client;

  ExaminationRemoteDataSourceImpl(this.client);

  @override
  Future<ExaminationPageEntity> getExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
  }) async {
    return _getExaminationsPage(
      endpoint: ApiConstants.examinationsEndpoint,
      token: token,
      page: page,
      size: size,
      errorMessage: 'Không thể tải danh sách ca khám',
    );
  }

  @override
  Future<List<ExaminationEntity>> getExaminations({required String token}) {
    return _getPagedExaminations(
      endpoint: ApiConstants.examinationsEndpoint,
      token: token,
      errorMessage: 'Không thể tải danh sách ca khám',
    );
  }

  @override
  Future<List<ExaminationEntity>> getDoctorExaminations({
    required int doctorId,
    required String token,
  }) {
    return _getPagedExaminations(
      endpoint: ApiConstants.examinationsByDoctorEndpoint(doctorId),
      token: token,
      errorMessage: 'Không thể tải danh sách ca khám của bác sĩ',
    );
  }

  Future<List<ExaminationEntity>> _getPagedExaminations({
    required String endpoint,
    required String token,
    required String errorMessage,
  }) async {
    final examinations = <ExaminationEntity>[];
    var page = 0;
    var isLast = false;

    while (!isLast) {
      final uri = Uri.parse(endpoint).replace(
        queryParameters: {
          'page': page.toString(),
          'size': '100',
          'sort': 'asc',
        },
      );
      _logRequest('GET', uri, token);
      final response = await client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map) {
          final content = data['content'];
          if (content is List) {
            examinations.addAll(
              content.whereType<Map>().map((item) {
                return ExaminationModel.fromJson(
                  Map<String, dynamic>.from(item),
                );
              }),
            );
          }
          isLast = data['isLast'] as bool? ?? data['last'] as bool? ?? true;
        } else if (data is List) {
          examinations.addAll(
            data.whereType<Map>().map((item) {
              return ExaminationModel.fromJson(Map<String, dynamic>.from(item));
            }),
          );
          isLast = true;
        } else {
          throw Exception('Định dạng danh sách ca khám không hợp lệ');
        }
        page++;
        continue;
      }

      if (response.statusCode != 200) {
        throw Exception(_httpErrorMessage(response.statusCode, errorMessage));
      }
    }

    examinations.sort((a, b) {
      final bTime = b.visitTime ?? b.studyDate ?? DateTime(1900);
      final aTime = a.visitTime ?? a.studyDate ?? DateTime(1900);
      return bTime.compareTo(aTime);
    });

    return examinations;
  }

  Future<ExaminationPageEntity> _getExaminationsPage({
    required String endpoint,
    required String token,
    required int page,
    required int size,
    required String errorMessage,
  }) async {
    final uri = Uri.parse(endpoint).replace(
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
        'sort': 'asc',
      },
    );
    _logRequest('GET', uri, token);
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
      throw Exception(_httpErrorMessage(response.statusCode, errorMessage));
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is List) {
      final examinations = data
          .whereType<Map>()
          .map(
            (item) =>
                ExaminationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return ExaminationPageEntity(
        content: examinations,
        totalElements: examinations.length,
        totalPages: 1,
        isLast: true,
        pageNumber: 0,
        pageSize: examinations.length,
      );
    }
    if (data is! Map) {
      throw Exception('Định dạng danh sách ca khám không hợp lệ');
    }

    final pageData = Map<String, dynamic>.from(data);
    final content = pageData['content'];
    final examinations = content is List
        ? content
              .whereType<Map>()
              .map(
                (item) =>
                    ExaminationModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <ExaminationEntity>[];
    examinations.sort((a, b) {
      final bTime = b.visitTime ?? b.studyDate ?? DateTime(1900);
      final aTime = a.visitTime ?? a.studyDate ?? DateTime(1900);
      return bTime.compareTo(aTime);
    });

    return ExaminationPageEntity(
      content: examinations,
      totalElements: pageData['totalElements'] as int? ?? examinations.length,
      totalPages: pageData['totalPages'] as int? ?? 1,
      isLast: pageData['isLast'] as bool? ?? pageData['last'] as bool? ?? true,
      pageNumber:
          pageData['pageNumber'] as int? ?? pageData['number'] as int? ?? page,
      pageSize:
          pageData['pageSize'] as int? ?? pageData['size'] as int? ?? size,
    );
  }

  @override
  Future<List<ExaminationEntity>> getPatientExaminations({
    required String patientId,
    required String token,
  }) async {
    final page = await _getExaminationsPage(
      endpoint: ApiConstants.examinationsByPatientEndpoint(patientId),
      token: token,
      page: 0,
      size: 10,
      errorMessage: 'Khong the tai danh sach ca kham cua benh nhan',
    );
    return page.content;
  }

  String _httpErrorMessage(int statusCode, String fallbackMessage) {
    if (statusCode == 403) {
      return 'Bạn cần được cấp quyền để tiếp tục sử dụng tính năng này ($statusCode)';
    }
    if (statusCode >= 500 && statusCode < 600) {
      return 'Chưa nhận được phản hồi từ sever ($statusCode)';
    }
    return '$fallbackMessage ($statusCode)';
  }

  void _logRequest(String method, Uri uri, String token) {
    debugPrint(
      '[Examination API request] $method $uri, '
      'Authorization=${token.trim().isEmpty ? 'missing' : 'Bearer ***'}',
      wrapWidth: 1024,
    );
  }
}
