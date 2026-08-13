import '../../data/models/chat_answer_model.dart';

abstract class ChatRepository {
  Future<ChatAnswerModel> ask({
    required String question,
    required String token,
    int? sessionId,
  });

  Future<List<ChatSessionModel>> getSessions({
    required String token,
    int page = 0,
    int size = 20,
  });

  Future<ChatSessionModel> createSession({
    required String token,
    String? title,
    int? examinationId,
  });

  Future<ChatSessionModel> updateSession({
    required int sessionId,
    required String token,
    String? title,
    bool? active,
  });

  Future<List<ChatMessageModel>> getSessionMessages({
    required int sessionId,
    required String token,
    int page = 0,
    int size = 50,
  });
}
