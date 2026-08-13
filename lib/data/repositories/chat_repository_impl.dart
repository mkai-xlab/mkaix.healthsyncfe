import '../../domain/interface_repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/chat_answer_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ChatAnswerModel> ask({
    required String question,
    required String token,
    int? sessionId,
  }) {
    return remoteDataSource.ask(
      question: question,
      token: token,
      sessionId: sessionId,
    );
  }

  @override
  Future<List<ChatSessionModel>> getSessions({
    required String token,
    int page = 0,
    int size = 20,
  }) {
    return remoteDataSource.getSessions(token: token, page: page, size: size);
  }

  @override
  Future<ChatSessionModel> createSession({
    required String token,
    String? title,
    int? examinationId,
  }) {
    return remoteDataSource.createSession(
      token: token,
      title: title,
      examinationId: examinationId,
    );
  }

  @override
  Future<ChatSessionModel> updateSession({
    required int sessionId,
    required String token,
    String? title,
    bool? active,
  }) {
    return remoteDataSource.updateSession(
      sessionId: sessionId,
      token: token,
      title: title,
      active: active,
    );
  }

  @override
  Future<List<ChatMessageModel>> getSessionMessages({
    required int sessionId,
    required String token,
    int page = 0,
    int size = 50,
  }) {
    return remoteDataSource.getSessionMessages(
      sessionId: sessionId,
      token: token,
      page: page,
      size: size,
    );
  }
}
