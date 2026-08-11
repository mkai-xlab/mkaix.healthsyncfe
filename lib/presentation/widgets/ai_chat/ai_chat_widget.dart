import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/chat_message_entity.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';

class AiChatWidget extends StatelessWidget {
  final Widget child;

  const AiChatWidget({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final canUseDoctorShellChat = context.select<AuthViewModel, bool>((auth) {
      final user = auth.currentUser;
      return user != null && !user.isAdmin;
    });
    final doctorFullName = context.select<AuthViewModel, String?>(
      (auth) => auth.currentUser?.fullName,
    );
    final isFullPageVisible = context.select<ChatViewModel, bool>(
      (chat) => chat.isFullPageVisible,
    );

    if (!canUseDoctorShellChat || isFullPageVisible) return child;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<ChatViewModel>().updateDoctorName(doctorFullName);
    });

    return Stack(
      children: [
        child,
        Consumer<ChatViewModel>(
          builder: (context, vm, _) {
            final size = MediaQuery.sizeOf(context);
            final isMobile = size.width < 600;

            if (vm.isOpen && isMobile) {
              return const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: _ChatWindow(),
                ),
              );
            }

            return Positioned(
              right: isMobile ? 12 : 24,
              bottom: isMobile ? 12 : 88,
              child: vm.isOpen
                  ? const _ChatWindow()
                  : _ChatFloatingButton(
                      onPressed: () {
                        final token =
                            context.read<AuthViewModel>().currentUser?.token ??
                            '';
                        vm.open();
                        vm.loadLatestSession(token: token);
                      },
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _ChatFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ChatFloatingButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: true,
        label: 'Mở trợ lý y khoa',
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatWindow extends StatelessWidget {
  const _ChatWindow();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;
    final width = isMobile
        ? null
        : (vm.isExpanded ? 520.0 : 400.0).clamp(320.0, size.width - 48);
    final height = isMobile
        ? null
        : (vm.isExpanded ? size.height - 140 : 560.0)
              .clamp(420.0, size.height - 120)
              .toDouble();

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: const Column(
          children: [
            _ChatHeader(),
            Expanded(child: _ChatBody()),
            _ChatInputBar(),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.primary,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý y khoa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    color: Color(0xFFB1EFDE),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: vm.startNewSession,
            icon: const Icon(
              Icons.add_comment_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          IconButton(
            onPressed: vm.requestFullPage,
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          IconButton(
            onPressed: vm.close,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ChatBody extends StatefulWidget {
  const _ChatBody();

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Container(
      color: Colors.white,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        children: [
          if (vm.isLoadingHistory) const _ChatHistoryLoadingIndicator(),
          for (final message in vm.messages) _ChatBubble(message: message),
          const _ChatSuggestionChips(),
          if (vm.isTyping) const _ChatTypingIndicator(),
          const SizedBox(height: 8),
          const _MedicalDisclaimer(),
        ],
      ),
    );
  }
}

class _ChatHistoryLoadingIndicator extends StatelessWidget {
  const _ChatHistoryLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Đang tải lịch sử...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageEntity message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface2,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 12),
                ),
              ),
              child: Text(
                _wrapLongTokens(message.content),
                softWrap: true,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
}

class _ChatSuggestionChips extends StatelessWidget {
  const _ChatSuggestionChips();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    if (vm.messages.length > 2 || vm.isTyping) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 42, bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final suggestion in ChatViewModel.defaultSuggestions)
            ActionChip(
              label: Text(suggestion),
              labelStyle: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.24),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              onPressed: () {
                final token =
                    context.read<AuthViewModel>().currentUser?.token ?? '';
                context.read<ChatViewModel>().sendMessage(
                  suggestion,
                  token: token,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ChatTypingIndicator extends StatelessWidget {
  const _ChatTypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 42, bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'AI đang suy nghĩ...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MedicalDisclaimer extends StatelessWidget {
  const _MedicalDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'AI chỉ hỗ trợ thông tin tham khảo và thao tác hệ thống, không thay thế chẩn đoán của bác sĩ.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatefulWidget {
  const _ChatInputBar();

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    final token = context.read<AuthViewModel>().currentUser?.token ?? '';
    await context.read<ChatViewModel>().sendMessage(text, token: token);
  }

  @override
  Widget build(BuildContext context) {
    final isTyping = context.watch<ChatViewModel>().isTyping;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !isTyping,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Hỏi trợ lý y khoa...',
                filled: true,
                fillColor: AppColors.surface1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            height: 42,
            child: FilledButton(
              onPressed: isTyping ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(Icons.send_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
