enum ChatMessageRole { user, assistant }

enum ChatMessageStatus { sending, sent, error }

class ChatMessageSourceEntity {
  final String sourceId;
  final String title;
  final String sourceType;
  final String locator;
  final double score;

  const ChatMessageSourceEntity({
    required this.sourceId,
    required this.title,
    required this.sourceType,
    required this.locator,
    required this.score,
  });
}

class ChatMessageEntity {
  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime createdAt;
  final ChatMessageStatus status;
  final String? warning;
  final List<ChatMessageSourceEntity> sources;

  const ChatMessageEntity({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = ChatMessageStatus.sent,
    this.warning,
    this.sources = const [],
  });

  ChatMessageEntity copyWith({
    String? id,
    ChatMessageRole? role,
    String? content,
    DateTime? createdAt,
    ChatMessageStatus? status,
    String? warning,
    List<ChatMessageSourceEntity>? sources,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      warning: warning ?? this.warning,
      sources: sources ?? this.sources,
    );
  }
}
