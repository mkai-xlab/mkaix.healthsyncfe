import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../domain/entities/admin_dashboard_stats_entity.dart';

class AdminDashboardRemoteDataSource {
  final http.Client client;

  const AdminDashboardRemoteDataSource(this.client);

  Future<AdminDashboardStatsEntity> getStats({required String token}) async {
    final results = await Future.wait<_StatResult>([
      _getIntOrZero(
        ApiConstants.examinationsTotalEndpoint,
        token,
        label: 'GET /examinations/total',
      ),
      _getIntOrZero(
        ApiConstants.examinationsTotalVerifiedEndpoint,
        token,
        label: 'GET /examinations/total-verified',
      ),
      _getIntOrZero(
        ApiConstants.examinationsTotalUnverifiedEndpoint,
        token,
        label: 'GET /examinations/total-unverified',
      ),
      _getIntOrZero(
        ApiConstants.examinationsTotalSevereEndpoint,
        token,
        label: 'GET /examinations/total-severe',
      ),
      _getIntOrZero(
        ApiConstants.dicomTotalStudiesEndpoint,
        token,
        label: 'GET /dicom/total-studies',
      ),
      _getPageTotalOrZero(
        ApiConstants.patientsEndpoint,
        token,
        label: 'GET /patients',
      ),
      _getPageTotalOrZero(
        ApiConstants.doctorsEndpoint,
        token,
        label: 'GET /doctors',
      ),
      _getPageTotalOrZero(
        ApiConstants.activeDoctorsEndpoint,
        token,
        label: 'GET /doctors/active',
      ),
    ]);

    final gradeResult = await _getGradeCountsOrEmpty(token);
    final warnings = [
      ...results.map((result) => result.errorMessage).whereType<String>(),
      if (gradeResult.errorMessage != null) gradeResult.errorMessage!,
    ];

    return AdminDashboardStatsEntity(
      totalExaminations: results[0].value,
      verifiedExaminations: results[1].value,
      unverifiedExaminations: results[2].value,
      severeExaminations: results[3].value,
      totalDicomStudies: results[4].value,
      totalPatients: results[5].value,
      totalDoctors: results[6].value,
      activeDoctors: results[7].value,
      gradeCounts: gradeResult.gradeCounts,
      warningMessage: warnings.isEmpty ? null : warnings.join('\n'),
    );
  }

  Future<_StatResult> _getIntOrZero(
    String endpoint,
    String token, {
    required String label,
  }) async {
    try {
      final decoded = await _getDecoded(endpoint, token);
      return _StatResult(value: _parseInt(decoded));
    } catch (e) {
      return _StatResult(value: 0, errorMessage: '$label: ${_cleanError(e)}');
    }
  }

  Future<_StatResult> _getPageTotalOrZero(
    String endpoint,
    String token, {
    required String label,
  }) async {
    try {
      final decoded = await _getDecoded(
        endpoint,
        token,
        queryParameters: const {'page': '0', 'size': '1'},
      );
      if (decoded is Map) {
        return _StatResult(
          value: _parseInt(
            decoded['totalElements'] ?? decoded['total'] ?? decoded['count'],
          ),
        );
      }
      if (decoded is List) return _StatResult(value: decoded.length);
      return _StatResult(value: _parseInt(decoded));
    } catch (e) {
      return _StatResult(value: 0, errorMessage: '$label: ${_cleanError(e)}');
    }
  }

  Future<_GradeResult> _getGradeCountsOrEmpty(String token) async {
    try {
      final decoded = await _getDecoded(
        ApiConstants.patientGradeStatisticsEndpoint,
        token,
      );
      return _GradeResult(gradeCounts: _parseGradeCounts(decoded));
    } catch (e) {
      return _GradeResult(
        gradeCounts: const {},
        errorMessage:
            'GET /examinations/statistics/patients-by-grade: ${_cleanError(e)}',
      );
    }
  }

  Future<dynamic> _getDecoded(
    String endpoint,
    String token, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: queryParameters);
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
        '[Admin dashboard API error] GET $uri status=${response.statusCode}, body=$body',
        wrapWidth: 1024,
      );
      throw Exception('Không thể tải số liệu (${response.statusCode})');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Map<int, int> _parseGradeCounts(dynamic decoded) {
    final counts = <int, int>{};
    if (decoded is Map) {
      final data = decoded['data'] ?? decoded['content'] ?? decoded;
      if (data is Map) {
        for (final entry in data.entries) {
          final grade = _parseGrade(entry.key);
          if (grade != null) counts[grade] = _parseInt(entry.value);
        }
        return counts;
      }
      if (data is List) return _parseGradeList(data);
    }
    if (decoded is List) return _parseGradeList(decoded);
    return counts;
  }

  Map<int, int> _parseGradeList(List<dynamic> items) {
    final counts = <int, int>{};
    for (final item in items) {
      if (item is! Map) continue;
      final grade = _parseGrade(
        item['grade'] ??
            item['klGrade'] ??
            item['predictedGrade'] ??
            item['effectiveGrade'],
      );
      if (grade == null) continue;
      counts[grade] = _parseInt(
        item['count'] ??
            item['total'] ??
            item['totalPatients'] ??
            item['patientCount'] ??
            item['value'],
      );
    }
    return counts;
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _parseGrade(dynamic value) {
    if (value is int) return value;
    final text = value?.toString().trim() ?? '';
    final match = RegExp(r'\d+').firstMatch(text);
    return int.tryParse(match?.group(0) ?? '');
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }
}

class _StatResult {
  final int value;
  final String? errorMessage;

  const _StatResult({required this.value, this.errorMessage});
}

class _GradeResult {
  final Map<int, int> gradeCounts;
  final String? errorMessage;

  const _GradeResult({required this.gradeCounts, this.errorMessage});
}
