import 'dart:async';

import 'package:flutter/material.dart';

enum AppToastType { success, error, warning, info }

class AppToast {
  AppToast._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showSuccess(String message) {
    show(message: message, type: AppToastType.success);
  }

  static void showError(String message) {
    show(message: message, type: AppToastType.error);
  }

  static void showWarning(String message) {
    show(message: message, type: AppToastType.warning);
  }

  static void showInfo(String message) {
    show(message: message, type: AppToastType.info);
  }

  static void show({
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 5),
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _removeCurrent();

    final entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        type: type,
        duration: duration,
        onDismiss: _removeCurrent,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, _removeCurrent);
  }

  static void dismissCurrent() {
    _removeCurrent();
  }

  static void _removeCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final entry = _currentEntry;
    _currentEntry = null;
    entry?.remove();
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onDismiss();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _ToastTheme.of(widget.type);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final toastWidth = screenWidth < 600
        ? screenWidth - 32
        : (screenWidth * 0.2).clamp(280.0, 420.0);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Material(
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: Curves.easeOut.transform(
                        _controller.value < 0.15
                            ? _controller.value / 0.15
                            : (_controller.value > 0.85
                                  ? (1 - _controller.value) / 0.15
                                  : 1),
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    width: toastWidth,
                    constraints: const BoxConstraints(minHeight: 72),
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
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: scheme.softBackground,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            scheme.icon,
                                            size: 20,
                                            color: scheme.accent,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              widget.message,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.35,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          onPressed: widget.onDismiss,
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, _) {
                                    return FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: 1 - _controller.value,
                                      child: Container(
                                        height: 4,
                                        color: scheme.accent,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
