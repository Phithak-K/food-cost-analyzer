import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Floating Capsule Toast / Notification at Top-Right
/// Styled with Vercel / Linear dark glass aesthetics, crisp glowing borders, and icons.
class CapsuleToast {
  static void showSuccess(BuildContext context, String message, {String? title}) {
    show(
      context,
      message: message,
      title: title,
      icon: Icons.check_circle_rounded,
      accentColor: AppTheme.success,
    );
  }

  static void showError(BuildContext context, String message, {String? title}) {
    show(
      context,
      message: message,
      title: title,
      icon: Icons.error_outline_rounded,
      accentColor: AppTheme.danger,
    );
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    show(
      context,
      message: message,
      title: title,
      icon: Icons.info_outline_rounded,
      accentColor: AppTheme.info,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    IconData icon = Icons.check_circle_rounded,
    Color accentColor = AppTheme.success,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) => _CapsuleToastWidget(
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
        duration: duration,
        onDismissed: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _CapsuleToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final Duration duration;
  final VoidCallback onDismissed;

  const _CapsuleToastWidget({
    this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_CapsuleToastWidget> createState() => _CapsuleToastWidgetState();
}

class _CapsuleToastWidgetState extends State<_CapsuleToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: InkWell(
              onTap: _dismiss,
              borderRadius: BorderRadius.circular(32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420, minWidth: 260),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.22),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xE60F172A),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.accentColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.accentColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.title != null) ...[
                                  Text(
                                    widget.title!,
                                    style: const TextStyle(
                                      color: Color(0xFFF8FAFC),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _dismiss,
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
