import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/patient_model.dart';
import '../mock/mock_patients.dart';
import '../../domain/entities/patient_page_entity.dart';

abstract class PatientRemoteDataSource {
  Future<PatientPageEntity> getAllPatients({
    required String token,
    String? fullName,
    String? patientCode,
    String? gender,
    int page = 0,
    int size = 15,
  });
}

class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final http.Client client;
  PatientRemoteDataSourceImpl(this.client);

  @override
  Future<PatientPageEntity> getAllPatients({
    required String token,
    String? fullName,
    String? patientCode,
    String? gender,
    int page = 0,
    int size = 15,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
        if (patientCode != null && patientCode.isNotEmpty)
          'patientCode': patientCode,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
      };

      final uri = Uri.parse(
        ApiConstants.patientsEndpoint,
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

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final dynamic responseData = jsonDecode(decodedBody);
        final result = _parsePage(responseData);

        // Nếu API trả về rỗng → fallback mock
        if (result.content.isEmpty) {
          return _mockPage(
            fullName: fullName,
            patientCode: patientCode,
            gender: gender,
            page: page,
            size: size,
          );
        }
        return result;
      }
      // Lỗi HTTP → fallback mock
      return _mockPage(
        fullName: fullName,
        patientCode: patientCode,
        gender: gender,
        page: page,
        size: size,
      );
    } catch (_) {
      // Không kết nối được → fallback mock
      return _mockPage(
        fullName: fullName,
        patientCode: patientCode,
        gender: gender,
        page: page,
        size: size,
      );
    }
  }

  /// Lọc + phân trang mock data
  PatientPageEntity _mockPage({
    String? fullName,
    String? patientCode,
    String? gender,
    required int page,
    required int size,
  }) {
    var all = MockPatients.samples;

    if (fullName != null && fullName.isNotEmpty) {
      final q = fullName.toLowerCase();
      all = all.where((p) => p.fullName.toLowerCase().contains(q)).toList();
    }
    if (patientCode != null && patientCode.isNotEmpty) {
      final q = patientCode.toLowerCase();
      all = all.where((p) => p.patientCode.toLowerCase().contains(q)).toList();
    }
    if (gender != null && gender.isNotEmpty) {
      all = all.where((p) => p.gender == gender).toList();
    }

    final total = all.length;
    final totalPages = total == 0 ? 1 : (total / size).ceil();
    final start = (page * size).clamp(0, total);
    final end = (start + size).clamp(0, total);

    return PatientPageEntity(
      content: all.sublist(start, end),
      totalElements: total,
      totalPages: totalPages,
      isLast: end >= total,
      pageNumber: page,
      pageSize: size,
    );
  }

  PatientPageEntity _parsePage(dynamic responseData) {
    Map<String, dynamic> pageData;
    if (responseData is Map) {
      pageData = Map<String, dynamic>.from(responseData);
    } else if (responseData is List && responseData.isNotEmpty) {
      if (responseData[0] is Map &&
          (responseData[0] as Map).containsKey('content')) {
        pageData = Map<String, dynamic>.from(responseData[0] as Map);
      } else {
        final patients = responseData
            .map((j) => PatientModel.fromJson(j as Map<String, dynamic>))
            .toList();
        return PatientPageEntity(
          content: patients,
          totalElements: patients.length,
          totalPages: 1,
          isLast: true,
          pageNumber: 0,
          pageSize: patients.length,
        );
      }
    } else {
      throw Exception('Định dạng dữ liệu không hợp lệ');
    }

    final List<dynamic> content = pageData['content'] ?? [];
    return PatientPageEntity(
      content: content
          .map((j) => PatientModel.fromJson(j as Map<String, dynamic>))
          .toList(),
      totalElements: pageData['totalElements'] as int? ?? 0,
      totalPages: pageData['totalPages'] as int? ?? 1,
      isLast: pageData['isLast'] as bool? ?? pageData['last'] as bool? ?? true,
      pageNumber:
          pageData['pageNumber'] as int? ?? pageData['number'] as int? ?? 0,
      pageSize: pageData['pageSize'] as int? ?? pageData['size'] as int? ?? 15,
    );
  }
}
