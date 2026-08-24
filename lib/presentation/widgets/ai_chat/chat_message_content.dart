import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/chat_message_entity.dart';

class ChatMessageContent extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isUser;

  const ChatMessageContent({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Text(
        _wrapLongTokens(message.content),
        softWrap: true,
        overflow: TextOverflow.clip,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MarkdownBody(
          data: _wrapLongTokens(message.content),
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.45,
            ),
            strong: const TextStyle(fontWeight: FontWeight.w800),
            listBullet: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.45,
            ),
            blockSpacing: 8,
            listIndent: 18,
          ),
        ),
        if (message.warning?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 10),
          _WarningCallout(message.warning!.trim()),
        ],
        if (message.sources.isNotEmpty) ...[
          const SizedBox(height: 10),
          _SourceChips(sources: message.sources),
        ],
      ],
    );
  }
}

class _WarningCallout extends StatelessWidget {
  final String warning;

  const _WarningCallout(this.warning);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF4D48B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Color(0xFF9A6A00),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warning,
              style: const TextStyle(
                color: Color(0xFF6F4B00),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceChips extends StatefulWidget {
  final List<ChatMessageSourceEntity> sources;

  const _SourceChips({required this.sources});

  @override
  State<_SourceChips> createState() => _SourceChipsState();
}

class _SourceChipsState extends State<_SourceChips> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visibleSources = _expanded
        ? widget.sources
        : widget.sources.take(3).toList();
    final hiddenCount = widget.sources.length - visibleSources.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nguồn tham khảo',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final source in visibleSources) _SourceChip(source: source),
            if (hiddenCount > 0)
              _ToggleChip(
                label: '+$hiddenCount',
                onTap: () => setState(() => _expanded = true),
              ),
            if (_expanded && widget.sources.length > 3)
              _ToggleChip(
                label: 'Thu gọn',
                onTap: () => setState(() => _expanded = false),
              ),
          ],
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  final ChatMessageSourceEntity source;

  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final title = source.title.trim().isNotEmpty
        ? source.title.trim()
        : source.sourceId.trim().isNotEmpty
        ? source.sourceId.trim()
        : 'Tài liệu';

    return Tooltip(
      message: source.locator.trim().isEmpty ? title : source.locator.trim(),
      child: Chip(
        avatar: const Icon(
          Icons.description_outlined,
          size: 15,
          color: AppColors.primary,
        ),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        backgroundColor: Colors.white,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.26)),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: AppColors.surface1,
      side: const BorderSide(color: AppColors.border),
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
