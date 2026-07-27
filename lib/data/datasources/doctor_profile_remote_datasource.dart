import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/doctor_account_model.dart';

class DoctorProfileRemoteDataSource {
  final http.Client client;

  DoctorProfileRemoteDataSource(this.client);

  Future<DoctorAccountModel> getProfile({required String token}) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConstants.doctorProfileEndpoint),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final json = jsonDecode(body);
        if (json is! Map<String, dynamic>) {
          throw Exception('Dữ liệu hồ sơ bác sĩ không hợp lệ');
        }
        return DoctorAccountModel.fromJson(json);
      }

      final body = utf8.decode(response.bodyBytes);
      String message = 'Không thể tải hồ sơ bác sĩ (${response.statusCode})';
      try {
        final json = jsonDecode(body);
        if (json is Map && json['message'] != null) {
          message = json['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    } on TimeoutException {
      throw Exception('Kết nối tới máy chủ quá thời gian khi tải hồ sơ bác sĩ');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối để tải hồ sơ bác sĩ');
    }
  }

  Future<DoctorAccountModel> updateProfile({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await client
          .put(
            Uri.parse(ApiConstants.doctorProfileEndpoint),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final json = jsonDecode(body);
        if (json is! Map<String, dynamic>) {
          throw Exception('Dữ liệu cập nhật hồ sơ bác sĩ không hợp lệ');
        }
        return DoctorAccountModel.fromJson(json);
      }

      final body = utf8.decode(response.bodyBytes);
      String message =
          'Không thể cập nhật hồ sơ bác sĩ (${response.statusCode})';
      try {
        final json = jsonDecode(body);
        if (json is Map && json['message'] != null) {
          message = json['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    } on TimeoutException {
      throw Exception(
        'Kết nối tới máy chủ quá thời gian khi cập nhật hồ sơ bác sĩ',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối để cập nhật hồ sơ bác sĩ');
    }
  }
}
