enum ChatMessageRole { user, assistant }

enum ChatMessageStatus { sending, sent, error }

class ChatMessageEntity {
  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime createdAt;
  final ChatMessageStatus status;

  const ChatMessageEntity({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = ChatMessageStatus.sent,
  });

  ChatMessageEntity copyWith({
    String? id,
    ChatMessageRole? role,
    String? content,
    DateTime? createdAt,
    ChatMessageStatus? status,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
