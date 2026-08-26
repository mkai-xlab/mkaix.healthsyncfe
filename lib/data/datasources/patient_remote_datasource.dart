import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/error_message_utils.dart';
import '../models/patient_model.dart';
import '../../domain/entities/patient_page_entity.dart';

abstract class PatientRemoteDataSource {
  Future<PatientPageEntity> getAllPatients({
    required String token,
    String? fullName,
    String? patientCode,
    String? gender,
    bool isPersonal = false,
    int page = 0,
    int size = 10,
  });

  Future<PatientModel> getPatientDetails({
    required String token,
    required String patientCode,
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
    bool isPersonal = false,
    int page = 0,
    int size = 10,
  }) async {
    final keyword = fullName?.trim() ?? '';
    final code = patientCode?.trim() ?? '';
    final genderFilter = gender?.trim() ?? '';
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sort': 'asc',
      'isPersonal': isPersonal.toString(),
      if (keyword.isNotEmpty || code.isNotEmpty)
        'keyword': [keyword, code].where((value) => value.isNotEmpty).join(' '),
      if (genderFilter.isNotEmpty) 'gender': genderFilter,
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
      return _parsePage(responseData, fallbackPage: page, fallbackSize: size);
    }

    throw Exception(
      apiStatusErrorMessage(
        response.statusCode,
        fallbackMessage: 'Không thể tải danh sách bệnh nhân',
      ),
    );
  }

  @override
  Future<PatientModel> getPatientDetails({
    required String token,
    required String patientCode,
  }) async {
    final code = patientCode.trim();
    if (code.isEmpty) {
      throw Exception('Không tìm thấy mã bệnh nhân hợp lệ');
    }

    final uri = Uri.parse(ApiConstants.patientDetailsEndpoint(code));
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
      return PatientModel.fromJson(_extractPatientJson(responseData));
    }

    throw Exception(
      apiStatusErrorMessage(
        response.statusCode,
        fallbackMessage: 'Không thể tải chi tiết bệnh nhân',
      ),
    );
  }

  Map<String, dynamic> _extractPatientJson(dynamic responseData) {
    if (responseData is Map) {
      final data = Map<String, dynamic>.from(responseData);
      for (final key in ['data', 'patient', 'content']) {
        final value = data[key];
        if (value is Map) return Map<String, dynamic>.from(value);
      }
      return data;
    }
    throw Exception('Định dạng dữ liệu chi tiết bệnh nhân không hợp lệ');
  }

  PatientPageEntity _parsePage(
    dynamic responseData, {
    required int fallbackPage,
    required int fallbackSize,
  }) {
    Map<String, dynamic> pageData;
    if (responseData is Map) {
      pageData = Map<String, dynamic>.from(responseData);
    } else if (responseData is List && responseData.isEmpty) {
      return PatientPageEntity(
        content: [],
        totalElements: 0,
        totalPages: 1,
        isLast: true,
        pageNumber: fallbackPage,
        pageSize: fallbackSize,
      );
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
          pageNumber: fallbackPage,
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
          pageData['pageNumber'] as int? ??
          pageData['number'] as int? ??
          fallbackPage,
      pageSize:
          pageData['pageSize'] as int? ??
          pageData['size'] as int? ??
          fallbackSize,
    );
  }
}
