import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppShimmer extends StatefulWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class AppSkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class AppSkeletonCircle extends StatelessWidget {
  final double size;

  const AppSkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton Loader list for Notifications Modal
class AppSkeletonNotificationList extends StatelessWidget {
  final int itemCount;

  const AppSkeletonNotificationList({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeletonCircle(size: 38),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          AppSkeletonBox(width: 140, height: 14, borderRadius: 4),
                          AppSkeletonBox(width: 16, height: 16, borderRadius: 4),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const AppSkeletonBox(width: double.infinity, height: 11, borderRadius: 4),
                      const SizedBox(height: 4),
                      const AppSkeletonBox(width: 180, height: 11, borderRadius: 4),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          AppSkeletonBox(width: 70, height: 10, borderRadius: 3),
                          AppSkeletonBox(width: 80, height: 10, borderRadius: 3),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton Loader list for Leaderboard Screen
class AppSkeletonLeaderboardList extends StatelessWidget {
  final int itemCount;

  const AppSkeletonLeaderboardList({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                // Rank Circle Skeleton
                const AppSkeletonCircle(size: 32),
                const SizedBox(width: 12),

                // Avatar Skeleton
                const AppSkeletonCircle(size: 40),
                const SizedBox(width: 12),

                // Name & Level Skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonBox(width: 110, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      AppSkeletonBox(width: 75, height: 11, borderRadius: 3),
                    ],
                  ),
                ),

                // Score Skeleton
                const AppSkeletonBox(width: 60, height: 16, borderRadius: 4),
              ],
            ),
          );
        },
      ),
    );
  }
}
