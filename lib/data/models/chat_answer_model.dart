class ChatAnswerModel {
  final String route;
  final String answer;
  final List<ChatSourceModel> sources;
  final String? warning;
  final DateTime? generatedAt;

  const ChatAnswerModel({
    required this.route,
    required this.answer,
    required this.sources,
    this.warning,
    this.generatedAt,
  });

  factory ChatAnswerModel.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    return ChatAnswerModel(
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
    );
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
