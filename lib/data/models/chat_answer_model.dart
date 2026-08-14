class ChatAnswerModel {
  final int? sessionId;
  final int? messageId;
  final String route;
  final String answer;
  final List<ChatSourceModel> sources;
  final String? warning;
  final DateTime? generatedAt;
  final int? tokensUsed;

  const ChatAnswerModel({
    this.sessionId,
    this.messageId,
    required this.route,
    required this.answer,
    required this.sources,
    this.warning,
    this.generatedAt,
    this.tokensUsed,
  });

  factory ChatAnswerModel.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    return ChatAnswerModel(
      sessionId: _parseInt(json['sessionId']),
      messageId: _parseInt(json['messageId']),
      route: json['route']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      sources: rawSources is List
          ? rawSources
                .whereType<Map>()
                .map(
                  (item) =>
                      ChatSourceModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      warning: json['warning']?.toString(),
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
      tokensUsed: _parseInt(json['tokensUsed']),
    );
  }

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class ChatSourceModel {
  final String sourceId;
  final String title;
  final String sourceType;
  final String locator;
  final double score;

  const ChatSourceModel({
    required this.sourceId,
    required this.title,
    required this.sourceType,
    required this.locator,
    required this.score,
  });

  factory ChatSourceModel.fromJson(Map<String, dynamic> json) {
    return ChatSourceModel(
      sourceId: json['sourceId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? '',
      locator: json['locator']?.toString() ?? '',
      score: _parseDouble(json['score']),
    );
  }

  static double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ChatSessionModel {
  final int id;
  final int? examinationId;
  final String title;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatSessionModel({
    required this.id,
    this.examinationId,
    required this.title,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: _parseInt(json['id']) ?? 0,
      examinationId: _parseInt(json['examinationId']),
      title: json['title']?.toString() ?? '',
      active: _parseBool(json['active']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}

class ChatMessageModel {
  final int id;
  final int sessionId;
  final String role;
  final String content;
  final String route;
  final int? tokensUsed;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.route,
    this.tokensUsed,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: _parseInt(json['id']) ?? 0,
      sessionId: _parseInt(json['sessionId']) ?? 0,
      role: json['role']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
      tokensUsed: _parseInt(json['tokensUsed']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
