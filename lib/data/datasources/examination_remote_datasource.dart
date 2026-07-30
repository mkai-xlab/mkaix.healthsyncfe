import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../domain/entities/examination_dashboard_totals_entity.dart';
import '../../domain/entities/examination_entity.dart';
import '../../domain/entities/examination_page_entity.dart';
import '../models/examination_model.dart';

abstract class ExaminationRemoteDataSource {
  Future<ExaminationPageEntity> getExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
    String mode = 'all',
    String direction = 'desc',
    String? date,
  });

  Future<ExaminationDashboardTotalsEntity> getMyDashboardTotals({
    required String token,
  });

  Future<ExaminationPageEntity> getMyRecentExaminationsPage({
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

  Future<ExaminationEntity> getExaminationById({
    required int examinationId,
    required String token,
  });
}

class _DashboardTotalResult {
  final int value;
  final String? errorMessage;

  const _DashboardTotalResult({required this.value, this.errorMessage});
}

class ExaminationRemoteDataSourceImpl implements ExaminationRemoteDataSource {
  final http.Client client;

  ExaminationRemoteDataSourceImpl(this.client);

  @override
  Future<ExaminationPageEntity> getExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
    String mode = 'all',
    String direction = 'desc',
    String? date,
  }) async {
    final normalizedDirection = direction == 'asc' ? 'asc' : 'desc';
    final filterDate = date ?? '';

    if (mode == 'studyDateAsc' || mode == 'studyDateDesc') {
      return _getExaminationsPage(
        endpoint: ApiConstants.examinationsStudyDateSortEndpoint,
        token: token,
        page: page,
        size: size,
        queryParameters: {'direction': mode == 'studyDateAsc' ? 'asc' : 'desc'},
        includeSort: false,
        shouldSortLocally: false,
        errorMessage: 'Khong the sap xep ca kham theo ngay kham',
      );
    }

    if (mode == 'uploadDateAsc' || mode == 'uploadDateDesc') {
      return _getExaminationsPage(
        endpoint: ApiConstants.examinationsUploadDateSortEndpoint,
        token: token,
        page: page,
        size: size,
        queryParameters: {
          'direction': mode == 'uploadDateAsc' ? 'asc' : 'desc',
        },
        includeSort: false,
        shouldSortLocally: false,
        errorMessage: 'Khong the sap xep ca kham theo ngay upload',
      );
    }

    if (mode == 'studyDateFilter') {
      return _getExaminationsPage(
        endpoint: ApiConstants.examinationsStudyDateFilterEndpoint,
        token: token,
        page: page,
        size: size,
        queryParameters: {'date': filterDate},
        includeSort: false,
        shouldSortLocally: false,
        errorMessage: 'Khong the loc ca kham theo ngay kham',
      );
    }

    if (mode == 'uploadDateFilter') {
      return _getExaminationsPage(
        endpoint: ApiConstants.examinationsUploadDateFilterEndpoint,
        token: token,
        page: page,
        size: size,
        queryParameters: {'date': filterDate},
        includeSort: false,
        shouldSortLocally: false,
        errorMessage: 'Khong the loc ca kham theo ngay upload',
      );
    }

    if (mode.startsWith('grade')) {
      final grade = mode.replaceFirst('grade', '');
      return _getExaminationsPage(
        endpoint: ApiConstants.examinationsGradeEndpoint,
        token: token,
        page: page,
        size: size,
        queryParameters: {'grade': grade, 'sort': normalizedDirection},
        includeSort: false,
        shouldSortLocally: false,
        errorMessage: 'Khong the loc ca kham theo KL grade',
      );
    }

    return _getExaminationsPage(
      endpoint: ApiConstants.examinationsEndpoint,
      token: token,
      page: page,
      size: size,
      queryParameters: {'sort': normalizedDirection},
      includeSort: false,
      shouldSortLocally: false,
      errorMessage: 'Khong the tai danh sach ca kham',
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
  Future<ExaminationEntity> getExaminationById({
    required int examinationId,
    required String token,
  }) async {
    final uri = Uri.parse(ApiConstants.examinationByIdEndpoint(examinationId));
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
        _httpErrorMessage(
          response.statusCode,
          'Khong the tai chi tiet ca kham',
        ),
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map) {
      throw Exception('Dinh dang chi tiet ca kham khong hop le');
    }

    return ExaminationModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<ExaminationPageEntity> getMyRecentExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
  }) async {
    return _getExaminationsPage(
      endpoint: ApiConstants.examinationsUploadDateSortEndpoint,
      token: token,
      page: page,
      size: size,
      queryParameters: const {'direction': 'desc'},
      includeSort: false,
      errorMessage: 'Khong the tai danh sach ca kham cua ban',
    );
  }

  @override
  Future<ExaminationDashboardTotalsEntity> getMyDashboardTotals({
    required String token,
  }) async {
    final results = await Future.wait<_DashboardTotalResult>([
      _getTotalOrZero(
        endpoint: ApiConstants.myTotalExaminationsEndpoint,
        token: token,
        errorMessage: 'Khong the tai tong so ca kham cua ban',
      ),
      _getTotalOrZero(
        endpoint: ApiConstants.myTotalVerifiedExaminationsEndpoint,
        token: token,
        errorMessage: 'Khong the tai so ca kham da xac nhan cua ban',
      ),
      _getTotalOrZero(
        endpoint: ApiConstants.myTotalUnverifiedExaminationsEndpoint,
        token: token,
        errorMessage: 'Khong the tai so ca kham cho xac nhan cua ban',
      ),
      _getTotalOrZero(
        endpoint: ApiConstants.myTotalSevereExaminationsEndpoint,
        token: token,
        errorMessage: 'Khong the tai so ca kham nang cua ban',
      ),
    ]);

    return ExaminationDashboardTotalsEntity(
      total: results[0].value,
      verified: results[1].value,
      unverified: results[2].value,
      severe: results[3].value,
      warningMessage: results
          .map((result) => result.errorMessage)
          .whereType<String>()
          .join('\n'),
    );
  }

  Future<_DashboardTotalResult> _getTotalOrZero({
    required String endpoint,
    required String token,
    required String errorMessage,
  }) async {
    try {
      final value = await _getTotal(
        endpoint: endpoint,
        token: token,
        errorMessage: errorMessage,
      );
      return _DashboardTotalResult(value: value);
    } catch (e) {
      debugPrint('[Examination total API fallback] $endpoint -> 0, error=$e');
      return _DashboardTotalResult(
        value: 0,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<int> _getTotal({
    required String endpoint,
    required String token,
    required String errorMessage,
  }) async {
    final uri = Uri.parse(endpoint);
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
      final body = utf8.decode(response.bodyBytes);
      debugPrint(
        '[Examination total API error] GET $uri '
        'status=${response.statusCode}, body=$body',
        wrapWidth: 1024,
      );
      throw Exception(_httpErrorMessage(response.statusCode, errorMessage));
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is int) return decoded;
    if (decoded is num) return decoded.toInt();
    throw Exception('Dinh dang so lieu dashboard khong hop le');
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
    Map<String, String> queryParameters = const {},
    bool includeSort = true,
    bool shouldSortLocally = true,
  }) async {
    final uri = Uri.parse(endpoint).replace(
      queryParameters: {
        ...queryParameters,
        'page': '$page',
        'size': '$size',
        if (includeSort) 'sort': 'asc',
      },
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
    if (shouldSortLocally) {
      examinations.sort((a, b) {
        final bTime = b.visitTime ?? b.studyDate ?? DateTime(1900);
        final aTime = a.visitTime ?? a.studyDate ?? DateTime(1900);
        return bTime.compareTo(aTime);
      });
    }

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
}
