import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../models/dicom_upload_model.dart';

class DicomUploadFile {
  final String name;
  final Uint8List bytes;

  const DicomUploadFile({required this.name, required this.bytes});
}

abstract class DicomRemoteDataSource {
  Future<List<DicomTagModel>> uploadFile({
    required DicomUploadFile file,
    required String token,
  });

  Future<BatchDicomUploadModel> uploadBatch({
    required List<DicomUploadFile> files,
    required String token,
  });
}

class DicomRemoteDataSourceImpl implements DicomRemoteDataSource {
  final http.Client client;

  const DicomRemoteDataSourceImpl(this.client);

  @override
  Future<List<DicomTagModel>> uploadFile({
    required DicomUploadFile file,
    required String token,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(ApiConstants.dicomUploadEndpoint),
          )
          ..headers.addAll(_headers(token))
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              file.bytes,
              filename: file.name,
            ),
          );

    final response = await _send(request);
    final data = jsonDecode(response);
    if (data is! List) {
      throw Exception('Phản hồi upload DICOM không đúng định dạng');
    }
    return data
        .whereType<Map>()
        .map((item) => DicomTagModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<BatchDicomUploadModel> uploadBatch({
    required List<DicomUploadFile> files,
    required String token,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.dicomUploadBatchEndpoint),
    )..headers.addAll(_headers(token));

    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes('files', file.bytes, filename: file.name),
      );
    }

    final response = await _send(request);
    final data = jsonDecode(response);
    if (data is! Map) {
      throw Exception('Phản hồi upload DICOM batch không đúng định dạng');
    }
    return BatchDicomUploadModel.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<String> _send(http.MultipartRequest request) async {
    try {
      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }

      String message = 'Upload DICOM thất bại (${response.statusCode})';
      try {
        final data = jsonDecode(body);
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    } on TimeoutException {
      throw Exception('Upload quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể upload file DICOM.');
    }
  }
}
