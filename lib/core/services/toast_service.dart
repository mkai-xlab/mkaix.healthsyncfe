import 'dart:async';

import 'package:flutter/material.dart';

enum AppToastType { success, error, warning, info }

class AppToast {
  AppToast._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _overlayEntry;
  static final List<_ToastItem> _items = [];
  static int _nextId = 0;

  static void showSuccess(String message, {String? title}) {
    show(title: title, message: message, type: AppToastType.success);
  }

  static void showError(String message, {String? title}) {
    show(title: title, message: message, type: AppToastType.error);
  }

  static void showWarning(String message, {String? title}) {
    show(title: title, message: message, type: AppToastType.warning);
  }

  static void showInfo(String message, {String? title}) {
    show(title: title, message: message, type: AppToastType.info);
  }

  static void show({
    String? title,
    required String message,
    AppToastType type = AppToastType.info,
    Duration? duration = const Duration(seconds: 5),
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _ensureOverlay(overlay);

    final item = _ToastItem(
      id: _nextId++,
      title: title?.trim(),
      message: message.trim(),
      type: type,
    );
    _items.add(item);

    if (duration != null) {
      item.dismissTimer = Timer(duration, () => _dismiss(item.id));
    }

    _overlayEntry?.markNeedsBuild();
  }

  static void dismissCurrent() {
    if (_items.isEmpty) return;
    _dismiss(_items.last.id);
  }

  static void _ensureOverlay(OverlayState overlay) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastStackOverlay(
        items: List.unmodifiable(_items),
        onDismiss: _dismiss,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  static void _dismiss(int id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = _items.removeAt(index);
    item.dismissTimer?.cancel();

    if (_items.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }

    _overlayEntry?.markNeedsBuild();
  }
}

class _ToastItem {
  _ToastItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
  });

  final int id;
  final String? title;
  final String message;
  final AppToastType type;
  Timer? dismissTimer;
}

class _ToastStackOverlay extends StatelessWidget {
  const _ToastStackOverlay({required this.items, required this.onDismiss});

  final List<_ToastItem> items;
  final ValueChanged<int> onDismiss;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final toastWidth = screenWidth < 600
        ? screenWidth - 32
        : (screenWidth * 0.28).clamp(320.0, 520.0);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16, top: 16),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: toastWidth,
                  child: ListView.separated(
                    shrinkWrap: true,
                    reverse: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[items.length - 1 - index];
                      return _ToastCard(
                        key: ValueKey(item.id),
                        item: item,
                        onDismiss: () => onDismiss(item.id),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({super.key, required this.item, required this.onDismiss});

  final _ToastItem item;
  final VoidCallback onDismiss;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _ToastTheme.of(widget.item.type);
    final title = widget.item.title?.trim() ?? '';

    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: scheme.softBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(scheme.icon, size: 18, color: scheme.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title.isNotEmpty) ...[
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            widget.item.message,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onDismiss,
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 4, color: scheme.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastTheme {
  const _ToastTheme({
    required this.accent,
    required this.softBackground,
    required this.icon,
  });

  final Color accent;
  final Color softBackground;
  final IconData icon;

  static _ToastTheme of(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return const _ToastTheme(
          accent: Color(0xFF47B36C),
          softBackground: Color(0xFFE6F6EA),
          icon: Icons.check_circle,
        );
      case AppToastType.error:
        return const _ToastTheme(
          accent: Color(0xFFE05D5D),
          softBackground: Color(0xFFFDEAEA),
          icon: Icons.error,
        );
      case AppToastType.warning:
        return const _ToastTheme(
          accent: Color(0xFFF0C44C),
          softBackground: Color(0xFFFFF5D6),
          icon: Icons.warning,
        );
      case AppToastType.info:
        return const _ToastTheme(
          accent: Color(0xFF4D8CC9),
          softBackground: Color(0xFFEAF3FB),
          icon: Icons.info,
        );
    }
  }
}
