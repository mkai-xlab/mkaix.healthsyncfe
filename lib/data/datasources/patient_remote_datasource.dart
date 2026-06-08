import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/patient_model.dart';
import '../../domain/entities/patient_page_entity.dart';

/// Contract định nghĩa các phương thức giao tiếp dữ liệu của phân hệ Bệnh nhân.
abstract class PatientRemoteDataSource {
  Future<PatientPageEntity> getAllPatients({
    required Map<String, dynamic> filter,
    required Map<String, dynamic> pageable,
  });
}

/// Triển khai thực tế kết nối API sử dụng giao thức HTTP.
class PatientRemoteDataSourceImpl implements PatientRemoteDataSource {
  final http.Client client;

  PatientRemoteDataSourceImpl(this.client);

  @override
  Future<PatientPageEntity> getAllPatients({
    required Map<String, dynamic> filter,
    required Map<String, dynamic> pageable,
  }) async {
    // 1. Đồng bộ hóa cấu trúc Query Parameters với Spring Boot Swagger ký nhận
    // Mẹo: Nếu đang dùng MockAPI bọc mẹo, tạm thời clear query parameters để MockAPI không filter lỗi
    final bool isMockApi = ApiConstants.patientsEndpoint.contains('mockapi.io');

    final Map<String, String> queryParams = isMockApi
        ? {}
        : {
            ...filter.map((key, value) => MapEntry(key, value.toString())),
            ...pageable.map((key, value) => MapEntry(key, value.toString())),
          };

    final uri = Uri.parse(
      ApiConstants.patientsEndpoint,
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      // 2. Tiến hành gọi API với thời gian chờ tối đa là 10 giây
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Giải mã chuỗi utf8 tránh lỗi hiển thị tiếng Việt có dấu bị lỗi font
        final String decodedBody = utf8.decode(response.bodyBytes);
        final dynamic responseData = jsonDecode(decodedBody);

        // --- KỊCH BẢN MOCKAPI (Dữ liệu trả về là một Mảng [ ... ]) ---
        if (responseData is List) {
          // Hướng xử lý A: MockAPI dùng mẹo bọc Phân trang (Mảng chứa 1 Object lớn có trường 'content')
          if (responseData.isNotEmpty &&
              responseData[0] is Map &&
              responseData[0].containsKey('content')) {
            final Map<dynamic, dynamic> pageData = responseData[0];
            final List<dynamic> content = pageData['content'] ?? [];

            return PatientPageEntity(
              content: content
                  .map(
                    (json) =>
                        PatientModel.fromJson(json as Map<String, dynamic>),
                  )
                  .toList(),
              totalElements: pageData['totalElements'] ?? 0,
              totalPages: pageData['totalPages'] ?? 0,
              size: pageData['size'] ?? 10,
              number: pageData['number'] ?? 0,
            );
          }

          // Hướng xử lý B: MockAPI kiểu cũ (Mảng phẳng chứa trực tiếp danh sách bệnh nhân)
          final patients = responseData
              .map(
                (json) => PatientModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

          return PatientPageEntity(
            content: patients,
            totalElements: patients.length,
            totalPages: 1,
            size: patients.length,
            number: 0,
          );
        }
        // --- KỊCH BẢN SPRING BOOT (Dữ liệu trả về trực tiếp là Object { ... }) ---
        // Sửa lỗi: Check 'is Map' thay vì 'is Map<String, dynamic>' để tránh lỗi kén kiểu dữ liệu của Dart
        else if (responseData is Map) {
          final List<dynamic> content = responseData['content'] ?? [];

          return PatientPageEntity(
            content: content
                .map(
                  (json) => PatientModel.fromJson(json as Map<String, dynamic>),
                )
                .toList(),
            totalElements: responseData['totalElements'] ?? 0,
            totalPages: responseData['totalPages'] ?? 0,
            size: responseData['size'] ?? 10,
            number: responseData['number'] ?? 0,
          );
        } else {
          throw Exception('Định dạng dữ liệu từ Server không hợp lệ.');
        }
      } else {
        throw Exception(
          'Không thể tải danh sách bệnh nhân (Mã lỗi: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối mạng: $e');
    }
  }
}
