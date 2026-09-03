import 'package:flutter/material.dart';
import '../models/floating_particle.dart';
import '../theme/app_colors.dart';

class ParticleLayer extends StatelessWidget {
  final List<FloatingParticle> particles;
  final Function(String) onParticleFinished;

  const ParticleLayer({
    super.key,
    required this.particles,
    required this.onParticleFinished,
  });

  @override
  Widget build(BuildContext context) {
    if (particles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        for (final particle in particles)
          Positioned(
            key: ValueKey(particle.id),
            left: particle.position.dx - 28,
            top: particle.position.dy - 20,
            child: _SingleParticleWidget(
              particle: particle,
              onFinished: () => onParticleFinished(particle.id),
            ),
          ),
      ],
    );
  }
}

class _SingleParticleWidget extends StatefulWidget {
  final FloatingParticle particle;
  final VoidCallback onFinished;

  const _SingleParticleWidget({
    required this.particle,
    required this.onFinished,
  });

  @override
  State<_SingleParticleWidget> createState() => _SingleParticleWidgetState();
}

class _SingleParticleWidgetState extends State<_SingleParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _translateAnimation = Tween<double>(begin: 0.0, end: -70.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 1.2, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onFinished();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.particle.text,
                    style: TextStyle(
                      color: widget.particle.color,
                      fontSize: widget.particle.fontSize,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.9),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                        if (widget.particle.showFireIcon)
                          Shadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                      ],
                    ),
                  ),
                  if (widget.particle.showFireIcon) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.local_fire_department,
                      color: AppColors.primary,
                      size: widget.particle.fontSize * 0.95,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
