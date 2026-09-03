import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TapButton extends StatefulWidget {
  final Function(Offset globalPosition) onTap;

  const TapButton({
    super.key,
    required this.onTap,
  });

  @override
  State<TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<TapButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    setState(() => _isPressed = true);
    _controller.forward();
    widget.onTap(event.position);
  }

  void _handlePointerUp(PointerUpEvent event) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 270,
        height: 270,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer subtle breathing rings
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),

            // Main Interactive Tap Target
            Listener(
              onPointerDown: _handlePointerDown,
              onPointerUp: _handlePointerUp,
              onPointerCancel: _handlePointerCancel,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceCard,
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          if (_isPressed)
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '+',
                          style: TextStyle(
                            fontSize: 68,
                            fontWeight: FontWeight.w200,
                            color: AppColors.primary,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
