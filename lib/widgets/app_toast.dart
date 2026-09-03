import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        isError: isError,
        onDismissed: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismissed;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.onDismissed,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
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
      bottom: 84,
      left: 24,
      right: 24,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: widget.isError
                        ? const Color(0xFFFF5252).withValues(alpha: 0.65)
                        : AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                    if (widget.isError)
                      BoxShadow(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 1,
                      )
                    else
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    height: 1.3,
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
