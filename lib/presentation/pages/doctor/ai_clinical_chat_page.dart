import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/chat_answer_model.dart';
import '../../../domain/entities/chat_message_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';

class AiClinicalChatPage extends StatefulWidget {
  const AiClinicalChatPage({super.key});

  @override
  State<AiClinicalChatPage> createState() => _AiClinicalChatPageState();
}

class _AiClinicalChatPageState extends State<AiClinicalChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthViewModel>().currentUser?.token ?? '';
      final vm = context.read<ChatViewModel>();
      vm.setFullPageVisible(true);
      vm.loadLatestSession(token: token, force: true);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    await context.read<ChatViewModel>().sendMessage(text, token: token);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = context.select<AuthViewModel, String>(
      (auth) => auth.currentUser?.token ?? '',
    );
    return Consumer<ChatViewModel>(
      builder: (context, vm, _) {
        _scrollToBottom();
        final compact = MediaQuery.sizeOf(context).width < 1050;
        return ColoredBox(
          color: const Color(0xFFFAFAF7),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _ChatPageHeader(onNewSession: vm.startNewSession),
                    Expanded(
                      child: _ChatConversation(
                        controller: _scrollController,
                        messages: vm.messages,
                        isLoading: vm.isLoadingHistory,
                        isTyping: vm.isTyping,
                      ),
                    ),
                    _PromptBar(
                      controller: _inputController,
                      enabled: !vm.isTyping && token.trim().isNotEmpty,
                      onSend: _send,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, 14),
                      child: Text(
                        'KneeAI có thể mắc lỗi. Vui lòng kiểm chứng lại các thông tin lâm sàng quan trọng.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF7A8681),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                _SessionHistoryPanel(
                  sessions: vm.sessions,
                  currentSessionId: vm.currentSessionId,
                  isLoading: vm.isLoadingSessions,
                  onNewSession: vm.startNewSession,
                  onRefresh: () => vm.reloadSessions(token: token),
                  onSelect: (session) =>
                      vm.selectSession(sessionId: session.id, token: token),
                  onRename: (session, title) => vm.renameSession(
                    sessionId: session.id,
                    title: title,
                    token: token,
                  ),
                  onArchive: (session) =>
                      _showArchiveSessionDialog(context, vm, session, token),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showArchiveSessionDialog(
    BuildContext context,
    ChatViewModel vm,
    ChatSessionModel session,
    String token,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa session?'),
        content: Text(
          'Session "${session.title.trim().isEmpty ? '#${session.id}' : session.title.trim()}" sẽ được ẩn khỏi danh sách.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await vm.archiveSession(sessionId: session.id, token: token);
  }
}

class _ChatPageHeader extends StatelessWidget {
  const _ChatPageHeader({required this.onNewSession});

  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDDE7E2))),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Clinical Assistant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF1F2925),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF9FEBD8), size: 8),
                    SizedBox(width: 6),
                    Text(
                      'Trợ lý trực tuyến (KneeAI v2.4)',
                      style: TextStyle(color: Color(0xFF6E7A75), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNewSession,
            icon: const Icon(Icons.add_comment_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ChatConversation extends StatelessWidget {
  const _ChatConversation({
    required this.controller,
    required this.messages,
    required this.isLoading,
    required this.isTyping,
  });

  final ScrollController controller;
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(44, 34, 44, 26),
      children: [
        const Center(child: _TimePill(label: 'Hôm nay')),
        const SizedBox(height: 26),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        for (final message in messages) _MessageRow(message: message),
        if (isTyping) const _AssistantTypingRow(),
      ],
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message});

  final ChatMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _AvatarIcon(icon: Icons.smart_toy_rounded),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isUser
                      ? null
                      : Border.all(color: const Color(0xFFD9E3DE)),
                  boxShadow: isUser
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Text(
                    _wrapLongTokens(message.content),
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF24312C),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            const _AvatarIcon(
              icon: Icons.person_outline_rounded,
              background: Color(0xFFAEEFE2),
              iconColor: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class _AssistantTypingRow extends StatelessWidget {
  const _AssistantTypingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          _AvatarIcon(icon: Icons.smart_toy_rounded),
          SizedBox(width: 12),
          Text(
            'AI đang suy nghĩ...',
            style: TextStyle(color: Color(0xFF6E7A75), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon({
    required this.icon,
    this.background = AppColors.primary,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}

class _PromptBar extends StatelessWidget {
  const _PromptBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 0),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAF7),
        border: Border(top: BorderSide(color: Color(0xFFDDE7E2))),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in ChatViewModel.defaultSuggestions.take(
                  3,
                ))
                  ActionChip(
                    label: Text(suggestion),
                    avatar: const Icon(
                      Icons.auto_awesome_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    side: const BorderSide(color: Color(0xFFBFD2CB)),
                    backgroundColor: Colors.white,
                    labelStyle: const TextStyle(
                      color: Color(0xFF51605A),
                      fontSize: 13,
                    ),
                    onPressed: enabled
                        ? () {
                            controller.text = suggestion;
                            onSend();
                          }
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFD2CB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    minLines: 2,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập yêu cầu phân tích, truy vấn bệnh án...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(18, 16, 12, 16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: FilledButton(
                      onPressed: enabled ? onSend : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryPanel extends StatelessWidget {
  const _SessionHistoryPanel({
    required this.sessions,
    required this.currentSessionId,
    required this.isLoading,
    required this.onNewSession,
    required this.onRefresh,
    required this.onSelect,
    required this.onRename,
    required this.onArchive,
  });

  final List<ChatSessionModel> sessions;
  final int? currentSessionId;
  final bool isLoading;
  final VoidCallback onNewSession;
  final VoidCallback onRefresh;
  final ValueChanged<ChatSessionModel> onSelect;
  final Future<void> Function(ChatSessionModel session, String title) onRename;
  final ValueChanged<ChatSessionModel> onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F1),
        border: Border(left: BorderSide(color: Color(0xFFDDE7E2))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lịch sử',
                    style: TextStyle(
                      color: Color(0xFF202823),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: onNewSession,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Cuộc hội thoại mới'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                    itemCount: sessions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _SessionTile(
                        key: ValueKey(session.id),
                        session: session,
                        selected: session.id == currentSessionId,
                        onTap: () => onSelect(session),
                        onRename: (title) => onRename(session, title),
                        onArchive: () => onArchive(session),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatefulWidget {
  const _SessionTile({
    super.key,
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onArchive,
  });

  final ChatSessionModel session;
  final bool selected;
  final VoidCallback onTap;
  final Future<void> Function(String title) onRename;
  final VoidCallback onArchive;

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  late final TextEditingController _titleController;
  late final FocusNode _titleFocusNode;
  bool _isEditing = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _displayTitle);
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _SessionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.session.title != widget.session.title) {
      _titleController.text = _displayTitle;
    }
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_handleFocusChanged);
    _titleFocusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String get _displayTitle {
    final title = widget.session.title.trim();
    return title.isEmpty ? 'Cuộc hội thoại #${widget.session.id}' : title;
  }

  void _handleFocusChanged() {
    if (!_titleFocusNode.hasFocus && _isEditing) {
      _submitRename();
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _titleController.text = _displayTitle;
      _titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _titleController.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _titleFocusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _titleController.text = _displayTitle;
    });
    _titleFocusNode.unfocus();
  }

  Future<void> _submitRename() async {
    if (_isSubmitting) return;
    final nextTitle = _titleController.text.trim();
    if (nextTitle.isEmpty) {
      _cancelEditing();
      return;
    }
    final currentTitle = widget.session.title.trim();
    setState(() {
      _isEditing = false;
      _isSubmitting = true;
    });
    try {
      if (nextTitle != currentTitle) {
        await widget.onRename(nextTitle);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: widget.selected ? AppColors.primary : Colors.transparent,
          width: widget.selected ? 1.4 : 0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isEditing ? null : widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditing)
                _titleEditor()
              else
                Row(
                  children: [
                    Expanded(child: _titleText()),
                    Text(
                      _timeLabel(
                        widget.session.updatedAt ?? widget.session.createdAt,
                      ),
                      style: TextStyle(
                        color: const Color(0xFF75817B),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _SessionTileMenu(
                      selected: widget.selected,
                      onRename: _startEditing,
                      onArchive: widget.onArchive,
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Text(
                widget.session.active ? 'Đang hoạt động' : 'Đã lưu trữ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: const Color(0xFF75817B), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleText() {
    return Text(
      _displayTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: const Color(0xFF26312D),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _titleEditor() {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _cancelEditing();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _titleController,
        builder: (context, value, child) {
          final length = value.text.characters.length;
          final isNearLimit = length >= 100;
          final borderColor = isNearLimit
              ? const Color(0xFFD92D20)
              : AppColors.primary;

          return TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            maxLength: 120,
            minLines: 1,
            maxLines: 1,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitRename(),
            style: TextStyle(
              color: const Color(0xFF26312D),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              counterText: isNearLimit ? '$length/120' : '',
              counterStyle: TextStyle(
                color: isNearLimit
                    ? const Color(0xFFD92D20)
                    : const Color(0xFF75817B),
                fontSize: 10,
                height: 1,
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: borderColor, width: 1.4),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionTileMenu extends StatelessWidget {
  const _SessionTileMenu({
    required this.selected,
    required this.onRename,
    required this.onArchive,
  });

  final bool selected;
  final VoidCallback onRename;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppColors.primary : const Color(0xFF75817B);
    return PopupMenuButton<_SessionMenuAction>(
      tooltip: 'Tùy chọn session',
      icon: Icon(Icons.more_vert_rounded, size: 18, color: iconColor),
      padding: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      onSelected: (action) {
        switch (action) {
          case _SessionMenuAction.rename:
            onRename();
            break;
          case _SessionMenuAction.archive:
            onArchive();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<_SessionMenuAction>(
          value: _SessionMenuAction.rename,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 17, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Đổi tên'),
            ],
          ),
        ),
        PopupMenuItem<_SessionMenuAction>(
          value: _SessionMenuAction.archive,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 17, color: AppColors.error),
              SizedBox(width: 8),
              Text('Xóa session'),
            ],
          ),
        ),
      ],
    );
  }
}

enum _SessionMenuAction { rename, archive }

class _TimePill extends StatelessWidget {
  const _TimePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF7A8681), fontSize: 12),
      ),
    );
  }
}

String _wrapLongTokens(String text) {
  return text.replaceAllMapped(RegExp(r'\S{40,}'), (match) {
    final value = match.group(0)!;
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      if (index > 0 && index % 24 == 0) {
        buffer.write('\u200B');
      }
      buffer.write(value[index]);
    }
    return buffer.toString();
  });
}

String _timeLabel(DateTime? value) {
  if (value == null) return '';
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
