import 'package:flutter/foundation.dart';

import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/models/chat_answer_model.dart';
import '../../domain/entities/chat_message_entity.dart';

class ChatViewModel extends ChangeNotifier {
  static const List<String> defaultSuggestions = [
    'Tóm tắt các ca hôm nay',
    'Giải thích kết quả X-quang',
    'Hỗ trợ xem lại bệnh án',
    'Tìm ca nguy cơ cao',
  ];

  final ChatRemoteDataSource remoteDataSource;
  final List<ChatMessageEntity> _messages;

  bool _isOpen = false;
  bool _isExpanded = false;
  bool _isTyping = false;
  String? _errorMessage;
  String _doctorDisplayName = 'Bác sĩ';

  ChatViewModel({required this.remoteDataSource})
    : _messages = [
        ChatMessageEntity(
          id: 'welcome-message',
          role: ChatMessageRole.assistant,
          content:
              'Xin chào Bác sĩ, tôi có thể hỗ trợ gì cho các ca chẩn đoán hôm nay?',
          createdAt: DateTime.now(),
        ),
      ];

  List<ChatMessageEntity> get messages => List.unmodifiable(_messages);
  bool get isOpen => _isOpen;
  bool get isExpanded => _isExpanded;
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;

  void updateDoctorName(String? fullName) {
    final normalized = fullName?.trim();
    final nextName = normalized == null || normalized.isEmpty
        ? 'Bác sĩ'
        : normalized;
    if (_doctorDisplayName == nextName) return;

    _doctorDisplayName = nextName;
    final welcomeIndex = _messages.indexWhere(
      (message) => message.id == 'welcome-message',
    );
    if (welcomeIndex == -1) return;

    _messages[welcomeIndex] = _messages[welcomeIndex].copyWith(
      content:
          'Xin chào $_doctorDisplayName, tôi có thể hỗ trợ gì cho các ca chẩn đoán hôm nay?',
    );
    notifyListeners();
  }

  void open() {
    _isOpen = true;
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    _isExpanded = false;
    notifyListeners();
  }

  void toggleOpen() {
    _isOpen = !_isOpen;
    if (!_isOpen) {
      _isExpanded = false;
    }
    notifyListeners();
  }

  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> sendMessage(String rawText, {required String token}) async {
    final text = rawText.trim();
    if (text.isEmpty || _isTyping) return;
    if (token.trim().isEmpty) {
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _messages.add(
      ChatMessageEntity(
        id: 'user-${DateTime.now().microsecondsSinceEpoch}',
        role: ChatMessageRole.user,
        content: text,
        createdAt: DateTime.now(),
      ),
    );
    _isTyping = true;
    notifyListeners();

    try {
      final answer = await remoteDataSource.ask(question: text, token: token);
      _messages.add(
        ChatMessageEntity(
          id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
          role: ChatMessageRole.assistant,
          content: _formatAnswer(answer),
          createdAt: DateTime.now(),
        ),
      );
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _messages.add(
        ChatMessageEntity(
          id: 'assistant-error-${DateTime.now().microsecondsSinceEpoch}',
          role: ChatMessageRole.assistant,
          content: _errorMessage!,
          createdAt: DateTime.now(),
          status: ChatMessageStatus.error,
        ),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  String _formatAnswer(ChatAnswerModel answer) {
    final warning = answer.warning?.trim();
    final sourceText = _formatSources(answer.sources);
    return [
      answer.answer.trim().isEmpty
          ? 'AI không trả về nội dung phản hồi.'
          : answer.answer.trim(),
      if (warning != null && warning.isNotEmpty) 'Lưu ý: $warning',
      if (sourceText.isNotEmpty) sourceText,
    ].join('\n\n');
  }

  String _formatSources(List<ChatSourceModel> sources) {
    final titles = sources
        .map((source) => source.title.trim())
        .where((title) => title.isNotEmpty)
        .take(3)
        .toList();
    if (titles.isEmpty) return '';
    return 'Nguồn tham khảo: ${titles.join(', ')}';
  }

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) {
      return 'Không thể kết nối AI chat. Vui lòng thử lại.';
    }
    return raw;
  }
}
