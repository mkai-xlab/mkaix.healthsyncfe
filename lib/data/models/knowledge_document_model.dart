class KnowledgeDocumentModel {
  final int id;
  final String title;
  final String sourceType;
  final String sourceUrl;
  final String originalName;
  final String accessScope;
  final String status;
  final int chunkCount;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? indexedAt;

  const KnowledgeDocumentModel({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.sourceUrl,
    required this.originalName,
    required this.accessScope,
    required this.status,
    required this.chunkCount,
    this.errorMessage,
    this.createdAt,
    this.indexedAt,
  });

  factory KnowledgeDocumentModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocumentModel(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? '',
      sourceUrl: json['sourceUrl']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
      accessScope: json['accessScope']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      chunkCount: _parseInt(json['chunkCount']),
      errorMessage: _readOptionalString(json['errorMessage']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      indexedAt: DateTime.tryParse(json['indexedAt']?.toString() ?? ''),
    );
  }

  String get displayName {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isNotEmpty) return normalizedTitle;
    final normalizedOriginalName = originalName.trim();
    if (normalizedOriginalName.isNotEmpty) return normalizedOriginalName;
    return 'Tài liệu #$id';
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _readOptionalString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
