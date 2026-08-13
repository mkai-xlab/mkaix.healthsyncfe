import '../../data/models/chat_answer_model.dart';
import '../interface_repositories/chat_repository.dart';

class GetChatSessionsUseCase {
  final ChatRepository repository;

  GetChatSessionsUseCase(this.repository);

  Future<List<ChatSessionModel>> execute({
    required String token,
    int page = 0,
    int size = 20,
  }) {
    return repository.getSessions(token: token, page: page, size: size);
  }
}
