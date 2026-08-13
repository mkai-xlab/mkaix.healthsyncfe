import '../../data/models/chat_answer_model.dart';
import '../interface_repositories/chat_repository.dart';

class AskChatUseCase {
  final ChatRepository repository;

  AskChatUseCase(this.repository);

  Future<ChatAnswerModel> execute({
    required String question,
    required String token,
    int? sessionId,
  }) {
    return repository.ask(
      question: question,
      token: token,
      sessionId: sessionId,
    );
  }
}
