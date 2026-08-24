import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../domain/entities/daily_examination_stat_entity.dart';
import '../../domain/entities/examination_dashboard_totals_entity.dart';
import '../../domain/entities/examination_entity.dart';
import '../../domain/entities/examination_page_entity.dart';
import '../../domain/entities/patient_grade_stats_entity.dart';
import '../models/daily_examination_stat_model.dart';
import '../models/examination_model.dart';
import '../models/patient_grade_stats_model.dart';

abstract class ExaminationRemoteDataSource {
  Future<ExaminationPageEntity> getExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
    String mode = 'all',
    String direction = 'desc',
    String? date,
    bool isPersonal = false,
    List<String> statuses = const [],
    List<int> grades = const [],
    String? sort,
  });

  Future<ExaminationDashboardTotalsEntity> getMyDashboardTotals({
    required String token,
    bool isPersonal = false,
  });

  Future<ExaminationPageEntity> getMyRecentExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
    bool isPersonal = false,
  });

  Future<List<PatientGradeStatsEntity>> getPatientGradeStatistics({
    required String token,
    bool isPersonal = false,
  });

  Future<List<DailyExaminationStatEntity>> getDailyLast7DaysStatistics({
    required String token,
    bool isPersonal = false,
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

  Future<ExaminationPageEntity> getPatientExaminationsPage({
    required String patientId,
    required String token,
    int page = 0,
    int size = 10,
  });

  Future<ExaminationEntity> getExaminationById({
    required int examinationId,
    required String token,
  });

  Future<void> markExaminationViewed({
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
    bool isPersonal = false,
    List<String> statuses = const [],
    List<int> grades = const [],
    String? sort,
  }) async {
    final normalizedDirection = direction == 'asc' ? 'asc' : 'desc';
    final filterDate = date ?? '';

    if (mode == 'studyDateFilter') {
      return _getExaminationsPage(
        endpoint: ApiConstants.examinationsStudyDateFilterEndpoint,
        token: token,
        page: page,
        size: size,
        queryParameters: {
          'date': filterDate,
          'isPersonal': isPersonal.toString(),
        },
        includeSort: false,
        shouldSortLocally: false,
        errorMessage: 'Không thể lọc ca khám theo ngày khám',
      );
    }

    if (mode == 'uploadDateFilter') {
      return _getExaminationsPage(
        endpoint: ApiConstants.examinationsUploadDateFilterEndpoint,
        token: token,
        page: page,
        size: size,
        queryParameters: {
          'date': filterDate,
          'isPersonal': isPersonal.toString(),
        },
        includeSort: false,
        shouldSortLocally: false,
        errorMessage: 'Không thể lọc ca khám theo ngày upload',
      );
    }

    final effectiveStatuses = <String>{...statuses};
    final effectiveGrades = <int>{...grades};
    if (mode.startsWith('status')) {
      effectiveStatuses.add(_statusFilterForMode(mode));
    }
    if (mode.startsWith('grade')) {
      final grade = int.tryParse(mode.replaceFirst('grade', ''));
      if (grade != null) effectiveGrades.add(grade);
    }

    final effectiveSort = sort ?? _sortForMode(mode, normalizedDirection);
    final queryParameters = <String, String>{
      'isPersonal': isPersonal.toString(),
      if (effectiveStatuses.isNotEmpty) 'statuses': effectiveStatuses.join(','),
      if (effectiveGrades.isNotEmpty) 'grades': effectiveGrades.join(','),
      if (effectiveSort != null && effectiveSort.isNotEmpty)
        'sort': effectiveSort,
    };
    return _getExaminationsPage(
      endpoint: ApiConstants.examinationsFilterEndpoint,
      token: token,
      page: page,
      size: size,
      queryParameters: queryParameters,
      includeSort: false,
      shouldSortLocally: false,
      errorMessage: 'Không thể tải danh sách ca khám',
    );
  }

  String? _sortForMode(String mode, String direction) {
    switch (mode) {
      case 'studyDateAsc':
        return 'studyDate,asc';
      case 'studyDateDesc':
        return 'studyDate,desc';
      case 'uploadDateAsc':
        return 'createdAt,asc';
      case 'uploadDateDesc':
        return 'createdAt,desc';
      case 'all':
        return null;
      default:
        return direction == 'asc' ? 'studyDate,asc' : null;
    }
  }

  String _statusFilterForMode(String mode) {
    switch (mode) {
      case 'statusAiProcessing':
        return 'AI_PROCESSING';
      case 'statusAiFailed':
        return 'AI_FAILED';
      case 'statusNeedVerify':
        return 'NEED_VERIFY';
      case 'statusVerified':
        return 'VERIFIED';
      case 'statusReportGenerated':
        return 'REPORT_GENERATED';
      default:
        return mode.replaceFirst('status', '').toUpperCase();
    }
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
          'Không thể tải chi tiết ca khám',
        ),
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map) {
      throw Exception('Định dạng chi tiết ca khám không hợp lệ');
    }

    return ExaminationModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> markExaminationViewed({
    required int examinationId,
    required String token,
  }) async {
    final uri = Uri.parse(
      ApiConstants.markExaminationViewedEndpoint(examinationId),
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
        _httpErrorMessage(
          response.statusCode,
          'Không thể đánh dấu ca khám đã xem',
        ),
      );
    }
  }

  @override
  Future<ExaminationPageEntity> getMyRecentExaminationsPage({
    required String token,
    int page = 0,
    int size = 10,
    bool isPersonal = false,
  }) async {
    return _getExaminationsPage(
      endpoint: ApiConstants.examinationsUploadDateSortEndpoint,
      token: token,
      page: page,
      size: size,
      queryParameters: {
        'direction': 'desc',
        'isPersonal': isPersonal.toString(),
      },
      includeSort: false,
      errorMessage: 'Không thể tải danh sách ca khám của bạn',
    );
  }

  @override
  Future<ExaminationDashboardTotalsEntity> getMyDashboardTotals({
    required String token,
    bool isPersonal = false,
  }) async {
    final results = await Future.wait<_DashboardTotalResult>([
      _getTotalOrZero(
        endpoint: ApiConstants.myTotalExaminationsEndpoint,
        token: token,
        isPersonal: isPersonal,
        errorMessage: 'Không thể tải tổng số ca khám của bạn',
      ),
      _getTotalOrZero(
        endpoint: ApiConstants.myTotalVerifiedExaminationsEndpoint,
        token: token,
        isPersonal: isPersonal,
        errorMessage: 'Không thể tải số ca khám đã xác nhận của bạn',
      ),
      _getTotalOrZero(
        endpoint: ApiConstants.myTotalUnverifiedExaminationsEndpoint,
        token: token,
        isPersonal: isPersonal,
        errorMessage: 'Không thể tải số ca khám chờ xác nhận của bạn',
      ),
      _getTotalOrZero(
        endpoint: ApiConstants.myTotalSevereExaminationsEndpoint,
        token: token,
        isPersonal: isPersonal,
        errorMessage: 'Không thể tải số ca khám nặng của bạn',
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

  @override
  Future<List<PatientGradeStatsEntity>> getPatientGradeStatistics({
    required String token,
    bool isPersonal = false,
  }) async {
    final uri = Uri.parse(
      ApiConstants.patientGradeStatisticsEndpoint,
    ).replace(queryParameters: {if (isPersonal) 'isPersonal': 'true'});
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
          'Không thể tải thống kê bệnh nhân theo KL grade',
        ),
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) {
      throw Exception('Định dạng thống kê KL grade không hợp lệ');
    }

    return data.whereType<Map>().map((item) {
      return PatientGradeStatsModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  @override
  Future<List<DailyExaminationStatEntity>> getDailyLast7DaysStatistics({
    required String token,
    bool isPersonal = false,
  }) async {
    final uri = Uri.parse(
      ApiConstants.dailyLast7DaysExaminationsEndpoint,
    ).replace(queryParameters: {if (isPersonal) 'isPersonal': 'true'});
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
          'Không thể tải thống kê ca khám 7 ngày gần nhất',
        ),
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) {
      throw Exception('Định dạng thống kê ca khám 7 ngày không hợp lệ');
    }

    return data.whereType<Map>().map((item) {
      return DailyExaminationStatModel.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  Future<_DashboardTotalResult> _getTotalOrZero({
    required String endpoint,
    required String token,
    required bool isPersonal,
    required String errorMessage,
  }) async {
    try {
      final value = await _getTotal(
        endpoint: endpoint,
        token: token,
        isPersonal: isPersonal,
        errorMessage: errorMessage,
      );
      return _DashboardTotalResult(value: value);
    } catch (e) {
      return _DashboardTotalResult(
        value: 0,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<int> _getTotal({
    required String endpoint,
    required String token,
    required bool isPersonal,
    required String errorMessage,
  }) async {
    final uri = Uri.parse(
      endpoint,
    ).replace(queryParameters: {'isPersonal': isPersonal.toString()});
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

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is int) return decoded;
    if (decoded is num) return decoded.toInt();
    throw Exception('Định dạng số liệu dashboard không hợp lệ');
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
    final page = await getPatientExaminationsPage(
      patientId: patientId,
      token: token,
    );
    return page.content;
  }

  @override
  Future<ExaminationPageEntity> getPatientExaminationsPage({
    required String patientId,
    required String token,
    int page = 0,
    int size = 10,
  }) async {
    return _getExaminationsPage(
      endpoint: ApiConstants.examinationsByPatientEndpoint(patientId),
      token: token,
      page: page,
      size: size,
      errorMessage: 'Không thể tải danh sách ca khám của bệnh nhân',
    );
  }

  String _httpErrorMessage(int statusCode, String fallbackMessage) {
    if (statusCode == 403) {
      return 'Bạn cần được cấp quyền để tiếp tục sử dụng tính năng này ($statusCode)';
    }
    if (statusCode >= 500 && statusCode < 600) {
      return 'Máy chủ đang gặp lỗi. Vui lòng thử lại sau. ($statusCode)';
    }
    return '$fallbackMessage ($statusCode)';
  }
}
