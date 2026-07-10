import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../domain/entities/examination_entity.dart';
import '../models/examination_model.dart';
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

  Future<DicomUploadSubmission> uploadBatch({
    required List<DicomUploadFile> files,
    required String token,
  });

  Future<DicomUploadSubmission> uploadZipBatch({
    required DicomUploadFile file,
    required String token,
  });

  Future<List<ExaminationEntity>> predictBatch({
    required List<int> dicomInstanceIds,
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
    final data = jsonDecode(response.body);
    if (data is! List) {
      throw Exception('Phản hồi upload DICOM không đúng định dạng');
    }
    return data
        .whereType<Map>()
        .map((item) => DicomTagModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<DicomUploadSubmission> uploadBatch({
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
    return _parseBatchSubmission(response);
  }

  @override
  Future<DicomUploadSubmission> uploadZipBatch({
    required DicomUploadFile file,
    required String token,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(ApiConstants.dicomUploadZipBatchEndpoint),
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
    return _parseBatchSubmission(response);
  }

  @override
  Future<List<ExaminationEntity>> predictBatch({
    required List<int> dicomInstanceIds,
    required String token,
  }) async {
    try {
      final response = await client
          .post(
            Uri.parse(ApiConstants.aiPredictBatchEndpoint),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'dicomInstanceIds': dicomInstanceIds}),
          )
          .timeout(const Duration(seconds: 120));

      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Chạy AI thất bại (${response.statusCode})';
        try {
          final data = jsonDecode(body);
          if (data is Map && data['message'] != null) {
            message = data['message'].toString();
          }
        } catch (_) {}
        throw Exception(message);
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw Exception('Phản hồi AI không đúng định dạng');
      }

      return data
          .whereType<Map>()
          .map(
            (item) =>
                ExaminationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on TimeoutException {
      throw Exception('Chạy AI quá thời gian. Vui lòng thử lại.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Không thể chạy phân tích AI.');
    }
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  DicomUploadSubmission _parseBatchSubmission(_UploadHttpResponse response) {
    final body = response.body.trim();
    debugPrint(
      '[DICOM upload HTTP response] status=${response.statusCode}, bytes=${body.length}',
    );
    if (response.statusCode == 202 || body.isEmpty) {
      return DicomUploadSubmission.accepted(message: body);
    }

    dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      return DicomUploadSubmission.accepted(message: body);
    }

    if (data is! Map) {
      return DicomUploadSubmission.accepted(message: body);
    }

    final map = Map<String, dynamic>.from(data);
    if (_looksLikeBatchResult(map)) {
      debugPrint('[DICOM upload HTTP parsed batch] keys=${map.keys.join(',')}');
      return DicomUploadSubmission.completed(
        BatchDicomUploadModel.fromJson(map),
      );
    }

    return DicomUploadSubmission.accepted(
      message:
          map['message']?.toString() ??
          map['status']?.toString() ??
          map['detail']?.toString() ??
          body,
    );
  }

  bool _looksLikeBatchResult(Map<String, dynamic> data) {
    return data.containsKey('errors') ||
        data.containsKey('successfulPatients') ||
        data.containsKey('successful_patients');
  }

  Future<_UploadHttpResponse> _send(http.MultipartRequest request) async {
    try {
      final streamed = await client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final body = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _UploadHttpResponse(statusCode: response.statusCode, body: body);
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

class DicomUploadSubmission {
  final bool accepted;
  final BatchDicomUploadModel? result;
  final String? message;

  const DicomUploadSubmission._({
    required this.accepted,
    required this.result,
    this.message,
  });

  const DicomUploadSubmission.completed(BatchDicomUploadModel result)
    : this._(accepted: false, result: result);

  const DicomUploadSubmission.accepted({String? message})
    : this._(accepted: true, result: null, message: message);
}

class _UploadHttpResponse {
  final int statusCode;
  final String body;

  const _UploadHttpResponse({required this.statusCode, required this.body});
}
