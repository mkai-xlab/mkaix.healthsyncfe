import '../entities/examination_entity.dart';
import '../../data/datasources/dicom_remote_datasource.dart';
import '../../data/models/dicom_upload_model.dart';

abstract class DicomRepository {
  Future<List<DicomTagModel>> uploadFile({
    required DicomUploadFile file,
    required String token,
  });

  Future<DicomUploadSubmission> uploadBatch({
    required List<DicomUploadFile> files,
    required String token,
  });

  Future<DicomUploadSubmission> uploadZipBatch({
    required List<DicomUploadFile> files,
    required String token,
  });

  Future<DicomVerifyResponse> verifyUploadSession({
    required String uploadSessionId,
    required List<String> acceptedPatientCodes,
    required String token,
  });

  Future<DicomUploadNotificationPollResult> fetchUnreadNotifications({
    required String token,
  });

  Future<List<ExaminationEntity>> predictBatch({
    required List<int> dicomInstanceIds,
    required String token,
  });
}
