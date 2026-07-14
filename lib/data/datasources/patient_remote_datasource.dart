import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/patient_model.dart';
import '../../domain/entities/patient_page_entity.dart';

abstract class PatientRemoteDataSource {
  Future<PatientPageEntity> getAllPatients({
    required String token,
    String? fullName,
    String? patientCode,
    String? gender,
    int page = 0,
    int size = 10,
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
    int size = 10,
  }) async {
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
      return _parsePage(responseData, fallbackPage: page, fallbackSize: size);
    }

    throw Exception(
      'Không thể tải danh sách bệnh nhân (${response.statusCode})',
    );
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
