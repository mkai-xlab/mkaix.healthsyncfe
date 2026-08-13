import '../../data/models/chat_answer_model.dart';
import '../interface_repositories/chat_repository.dart';

class CreateChatSessionUseCase {
  final ChatRepository repository;

  CreateChatSessionUseCase(this.repository);

  Future<ChatSessionModel> execute({
    required String token,
    String? title,
    int? examinationId,
  }) {
    return repository.createSession(
      token: token,
      title: title,
      examinationId: examinationId,
    );
  }
}
