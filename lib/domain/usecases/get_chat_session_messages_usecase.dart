import '../../data/models/chat_answer_model.dart';
import '../interface_repositories/chat_repository.dart';

class GetChatSessionMessagesUseCase {
  final ChatRepository repository;

  GetChatSessionMessagesUseCase(this.repository);

  Future<List<ChatMessageModel>> execute({
    required int sessionId,
    required String token,
    int page = 0,
    int size = 50,
  }) {
    return repository.getSessionMessages(
      sessionId: sessionId,
      token: token,
      page: page,
      size: size,
    );
  }
}
