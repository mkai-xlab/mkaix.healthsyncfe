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
  final List<ChatSessionModel> _sessions = [];

  bool _isOpen = false;
  bool _isExpanded = false;
  bool _isTyping = false;
  bool _isLoadingHistory = false;
  bool _hasLoadedHistory = false;
  bool _isLoadingSessions = false;
  bool _isFullPageVisible = false;
  int _fullPageRequestVersion = 0;
  int? _currentSessionId;
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
  List<ChatSessionModel> get sessions => List.unmodifiable(_sessions);
  bool get isOpen => _isOpen;
  bool get isExpanded => _isExpanded;
  bool get isTyping => _isTyping;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get isFullPageVisible => _isFullPageVisible;
  int get fullPageRequestVersion => _fullPageRequestVersion;
  int? get currentSessionId => _currentSessionId;
  String? get errorMessage => _errorMessage;

  void setFullPageVisible(bool visible) {
    if (_isFullPageVisible == visible) return;
    _isFullPageVisible = visible;
    if (visible) {
      _isOpen = false;
      _isExpanded = false;
    }
    notifyListeners();
  }

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

  void requestFullPage() {
    _fullPageRequestVersion++;
    _isOpen = false;
    _isExpanded = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadLatestSession({
    required String token,
    bool force = false,
  }) async {
    if ((!force && _hasLoadedHistory) ||
        _isLoadingHistory ||
        token.trim().isEmpty) {
      return;
    }

    _isLoadingHistory = true;
    _isLoadingSessions = true;
    notifyListeners();

    try {
      final sessions = await remoteDataSource.getSessions(
        token: token,
        size: 20,
      );
      _sessions
        ..clear()
        ..addAll(sessions);
      if (sessions.isNotEmpty) {
        final session = sessions.first;
        _currentSessionId = session.id;
        final messages = await remoteDataSource.getSessionMessages(
          sessionId: session.id,
          token: token,
        );
        if (messages.isNotEmpty) {
          _messages
            ..clear()
            ..addAll(
              messages.map(
                (message) => ChatMessageEntity(
                  id: 'history-${message.id}',
                  role: _mapRole(message.role),
                  content: message.content,
                  createdAt: message.createdAt ?? DateTime.now(),
                ),
              ),
            );
        }
      }
      _hasLoadedHistory = true;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoadingHistory = false;
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<void> reloadSessions({required String token}) async {
    if (_isLoadingSessions || token.trim().isEmpty) return;
    _isLoadingSessions = true;
    notifyListeners();

    try {
      final sessions = await remoteDataSource.getSessions(token: token);
      _sessions
        ..clear()
        ..addAll(sessions);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<void> selectSession({
    required int sessionId,
    required String token,
  }) async {
    if (_currentSessionId == sessionId && _messages.isNotEmpty) return;
    if (token.trim().isEmpty) return;

    _currentSessionId = sessionId;
    _isLoadingHistory = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final messages = await remoteDataSource.getSessionMessages(
        sessionId: sessionId,
        token: token,
      );
      _messages
        ..clear()
        ..addAll(
          messages.map(
            (message) => ChatMessageEntity(
              id: 'history-${message.id}',
              role: _mapRole(message.role),
              content: message.content,
              createdAt: message.createdAt ?? DateTime.now(),
            ),
          ),
        );
      if (_messages.isEmpty) {
        _messages.add(_welcomeMessage());
      }
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> renameSession({
    required int sessionId,
    required String title,
    required String token,
  }) async {
    final normalizedTitle = title.trim();
    if (sessionId <= 0 || normalizedTitle.isEmpty || token.trim().isEmpty) {
      return;
    }

    _isLoadingSessions = true;
    notifyListeners();

    try {
      final updated = await remoteDataSource.updateSession(
        sessionId: sessionId,
        token: token,
        title: normalizedTitle,
      );
      final index = _sessions.indexWhere((session) => session.id == sessionId);
      if (index >= 0) {
        _sessions[index] = updated;
      }
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<void> archiveSession({
    required int sessionId,
    required String token,
  }) async {
    if (sessionId <= 0 || token.trim().isEmpty) return;

    _isLoadingSessions = true;
    notifyListeners();

    try {
      await remoteDataSource.updateSession(
        sessionId: sessionId,
        token: token,
        active: false,
      );
      _sessions.removeWhere((session) => session.id == sessionId);
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages
          ..clear()
          ..add(_welcomeMessage());
      }
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  void startNewSession() {
    _currentSessionId = null;
    _hasLoadedHistory = true;
    _errorMessage = null;
    _messages
      ..clear()
      ..add(_welcomeMessage());
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
      final sessionId = await _ensureSession(question: text, token: token);
      final answer = await remoteDataSource.ask(
        question: text,
        token: token,
        sessionId: sessionId,
      );
      _currentSessionId = answer.sessionId ?? sessionId;
      if (_currentSessionId != null) {
        await reloadSessions(token: token);
      }
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

  Future<int?> _ensureSession({
    required String question,
    required String token,
  }) async {
    if (_currentSessionId != null) return _currentSessionId;
    final session = await remoteDataSource.createSession(
      token: token,
      title: _titleFromQuestion(question),
    );
    _currentSessionId = session.id;
    return _currentSessionId;
  }

  ChatMessageRole _mapRole(String rawRole) {
    final normalized = rawRole.trim().toLowerCase();
    if (normalized == 'user') return ChatMessageRole.user;
    return ChatMessageRole.assistant;
  }

  String _titleFromQuestion(String question) {
    final normalized = question.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 60) return normalized;
    return '${normalized.substring(0, 57)}...';
  }

  ChatMessageEntity _welcomeMessage() {
    return ChatMessageEntity(
      id: 'welcome-message',
      role: ChatMessageRole.assistant,
      content:
          'Xin chào $_doctorDisplayName, tôi có thể hỗ trợ gì cho các ca chẩn đoán hôm nay?',
      createdAt: DateTime.now(),
    );
  }
}
