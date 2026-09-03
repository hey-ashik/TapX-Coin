import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ultra-premium iOS / Nsave style pull-to-refresh with spinning flower activity indicator.
/// Built using CupertinoSliverRefreshControl to ensure 100% native smooth physics,
/// zero layout interference, and pure jet-black (#000000) background without any overlays.
class AppPullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const AppPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF000000),
      child: CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: Color(0xFFFFFFFF),
          scaffoldBackgroundColor: Color(0xFF000000),
          barBackgroundColor: Color(0xFF000000),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(
            refreshTriggerPullDistance: 75.0,
            refreshIndicatorExtent: 52.0,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await Future.wait([
                onRefresh(),
                Future.delayed(const Duration(milliseconds: 1200)),
              ]);
            },
            builder: (
              BuildContext context,
              RefreshIndicatorMode refreshState,
              double pulledExtent,
              double refreshTriggerPullDistance,
              double refreshIndicatorExtent,
            ) {
              final double percentage =
                  (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
              final bool isSpinning = refreshState == RefreshIndicatorMode.refresh ||
                  refreshState == RefreshIndicatorMode.armed;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2C2C30),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xD9000000),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isSpinning
                        ? const CupertinoActivityIndicator(
                            radius: 11,
                            color: Colors.white,
                          )
                        : Transform.rotate(
                            angle: percentage * 2 * math.pi,
                            child: CupertinoActivityIndicator.partiallyRevealed(
                              radius: 11,
                              progress: percentage.clamp(0.1, 1.0),
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: child,
          ),
        ],
      ),
    ),
  );
  }
}
