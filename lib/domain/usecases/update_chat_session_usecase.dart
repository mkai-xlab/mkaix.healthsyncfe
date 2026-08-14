import '../../data/models/chat_answer_model.dart';
import '../interface_repositories/chat_repository.dart';

class UpdateChatSessionUseCase {
  final ChatRepository repository;

  UpdateChatSessionUseCase(this.repository);

  Future<ChatSessionModel> execute({
    required int sessionId,
    required String token,
    String? title,
    bool? active,
  }) {
    return repository.updateSession(
      sessionId: sessionId,
      token: token,
      title: title,
      active: active,
    );
  }
}
