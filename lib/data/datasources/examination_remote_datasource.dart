import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../domain/entities/examination_entity.dart';
import '../models/examination_model.dart';

abstract class ExaminationRemoteDataSource {
  Future<List<ExaminationEntity>> getAllExaminations({required String token});

  Future<List<ExaminationEntity>> getPatientExaminations({
    required String patientId,
    required String token,
  });
}

class ExaminationRemoteDataSourceImpl implements ExaminationRemoteDataSource {
  final http.Client client;

  ExaminationRemoteDataSourceImpl(this.client);

  @override
  Future<List<ExaminationEntity>> getAllExaminations({
    required String token,
  }) async {
    final patients = await _getAllPatients(token);
    final examinations = <ExaminationEntity>[];

    for (final patient in patients) {
      final patientDbId = patient['id']?.toString() ?? '';
      final patientCode =
          patient['patientCode']?.toString() ??
          patient['patient_id']?.toString() ??
          '';
      final detailId = patientCode.isNotEmpty ? patientCode : patientDbId;
      if (detailId.isEmpty) continue;

      examinations.addAll(
        await _getPatientExaminationsById(
          patientId: detailId,
          token: token,
          fallbackPatientJson: patient,
        ),
      );
    }

    examinations.sort((a, b) {
      final bTime = b.visitTime ?? b.studyDate ?? DateTime(1900);
      final aTime = a.visitTime ?? a.studyDate ?? DateTime(1900);
      return bTime.compareTo(aTime);
    });

    return examinations;
  }

  @override
  Future<List<ExaminationEntity>> getPatientExaminations({
    required String patientId,
    required String token,
  }) async {
    return _getPatientExaminationsById(patientId: patientId, token: token);
  }

  Future<List<Map<String, dynamic>>> _getAllPatients(String token) async {
    final patients = <Map<String, dynamic>>[];
    var page = 0;
    var isLast = false;

    while (!isLast) {
      final uri = Uri.parse(
        ApiConstants.patientsEndpoint,
      ).replace(queryParameters: {'page': page.toString(), 'size': '100'});
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
          'Không thể tải danh sách bệnh nhân (${response.statusCode})',
        );
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map) {
        final content = data['content'];
        if (content is List) {
          patients.addAll(
            content.whereType<Map>().map((item) {
              return Map<String, dynamic>.from(item);
            }),
          );
        }
        isLast = data['isLast'] as bool? ?? data['last'] as bool? ?? true;
      } else if (data is List) {
        patients.addAll(
          data.whereType<Map>().map((item) {
            return Map<String, dynamic>.from(item);
          }),
        );
        isLast = true;
      } else {
        throw Exception('Định dạng danh sách bệnh nhân không hợp lệ');
      }

      page++;
    }

    return patients;
  }

  Future<List<ExaminationEntity>> _getPatientExaminationsById({
    required String patientId,
    required String token,
    Map<String, dynamic>? fallbackPatientJson,
  }) async {
    final uri = Uri.parse(ApiConstants.patientDetailsEndpoint(patientId));
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
      if (data is! Map) {
        throw Exception('Định dạng chi tiết bệnh nhân không hợp lệ');
      }

      final examinations = data['recentExaminations'];
      if (examinations is! List) return [];
      final patientJson = data['patient'] is Map
          ? Map<String, dynamic>.from(data['patient'] as Map)
          : fallbackPatientJson;

      return examinations
          .whereType<Map>()
          .map(
            (item) => ExaminationModel.fromJson(
              Map<String, dynamic>.from(item),
              patientJson: patientJson,
            ),
          )
          .toList();
    }

    throw Exception('Không thể tải danh sách ca khám (${response.statusCode})');
  }
}
