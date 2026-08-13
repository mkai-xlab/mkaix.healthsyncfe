import '../../domain/entities/examination_entity.dart';
import '../../domain/interface_repositories/dicom_repository.dart';
import '../datasources/dicom_remote_datasource.dart';
import '../models/dicom_upload_model.dart';

class DicomRepositoryImpl implements DicomRepository {
  final DicomRemoteDataSource remoteDataSource;

  DicomRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<DicomTagModel>> uploadFile({
    required DicomUploadFile file,
    required String token,
  }) {
    return remoteDataSource.uploadFile(file: file, token: token);
  }

  @override
  Future<DicomUploadSubmission> uploadBatch({
    required List<DicomUploadFile> files,
    required String token,
  }) {
    return remoteDataSource.uploadBatch(files: files, token: token);
  }

  @override
  Future<DicomUploadSubmission> uploadZipBatch({
    required List<DicomUploadFile> files,
    required String token,
  }) {
    return remoteDataSource.uploadZipBatch(files: files, token: token);
  }

  @override
  Future<DicomVerifyResponse> verifyUploadSession({
    required String uploadSessionId,
    required List<String> acceptedPatientCodes,
    required String token,
  }) {
    return remoteDataSource.verifyUploadSession(
      uploadSessionId: uploadSessionId,
      acceptedPatientCodes: acceptedPatientCodes,
      token: token,
    );
  }

  @override
  Future<DicomUploadNotificationPollResult> fetchUnreadNotifications({
    required String token,
  }) {
    return remoteDataSource.fetchUnreadNotifications(token: token);
  }

  @override
  Future<List<ExaminationEntity>> predictBatch({
    required List<int> dicomInstanceIds,
    required String token,
  }) {
    return remoteDataSource.predictBatch(
      dicomInstanceIds: dicomInstanceIds,
      token: token,
    );
  }
}
